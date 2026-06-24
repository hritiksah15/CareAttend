# Performance Benchmark — NFR-02 (Latency)

**Requirement (NFR-02):** interactive decision-support endpoints must return
within an interactive budget. Target: **p95 ≤ 500 ms** for `/api/predict` and
**p95 ≤ 1000 ms** for `/api/bias-audit`. Both are met with a wide margin (see
results).

This document is the formal latency evidence for NFR-02, replacing the previous
"benchmark TODO" placeholder in the traceability matrix.

## Method

Latency is measured **server-side, in-process** using Flask's test client
(`backend/benchmark_latency.py`). Each endpoint is warmed up (untimed) to absorb
lazy imports and model loading, then timed over N requests with
`time.perf_counter()`. The script reports min / mean / p50 / p95 / p99 / max.

- `POST /api/predict` — single high-risk patient; exercises feature scaling,
  calibrated logistic-regression inference, SHAP attribution, intervention
  generation, NL summary, and the assessment-summary DB write.
- `GET /api/bias-audit` — the full fairness audit across protected attributes
  plus governance verdict.

**Scope:** this measures application + model compute (the part the project
controls), not network transit. Numbers are reproducible on any machine without
Postgres or a running web server — the script forces a throwaway in-memory
SQLite database, identical to the test suite's isolation.

### Reproduce

```bash
cd backend
python benchmark_latency.py                 # 200 timed + 20 warmup per endpoint
python benchmark_latency.py -n 500 -w 50     # custom counts
python benchmark_latency.py --json out.json  # machine-readable output
```

## Results

Run: 200 timed requests/endpoint, 20 warmup. Times in **milliseconds**.

| Endpoint            |   n |  min | mean |  p50 |  p95 |  p99 |  max |
|---------------------|----:|-----:|-----:|-----:|-----:|-----:|-----:|
| `POST /api/predict`   | 200 | 1.06 | 1.17 | 1.14 | 1.35 | 1.51 | 2.22 |
| `GET /api/bias-audit` | 200 | 3.25 | 3.92 | 3.51 | 4.48 | 9.72 | 41.0 |

### Environment

- Apple M4 (10 cores), macOS 26.4.1 (arm64)
- Python 3.14.2, Flask 3.1.0, scikit-learn 1.5.2
- In-memory SQLite; single-threaded synchronous client

## Interpretation

Both endpoints clear their NFR-02 targets by more than two orders of magnitude
(`/predict` p95 ≈ 1.35 ms vs 500 ms target; `/bias-audit` p95 ≈ 4.48 ms vs
1000 ms target). The single-figure `/bias-audit` `max` of ~41 ms is a one-off
cold-path outlier (GC / first-touch), not representative — p95 and p99 stay in
single digits.

**Caveats:**
- Figures exclude network and TLS; a real HTTP round-trip on a LAN adds a small,
  near-constant overhead that does not change the conclusion.
- Measured single-threaded with no concurrent load. Throughput under
  concurrency is governed by the WSGI server (gunicorn) worker count, which is a
  deployment concern outside this functional latency budget.
- The calibrated logistic-regression model is intentionally lightweight, which
  is why inference dominates negligibly; a heavier model would shift these
  numbers but the harness and budget remain valid.
