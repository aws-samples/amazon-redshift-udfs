# IAM and VPC Prerequisites

## 1. Lambda Execution Role

Trust: `lambda.amazonaws.com`. Attach `AWSLambdaBasicExecutionRole` managed policy.
Naming: `redshift-udf-lambda-role`

> **Deployer permissions** (on the IAM principal performing deployment, NOT the Lambda role):
> `lambda:CreateFunction`, `lambda:UpdateFunctionCode`, `s3:GetObject`, `s3:PutObject` (on the deploy bucket prefix), `iam:PassRole` (on Lambda role ARN), `redshift-data:ExecuteStatement`, `redshift-data:DescribeStatement`, `redshift-data:GetStatementResult`, `secretsmanager:GetSecretValue` (on the admin secret ARN, for Serverless `--secret-arn` auth).
> For provisioned clusters using `--db-user`: also `redshift:GetClusterCredentials`.

## 2. Redshift Namespace Role (invokes Lambda)

**Trust policy — MUST include both services:**
```json
{"Version": "2012-10-17", "Statement": [{"Effect": "Allow",
  "Principal": {"Service": ["redshift.amazonaws.com", "redshift-serverless.amazonaws.com"]},
  "Action": "sts:AssumeRole"}]}
```

**Inline policy:** `lambda:InvokeFunction` on `arn:aws:lambda:<region>:<account-id>:function:*_lambda`

> `<region>` = e.g., `us-east-1`. `<account-id>` = 12-digit ID (e.g., `123456789012`).

Naming: `redshift-udf-serverless-role`

**Common failure:** Trust policy only has `redshift.amazonaws.com` → Serverless cannot assume role → "Empty format" error with no CloudWatch logs. **Fix:** Add `redshift-serverless.amazonaws.com`.

## 3. Namespace Configuration

> Namespace name may differ from workgroup. Retrieve via:
> `aws redshift-serverless get-workgroup --workgroup-name <workgroup-name> --region <region> --query 'workgroup.namespaceName' --output text`

Required:
- Attach invoke role: `aws redshift-serverless update-namespace --namespace-name <namespace-name> --iam-roles <role-arn> --default-iam-role-arn <role-arn> --region <region>`
- Enable managed admin password: `aws redshift-serverless update-namespace --namespace-name <namespace-name> --manage-admin-password --region <region>`

> **IMPORTANT:** `--iam-roles` replaces ALL existing roles on the namespace. Include any previously attached role ARNs in the list to avoid removing them.

## VPC Endpoints

Required when enhanced VPC routing is enabled OR Lambda UDFs return "Empty format" with no CloudWatch invocation.

```bash
# Lambda endpoint
aws ec2 create-vpc-endpoint --vpc-id <vpc-id> \
  --service-name com.amazonaws.<region>.lambda --vpc-endpoint-type Interface \
  --subnet-ids <subnet-id-1> <subnet-id-2> --security-group-ids <sg-id> \
  --private-dns-enabled --region <region>

# STS endpoint
aws ec2 create-vpc-endpoint --vpc-id <vpc-id> \
  --service-name com.amazonaws.<region>.sts --vpc-endpoint-type Interface \
  --subnet-ids <subnet-id-1> <subnet-id-2> --security-group-ids <sg-id> \
  --private-dns-enabled --region <region>

# Security group ingress (TCP 443 from VPC CIDR)
aws ec2 authorize-security-group-ingress --group-id <sg-id> \
  --protocol tcp --port 443 --cidr <vpc-cidr> --region <region>
```

> **Placeholder formats:** `<vpc-id>` = `vpc-xxxxxxxxxxxxxxxxx`, `<subnet-id-N>` = `subnet-xxxxxxxxxxxxxxxxx`, `<sg-id>` = `sg-xxxxxxxxxxxxxxxxx`, `<vpc-cidr>` = CIDR notation (e.g., `10.0.0.0/16`)

## Diagnosing "Empty Format" Error

| Symptom | Cause | Fix |
|---------|-------|-----|
| No Lambda CloudWatch logs | Redshift cannot reach Lambda | Add Lambda + STS VPC endpoints |
| No Lambda CloudWatch logs | Trust policy missing `redshift-serverless.amazonaws.com` | Update trust policy |
| Lambda IS invoked | Returns Python dict instead of `json.dumps()` string | Fix handler return |
| "permission denied for language exfunc" | Non-superuser creating EXTERNAL FUNCTION | Use `--secret-arn` with admin credentials |

## Superuser Access for DDL

IAM-mapped user (`IAMR:admin`) is NOT a superuser by default. Two options to create external functions:

**Option A (Recommended): Managed admin password**
1. Enable managed admin password: `aws redshift-serverless update-namespace --namespace-name <namespace-name> --manage-admin-password --region <region>`
2. Get secret ARN from response: `adminPasswordSecretArn`
3. Use in Data API: `--secret-arn <arn>` on `execute-statement`

**Option B: Grant superuser to IAM-mapped user**
1. Connect as an existing superuser (e.g., via managed admin password)
2. Run: `ALTER USER "IAMR:admin" CREATEUSER;`
3. The IAM-mapped user can now create external functions directly
