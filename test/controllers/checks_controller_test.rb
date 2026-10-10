require "test_helper"

class ChecksControllerTest < ActionDispatch::IntegrationTest
  Finding = TransparencyCheck::Finding

  setup do
    @report = TransparencyCheck::Report.new(
      domain: "example.com", addresses: [ "104.17.2.3" ], address: "104.17.2.3", rdns: nil,
      network: AsnLookup::Network.new(asn: 13_335, org: "CLOUDFLARENET", country: "US", prefix: "104.16.0.0/13"),
      findings: [ Finding.new(status: "warn", message: "behind Cloudflare: 104.17.2.3 is in 104.16.0.0/13"), Finding.new(status: "ok", message: "IP not in AWS, Google Cloud or Azure ranges") ],
      checked_at: Time.utc(2026, 6, 1, 12)
    )
  end

  # "domain" is also a url_for option, so it has to travel in params:.
  test "the home page has the form" do
    get root_path

    assert_response :success
    assert_select "form[action='/check'][method=get] input[name=domain]"
  end

  test "shows a report for the normalized domain" do
    checked = nil
    stub_method(TransparencyCheck, :call, ->(domain) { checked = domain; @report }) do
      get check_path(params: { domain: "https://Example.com/pricing" })
    end

    assert_response :success
    assert_equal "example.com", checked
    assert_select "h1", "example.com"
    assert_select ".lead", text: /routed through a CDN/
    assert_select ".status-badge--warn", text: "warn"
    assert_select ".findings__item", 2
    assert_select "meta[http-equiv=refresh]", count: 0
  end

  test "watch re-checks on an interval, within limits" do
    stub_method(TransparencyCheck, :call, @report) do
      get check_path(params: { domain: "example.com", watch: 30 })
      assert_select "meta[http-equiv=refresh][content='30']"

      get check_path(params: { domain: "example.com", watch: 1 })
      assert_select "meta[http-equiv=refresh][content='10']"
    end
  end

  test "answers in JSON and plain text" do
    stub_method(TransparencyCheck, :call, @report) do
      get check_path(format: :json, params: { domain: "example.com" })
      assert_equal [ "example.com", false, "AS13335" ], response.parsed_body.values_at("domain", "self_hosted", "asn")

      get check_path(format: :text, params: { domain: "example.com" })
      assert_includes response.body, "  [WARN] behind Cloudflare: 104.17.2.3 is in 104.16.0.0/13"
    end
  end

  test "an invalid domain is refused before anything is looked up" do
    stub_method(TransparencyCheck, :call, ->(*) { flunk "must not run" }) do
      get check_path(params: { domain: "http://127.0.0.1/admin" })
      assert_redirected_to root_path
      assert_equal "127.0.0.1 is not a valid domain name.", flash[:alert]

      get check_path(format: :json, params: { domain: "localhost" })
      assert_response :unprocessable_entity
      assert_equal "localhost is not a valid domain name.", response.parsed_body["error"]

      get check_path
      assert_redirected_to root_path
    end
  end
end
