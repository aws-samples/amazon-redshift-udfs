# Conversion Rules

## Lambda Handler Template

**CRITICAL: Return `json.dumps(...)` string, NOT a Python dict. Returning a dict causes "Empty format" error.**
**CRITICAL: Arguments are ROW-BASED. `event["arguments"][i]` is a list of all args for row i.**

```python
import json

def lambda_handler(event, context):
    results = []
    for i in range(event['num_records']):
        try:
            row = event['arguments'][i]
            if any(a is None for a in row):
                results.append(None)
            else:
                results.append(_udf_impl(row[0], row[1], ...))
        except Exception:
            results.append(None)
    return json.dumps({"results": results, "success": True})

def _udf_impl(arg1, arg2, ...):
    <original UDF body>
```

## Argument Access

**CORRECT (row-based):** `args[i][0]` = row i, first argument
**WRONG (column-based):** `args[0][i]` — will cause IndexError for multi-arg functions

## Response Format

```python
# WRONG — causes "Empty format" error
return {"results": results, "success": True}
# CORRECT
return json.dumps({"results": results, "success": True})
```

## Conversion Steps

1. Extract Python body from between `$$...$$`
2. Move imports to module level (always include `import json`)
3. Wrap body in `_udf_impl()` preserving nested defs
4. Null-check each arg before calling `_udf_impl`
5. Apply Python 2-to-3 fixes (see table below)
6. Scan imports for non-stdlib packages; create `layers.json` if needed
7. Preserve regex backslashes with raw strings `r'...'`

## SQL DDL Template

```sql
CREATE OR REPLACE EXTERNAL FUNCTION
    <schema>.<function_name>_lambdaudf(arg1_name arg1_type, arg2_name arg2_type, ...)
    RETURNS <return_type>
    IMMUTABLE
    LAMBDA '<function_name>_lambda'
    IAM_ROLE default;
```

## Type Mapping

| Redshift | SQL DDL | Python |
|----------|---------|--------|
| int4/integer | INTEGER | int |
| int8/bigint | BIGINT | int |
| float8/double precision | FLOAT8 | float |
| character varying/varchar | VARCHAR | str |
| bool/boolean | BOOLEAN | bool |
| numeric | NUMERIC | Decimal |
| date | DATE | str |
| timestamp | TIMESTAMP | str |

## Python 2 to 3

| Python 2 | Python 3 |
|----------|----------|
| `import urlparse` | `from urllib.parse import urlparse` |
| `except Exception, e:` | `except Exception as e:` |
| `print x` | `print(x)` |
| `unicode(x)` | `str(x)` |
| `dict.has_key(k)` | `k in dict` |
| `xrange(n)` | `range(n)` |

## External Libraries

| Library | Approach |
|---------|----------|
| numpy (simple) | Replace with math module |
| re, json, xml.etree | Native in Python 3.12 |
| urllib/urlparse | urllib.parse |
| thefuzz, ua_parser, scipy, pandas | Lambda layer required |
