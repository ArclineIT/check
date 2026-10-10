require "test_helper"

class CdnRangesTest < ActiveSupport::TestCase
  setup do
    @ranges = CdnRanges.new("updated_at" => "2026-01-01", "providers" => {
      "cloudflare" => [ "104.16.0.0/13", "2606:4700::/32" ], "fastly" => [ "151.101.0.0/16" ],
      "cloudfront" => [ "13.32.0.0/15" ], "aws" => [ "13.32.0.0/12", "52.95.110.0/24" ], "gcp" => [ "34.64.0.0/11" ]
    })
  end

  test "matches an address to its provider, in IPv4 and IPv6" do
    assert_equal [ "cloudflare", "104.16.0.0/13" ], @ranges.match("104.17.2.3").then { |m| [ m.provider, m.range ] }
    assert_equal "Cloudflare", @ranges.match("2606:4700::6810:84e5").name
    assert_equal "Fastly", @ranges.match("151.101.1.140").name
    assert_equal "Google Cloud", @ranges.match("34.64.0.1").name
  end

  test "a CloudFront address is reported as the CDN, not the cloud it runs on" do
    match = @ranges.match("13.33.1.1")
    assert_equal "AWS CloudFront", match.name
    assert match.cdn?

    assert_not @ranges.match("52.95.110.7").cdn?
  end

  test "an address outside every range, or not an address, is nil" do
    assert_nil @ranges.match("69.164.205.165")
    assert_nil @ranges.match("2001:db8::1")
    assert_nil @ranges.match("nope")
  end

  test "the shipped range file loads and knows the big providers" do
    shipped = CdnRanges.default

    assert shipped.size > 1000
    assert_equal "Cloudflare", shipped.match("104.16.132.229").name
    assert_equal "Fastly", shipped.match("151.101.1.140").name
    assert_match(/\A\d{4}-\d\d-\d\d\z/, shipped.updated_at)
  end
end
