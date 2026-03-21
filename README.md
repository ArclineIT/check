# arcline-check

CLI tool that checks whether a domain is genuinely self-hosted or routing through a CDN or cloud provider (Cloudflare, Fastly, AWS CloudFront, etc.).

Core to the Arcline brand — useful as a standalone tool for anyone who wants to verify a host's transparency claims.

## Status

Planned. Not yet started.

## Stack

- Go — single static binary
- Targets: linux/amd64, darwin/arm64, windows/amd64
- No runtime dependencies

## Usage

```sh
arcline-check example.com
arcline-check example.com --json
arcline-check example.com --watch 30
```

## How it works

1. Resolves domain to IP
2. PTR/rDNS lookup
3. ASN/org lookup (ip-api.com or self-hosted fallback)
4. Checks IP against known CDN/cloud CIDR ranges
5. Fetches HTTP headers and inspects for CDN fingerprints (CF-Ray, X-Served-By, Via, X-Cache)

See [todo.md](todo.md) for the full task list and output format spec.

## License

MIT — see [LICENSE](LICENSE).
