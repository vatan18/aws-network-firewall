# AWS Network Firewall vs Sophos POC package

| Document | What it is |
|---|---|
| [`cloudformation/`](cloudformation) | Production-oriented CloudFormation for AWS Network Firewall (parent + nested stacks) |
| [`docs/customer-guide.md`](docs/customer-guide.md) | How customers manage ingress, egress, east-west and domain lists through parameters |
| [`docs/sophos-setup.md`](docs/sophos-setup.md) | Sophos Firewall on AWS: options, licensing, setup, policy, HA, operations |
| [`docs/comparison.md`](docs/comparison.md) | Feature comparison, cost model, results sheet, weighted decision matrix |
| [`docs/pitch.md`](docs/pitch.md) | The case for AWS Network Firewall, including where Sophos is better |
| [`scripts/deploy.sh`](scripts/deploy.sh) | Package, validate, change-set review, deploy |

## What is in the CloudFormation
| Template | Purpose |
|---|---|
| `firewall-master.yaml` | Parent stack with all customer-facing parameters |
| `08-logging-monitoring.yaml` | KMS key, alert log group, S3 archive, SNS, alarms, dashboard (deployed first) |
| `02-network-firewall-rule-groups.yaml` | Stateless baseline; IP/domain denylists; allowlist; **app presets (Google, YouTube, Facebook, Instagram, WhatsApp, X, LinkedIn, TikTok, Microsoft 365, Netflix)**; **traffic policy (ingress, east-west, egress ports/CIDRs, QUIC)**; SSH/RDP; DNS; IPS |
| `03-network-firewall-policy.yaml` | Strict-order policy; `EnforcementMode` alert/drop; `EgressMode` allowlist/open |
| `04-network-firewall-deployment.yaml` | Firewall (endpoint per AZ), protections, logging |
| `09-cfn-deployment-role.yaml` | Least-privilege CloudFormation service role |

Validated with `cfn-lint` 1.61.0 (only warnings: relative nested template paths, resolved by `aws cloudformation package`).
**Not yet deployed to an AWS account.** Still to build: `01` VPC, `05` routing, `06`/`07` Transit Gateway and centralized inspection.

## Quick start
```bash
# 1. edit cloudformation/params/poc-existing-vpc.json (VPC, firewall subnets, AZs)
# 2. deploy (reviews a change set before executing)
./scripts/deploy.sh anfw-poc-firewall <artifact-bucket> cloudformation/params/poc-existing-vpc.json
# 3. watch the CloudWatch dashboard "<project>-<env>-network-firewall"; switch EnforcementMode to drop when ready
```

## How the customer controls traffic (summary)
- **Egress:** `EgressMode` (allowlist or open), app presets `Preset*` = none/allow/block, `DomainAllowlist`, `DomainDenylist`, `EgressAllowedTcpPorts`, `EgressAllowedUdpPorts`, `EgressAllowedDestinationCidrs`, `BlockQuic`.
- **Ingress:** `IngressMode`, `IngressAllowedSourceCidrs`, `IngressAllowedTcpPorts`, `IngressAllowedUdpPorts`, `AdminAllowedCidrs`, `BlockedIpCidrs`.
- **East-west:** `EastWestMode`, `EastWestAllowedTcpPorts`, `HomeNetCidrs`.
- **Rollout:** `EnforcementMode`, `StreamExceptionPolicy`. Details and examples in `docs/customer-guide.md`.

## Order of work
1. Deploy the firewall stack in alert mode (non-disruptive; changes no routes).
2. Build and review routing (`05`), then route one subnet or AZ at a time.
3. Run the test plan against AWS and Sophos, fill `docs/comparison.md` sections 4 and 5.
4. Decide and switch to `drop`.

## Verify on first deployment
1. Managed rule group names (`MalwareDomainsStrictOrder`, `BotNetCommandAndControlDomainsStrictOrder`, `ThreatSignaturesIOCStrictOrder`): `aws network-firewall list-rule-groups --scope MANAGED`, or disable the toggles.
2. Metric `ReceivedPackets` with `Engine=Stateless` used by the path-health alarms.
3. Rule groups defining variables that are only used when a feature is enabled (the traffic-policy group uses placeholder values for unused lists). If the service rejects a placeholder, set that list to a real value or tell me and I will restructure it.
4. Number of stateful rule groups attached to the policy against your account quota (up to 13 are attached with all toggles on).
5. Preset domain lists against real traffic; CDN domains change.
6. Behaviour of non-allowlisted domains under the default action (test cases 3 and 4).
7. Deployment role permissions; tighten using CloudTrail AccessDenied events.
8. Current prices (Network Firewall, NAT, Transit Gateway) on the AWS pricing pages and Sophos prices from Marketplace and your partner.

## Rollback
- Rules: restore the previous parameter file or set `EnforcementMode=alert`, update the stack.
- Traffic path: restore saved routes. The firewall may stay deployed but bypassed.
- Removal: lift protections, remove routes, delete the stack. KMS key and S3 bucket are retained deliberately.
