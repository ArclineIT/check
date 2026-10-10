require "net/http"

# Downloads the providers' published ranges and rewrites config/cdn_ranges.json.
class CdnRangesUpdate
  SOURCES = {
    "cloudflare" => %w[ https://www.cloudflare.com/ips-v4 https://www.cloudflare.com/ips-v6 ],
    "fastly" => %w[ https://api.fastly.com/public-ip-list ],
    "aws" => %w[ https://ip-ranges.amazonaws.com/ip-ranges.json ],
    "gcp" => %w[ https://www.gstatic.com/ipranges/cloud.json ]
  }.freeze

  def call
    providers = {
      "cloudflare" => SOURCES["cloudflare"].flat_map { |url| fetch(url).split },
      "fastly" => JSON.parse(fetch(SOURCES["fastly"].first)).values_at("addresses", "ipv6_addresses").flatten,
      "gcp" => JSON.parse(fetch(SOURCES["gcp"].first))["prefixes"].map { |prefix| prefix["ipv4Prefix"] || prefix["ipv6Prefix"] }
    }

    aws = JSON.parse(fetch(SOURCES["aws"].first))
    entries = aws["prefixes"].map { |p| [ p["service"], p["ip_prefix"] ] } + aws["ipv6_prefixes"].map { |p| [ p["service"], p["ipv6_prefix"] ] }
    providers["cloudfront"] = entries.select { |service, _| service == "CLOUDFRONT" }.map(&:last)
    providers["aws"] = entries.map(&:last) - providers["cloudfront"]

    providers.transform_values! { |cidrs| cidrs.compact.uniq.each { |cidr| IPAddr.new(cidr) }.sort }
    raise "a provider returned no ranges: #{providers.select { |_, v| v.empty? }.keys.join(', ')}" if providers.values.any?(&:empty?)

    data = { "updated_at" => Date.current.iso8601, "sources" => SOURCES.values.flatten, "providers" => providers.sort.to_h }
    File.write(CdnRanges::PATH, JSON.generate(data).gsub('],"', "],\n\"") + "\n")
    providers.transform_values(&:size)
  end

  private
    def fetch(url)
      response = Net::HTTP.get_response(URI.parse(url))
      raise "#{url} answered #{response.code}" unless response.is_a?(Net::HTTPSuccess)
      response.body
    end
end
