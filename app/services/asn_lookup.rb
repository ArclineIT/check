require "ipaddr"

# Finds the network (AS number and organisation) that announces an address,
# using Team Cymru's IP-to-ASN service over DNS. No API key, no HTTP.
class AsnLookup
  Network = Data.define(:asn, :org, :country, :prefix) do
    def to_s = "AS#{asn}  #{org}"
  end

  def initialize(dns: DnsLookup.new)
    @dns = dns
  end

  def call(address)
    ip = IPAddr.new(address)
    zone = ip.ipv4? ? "origin.asn.cymru.com" : "origin6.asn.cymru.com"
    name = ip.ipv4? ? ip.reverse.delete_suffix(".in-addr.arpa") : ip.reverse.delete_suffix(".ip6.arpa")

    # "13335 | 104.16.0.0/13 | US | arin | 2014-03-28"; several ASNs may share one answer.
    origin = @dns.txt("#{name}.#{zone}").first or return
    asns, prefix, country = origin.split("|").map(&:strip)
    asn = asns.split.first or return

    # "13335 | US | arin | 2010-07-14 | CLOUDFLARENET, US"
    description = @dns.txt("AS#{asn}.asn.cymru.com").first.to_s.split("|").last.to_s.strip
    Network.new(asn: asn.to_i, org: description.presence || "unknown", country: country.to_s, prefix: prefix.to_s)
  rescue IPAddr::Error
    nil
  end
end
