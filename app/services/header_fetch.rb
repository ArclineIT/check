require "net/http"
require "openssl"

# Fetches a site's response headers. The connection goes to the address that
# was already resolved and vetted, so the lookup cannot be redirected to a
# private host between the DNS answer and the request.
class HeaderFetch
  TIMEOUT = 8
  Result = Data.define(:url, :status, :headers, :error)

  def initialize(host, address)
    @host = host
    @address = address
  end

  # HTTPS first; plain HTTP if the site does not answer on 443.
  def call
    secure = request("https", 443)
    return secure if secure.error.nil?

    plain = request("http", 80)
    plain.error.nil? ? plain : secure
  end

  private
    def request(scheme, port)
      http = Net::HTTP.new(@host, port)
      http.ipaddr = @address
      http.use_ssl = scheme == "https"
      # The certificate is not what is being judged here, only the headers.
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?
      http.open_timeout = http.read_timeout = TIMEOUT

      response = http.request_get("/", "User-Agent" => "arcline-check/1.0", "Accept" => "*/*") { |_response| break _response }
      headers = response.each_header.to_h.transform_keys(&:downcase)
      Result.new(url: "#{scheme}://#{@host}/", status: response.code.to_i, headers: headers, error: nil)
    rescue SystemCallError, SocketError, IOError, Timeout::Error, OpenSSL::SSL::SSLError, Net::ProtocolError => e
      Result.new(url: "#{scheme}://#{@host}/", status: nil, headers: {}, error: e.message.truncate(140))
    end
end
