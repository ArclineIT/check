# In-memory stand-ins for the network.
class FakeDns
  def initialize(addresses: {}, reverse: {}, txt: {})
    @addresses, @reverse, @txt = addresses, reverse, txt
  end

  def addresses(host) = @addresses.fetch(host, [])
  def reverse(ip) = @reverse[ip]
  def txt(name) = @txt.fetch(name, [])
end

class FakeFetcher
  Result = HeaderFetch::Result

  def self.answering(headers = {}, status: 200, error: nil)
    Class.new do
      define_method(:initialize) { |host, address| @host, @address = host, address }
      define_method(:call) { Result.new(url: "https://#{@host}/", status: status, headers: headers, error: error) }
    end
  end
end
