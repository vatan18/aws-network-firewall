# AWS Network Firewall vs Sophos Firewall

Status: **desk comparison plus cost model.** Sections 4 and 5 are completed with measured POC results (test cases in the POC test plan).
Price sources and dates are in section 3. No Sophos prices are included; they must come from Marketplace and your Sophos partner.

## 1. Feature and operations comparison

| Criteria | AWS Network Firewall | Sophos Firewall (on EC2) |
|---|---|---|
| Service model | Managed AWS service. No instances, OS or patching | Virtual appliance you run on EC2 (patching, sizing, HA are yours) |
| Deployment complexity | Moderate: endpoints plus route tables. Fully expressible in CloudFormation (provided) | Marketplace CloudFormation plus appliance configuration in its own UI. Routing is similar; HA adds Transit Gateway/GRE/BGP or GWLB |
| Multi-VPC / centralized | Inspection VPC plus Transit Gateway; AWS states one firewall can serve up to 50 VPCs per AZ via multiple VPC endpoints | HA/AA documented with Transit Gateway; GWLB option; single-VPC HA needs Sophos guidance |
| High availability | Multi-AZ by design (one endpoint per AZ, each AZ independent) | You build it: HA pair, AA, GWLB or autoscaling; failover time and session sync are your test items |
| Scaling | Automatic. Check current per-endpoint throughput and quota limits in AWS docs | Fixed by instance size; scale up (resize) or out (AA/autoscaling) |
| IPS/IDS | Suricata-compatible rules, AWS managed threat signature groups, custom signatures | Sophos IPS engine and signature updates, policy-driven |
| Domain filtering | Allow/deny by HTTP Host and TLS SNI, wildcard by leading dot, managed domain lists | Web filtering with URL/category policies, custom exceptions |
| URL categories, user/group policy | No | Yes (user identity, categories, schedules) |
| Application control | Protocol and signature based via Suricata; no application catalogue | Application control catalogue and policies |
| TLS inspection | Supported (certificate required via ACM; scope and cost review needed) | Supported (CA deployed to clients; scope review needed) |
| QUIC/HTTP3 | Cannot read domain inside QUIC; block UDP 443 to force TCP | Sophos documents its own handling; validate in POC |
| VPN / ZTNA / remote access | Not part of the service (use AWS VPN, Client VPN) | SSL VPN, site-to-site, ZTNA options (licensing dependent) |
| Threat intelligence | AWS managed rule groups | Sophos threat intelligence, synchronized security with Sophos endpoints |
| Logging | Alert and flow logs to CloudWatch Logs, S3, Firehose; CloudWatch metrics per AZ | Logs to appliance, CloudWatch option, syslog; Sophos Central reporting if licensed |
| Monitoring | Native CloudWatch metrics and alarms; fits Prometheus via a CloudWatch exporter | EC2 metrics plus appliance dashboards; you build alarms |
| Management UI | AWS console, API, IaC. No dedicated firewall GUI | Full web admin UI, familiar to network teams; Sophos Central for fleets |
| Maintenance | AWS runs the service; you maintain rules | Firmware, pattern updates, HA-aware upgrades, backup/restore tests |
| Licensing | None. Pay per endpoint-hour and per GB | PAYG (hourly software charge) or BYOL (subscription and support), plus Central tiers |
| AWS integration | Native: IAM, CloudFormation, Firewall Manager, TGW, KMS, CloudWatch | Via CloudFormation templates and instance-level integration |
| Hybrid/multi-cloud consistency | AWS only | Same product on-prem and in other clouds |

## 2. Where each one wins
- **Network Firewall:** low operational burden, automatic multi-AZ scaling, everything as code, AWS-native logging and metrics, no licences. Best when the need is egress/ingress control by domain, IP, port and signature at VPC scale.
- **Sophos:** user- and category-aware web policy, application catalogue, VPN/ZTNA in the same box, endpoint-firewall integration, one GUI across on-prem and cloud. Best when policy must follow users or the team already runs Sophos everywhere.
- **Can coexist:** Network Firewall for the AWS network perimeter plus Sophos for remote access or user-based web filtering.

## 3. Cost model (ap-south-1, all figures USD, 730 hours per month)

Network Firewall list rates used: **$0.395 per endpoint-hour** and **$0.065 per GB processed** (Mumbai).
Sources: AWS price list data for Asia Pacific (Mumbai), effective 2025-09-01, and AWS's pricing page structure
(`aws.amazon.com/network-firewall/pricing`). I could not load the live Mumbai table on 2026-11-25, so **re-confirm both
numbers in the AWS Pricing Calculator before quoting**. AWS's February 2026 announcement removed the extra Advanced
Inspection (TLS) per-GB charge in Mumbai and extended NAT Gateway discounts to service-chained secondary endpoints.

| Scenario | Assumptions | Network Firewall hourly | NFW data processing | NFW subtotal |
|---|---|---|---|---|
| Small POC | 2 endpoints (2 AZ), 500 GB/month | $576.70 | $32.50 | **$609.20** |
| Medium production | 2 endpoints, 5,000 GB/month | $576.70 | $325.00 | **$901.70** |
| Enterprise multi-VPC | 3 endpoints (central), 20,000 GB/month | $865.05 | $1,300.00 | **$2,165.05** |

Subtotals exclude: NAT Gateway (hourly and per GB), Transit Gateway attachments and data processing (AWS's published example
uses $0.05 per attachment-hour and $0.02 per GB; **confirm Mumbai rates**), CloudWatch Logs ingestion and storage, S3, KMS, cross-AZ transfer ($0.01 per GB each way).
Formula: `endpoints x 730 x 0.395 + GB x 0.065 + NAT + TGW + logs + cross-AZ`.

Sophos model to fill in (same three scenarios):

| Line | How to get it |
|---|---|
| EC2 instances | instance type per Sophos sizing x 730 h x node count (HA = 2, AA/autoscale = N) from the EC2 pricing page |
| Sophos software | PAYG hourly charge from the Marketplace listing, **or** BYOL subscription quote per edition |
| Support | Sophos support tier quote |
| Sophos Central | only if licensed beyond the included tier |
| NAT, TGW, CloudWatch, S3, cross-AZ | same as above (appliance traffic still pays these) |
| People cost | patching, upgrades, failover drills; estimate hours per month x loaded rate |

Total cost of ownership should include the people line. A managed service with higher per-GB cost can still be cheaper than
appliances once HA duplication, licences and operations time are counted; at low traffic volume the always-on endpoint charge dominates,
at very high volume the per-GB charge does. Run your real traffic numbers.

## 4. Measured results (fill during POC)

| Test | Metric | AWS Network Firewall | Sophos |
|---|---|---|---|
| Blocked domain / allowed domain | pass/fail | | |
| Blocked IP, SSH/RDP, DNS | pass/fail | | |
| East-west and inter-VPC | pass/fail | | |
| Endpoint/instance failure | seconds of traffic loss | | |
| AZ failure | seconds of traffic loss | | |
| Throughput (iperf3, same clients) | Gbps and CPU/latency | | |
| Policy change time | minutes from commit to enforced | | |
| 30-day measured cost | USD | | |

## 5. Weighted decision matrix

Weights are a proposal; adjust with the customer. Scores 1 to 5 filled after testing. The preliminary column is a desk estimate and must not be used as the final answer.

| Criterion | Weight | Preliminary NFW | Preliminary Sophos | Final NFW | Final Sophos |
|---|---|---|---|---|---|
| Security effectiveness | 20% | 4 | 4 | | |
| Inspection coverage | 10% | 4 | 4 | | |
| Availability | 15% | 5 | 3 | | |
| Performance | 10% | 4 | 3 | | |
| Scalability | 10% | 5 | 3 | | |
| Ease of deployment | 5% | 4 | 3 | | |
| Operational overhead | 10% | 5 | 2 | | |
| AWS integration | 5% | 5 | 3 | | |
| Total cost of ownership | 10% | 3 | 3 | | |
| Long-term maintainability | 5% | 5 | 3 | | |

Preliminary weighted totals: NFW 4.35, Sophos 3.20 (calculated as sum of weight x score).
If the customer needs per-user policy, URL categories or VPN in the same appliance, add those as criteria; that moves the result toward Sophos or a combination.
