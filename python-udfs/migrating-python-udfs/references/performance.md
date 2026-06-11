# Performance and Cost Optimization

## Language Selection

| Language | Cold Start | Throughput | Best For |
|----------|-----------|------------|----------|
| Rust | ~10ms | Highest | High-volume, performance-critical |
| Golang | ~20-50ms | Very High | Compute-heavy; up to 100x faster than Python |
| Node.js | ~100-300ms | Good | String manipulation, JSON |
| Python | ~200-500ms | Good | Quick ports; rich ecosystem |
| Java | ~1-3s | High | Complex business logic |

Start with Python for quick port, optimize to Golang/Rust if needed.

## Payload Management

Lambda limits payload to 6 MB ([Lambda quotas — Invocation payload](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html)). Redshift batches rows to minimize calls.
- Strip unnecessary columns before passing to UDF
- Trim whitespace (CHAR types are padded)
- Use MAX_BATCH_SIZE for large/variable returns (start at 2 MB, tune upward)

## Memoization

Cache results for duplicate inputs within a batch:
```python
from functools import lru_cache

@lru_cache(maxsize=10000)
def compute_expensive_result(input_value):
    return result
```

## Concurrency

- Default: 1,000 concurrent executions per Region per account ([AWS Lambda quotas](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html))
- Scales with concurrent queries, not row count
- Use reserved concurrency to isolate non-critical UDFs

## Cost Evaluation

CloudWatch Insights query (ARM pricing):
```
parse @message /Duration:\s*(?<@duration_ms>\d+\.\d+)\s*ms\s*Billed\s*Duration:\s*(?<@billed_duration_ms>\d+)\s*ms\s*Memory\s*Size:\s*(?<@memory_size_mb>\d+)\s*MB/
| filter @message like /REPORT RequestId/
| stats sum(@billed_duration_ms * @memory_size_mb * 1.3021e-11 + 2.0e-7) as @cost_dollars_total
```

> Constant `1.3021e-11` = ARM pricing $0.0000133334/GB-s ÷ 1024 MB/GB ÷ 1000 ms/s. For x86, use `1.6279e-11`.

Benchmark: 30M rows Levenshtein (Python, ARM, us-east-1) = $0.02329
