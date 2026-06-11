# Discovery Queries

## Primary: pg_proc (live UDFs)

```sql
SELECT p.proname AS function_name, p.pronargs AS num_args,
    t.typname AS return_type, n.nspname AS schema_name,
    l.lanname AS language, pg_get_functiondef(p.oid) AS function_definition
FROM pg_proc p, pg_language l, pg_type t, pg_namespace n
WHERE p.prolang = l.oid AND p.prorettype = t.oid
  AND l.lanname = 'plpythonu' AND p.pronamespace = n.oid
  AND nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY proname;
```

## Fallback: python_udf_inventory (post-Patch 198)

```sql
SELECT function_name, num_args, return_type, schema_name, function_definition
FROM public.python_udf_inventory ORDER BY function_name;
```

Use the fallback when `pg_proc` returns zero rows (Patch 198 blocks new plpythonu creation and may affect discovery on some clusters).
