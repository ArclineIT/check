require "ipaddr"

# Whether an address is on the public internet. Lookups are only ever made
# against public addresses, so this tool cannot be pointed at a private network.
module PublicAddress
  RESERVED = %w[
    0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.0.0.0/24 192.0.2.0/24
    192.88.99.0/24 192.168.0.0/16 198.18.0.0/15 198.51.100.0/24 203.0.113.0/24 224.0.0.0/4 240.0.0.0/4
    ::/128 ::1/128 ::ffff:0:0/96 64:ff9b::/96 100::/64 2001:db8::/32 fc00::/7 fe80::/10 ff00::/8
  ].map { |range| IPAddr.new(range) }.freeze

  def self.public?(address)
    ip = IPAddr.new(address.to_s)
    RESERVED.none? { |range| range.family == ip.family && range.include?(ip) }
  rescue IPAddr::Error
    false
  end
end
