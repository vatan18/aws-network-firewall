# Why AWS Network Firewall: the pitch

## The problem
Your workloads need controlled internet access: only approved sites and applications out, only intended services in,
every decision logged, and none of it slowing teams down or adding another system to babysit.

## The proposal
Use **AWS Network Firewall**, a managed, multi-AZ firewall that sits in your VPC, controlled entirely by parameters you already
know how to review: domain lists, app presets, ports, CIDRs. Roll it out in alert mode, prove it, then enforce.

## Five reasons it fits

1. **Nothing to run.** No instances, no OS, no firmware, no HA pairs to test. AWS operates the service and scales it. Your team maintains rules, not servers.
2. **Policy as parameters.** Allow Google and Microsoft 365, block Facebook, Instagram and TikTok, open a port for mail: change a value, review the change set, deploy. Customers manage ingress, egress, east-west and domain lists without touching rule syntax.
3. **Safe rollout.** One switch (`EnforcementMode`) turns every block into a log-only alert. Observe real traffic first, enforce when the logs are clean, roll back in minutes.
4. **Built for AWS operations.** Encrypted logs in CloudWatch and S3, per-AZ metrics, alarms, a dashboard, IAM least-privilege, CloudFormation end to end. It fits your existing Prometheus/Grafana/Loki stack through a CloudWatch exporter.
5. **Scales with the estate.** One inspection VPC and Transit Gateway can protect many VPCs, and AWS states a single firewall can serve up to 50 VPCs per AZ. No licence tier to outgrow, no instance to resize.

## Cost, honestly
You pay per endpoint-hour and per GB. At Mumbai list rates (re-confirm in the AWS Pricing Calculator) that is about **$609/month** for a
2-AZ proof of concept with 500 GB, **$902** for 2 AZs and 5 TB, **$2,165** for a 3-AZ central firewall with 20 TB, before NAT,
Transit Gateway and logging. Appliance alternatives add EC2, licences, support and the engineering hours to patch, upgrade and drill failover.
The right comparison is total cost of ownership, which the POC will measure.

## Where Sophos is the better answer
- You need **per-user or per-group** policies, URL categories, schedules.
- You want **VPN, ZTNA and endpoint-linked threat response** in one product, or one console across on-prem and several clouds.
- Your team already runs Sophos and values its GUI and reporting.

Network Firewall does not do these. If they are requirements, the recommendation becomes a combination: Network Firewall for the AWS perimeter, Sophos where identity-aware or remote-access features are needed.

## Limits we accept with Network Firewall
- No user identity or URL-category filtering; domain rules read SNI/Host only.
- QUIC (UDP 443) cannot be inspected by domain; we block it so clients fall back to TCP.
- TLS inspection is available but off by default; it needs certificates, scoping and a privacy review.
- One policy per firewall; different audiences need separate firewalls or VPCs.
- The always-on endpoint charge makes very small or idle environments proportionally expensive.

## Recommended architecture
- **Production:** centralized inspection VPC with Transit Gateway for egress and inter-VPC traffic, endpoints in three AZs with appliance mode on, alert-first rollout, `EnforcementMode=drop` after review.
- **VPCs with unique needs:** distributed firewall in that VPC.
- **Decision gate:** confirm with the measured results in `docs/comparison.md` section 4 before final sign-off.

## The ask
Approve a 30-day POC in `ap-south-1` using the supplied templates in alert mode on one non-critical VPC, with Sophos deployed in parallel for the same test cases. Decide on measured security, availability, performance and cost.
