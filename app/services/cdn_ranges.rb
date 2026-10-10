require "ipaddr"

# Published address ranges of CDNs and cloud providers, from config/cdn_ranges.json
# (refresh with `bin/rails cdn:update`).
class CdnRanges
  PATH = Rails.root.join("config/cdn_ranges.json")
  # A CDN sits in front of the origin; a cloud hosts it. Both mean "not self-hosted".
  CDNS = %w[ cloudflare fastly cloudfront ].freeze
  NAMES = { "cloudflare" => "Cloudflare", "fastly" => "Fastly", "cloudfront" => "AWS CloudFront", "aws" => "AWS", "gcp" => "Google Cloud" }.freeze

  Match = Data.define(:provider, :range) do
    def name = NAMES.fetch(provider, provider)
    def cdn? = CDNS.include?(provider)
  end

  def self.default
    @default ||= new(JSON.parse(File.read(PATH)))
  end

  def initialize(data)
    @updated_at = data["updated_at"]
    @ranges = data.fetch("providers").flat_map do |provider, cidrs|
      cidrs.map { |cidr| [ provider, IPAddr.new(cidr), cidr ] }
    end
  end

  attr_reader :updated_at

  # The most specific range containing the address, preferring a CDN over the
  # cloud it runs on (CloudFront addresses are also AWS addresses).
  def match(address)
    ip = IPAddr.new(address)
    hits = @ranges.select { |_provider, range, _cidr| range.family == ip.family && range.include?(ip) }
    provider, _range, cidr = hits.min_by { |name, range, _cidr| [ CDNS.include?(name) ? 0 : 1, -range.prefix ] }
    Match.new(provider: provider, range: cidr) if provider
  rescue IPAddr::Error
    nil
  end

  def size = @ranges.size
end
