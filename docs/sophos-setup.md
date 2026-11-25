# Sophos Firewall on AWS: design and setup guide

Sources: Sophos Community "Sophos Firewall: AWS Standalone Deployment", "HA/AA deployment with Transit Gateway",
"Deploying Sophos Firewall with AWS Autoscaling", and the AWS Marketplace listing for Sophos Firewall (reviewed 2026-11-25).
Sophos publishes the deployment CloudFormation templates through AWS Marketplace and keeps them current, so this guide
uses those templates rather than a home-made one. Menu names can differ slightly between SFOS versions; check Sophos docs for your release.

## 1. What you are deploying

Sophos Firewall is a virtual appliance that runs on EC2 and sits inline in your VPC. Unlike Network Firewall it is a
set of instances **you** operate (patching, sizing, HA, licensing).

| Marketplace delivery option | When to use | Notes |
|---|---|---|
| Standalone | POC, single VPC, labs | One instance, two ENIs in two subnets. No redundancy |
| High Availability (Active-Passive) | Production, simple | Two nodes in different AZs. Sophos documents it with Transit Gateway, GRE/Connect peers and BGP (higher peer ASN = passive) |
| Active-Active | Production scale-out | Multiple nodes via Transit Gateway and load distribution |
| Gateway Load Balancer | Production, centralized inspection | Appliances behind GWLB, AWS-native insertion |
| Auto Scaling | Elastic egress/ingress | Single-arm nodes (one functioning interface); needs Sophos Central API credentials with the Service Principal Firewall role |

For this POC: **Standalone first (functional comparison), then HA or GWLB for the availability and failover tests.**

## 2. Licensing (confirm in writing with Sophos or the reseller)

- **PAYG:** all functionality for an hourly software charge on top of the EC2 instance cost (billed through AWS).
- **BYOL:** you bring a Sophos Firewall licence (subscription bundles and support tiers); AWS bills only the EC2 instance.
- **Sophos Central** is the management and licensing portal (claiming the device, central reporting/management). Its feature tiers and any extra subscriptions are separate from the firewall licence. Autoscaling requires it.
- A 30-day trial can be claimed through Sophos Central for a POC.
- Instance size is chosen against Sophos's licence/CPU/RAM mapping. The standalone template accepts sizes with at least 2 NICs (for example m5.large).

I have not put prices here on purpose: Sophos and Marketplace pricing changes by edition and region. Take the exact hourly
software charge, BYOL quote and support quote from the Marketplace listing and your Sophos partner and enter them in the cost model in `docs/comparison.md`.

## 3. Prerequisites checklist
- [ ] AWS account with admin rights to deploy a CloudFormation stack that creates IAM resources
- [ ] EC2 key pair in `ap-south-1`
- [ ] Marketplace subscription (PAYG or BYOL) in the same account
- [ ] Your admin public IP (the "Trusted network CIDR" gets SSH 22 and web admin 4444)
- [ ] Sophos Central account (and BYOL serial number if applicable)
- [ ] Decide: new VPC (template creates it) or existing VPC (supply VPC ID, public subnet ID, private subnet ID)
- [ ] Plan for the second AZ if you will do HA

## 4. Standalone deployment (about 5 to 8 minutes)

1. **AWS Marketplace > Discover products**, search for Sophos Cloud Firewall, pick PAYG or BYOL, **Continue to Subscribe**, then **Continue to Configuration**.
2. Fulfilment option: **Sophos Standalone Firewall for AWS**, latest software version, region **Asia Pacific (Mumbai)**. Choose **Launch CloudFormation**.
3. Stack parameters:
   - AMI ID: keep *autodetect*; instance size: for example `m5.large` (needs 2+ NICs).
   - Availability Zone.
   - Network: enter the first two octets (for example `10.42`) for a new VPC, **or** existing VPC ID + public subnet ID + private subnet ID. For the existing-VPC case, subnets, route tables and the Internet Gateway must exist first.
   - **Trusted network CIDR:** your admin IP (full management access).
   - **Public network:** `0.0.0.0/0` or a specific range (all ports except management 22 and 4444).
   - Elastic IP: `yes`.
   - Firewall name/hostname, admin password, configuration backup password, Secure Storage Master Key, key pair.
   - Optional: S3 bucket for backup/restore, Sophos Central credentials, **CloudWatch logging = yes**.
   - Accept the EULA (`yes`).
4. Tick the IAM-resources acknowledgement and submit. Wait for `CREATE_COMPLETE`; open **Resources** to find the instance and public IP.
5. Browse to `https://<public-ip>:4444`, log in as admin.
6. Register the licence: enter the serial, or choose the trial and **Claim in Sophos Central** (SFUNL unlimited trial for 30 days).

## 5. Policy configuration (equivalent of the AWS rule set)

All under the firewall web admin (menu names per SFOS 20):

| Goal | Where / how |
|---|---|
| Allow LAN to internet | **PROTECT > Rules and policies > Firewall rules > Add firewall rule**: source zone LAN, destination zone WAN, destination *Internet IPv4 group*. Position Top. Attach web policy, application control and IPS policy here |
| Domain/website allow and block (Google, YouTube, Facebook...) | Web filtering policy with category and custom domain exceptions (for example block the Social Networking and Streaming categories, allow named domains). Attach to the LAN-to-WAN rule |
| App control | Application control policy attached to the same rule |
| IPS | IPS policy attached to the rule |
| Inbound publishing | Firewall rules / NAT rules from WAN to LAN with allowed ports and source networks |
| SSH/RDP restriction | Firewall rules limiting service and source network; keep management on a trusted CIDR only |
| TLS inspection | SSL/TLS inspection rules with a CA certificate distributed to clients. Do not enable broadly without a legal and certificate review |
| DNS control | DNS protection / DNS request route and firewall rules limiting outbound DNS to approved resolvers |

## 6. Route traffic through Sophos
Private-subnet route tables need `0.0.0.0/0` pointing at the **Sophos LAN-side ENI** (the interface in the private subnet, "PortA" in the Sophos article).
Verify source/destination check is disabled on the forwarding ENI. Inbound: public Elastic IP DNATs to LAN hosts via a firewall rule.
Keep the original routes saved so you can roll back with `replace-route`.

## 7. High availability and failover (production)
Use the Marketplace HA (Active-Passive) or AA CloudFormation, or the GWLB option, rather than hand-building. HA deployment in Sophos's guide:
- two nodes in different AZs, Transit Gateway with Connect attachment and Connect peers per node, BGP with different peer ASNs deciding the preferred node;
- the Active-Active variant adds nodes for throughput.
Test failover explicitly (stop the active instance, measure traffic gap and session loss) as test cases T-13/T-14.

## 8. Logging, monitoring, backup, updates
- **Logging:** enable the CloudWatch option at deploy time; use syslog export to your Loki/SIEM if required. Sophos Central provides reporting if licensed.
- **Monitoring:** CloudWatch EC2 metrics (CPU, network) plus Sophos dashboards. You build the alarms; there are no managed firewall metrics like Network Firewall's.
- **Backup:** scheduled configuration backups (S3 bucket field at deploy) and EBS snapshots. Test a restore.
- **Updates:** firmware and pattern updates are your responsibility on a schedule; HA pairs are updated node by node. Plan a maintenance window.

## 9. Known operational considerations
- You own capacity: pick the instance size for peak, resize means a change window.
- Cross-AZ traffic and Transit Gateway data processing are billed by AWS on top of licence and EC2.
- The Sophos HA/AA pattern documented by Sophos relies on Transit Gateway; a single-VPC HA design needs a Sophos account representative's guidance (Sophos's own guide says to contact them).
- Autoscaling nodes are single-arm and are managed through Sophos Central.

## 10. Test mapping
Run the same test cases as the AWS firewall (see POC test plan): outbound allowed/blocked domains, blocked IP, SSH/RDP,
DNS, east-west, logging, failover, throughput (use identical `iperf3` and `curl` scripts and the same instance types as clients).
Record results side by side in `docs/comparison.md` section 4.
