require "test_helper"

class AsnLookupTest < ActiveSupport::TestCase
  test "asks Team Cymru for the origin, then the AS description" do
    dns = FakeDns.new(txt: {
      "1.1.16.104.origin.asn.cymru.com" => [ "13335 | 104.16.0.0/20 | US | arin | 2014-03-28" ],
      "AS13335.asn.cymru.com" => [ "13335 | US | arin | 2010-07-14 | CLOUDFLARENET - Cloudflare, Inc., US" ]
    })
    network = AsnLookup.new(dns: dns).call("104.16.1.1")

    assert_equal 13_335, network.asn
    assert_equal "CLOUDFLARENET - Cloudflare, Inc., US", network.org
    assert_equal [ "US", "104.16.0.0/20" ], [ network.country, network.prefix ]
    assert_equal "AS13335  CLOUDFLARENET - Cloudflare, Inc., US", network.to_s
  end

  test "uses the IPv6 zone and the first of several origin ASNs" do
    name = "1.1.1.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.7.4.6.0.6.2.origin6.asn.cymru.com"
    dns = FakeDns.new(txt: { name => [ "13335 64512 | 2606:4700::/44 | US | arin | 2011-11-01" ] })
    network = AsnLookup.new(dns: dns).call("2606:4700::1111")

    assert_equal 13_335, network.asn
    assert_equal "unknown", network.org
  end

  test "an unannounced or malformed address has no network" do
    assert_nil AsnLookup.new(dns: FakeDns.new).call("10.0.0.1")
    assert_nil AsnLookup.new(dns: FakeDns.new).call("not-an-ip")
  end
end
