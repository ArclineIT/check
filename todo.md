# arcline-check — CDN / Transparency Auditor

Checks whether a domain is truly self-hosted or routing through a CDN/cloud
provider (Cloudflare, Fastly, AWS CloudFront, etc.). Core to the Arcline brand.

## Stack
- Ruby on Rails 8.1, no database
- Web page, JSON and text endpoints, and a rake task for the terminal

## Features
- [x] Resolve domain → IP
- [x] Reverse DNS lookup (PTR record)
- [x] ASN / org lookup (Team Cymru over DNS, no API key)
- [x] Detect known CDN/cloud CIDR ranges (Cloudflare, Fastly, CloudFront, AWS, GCP; Azure and Akamai by network)
- [x] HTTP header inspection (CF-Ray, X-Served-By, Via, Server, X-Cache)
- [x] Output: web report and terminal report (color-coded)
- [x] Output: JSON (`/check.json`, `FORMAT=json`)
- [x] Watch: re-check every N seconds (`&watch=30`)

## Interface
```
bin/rails 'check:domain[example.com]'
FORMAT=json bin/rails 'check:domain[example.com]'
GET /check?domain=example.com          (also .json and .txt, and &watch=30)
```

## Output format
```
$ arcline-check example.com

  domain      example.com
  resolved    203.0.113.42
  rdns        server1.arclineit.com
  asn         AS64496  Example ISP
  org         Example ISP LLC

  [OK]  not behind a known CDN
  [OK]  no Cloudflare headers detected
  [OK]  IP not in AWS/GCP/Azure ranges
```

## Tasks
- [x] Rails app scaffold
- [x] DNS resolution + PTR lookup
- [x] ASN lookup
- [x] CDN CIDR list (`config/cdn_ranges.json`, refreshed with `bin/rails cdn:update`)
- [x] HTTP header fetch + CDN header detection
- [x] Report renderer (web, text, JSON)
- [x] Watch mode
- [x] README with usage examples
- [ ] Publish Azure's ranges (the download address changes weekly)
- [ ] Refresh the range file on a schedule in CI
