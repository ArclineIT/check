# arcline-check — CDN / Transparency Auditor

Checks whether a domain is truly self-hosted or routing through a CDN/cloud
provider (Cloudflare, Fastly, AWS CloudFront, etc.). Core to the Arcline brand.

## Stack
- Language: Go
- Distribution: single static binary (linux/amd64, darwin/arm64, windows/amd64)
- No runtime dependencies

## Features
- [ ] Resolve domain → IP
- [ ] Reverse DNS lookup (PTR record)
- [ ] ASN / org lookup via ip-api.com or ipinfo.io (self-hosted fallback)
- [ ] Detect known CDN/cloud CIDR ranges (Cloudflare, Fastly, AWS, GCP, Azure)
- [ ] HTTP header inspection (CF-Ray, X-Served-By, Via, Server, X-Cache)
- [ ] Output: clean terminal report (color-coded pass/fail)
- [ ] Output: --json flag for scripting
- [ ] --watch flag: re-check every N seconds (useful during DNS migration)

## CLI interface
```
arcline-check example.com
arcline-check example.com --json
arcline-check example.com --watch 30
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
- [ ] Project scaffold (go mod init, cmd/, internal/)
- [ ] DNS resolution + PTR lookup
- [ ] ASN lookup (HTTP call to free API, cache result)
- [ ] CDN CIDR list (embed JSON, update via Makefile)
- [ ] HTTP header fetch + CDN header detection
- [ ] Report renderer (color terminal + JSON)
- [ ] --watch mode
- [ ] Cross-compile Makefile targets
- [ ] README with usage examples
- [ ] GitLab CI: build + release binaries on tag
