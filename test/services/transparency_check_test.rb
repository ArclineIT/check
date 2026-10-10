require "test_helper"

class TransparencyCheckTest < ActiveSupport::TestCase
  RANGES = CdnRanges.new("providers" => { "cloudflare" => [ "104.16.0.0/13", "2606:4700::/32" ], "cloudfront" => [ "13.32.0.0/15" ], "aws" => [ "3.208.0.0/12" ] })
  NETWORK = AsnLookup::Network

  test "a self-hosted site passes every check" do
    report = check("example.test", addresses: [ "203.1.113.42" ], reverse: { "203.1.113.42" => "server1.arclineit.com" },
                   network: NETWORK.new(asn: 64_496, org: "EXAMPLE-ISP - Example ISP LLC, US", country: "US", prefix: "203.1.113.0/24"),
                   headers: { "server" => "nginx" })

    assert report.self_hosted?
    assert_equal [ "not behind a known CDN", "IP not in AWS, Google Cloud or Azure ranges", "no CDN headers detected (https://example.test/ answered 200)" ],
                 report.findings.map(&:message)
    assert_equal [
      "",
      "  domain      example.test",
      "  resolved    203.1.113.42",
      "  rdns        server1.arclineit.com",
      "  asn         AS64496",
      "  org         EXAMPLE-ISP - Example ISP LLC, US",
      "",
      "  [OK]   not behind a known CDN",
      "  [OK]   IP not in AWS, Google Cloud or Azure ranges",
      "  [OK]   no CDN headers detected (https://example.test/ answered 200)",
      ""
    ].join("\n"), report.to_text
  end

  test "a site behind Cloudflare is flagged by range and by headers" do
    report = check("example.test", addresses: [ "2606:4700::1", "104.17.2.3" ], headers: { "cf-ray" => "8a1b", "server" => "cloudflare" })

    assert_not report.self_hosted?
    assert_equal "104.17.2.3", report.address, "IPv4 is the headline address"
    assert_equal [ "warn", "behind Cloudflare: 104.17.2.3 is in 104.16.0.0/13" ], report.findings.first.to_h.values
    assert_includes report.findings.map(&:message), "Cloudflare headers detected: cf-ray, server"
  end

  test "a site on AWS is flagged as cloud-hosted but not as behind a CDN" do
    report = check("example.test", addresses: [ "3.211.157.115" ])

    assert_equal %w[ ok warn ok ], report.findings.map(&:status)
    assert_equal "hosted on AWS: 3.211.157.115 is in 3.208.0.0/12", report.findings.second.message
  end

  test "CloudFront counts once, as the CDN" do
    report = check("example.test", addresses: [ "13.33.1.1" ], network: NETWORK.new(asn: 16_509, org: "AMAZON-02 - Amazon.com, Inc., US", country: "US", prefix: "13.32.0.0/15"))

    assert_equal [ "behind AWS CloudFront: 13.33.1.1 is in 13.32.0.0/15", "IP not in AWS, Google Cloud or Azure ranges" ], report.findings.first(2).map(&:message)
  end

  test "providers without a published list are recognised by the announcing network" do
    akamai = check("example.test", addresses: [ "23.1.2.3" ], network: NETWORK.new(asn: 20_940, org: "AKAMAI-ASN1, NL", country: "NL", prefix: "23.0.0.0/12"))
    assert_match "behind Akamai: the address is announced by AS20940", akamai.findings.first.message

    azure = check("example.test", addresses: [ "20.1.2.3" ], network: NETWORK.new(asn: 8075, org: "MICROSOFT-CORP-MSN-AS-BLOCK, US", country: "US", prefix: "20.0.0.0/11"))
    assert_match "hosted on Microsoft Azure", azure.findings.second.message

    linode = check("example.test", addresses: [ "69.164.205.165" ], network: NETWORK.new(asn: 63_949, org: "AKAMAI-LINODE-AP - Akamai Connected Cloud, SG", country: "US", prefix: "69.164.192.0/20"))
    assert linode.self_hosted?, "a rented server at Linode is not a CDN"
  end

  test "headers that cannot be fetched are noted without failing the check" do
    report = check("example.test", addresses: [ "203.1.113.42" ], error: "Connection refused")

    assert report.self_hosted?
    assert_equal [ "info", "could not fetch headers: Connection refused" ], report.findings.last.to_h.values
  end

  test "a domain that does not resolve, or only to private addresses, is not checked" do
    missing = check("nope.test", addresses: [])
    assert_not missing.resolved?
    assert_not missing.self_hosted?
    assert_equal "nope.test does not resolve to an address", missing.findings.sole.message

    internal = check("intranet.test", addresses: [ "10.0.0.5", "::1" ], fetcher: Class.new { def initialize(*) = flunk("must not connect") })
    assert_not internal.resolved?
    assert_match "private or reserved address", internal.findings.sole.message
  end

  test "the JSON form carries the verdict and findings" do
    json = check("example.test", addresses: [ "104.17.2.3" ]).as_json

    assert_equal false, json[:self_hosted]
    assert_equal "104.17.2.3", json[:resolved]
    assert_equal({ status: "warn", message: "behind Cloudflare: 104.17.2.3 is in 104.16.0.0/13" }, json[:findings].first)
  end

  private
    def check(domain, addresses:, reverse: {}, network: nil, headers: {}, error: nil, fetcher: nil)
      asn = Object.new.tap { |fake| fake.define_singleton_method(:call) { |_address| network } }
      TransparencyCheck.call(domain, dns: FakeDns.new(addresses: { domain => addresses }, reverse: reverse), asn: asn, ranges: RANGES,
                             fetcher: fetcher || FakeFetcher.answering(headers, error: error))
    end
end
