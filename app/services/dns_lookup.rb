require "resolv"

# The DNS questions this app asks, each with a timeout and without raising.
class DnsLookup
  TIMEOUT = 5

  def addresses(host)
    query { |dns| dns.getaddresses(host).map(&:to_s) } || []
  end

  def reverse(ip)
    query { |dns| dns.getname(ip).to_s }
  end

  def txt(name)
    query { |dns| dns.getresources(name, Resolv::DNS::Resource::IN::TXT).map { |record| record.strings.join } } || []
  end

  private
    def query
      Resolv::DNS.open do |dns|
        dns.timeouts = TIMEOUT
        yield dns
      end
    rescue Resolv::ResolvError, Resolv::ResolvTimeout, SystemCallError
      nil
    end
end
