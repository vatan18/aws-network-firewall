# AWS Network Firewall POC: firewall stack (Phase 3, part 1)

Deploys the firewall itself. It does **not** change any route table, so deploying it is non-disruptive.
Routing (05), VPC (01), TGW (06/07) follow as separate templates.

| File | Purpose |
|---|---|
| `08-logging-monitoring.yaml` | KMS CMK (or BYO), alert log group, S3 archive, SNS, alarms, dashboard. Deployed first. |
| `02-network-firewall-rule-groups.yaml` | Stateless baseline + 6 stateful strict-order groups |
| `03-network-firewall-policy.yaml` | Policy; `EnforcementMode` alert/drop |
| `04-network-firewall-deployment.yaml` | Firewall, protections, logging config |
| `firewall-master.yaml` | Nested-stack parent (08, 02, 03, 04) |
| `09-cfn-deployment-role.yaml` | Least-privilege CloudFormation service role (deploy first, needs `CAPABILITY_NAMED_IAM`) |
| `params/*.json` | Example parameter sets. Shared parameters live here (the "00" role) |

## Prerequisites
- One dedicated subnet per AZ for the endpoints (/28 minimum), containing nothing else.
- An S3 bucket in `ap-south-1` for packaged nested templates.
- `AWSServiceRoleForNetworkFirewall` is created automatically on first firewall creation.

## Deploy
```bash
# optional: service role
aws cloudformation deploy --stack-name anfw-poc-deploy-role \
  --template-file cloudformation/09-cfn-deployment-role.yaml --capabilities CAPABILITY_NAMED_IAM

# firewall (edit REPLACE_ values first)
./scripts/deploy.sh anfw-poc-firewall <artifact-bucket> cloudformation/params/poc-existing-vpc.json [role-arn]
```
Your own principal needs `iam:PassRole` on the service role plus CloudFormation permissions.

## Staged rollout (important for an existing VPC)
1. Deploy with `EnforcementMode=alert`, `StreamExceptionPolicy=CONTINUE`. All stateful drops become alerts, the stateless drop group is withheld.
2. Route traffic through the endpoints (template 05), AZ by AZ.
3. Review alerts (dashboard, Logs Insights). Tune allowlists and CIDR parameters.
4. Switch `EnforcementMode=drop`, `StreamExceptionPolicy=DROP`, enable the three protection flags. Update the stack; no endpoint replacement occurs.

## Rollback
- Rules: set `EnforcementMode=alert` and update the stack (seconds, no traffic path change).
- Traffic path: restore the saved route entries (`replace-route`), the firewall can stay deployed but bypassed.
- Full removal: set protections to `false`, remove routes first, then delete the stack. The KMS key and S3 bucket are retained on purpose.

## Things you must know
- Rule order and rule group **capacity are immutable**; changing them replaces the resource.
- `aws:drop_established_strict` does not drop unmatched UDP/ICMP first packets. Use `drop_strict` for stricter egress.
- Queries to the Amazon-provided DNS resolver do not traverse the firewall; DNS rules cover external resolvers only. Pair with Route 53 Resolver DNS Firewall.
- IPv4 only. TLS inspection is deliberately not enabled.
- Domain allowlist traffic outside the list is handled by the policy default action; verify with test cases.
# aws-network-firewall
