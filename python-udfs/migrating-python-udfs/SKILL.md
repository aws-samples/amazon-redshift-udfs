---
name: migrating-python-udfs
description: "Migrate Redshift Python UDFs (plpythonu) to Lambda UDFs. Triggers on phrases like: migrate python udf, plpythonu to lambda, udf migration, convert python udf, redshift lambda udf, python udf end of support. Do NOT use for creating new Lambda functions from scratch (not a migration), writing Redshift stored procedures, or general Lambda development."
argument-hint: "[cluster-name|workgroup-name|'all'|function-name-list]"
---

# Migrate Python UDFs

Migrate Amazon Redshift Python UDFs (plpythonu) to Lambda UDFs before the June 30, 2026 end-of-support deadline. Discovers UDFs via MCP or CLI, converts Python bodies to Lambda handlers, deploys with safe naming, validates, and renames post-approval.

## Reference Documentation

- [Discovery queries](references/discovery-queries.md)
- [Conversion rules and type mapping](references/conversion-rules.md)
- [CLI patterns and Data API rules](references/cli-patterns.md)
- [IAM and VPC prerequisites](references/iam-vpc-setup.md)
- [Rollback procedures](references/rollback-procedures.md)
- [Performance and cost optimization](references/performance.md)

## Workflow

### Phase 1: Discover Clusters

Ask the user which region to target. Then use the AWS MCP to list all Redshift Serverless workgroups and provisioned clusters in that region. Present the list and ask which one(s) to migrate. Do NOT auto-discover across all regions — require the user to specify the region.

If the user already provided a specific workgroup/cluster name, skip the listing and use the AWS MCP to verify the workgroup or cluster exists in the specified region.

**Routing rules based on user input:**
- Rule 0 (precedence): If the input matches both Rule 1's conditions AND Rule 2's conditions (e.g., user says both "cluster" and "workgroup" as type keywords, or provides both `--cluster-identifier` and `--workgroup-name`), ask the user to clarify which resource type to target. Incidental substrings inside resource names do NOT count as type keywords.
- Rule 1: User says "cluster" as a type keyword (not as a substring within a resource name) or provides `--cluster-identifier` → use `aws redshift describe-clusters` directly
- Rule 2: User says "workgroup" as a type keyword (not as a substring within a resource name) or provides `--workgroup-name` → use `aws redshift-serverless get-workgroup` directly
- Rule 3: User provides a name with no type keyword (neither "cluster"/"workgroup" as type keywords nor `--cluster-identifier`/`--workgroup-name` present) → try Serverless first; if not found, try provisioned. Use whichever succeeds.
- Rule 4: If the user specifies `'all'`, skip listing and migrate all discovered workgroups/clusters in the specified region without asking for selection.

### Phase 2: Validate IAM and VPC Prerequisites

Before any deployment, verify the infrastructure. See [iam-vpc-setup.md](references/iam-vpc-setup.md).

1. **IAM role for Lambda execution** — must have `lambda.amazonaws.com` trust
2. **IAM role for Redshift namespace** — must have:
   - Trust policy with BOTH `redshift.amazonaws.com` AND `redshift-serverless.amazonaws.com`
   - `lambda:InvokeFunction` permission scoped to the Lambda function name pattern
3. **VPC connectivity** — if enhanced VPC routing is enabled (or if Lambda UDFs fail with "Empty format"):
   - Lambda VPC endpoint (`com.amazonaws.<region>.lambda`) required
   - STS VPC endpoint (`com.amazonaws.<region>.sts`) required
   - Security group must allow inbound TCP 443 from VPC CIDR
4. **Namespace default role** — verify the namespace has a default IAM role with Lambda invoke permissions
5. **Superuser credentials for DDL** — Creating EXTERNAL FUNCTIONs requires superuser. The IAM-mapped user (e.g., `IAMR:admin`) is NOT a superuser by default. Two options:
   - **(Recommended)** Enable managed admin password on the namespace and use `--secret-arn` with the admin secret.
   - **(Alternative)** Grant superuser to the IAM-mapped user via `ALTER USER "IAMR:admin" CREATEUSER;` (requires existing superuser access to run this grant).

Present findings to user and fix any gaps BEFORE proceeding to deployment.

### Phase 3: Discover Python UDFs

Use the AWS MCP to list databases on the selected workgroup/cluster and ask the user which one contains the Python UDFs (default: `dev`).

Use the AWS MCP to query for Python UDFs (see [discovery-queries.md](references/discovery-queries.md)). Try `pg_proc` with `lanname = 'plpythonu'` first, fall back to `python_udf_inventory` table. Present list and ask which to migrate.

### Phase 4: Convert

For each UDF, generate:
- `migration-input/<name>/original_udf.sql` — original source for traceability
- `migration-output/<name>/lambda_function.py` — Lambda handler
- `migration-output/<name>/<name>.sql` — Redshift EXTERNAL FUNCTION DDL

Conversion rules: see [conversion-rules.md](references/conversion-rules.md). Critical points:
- Lambda MUST return `json.dumps({"results": [...], "success": True})` — a JSON **string**, not a Python dict
- Arguments are row-based: `event["arguments"][i][j]` where i=row index, j=argument position
- Use `_lambdaudf` suffix for EXTERNAL FUNCTION names to avoid production disruption

### Phase 5: Present Migration Plan and Get Approval

**STOP and present the full plan to the user before deploying anything.** Include:
- Number of UDFs to migrate
- Lambda function names (with `_lambda` suffix)
- Redshift function names (with `_lambdaudf` suffix)
- IAM role being used
- Target region
- Any infrastructure changes needed (VPC endpoints, IAM policy updates)

Wait for explicit approval: "Does this plan look good? I will deploy with the `_lambdaudf` suffix so your existing functions remain untouched."

Do NOT proceed without user confirmation.

### Phase 6: Deploy and Validate (One UDF at a Time)

After approval, migrate each UDF **sequentially** — do NOT batch:

**For each UDF:**
1. **Deploy Lambda** — create or update the Lambda function (see [cli-patterns.md](references/cli-patterns.md))
2. **Create Redshift EXTERNAL FUNCTION** via Data API using admin credentials:
   - **Serverless:** use `--secret-arn` (managed admin password from Secrets Manager)
   - **Provisioned cluster:** use `--db-user` with `--cluster-identifier` (temporary credentials via `GetClusterCredentials`)
   - Use `IAM_ROLE default` in DDL (references the namespace's default role)
3. **Validate — compare PUDF vs LUDF output:**
   - Run the same input through both the original Python UDF and the new `_lambdaudf`
   - Assert outputs are identical. Use type-safe casting (see [cli-patterns.md](references/cli-patterns.md))
   - Example comparison query:
     ```sql
     SELECT <schema>.<name>(args) AS pudf_result,
            <schema>.<name>_lambdaudf(args) AS ludf_result
     FROM <test_input>;
     ```
4. **On success** → report result to user, proceed to next UDF
5. **On failure** → **STOP.** Report the failure to the user and ask how to proceed. Do NOT continue to the next UDF.

If validation fails with "Empty format" error, check CloudWatch logs for the Lambda function:
- **No Lambda invocation in CloudWatch** → VPC/IAM connectivity issue. Check VPC endpoints and IAM trust policy per [iam-vpc-setup.md](references/iam-vpc-setup.md).
- **Lambda WAS invoked in CloudWatch** → Lambda is returning a Python dict instead of a `json.dumps()` string. Fix the handler to return `json.dumps({"results": [...], "success": True})`.

### Phase 7: Rename (Post-Validation)

**STOP:** Wait for explicit customer sign-off: "All UDFs validated successfully. Ready to rename `_lambdaudf` functions to replace the originals? The old Python UDFs will be renamed with a `_pythonudf` suffix as a safety net."

Only after confirmation, for **each UDF pair in a separate transaction**:
1. RENAME the old Python UDF to `<original_name>_pythonudf`:
   ```sql
   ALTER FUNCTION <schema>.<original_name>(<arg-types>) RENAME TO <original_name>_pythonudf;
   ```
2. RENAME the Lambda UDF from `<original_name>_lambdaudf` to the original name:
   ```sql
   ALTER FUNCTION <schema>.<original_name>_lambdaudf(<arg-types>) RENAME TO <original_name>;
   ```

Execute each pair as a separate Data API statement. Do NOT batch all renames into one transaction — isolate failures to individual UDFs.

After all renames succeed, inform the user that `_pythonudf` functions remain available for rollback until they choose to drop them.

## Gotchas

- NEVER deploy without user approval. Always present the plan first.
- Lambda response MUST be `json.dumps(...)` (string), NOT a Python dict. Returning a dict causes "Empty format" error.
- Arguments are ROW-BASED: `args[i][j]` (row i, argument j). NOT column-based `args[j][i]`.
- "Empty format" error with no Lambda invocation in CloudWatch = VPC/IAM connectivity issue. Check VPC endpoints and IAM trust policy.
- IAM trust policy for the Redshift namespace role MUST include `redshift-serverless.amazonaws.com` for Serverless workgroups.
- Creating EXTERNAL FUNCTIONs requires superuser. IAM-mapped users are NOT superusers by default — use `--secret-arn` with managed admin password, or grant superuser to the IAM-mapped user via `ALTER USER`.
- All DDL must use the AWS MCP via `aws redshift-data execute-statement`. Do NOT attempt DDL through read-only query tools.
- Do NOT scan all regions. Ask the user for the region, then list workgroups/clusters in that region for them to pick from.
- Schema comes from discovery query. Do NOT hardcode `public`.
- Lambda cold starts take 10-30s. Account for this when polling validation results — use retry with sufficient timeout.
- Redshift cannot CAST boolean to VARCHAR. Use `CASE WHEN fn(...) THEN 'true' ELSE 'false' END`.

