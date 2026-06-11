# CLI Patterns and Data API Rules

## Variables

```bash
REGION="us-east-1"                          # AWS region
WORKGROUP="my-workgroup"                    # Redshift Serverless workgroup name (human-readable, not ARN)
CLUSTER_ID="my-cluster"                     # Redshift provisioned cluster identifier
DATABASE="dev"                              # Target database name
SECRET_ARN="arn:aws:secretsmanager:us-east-1:123456789012:secret:redshift-admin-xxxxxx"  # Admin secret (xxxxxx = random suffix added by Secrets Manager)
S3_BUCKET="my-lambda-deploy-bucket"         # S3 bucket for Lambda deployment packages
S3_PREFIX="lambda-udfs"                     # S3 key prefix for zip files
ROLE_ARN="arn:aws:iam::123456789012:role/redshift-udf-lambda-role"  # Lambda execution role ARN
DB_USER="admin"                             # Redshift database superuser (provisioned clusters ONLY; do NOT use for Serverless — use SECRET_ARN instead)
```

## Data API Rules

1. Strip whitespace from IDs: `STMT_ID=$(aws redshift-data execute-statement ... --query 'Id' --output text | tr -d '[:space:]')`
2. Use `|` delimiter for FUNC_NAME|STMT_ID pairs (safe with bash `%%`/`##` operators).
3. Use `grep -A10` when extracting DDL from SQL files (multi-arg functions span many lines).
4. Poll with retry loop (never single fixed sleep). Status values: `SUBMITTED`, `PICKED`, `STARTED`, `FINISHED`, `FAILED`, `ABORTED`.

## Lambda Deploy (parallel upsert)

> **Do NOT pass `--vpc-config` to `create-function`.** Lambda does NOT need to be in a VPC. Redshift reaches Lambda via VPC endpoints.

```bash
for dir in migration-output/*/; do
    FUNC_NAME=$(basename "$dir"); LAMBDA_NAME="${FUNC_NAME}_lambda"
    S3_KEY="${S3_PREFIX}/${FUNC_NAME}/lambda_function.zip"
    { aws lambda update-function-code --function-name "$LAMBDA_NAME" \
        --s3-bucket "$S3_BUCKET" --s3-key "$S3_KEY" --region "$REGION" 2>/dev/null || \
      aws lambda create-function --function-name "$LAMBDA_NAME" \
        --runtime python3.12 --architectures arm64 \
        --handler lambda_function.lambda_handler --role "$ROLE_ARN" \
        --code "S3Bucket=${S3_BUCKET},S3Key=${S3_KEY}" \
        --timeout 60 --memory-size 128 --region "$REGION"
    } &
done
wait
```

## Redshift DDL (sequential per-UDF)

> **Authentication for DDL execution (mutually exclusive — do NOT mix):**
> - **Serverless:** use `--workgroup-name` + `--secret-arn`. Do NOT use `--db-user` with Serverless.
> - **Provisioned cluster:** use `--cluster-identifier` + `--db-user`. Do NOT use `--secret-arn` with provisioned clusters. Deployer needs `redshift:GetClusterCredentials`. See [iam-vpc-setup.md](iam-vpc-setup.md).

Deploy and validate one UDF at a time. For each UDF:

### Serverless

```bash
FUNC_NAME="<function_name>"
SQL=$(grep -A10 "^CREATE OR REPLACE" "migration-output/${FUNC_NAME}/${FUNC_NAME}.sql" | sed '/^$/d' | sed '/^--/d' | tr '\n' ' ')
STMT_ID=$(aws redshift-data execute-statement --workgroup-name "$WORKGROUP" \
    --database "$DATABASE" --secret-arn "$SECRET_ARN" --sql "$SQL" --region "$REGION" \
    --query 'Id' --output text | tr -d '[:space:]')
```

### Provisioned cluster

```bash
FUNC_NAME="<function_name>"
SQL=$(grep -A10 "^CREATE OR REPLACE" "migration-output/${FUNC_NAME}/${FUNC_NAME}.sql" | sed '/^$/d' | sed '/^--/d' | tr '\n' ' ')
STMT_ID=$(aws redshift-data execute-statement --cluster-identifier "$CLUSTER_ID" \
    --database "$DATABASE" --db-user "$DB_USER" --sql "$SQL" --region "$REGION" \
    --query 'Id' --output text | tr -d '[:space:]')
```

### Poll result

```bash
for i in 1 2 3 4 5 6 7 8 9 10; do
    sleep 3
    STATUS=$(aws redshift-data describe-statement --id "$STMT_ID" --region "$REGION" --query 'Status' --output text | tr -d '[:space:]')
    if [ "$STATUS" = "FINISHED" ] || [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "ABORTED" ]; then break; fi
done
echo "  $FUNC_NAME: $STATUS"
```

## Validation (PUDF vs LUDF comparison)

After creating each LUDF, compare its output against the original PUDF using the same input:

```sql
SELECT <schema>.<name>(args) AS pudf_result,
       <schema>.<name>_lambdaudf(args) AS ludf_result
FROM <test_input>;
```

Assert both columns return identical values. If they differ, STOP and report to user.

Type-safe casting:
- BOOLEAN: `CASE WHEN fn(...) THEN 'true' ELSE 'false' END`
- INTEGER/FLOAT: `CAST(fn(...) AS VARCHAR)`
- VARCHAR: no cast needed
