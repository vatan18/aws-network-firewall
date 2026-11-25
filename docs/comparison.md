# **AWS Network Firewall vs Sophos Firewall – Complete Pricing Comparison**

Below is the comparison covering all four Sophos deployment combinations:

1. Single appliance – PAYG
2. Single appliance – BYOL
3. Two-node HA – PAYG
4. Two-node HA – BYOL

I'll also compare these against AWS Network Firewall in single-AZ and two-AZ deployments.

**Pricing region:** AWS Mumbai (`ap-south-1`)\
**Billing assumption:** 730 hours/month\
**Currency:** USD

## **1. Pricing assumptions**

For a fair comparison, I'll use three sizing profiles:

| Scenario          | Sophos EC2 instance | vCPU | RAM   |
| ----------------- | ------------------- | ---- | ----- |
| Small POC         | c5.large            | 2    | 4 GB  |
| Medium production | c5.xlarge           | 4    | 8 GB  |
| Enterprise        | c5.2xlarge          | 8    | 16 GB |

These are supported Sophos instance mappings. Actual sizing must be validated against throughput and enabled security features.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://docs.sophos.com\&sz=32)

Sophos Firewall



**Sophos Marketplace software rates:**

| Instance   | PAYG software/hour |
| ---------- | ------------------ |
| c5.large   | $0.54              |
| c5.xlarge  | $1.02              |
| c5.2xlarge | $1.56              |

Source: Sophos AWS Marketplace listing.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://aws.amazon.com\&sz=32)

Amazon Web Services, Inc.



**Mumbai EC2 on-demand assumptions:**

| Instance   | EC2/hour |
| ---------- | -------- |
| c5.large   | $0.085   |
| c5.xlarge  | $0.17    |
| c5.2xlarge | $0.34    |

[image](https://www.google.com/s2/favicons?domain=https://instances.usage.ai\&sz=32)

Usage AI

PAYG = EC2 + Sophos software.\
BYOL = EC2 only in the AWS bill, with a separate Sophos licence purchase.

## **2. Sophos – PAYG pricing**

PAYG includes the Sophos software charge and EC2 infrastructure charge.

Formula:

\\[ (\text{EC2 hourly}+\text{PAYG hourly})\times730 \\]

Monthly cost in USD · No HA duplication in single-appliance column

| Scenario                | Single appliance | Two-node HA |
| ----------------------- | ---------------- | ----------- |
| Small POC – c5.large    | $456.25          | $912.50     |
| Medium – c5.xlarge      | $868.70          | $1,737.40   |
| Enterprise – c5.2xlarge | $1,387.00        | $2,774.00   |

Example: Small POC, two-node HA:

\\[ (0.54+0.085)\times730\times2 =\\$912.50 \\]

Both appliances are assumed to run continuously.

## **3. Sophos – BYOL pricing**

With BYOL, there is no Sophos Marketplace hourly software charge. However, the customer must purchase the Sophos licence separately.

| Scenario                | Single appliance – EC2 | Two-node HA – EC2 |
| ----------------------- | ---------------------- | ----------------- |
| Small POC – c5.large    | $62.05                 | $124.10           |
| Medium – c5.xlarge      | $124.10                | $248.20           |
| Enterprise – c5.2xlarge | $248.20                | $496.40           |

**Additional BYOL costs not included:**

- Sophos firewall licence.
- Security subscription bundle.
- Support and maintenance.
- Sophos Central, if separately chargeable.

The Marketplace BYOL listing confirms that software licensing is handled through an external vendor relationship, while AWS infrastructure is billed separately.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://aws.amazon.com\&sz=32)

Amazon Web Services, Inc.



This means the BYOL figures above are infrastructure-only costs, not the total Sophos solution cost.

## **4. AWS Network Firewall pricing**

For comparison, consider:

- Single appliance equivalent: one firewall endpoint in one AZ.
- HA equivalent: two firewall endpoints across two AZs.
- Endpoint charge: $0.395/hour.
- Traffic processing: $0.065/GB.

These are the Mumbai assumptions from your supplied pricing document; verify them in the AWS Pricing Calculator before quotation.

| Scenario          | Traffic/month | Single AZ | Two AZ    |
| ----------------- | ------------- | --------- | --------- |
| Small POC         | 500 GB        | $320.85   | $609.20   |
| Medium production | 5 TB          | $613.35   | $901.70   |
| Enterprise        | 20 TB         | $1,588.35 | $1,876.70 |

Formula:

\\[ (\text{Endpoint count}\times0.395\times730) +(\text{GB}\times0.065) \\]

AWS charges by endpoint and traffic processed, rather than by EC2 instance or firewall software licence.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://aws.amazon.com\&sz=32)

Amazon Web Services+1



## **5. Complete comparison – all deployment combinations**

All four Sophos options included

### **Small POC – 500 GB/month**

| Solution             | Single           | Two-node HA        |
| -------------------- | ---------------- | ------------------ |
| AWS Network Firewall | $320.85          | $609.20            |
| Sophos PAYG          | $456.25          | $912.50            |
| Sophos BYOL          | $62.05 + licence | $124.10 + licences |

### **Medium production – 5 TB/month**

| Solution             | Single            | Two-node HA        |
| -------------------- | ----------------- | ------------------ |
| AWS Network Firewall | $613.35           | $901.70            |
| Sophos PAYG          | $868.70           | $1,737.40          |
| Sophos BYOL          | $124.10 + licence | $248.20 + licences |

### **Enterprise – 20 TB/month**

| Solution             | Single            | Two-node HA        |
| -------------------- | ----------------- | ------------------ |
| AWS Network Firewall | $1,588.35         | $1,876.70          |
| Sophos PAYG          | $1,387.00         | $2,774.00          |
| Sophos BYOL          | $248.20 + licence | $496.40 + licences |

Sophos BYOL figures exclude licence and support costs. AWS Network Firewall figures exclude other networking and logging costs. All figures are estimated monthly USD costs.

## **6. Architecture comparison**

[Deployment models for AWS Network Firewall | Networking & Content Delivery](https://images.openai.com/static-rsc-4/YzMr8lsI6HGQdand1ZkTx2eUtZJ1uPV3WF1C1tnpHhSXoIs04sFWm0dD08TN4HK2f2GC-ckQm5Pn2Qb-vjDhC7smqUq-r1ybTAWepVe5xuz5US1GgR5jFKaJqttG5manST9GTuoD3626Enz1GEs_PPzZkBMttUZCbzm8aHCoTcg?purpose=inline)

**AWS Network Firewall**

- Managed firewall endpoints
- Multi-AZ deployment
- AWS-managed infrastructure
- Route-table-based inspection

[AWS Marketplace: Sophos Cloud Firewall (PAYG)](https://images.openai.com/static-rsc-4/WtQxC6Hrea2FJhab4LSaYdMk9h0K9Y4BdbRPe0lHFkndzD1bC-asxw1DOdmXgmu17SkSdBtikeH0kbMheXUaaOgAC4h0k58keD6EQ665PgerV-SD8Ij9brcpG2t0KKLfnnwAlptrpGKOOasbfFzGgDlEbk0fRl-ZINONRXf1jR8?purpose=inline)

**Sophos Firewall**

- EC2-based appliances
- Active-passive HA option
- Appliance management
- Sophos software licensing

Note: Two Sophos appliances do not automatically provide HA. The HA configuration, synchronization, failover networking and licensing must be configured and validated. Similarly, AWS Network Firewall's two AZ endpoints provide AZ-level resilience, not two independently administered firewall appliances.

## **7. What costs are excluded?**

| Cost component         | AWS NFW                                   | Sophos                              |
| ---------------------- | ----------------------------------------- | ----------------------------------- |
| NAT Gateway            | Additional, subject to eligible discounts | Additional                          |
| Internet data transfer | Additional                                | Additional                          |
| CloudWatch logging     | Additional                                | Additional                          |
| S3 logging             | Optional                                  | Optional                            |
| KMS                    | Depends on encryption setup               | Depends on encryption setup         |
| EC2 infrastructure     | Not required for firewall                 | Required                            |
| Software licence       | Included in service                       | PAYG or BYOL                        |
| Administration         | Lower                                     | Higher                              |
| HA configuration       | Multi-AZ endpoints                        | Two appliances and HA configuration |

AWS announced additional NAT Gateway discounts for eligible firewall service chains and removed additional TLS inspection data-processing charges in Mumbai in February 2026.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://aws.amazon.com\&sz=32)

AWS



## **8. My recommendation**

For your customer's domain filtering requirement:

| Requirement                             | Recommended |
| --------------------------------------- | ----------- |
| Website allow/deny lists                | AWS NFW     |
| Lower operational maintenance           | AWS NFW     |
| Customer-managed CloudFormation         | AWS NFW     |
| User-based filtering                    | Sophos      |
| Application control                     | Sophos      |
| URL category filtering                  | Sophos      |
| Hybrid/on-premises firewall consistency | Sophos      |

My recommendation is to offer these three commercial options:

1. **AWS Network Firewall – Multi-AZ:** Managed solution with less infrastructure maintenance.
2. **Sophos PAYG – Two-node HA:** No upfront software licence purchase, but higher recurring software costs.
3. **Sophos BYOL – Two-node HA:** Potentially cost-effective if the customer already owns suitable Sophos licences.

Do not declare BYOL the cheapest option until the reseller provides the licence quotation and confirms whether two HA appliances require separate entitlements.

## **9. Official pricing and deployment references**

**AWS Network Firewall**

Endpoint, traffic processing and TLS inspection charges.

[AWS pricing](https://aws.amazon.com/network-firewall/pricing/?utm_source=chatgpt.com)

**Sophos PAYG**

Marketplace software charges and instance sizing.

[PAYG Marketplace](https://aws.amazon.com/marketplace/pp/prodview-ga4qvij427bvw?utm_source=chatgpt.com)

**Sophos BYOL**

External licensing and AWS infrastructure charges.

[BYOL Marketplace](https://aws.amazon.com/marketplace/pp/prodview-fniif7fuvwrck?cmp=40281\&utm_source=chatgpt.com)

**Sophos HA and deployment**

Supported EC2 sizing and AWS deployment options.

[Sophos AWS documentation](https://docs.sophos.com/nsg/sophos-firewall/21.0/Help/en-us/webhelp/onlinehelp/VirtualAndSoftwareAppliancesHelp/AWS/index.html?utm_source=chatgpt.com)

**One final consideration:** For a customer-facing quotation, I would also calculate the annual TCO, INR conversion, GST, Sophos BYOL licence quotation, and operational maintenance costs. The monthly estimates above are a comparison baseline, not a final vendor quote.
