# Turns what someone typed or pasted (a URL, a host with a port, mixed case)
# into a bare hostname, or raises if it cannot be one.
module DomainName
  Invalid = Class.new(StandardError)
  LABEL = /\A[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\z/

  def self.parse(input)
    host = input.to_s.strip.downcase.sub(%r{\A[a-z][a-z0-9+.-]*://}, "").sub(%r{[/?#].*\z}, "").sub(/\A[^@]*@/, "").sub(/:\d+\z/, "").chomp(".")
    labels = host.split(".")

    raise Invalid, "Enter a domain name, such as example.com." if host.empty?
    raise Invalid, "#{host.truncate(60)} is not a valid domain name." unless host.length <= 253 && labels.size >= 2 && labels.all?(LABEL) && labels.last.match?(/[a-z]/)
    host
  end
end
