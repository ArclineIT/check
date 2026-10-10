require "test_helper"

class HeaderTest < ActiveSupport::TestCase
  include LocalServerHelper

  test "fingerprints the common CDNs" do
    { { "cf-ray" => "8a1b-DFW", "server" => "cloudflare" } => "Cloudflare",
      { "x-served-by" => "cache-dfw-kdfw8210", "via" => "1.1 varnish" } => "Fastly",
      { "x-amz-cf-id" => "abc", "via" => "1.1 x.cloudfront.net (CloudFront)", "x-cache" => "Hit from cloudfront" } => "AWS CloudFront",
      { "x-vercel-id" => "iad1::abc" } => "Vercel",
      { "x-azure-ref" => "0abc" } => "Azure Front Door" }.each do |headers, provider|
      assert_includes HeaderFingerprint.detect(headers).map(&:provider), provider
    end
  end

  test "an ordinary origin server has no fingerprints" do
    headers = { "server" => "nginx/1.26.0", "x-cache" => "HIT", "x-served-by" => "web-01", "via" => "1.1 internal-proxy", "content-type" => "text/html" }
    assert_empty HeaderFingerprint.detect(headers)
  end

  test "fetches headers from the given address, whatever the hostname resolves to" do
    with_http_server(http_response(200, "ok", "Server" => "nginx", "X-Thing" => "1")) do |port, requests|
      result = fetch_on(port, "does-not-resolve.invalid")

      assert_nil result.error
      assert_equal 200, result.status
      assert_equal "nginx", result.headers["server"]
      assert_match "Host: does-not-resolve.invalid", requests.first
      assert_match "User-Agent: arcline-check/1.0", requests.first
    end
  end

  test "reports a failed fetch instead of raising" do
    result = fetch_on(closed_port, "example.test")

    assert_nil result.status
    assert_match(/refused/i, result.error)
  end

  private
    # HeaderFetch speaks to 443 then 80; point both attempts at the test server.
    def fetch_on(port, host)
      fetch = HeaderFetch.new(host, "127.0.0.1")
      original = Net::HTTP.method(:new)
      stub_method(Net::HTTP, :new, ->(name, _port) { original.call(name, port).tap { |http| http.define_singleton_method(:use_ssl=) { |_| } } }) do
        fetch.call
      end
    end
end
