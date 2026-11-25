# Customer guide: managing ingress and egress with parameters

Everything below is a CloudFormation parameter on `firewall-master.yaml` (or the matching child template).
Change the value, run `./scripts/deploy.sh` again, review the change set, execute. No rule editing, no console clicking.
Rule groups update in place; the firewall endpoints are not replaced.

## 1. Pick the model

| Question | Parameter | Values |
|---|---|---|
| Is outbound deny-by-default? | `EgressMode` | `allowlist` (only what you list is reachable) or `open` (everything except what you block) |
| Is inbound deny-by-default? | `IngressMode` | `restricted` (only listed sources and ports) or `open` |
| Traffic between your own subnets/VPCs | `EastWestMode` | `allow-all` or `ports-only` |
| Observe first or enforce? | `EnforcementMode` | `alert` (log only) or `drop` (block) |

Start with `EnforcementMode=alert`, look at the dashboard for a week, then switch to `drop`.

## 2. Egress: websites and applications

**App presets** (one parameter per app, each `none` / `allow` / `block`):
`PresetGoogle`, `PresetYouTube`, `PresetFacebook`, `PresetInstagram`, `PresetWhatsApp`, `PresetX`,
`PresetLinkedIn`, `PresetTikTok`, `PresetMicrosoft365`, `PresetNetflix`.

**Custom lists** (any domain, comma-separated, leading dot includes subdomains):
- `DomainAllowlist`: always allowed (for example `.github.com,.docker.io,api.partner.com`)
- `DomainDenylist`: always blocked

**Other egress openings:**
- `EgressAllowedTcpPorts` / `EgressAllowedUdpPorts`: ports open to any destination (mail 25,587, databases, NTP 123)
- `EgressAllowedDestinationCidrs`: partner or on-prem ranges reachable on any port

### Examples

Business-only outbound: Microsoft 365 and Google allowed, social media blocked, plus a few custom domains.

```json
{"ParameterKey":"EgressMode","ParameterValue":"allowlist"},
{"ParameterKey":"PresetMicrosoft365","ParameterValue":"allow"},
{"ParameterKey":"PresetGoogle","ParameterValue":"allow"},
{"ParameterKey":"PresetFacebook","ParameterValue":"block"},
{"ParameterKey":"PresetInstagram","ParameterValue":"block"},
{"ParameterKey":"PresetTikTok","ParameterValue":"block"},
{"ParameterKey":"DomainAllowlist","ParameterValue":".github.com,.docker.io,.amazonaws.com"}
```

Open internet except social and streaming:
```json
{"ParameterKey":"EgressMode","ParameterValue":"open"},
{"ParameterKey":"PresetFacebook","ParameterValue":"block"},
{"ParameterKey":"PresetInstagram","ParameterValue":"block"},
{"ParameterKey":"PresetWhatsApp","ParameterValue":"block"},
{"ParameterKey":"PresetNetflix","ParameterValue":"block"},
{"ParameterKey":"PresetYouTube","ParameterValue":"block"}
```

### Things customers must understand
1. **Presets are starter lists, not guarantees.** Large platforms use many CDN and API domains that change. Verify with the alert log and add domains to `DomainDenylist` / `DomainAllowlist` as needed.
2. **Google vs YouTube overlap.** YouTube video comes from `googlevideo.com`; the Google preset deliberately excludes `googleapis.com` so blocking Google does not break apps that call Google APIs. Add it yourself if you want it blocked.
3. **QUIC.** Chrome and many Google/YouTube/Meta apps use QUIC (UDP 443), which Network Firewall cannot read by domain. `BlockQuic=true` (default) forces TCP/TLS fallback so domain rules work. Leave it on.
4. **Encrypted traffic.** Domain rules read the TLS SNI or HTTP Host, which works without decrypting. Per-URL, per-user or per-category filtering needs TLS inspection (off by default) or a different tool.
5. **Same rules for the whole firewall.** No per-user or per-group policy. Different audiences need different firewalls or VPCs.

## 3. Ingress

| Parameter | Meaning | Default |
|---|---|---|
| `IngressMode` | `restricted` or `open` | `restricted` |
| `IngressAllowedSourceCidrs` | who may connect | `0.0.0.0/0` |
| `IngressAllowedTcpPorts` | for example `80,443,8000:8100` | `80,443` |
| `IngressAllowedUdpPorts` | for example `51820` | none |
| `AdminAllowedCidrs` | who may SSH/RDP in (everyone else denied) | placeholder, nothing allowed |
| `BlockedIpCidrs` | always blocked both directions | placeholder |

Ingress always passes the threat checks (blocked IPs, managed malware/botnet lists, custom IPS signatures) first.
Inbound web apps behind an ALB still need AWS WAF for HTTP-layer protection.

## 4. East-west
`EastWestMode=allow-all` keeps internal traffic flowing (threat rules still apply).
`ports-only` plus `EastWestAllowedTcpPorts=443,5432` allows only those internal TCP ports; everything else between internal addresses is dropped.
For multi-VPC designs set `HomeNetCidrs` to all VPC CIDRs so they count as internal.

## 5. DNS
`AllowedDnsResolverCidrs` lists resolvers workloads may reach through the firewall; other DNS and DNS-over-TLS are blocked.
Queries to the Amazon-provided resolver never cross the firewall, so use Route 53 Resolver DNS Firewall for domain-level DNS control.

## 6. Safe change procedure
1. Edit the parameter file, keep `EnforcementMode=alert` for new rules.
2. `./scripts/deploy.sh` and read the change set. Expect updates to rule groups and the policy only.
3. Watch the blocked-alerts widget and Logs Insights, then switch to `drop`.
4. Roll back by restoring the previous parameter file and updating the stack.
