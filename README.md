# Arcline Check

Checks whether a domain is genuinely self-hosted or routed through a CDN or
cloud provider (Cloudflare, Fastly, AWS CloudFront, AWS, Google Cloud, Azure
and others).

Core to the Arcline brand, and useful to anyone who wants to verify a host's
transparency claims.

This was planned as a Go command-line tool and is built instead as a Ruby on
Rails app: a web page, a JSON and plain-text endpoint for scripting, and a
terminal command.

## Use it

In the browser, enter a domain on the home page. For scripts:

```sh
curl 'https://check.arcline.it/check.txt?domain=example.com'
curl 'https://check.arcline.it/check.json?domain=example.com'
```

From a checkout:

```sh
bin/rails 'check:domain[example.com]'
FORMAT=json bin/rails 'check:domain[example.com]'
```

The terminal command exits 1 when the domain is behind a CDN or on a cloud.

```
  domain      example.com
  resolved    203.0.113.42
  rdns        server1.arclineit.com
  asn         AS64496
  org         EXAMPLE-ISP - Example ISP LLC, US

  [OK]   not behind a known CDN
  [OK]   IP not in AWS, Google Cloud or Azure ranges
  [OK]   no CDN headers detected (https://example.com/ answered 200)
```

Add `&watch=30` to the page address to re-check every 30 seconds, which is
handy while DNS changes propagate during a migration.

## How it works

1. Resolves the domain to its A and AAAA records.
2. Looks up reverse DNS for the address.
3. Finds the network that announces the address (AS number and organisation)
   through Team Cymru's IP-to-ASN service, which is queried over DNS and needs
   no API key.
4. Compares every address with the providers' published ranges in
   `config/cdn_ranges.json`. Providers without a published list, such as Akamai
   and Azure, are recognised by the announcing network instead.
5. Fetches the home page and inspects the response headers for CDN
   fingerprints (`CF-Ray`, `X-Served-By`, `Via`, `X-Cache` and others).

A rented server at a hosting company is not treated as a CDN. Only CDNs and
the three hyperscale clouds raise a warning.

## Keeping the ranges current

```sh
bin/rails cdn:update
```

This downloads the current lists from Cloudflare, Fastly, AWS and Google Cloud
and rewrites `config/cdn_ranges.json`. Commit the result. Run it every month
or so; the file records the date it was last refreshed.

## Safety

The app makes outbound requests on behalf of whoever uses it, so:

- Input must be a public hostname. IP addresses, single-label names and
  anything else are refused.
- A domain that resolves only to private, loopback, link-local or otherwise
  reserved addresses is not contacted.
- The header request connects to the exact address that was vetted, so a
  second DNS answer cannot redirect it.
- Checks are limited to 30 a minute per client.

## Requirements

- Ruby 4.0+
- No database

## Setup

```bash
bin/setup --skip-server
bin/rails server          # http://localhost:3000, or PORT if set
```

## Tests

```bash
bin/rails test
bin/rubocop
bin/brakeman
```

The tests do not touch the network.

## License

MIT. See [LICENSE](LICENSE).
