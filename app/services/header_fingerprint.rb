# Recognises CDNs and edge platforms from the response headers they add.
module HeaderFingerprint
  Hit = Data.define(:provider, :header, :value)

  # provider => { header name => pattern the value must match (nil: presence is enough) }
  SIGNATURES = {
    "Cloudflare" => { "cf-ray" => nil, "cf-cache-status" => nil, "server" => /\Acloudflare/i },
    "Fastly" => { "x-fastly-request-id" => nil, "x-served-by" => /\Acache-/i, "fastly-debug-digest" => nil },
    "AWS CloudFront" => { "x-amz-cf-id" => nil, "x-amz-cf-pop" => nil, "via" => /cloudfront/i, "x-cache" => /cloudfront/i },
    "Akamai" => { "x-akamai-transformed" => nil, "x-akamai-request-id" => nil, "server" => /\AAkamai/i },
    "Azure Front Door" => { "x-azure-ref" => nil, "x-fd-healthprobe" => nil },
    "Google Cloud CDN" => { "via" => /\b1\.1 google\b/i },
    "Vercel" => { "x-vercel-id" => nil, "server" => /\AVercel/i },
    "Netlify" => { "x-nf-request-id" => nil, "server" => /\ANetlify/i },
    "Sucuri" => { "x-sucuri-id" => nil, "server" => /\ASucuri/i },
    "Imperva" => { "x-iinfo" => nil, "x-cdn" => /imperva|incapsula/i },
    "BunnyCDN" => { "cdn-pullzone" => nil, "server" => /\ABunnyCDN/i },
    "KeyCDN" => { "server" => /\Akeycdn/i },
    "Varnish" => { "via" => /varnish/i, "x-varnish" => nil }
  }.freeze

  # +headers+ is a hash of lowercase names to values.
  def self.detect(headers)
    SIGNATURES.flat_map do |provider, signature|
      signature.filter_map do |name, pattern|
        value = headers[name]
        Hit.new(provider: provider, header: name, value: value) if value.present? && (pattern.nil? || value.match?(pattern))
      end
    end
  end
end
