# Amazon Redshift Python UDFs — End of Support

## ⚠️ Deprecation Notice

Amazon Redshift Python user-defined functions (plpythonu) are reaching **end of support after June 30, 2026**. AWS recommends migrating all existing Python UDFs to [Lambda UDFs](https://docs.aws.amazon.com/redshift/latest/dg/udf-creating-a-lambda-sql-udf.html) before this deadline.

### Timeline

| Milestone | What happens |
|-----------|--------------|
| Patch 198 | Creation of new Python UDFs is no longer supported (existing functions can still be invoked) |
| June 30, 2026 | Execution of existing Python UDFs will be suspended |

### Why Lambda UDFs?

Lambda UDFs provide significant advantages over the legacy Python UDF runtime:

- **Enhanced integration** — Connect to external services or APIs from within your UDF logic
- **Multiple Python runtimes** — Benefit from Lambda's support for modern Python versions with security patches available within a month of official release
- **Independent scaling** — Heavy compute or memory-intensive tasks don't impact query performance or resource concurrency within Amazon Redshift
- **Isolation and security** — Custom code executes in a separate service boundary, simplifying maintenance, monitoring, and permission management

For full details, see the AWS blog post: [Amazon Redshift Python user-defined functions will reach end of support after June 30, 2026](https://aws.amazon.com/blogs/big-data/amazon-redshift-python-user-defined-functions-will-reach-end-of-support-after-june-30-2026/).

---

## Automated Migration with Kiro, Cursor, Claude, Codex AI Skill

This repository includes a Kiro AI Skill that automates the entire end-to-end migration workflow. With a single natural language command, the skill handles discovery, conversion, deployment, validation, and cutover — all with safety gates that require your explicit approval before making any production changes.

### Install the Skill

Run the following command to install the skill into your AI-powered IDE (Kiro, Cursor, Claude, Codex, etc.):

```bash
npx skills add https://github.com/aws-samples/amazon-redshift-udfs/tree/master/python-udfs/migrating-python-udfs
```

The CLI will detect your agent environment and install the skill to the appropriate local skills folder.

### How to Use

Once installed, trigger the migration by telling Kiro:

```
Migrate python UDFs on workgroup my-workgroup in us-east-1
```

The skill guides you through an 8-phase workflow:

| Phase | Action | Details |
|-------|--------|---------|
| 1 | Discover clusters | Lists all Redshift Serverless workgroups and provisioned clusters in your specified region |
| 2 | Validate prerequisites | Checks IAM roles, VPC endpoints, Secrets Manager credentials, and namespace default roles |
| 3 | Discover Python UDFs | Queries `pg_proc` via the Redshift Data API to find all plpythonu functions |
| 4 | Convert | Generates Lambda handler code and Redshift EXTERNAL FUNCTION DDL for each UDF |
| 5 | Present plan & get approval | Shows the full migration plan and waits for explicit confirmation before deploying |
| 6 | Deploy | Creates Lambda functions and registers them as external functions with `_lambdaudf` suffix |
| 7 | Validate | Runs parallel validation queries comparing Python UDF output vs. Lambda UDF output |
| 8 | Rename (cutover) | After sign-off, renames old Python UDFs with `_pythonudf` suffix and renames `_lambdaudf` functions to original names |

### Safety Features

- **No production disruption** — Lambda UDFs are deployed with a `_lambdaudf` suffix so existing Python UDFs remain untouched until you approve the cutover
- **Explicit approval gates** — The skill pauses before deployment and before cutover to get your confirmation
- **Rollback support** — Until June 30, 2026, original Python UDFs are preserved with a `_pythonudf` suffix for easy revert
- **Sequential validation** — Each UDF is validated individually with side-by-side output comparison before proceeding to the next

---

## Python UDFs in this Repository

This folder contains the original Python UDF source code, retained for reference during migration. Each UDF has been converted to a Lambda UDF in the [`lambda-udfs/`](../lambda-udfs/) folder.

| Python UDF (deprecated) | Lambda UDF (replacement) | Description |
|--------------------------|--------------------------|-------------|
| `f_bitwise_to_delimited` | [`lambda-udfs/f_bitwise_to_delimited(bigint,int,char)`](../lambda-udfs/f_bitwise_to_delimited(bigint,int,char)/) | Convert a bitwise integer to a delimited string |
| `f_bitwise_to_string` | [`lambda-udfs/f_bitwise_to_string(bigint,int)`](../lambda-udfs/f_bitwise_to_string(bigint,int)/) | Convert a bitwise integer to a string |
| `f_cosine_similarity` | [`lambda-udfs/f_cosine_similarity(varchar,varchar)`](../lambda-udfs/f_cosine_similarity(varchar,varchar)/) | Calculate cosine similarity between two vectors |
| `f_format_number` | [`lambda-udfs/f_format_number(float,varchar,varchar,int,int,bool)`](../lambda-udfs/f_format_number(float,varchar,varchar,int,int,bool)/) | Format a number with custom locale settings |
| `f_fuzzy_string_match` | [`lambda-udfs/f_fuzzy_string_match(varchar,varchar)`](../lambda-udfs/f_fuzzy_string_match(varchar,varchar)/) | Fuzzy string matching |
| `f_next_business_day` | [`lambda-udfs/f_next_business_day(date)`](../lambda-udfs/f_next_business_day(date)/) | Get the next business day from a date |
| `f_null_syns` | [`lambda-udfs/f_null_syns(varchar)`](../lambda-udfs/f_null_syns(varchar)/) | Replace null synonyms with actual NULLs |
| `f_parse_url_query_string` | [`lambda-udfs/f_parse_url_query_string(varchar)`](../lambda-udfs/f_parse_url_query_string(varchar)/) | Parse URL query string parameters |
| `f_parse_url` | [`lambda-udfs/f_parse_url(varchar,varchar)`](../lambda-udfs/f_parse_url(varchar,varchar)/) | Parse URL components |
| `f_parse_xml` | [`lambda-udfs/f_parse_xml(varchar)`](../lambda-udfs/f_parse_xml(varchar)/) | Parse XML content |
| `f_sentiment` | [`lambda-udfs/f_sentiment(varchar)`](../lambda-udfs/f_sentiment(varchar)/) | Basic sentiment analysis |
| `f_ua_parser_family` | [`lambda-udfs/f_ua_parser_family(varchar)`](../lambda-udfs/f_ua_parser_family(varchar)/) | Parse user-agent strings |
| `f_unixts_to_timestamp` | [`lambda-udfs/f_unixts_to_timestamp(bigint,varchar)`](../lambda-udfs/f_unixts_to_timestamp(bigint,varchar)/) | Convert Unix timestamps to Redshift timestamps |
| `fn_levenshtein_distance` | [`lambda-udfs/fn_lambda_levenshtein_distance(varchar,varchar)`](../lambda-udfs/fn_lambda_levenshtein_distance(varchar,varchar)/) | Calculate Levenshtein (edit) distance between two strings |

---

## Additional Resources

- [AWS Blog — Python UDF End of Support](https://aws.amazon.com/blogs/big-data/amazon-redshift-python-user-defined-functions-will-reach-end-of-support-after-june-30-2026/)
- [Lambda UDF Examples (this repo)](../lambda-udfs/)
- [Amazon Redshift Lambda UDF Documentation](https://docs.aws.amazon.com/redshift/latest/dg/udf-creating-a-lambda-sql-udf.html)
- [AWS Lambda Pricing](https://aws.amazon.com/lambda/pricing/)
