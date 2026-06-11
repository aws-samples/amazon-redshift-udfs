# Rollback Procedures

## When to Roll Back

Roll back if ANY occur after the function swap:
- Query results differ between old and new functions
- Lambda invocation errors in CloudWatch
- Unexpected latency increases
- Downstream pipeline failures
- Lambda throttling causing query timeouts

## Steps

### Before Rename (Phase 7 — validation failed, `_lambdaudf` still exists alongside original)

1. Drop the Lambda UDF:
   ```sql
   DROP FUNCTION <schema>.<function_name>_lambdaudf(<arg-types>);
   ```
   > `<arg-types>` = argument types only, e.g., `VARCHAR, INTEGER, FLOAT`. Do NOT include argument names.

2. Verify the original Python UDF still exists:
   ```sql
   SELECT n.NSPNAME, p.PRONAME, l.LANNAME
   FROM PG_PROC_INFO p JOIN PG_LANGUAGE l ON p.PROLANG = l.OID
   JOIN PG_NAMESPACE n ON p.PRONAMESPACE = n.OID
   WHERE p.PRONAME = '<function_name>' AND n.NSPNAME = '<schema>';
   ```

3. Verify downstream queries work with the original function.

### After Rename (Phase 8 — swap completed, original Python UDF renamed to `_pythonudf`)

1. Rename the Lambda external function (now under the original name) back to `_lambdaudf`:
   ```sql
   ALTER FUNCTION <schema>.<function_name>(<arg-types>) RENAME TO <function_name>_lambdaudf;
   ```

2. Rename the Python UDF back to the original name:
   ```sql
   ALTER FUNCTION <schema>.<function_name>_pythonudf(<arg-types>) RENAME TO <function_name>;
   ```

3. Verify downstream queries work with the restored Python UDF.

## Critical Warning

Rollback is ONLY available until June 30, 2026. After that date:
- Python UDF execution is suspended regardless of function state
- There is NO way to re-enable Python UDFs
- Any queries depending on Python UDFs will fail

Complete all migrations well before the deadline.

## Escalation

1. Roll back immediately
2. Document the error (CloudWatch logs, SYS_QUERY_HISTORY)
3. Report to support channel
4. Investigate root cause before re-attempting
