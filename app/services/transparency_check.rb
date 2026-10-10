# Answers one question about a domain: is it served from its own host, or does
# it sit behind a CDN or on a hyperscale cloud? Combines the resolved address,
# reverse DNS, the announcing network, published provider ranges and response
# headers.
class TransparencyCheck
  Finding = Data.define(:status, :message) do
    def ok? = status == "ok"
    def tag = { "ok" => "[OK]", "warn" => "[WARN]", "info" => "[INFO]" }.fetch(status)
  end

  # Networks named by who announces them, for providers without a published list.
  CDN_NETWORKS = {
    /cloudflare/i => "Cloudflare", /fastly/i => "Fastly", /\bakamai(?!.*(linode|connected cloud))/i => "Akamai",
    /cdn77|datacamp/i => "CDN77", /bunny/i => "BunnyCDN", /incapsula|imperva/i => "Imperva", /sucuri/i => "Sucuri",
    /stackpath|highwinds/i => "StackPath", /vercel/i => "Vercel", /netlify/i => "Netlify"
  }.freeze
  CLOUD_NETWORKS = { /amazon|\baws\b/i => "AWS", /google/i => "Google Cloud", /microsoft/i => "Microsoft Azure" }.freeze

  Report = Data.define(:domain, :addresses, :address, :rdns, :network, :findings, :checked_at) do
    def resolved? = address.present?
    def self_hosted? = resolved? && findings.none? { |finding| finding.status == "warn" }

    def as_json(*)
      {
        domain: domain, resolved: address, addresses: addresses, rdns: rdns,
        asn: network && "AS#{network.asn}", org: network&.org, self_hosted: self_hosted?,
        findings: findings.map(&:to_h), checked_at: checked_at.utc.iso8601
      }
    end

    def to_text(color: false)
      paint = ->(finding) do
        next finding.tag unless color
        code = { "ok" => 32, "warn" => 33, "info" => 36 }.fetch(finding.status)
        "\e[#{code}m#{finding.tag}\e[0m"
      end
      rows = [ [ "domain", domain ], [ "resolved", address || "—" ], [ "rdns", rdns || "—" ],
               [ "asn", network ? "AS#{network.asn}" : "—" ], [ "org", network&.org || "—" ] ]

      [ "", *rows.map { |label, value| format("  %-10s  %s", label, value) }, "",
        *findings.map { |finding| "  #{paint.call(finding)}#{' ' * (7 - finding.tag.length)}#{finding.message}" }, "" ].join("\n")
    end
  end

  def self.call(domain, **options)
    new(domain, **options).call
  end

  def initialize(domain, dns: DnsLookup.new, asn: nil, ranges: CdnRanges.default, fetcher: HeaderFetch)
    @domain = domain
    @dns = dns
    @asn = asn || AsnLookup.new(dns: dns)
    @ranges = ranges
    @fetcher = fetcher
    @findings = []
  end

  def call
    addresses = @dns.addresses(@domain)
    return unresolved(addresses, "#{@domain} does not resolve to an address") if addresses.empty?

    # Prefer IPv4 for the headline address, as most visitors still arrive that way.
    address = addresses.find { |a| PublicAddress.public?(a) && !a.include?(":") } || addresses.find { |a| PublicAddress.public?(a) }
    return unresolved(addresses, "#{@domain} resolves to a private or reserved address, which cannot be checked") if address.nil?

    network = @asn.call(address)
    check_ranges([ address ] | addresses, network)
    check_headers(address)

    Report.new(domain: @domain, addresses: addresses, address: address, rdns: @dns.reverse(address),
               network: network, findings: @findings, checked_at: Time.current)
  end

  private
    def unresolved(addresses, message)
      Report.new(domain: @domain, addresses: addresses, address: nil, rdns: nil, network: nil,
                 findings: [ Finding.new(status: "warn", message: message) ], checked_at: Time.current)
    end

    def finding(status, message)
      @findings << Finding.new(status: status, message: message)
    end

    def check_ranges(addresses, network)
      matches = addresses.filter_map { |address| (match = @ranges.match(address)) && [ address, match ] }
      cdn = matches.find { |_address, match| match.cdn? }
      cloud = matches.find { |_address, match| !match.cdn? }
      cdn_network = named(CDN_NETWORKS, network)
      cloud_network = named(CLOUD_NETWORKS, network)

      if cdn
        finding "warn", "behind #{cdn.last.name}: #{cdn.first} is in #{cdn.last.range}"
      elsif cdn_network
        finding "warn", "behind #{cdn_network}: the address is announced by AS#{network.asn} (#{network.org})"
      else
        finding "ok", "not behind a known CDN"
      end

      if cloud
        finding "warn", "hosted on #{cloud.last.name}: #{cloud.first} is in #{cloud.last.range}"
      elsif cloud_network && !cdn
        finding "warn", "hosted on #{cloud_network}: the address is announced by AS#{network.asn} (#{network.org})"
      else
        finding "ok", "IP not in AWS, Google Cloud or Azure ranges"
      end
    end

    def named(table, network)
      return if network.nil?

      table.find { |pattern, _name| network.org.match?(pattern) }&.last
    end

    def check_headers(address)
      response = @fetcher.new(@domain, address).call
      return finding("info", "could not fetch headers: #{response.error}") if response.error

      hits = HeaderFingerprint.detect(response.headers)
      if hits.empty?
        finding "ok", "no CDN headers detected (#{response.url} answered #{response.status})"
      else
        hits.group_by(&:provider).each do |provider, group|
          finding "warn", "#{provider} headers detected: #{group.map(&:header).join(', ')}"
        end
      end
    end
end
