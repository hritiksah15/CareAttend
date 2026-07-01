"""NFR-02 latency benchmark — repeatable evidence for /predict and /bias-audit.

Measures server-side request-handling latency (model inference + SHAP + DB
write for /predict; full fairness audit for /bias-audit) using Flask's
in-process test client. This isolates application/model compute and excludes
network transit, so the numbers are stable and reproducible on any machine
without standing up Postgres or a web server.

Run:
    cd backend && python benchmark_latency.py                 # defaults
    cd backend && python benchmark_latency.py -n 500 -w 50     # custom counts
    cd backend && python benchmark_latency.py --json out.json  # machine-readable

The benchmark forces a throwaway in-memory SQLite database BEFORE importing the
app, so it can never touch a real PostgreSQL instance (same guarantee as the
test suite's conftest).
"""

import argparse
import json
import os
import statistics
import sys
import time

BENCH_LOGIN_CRED = "Password123!"

# Isolate from any real database BEFORE app.py reads DATABASE_URL.
os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")
os.environ.setdefault("FLASK_DEBUG", "0")

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import app as flask_app, load_models  # noqa: E402
from models import db, User  # noqa: E402

# Representative high-risk patient (mirrors the test-suite fixture).
SAMPLE_PATIENT = {
    "Age": 78,
    "Gender": 0,
    "AppointmentLeadTimeDays": 21,
    "SMSReceived": 0,
    "PriorDNACount": 4,
    "IMDDecile": 2,
    "Disability": 1,
}


def _percentile(sorted_values, pct):
    """Linear-interpolated percentile (pct in 0..100) of an ascending list."""
    if not sorted_values:
        return 0.0
    if len(sorted_values) == 1:
        return sorted_values[0]
    rank = (pct / 100) * (len(sorted_values) - 1)
    low = int(rank)
    high = min(low + 1, len(sorted_values) - 1)
    frac = rank - low
    return sorted_values[low] + (sorted_values[high] - sorted_values[low]) * frac


def _summarise(samples_ms):
    s = sorted(samples_ms)
    return {
        "n": len(s),
        "min": min(s),
        "mean": statistics.mean(s),
        "p50": _percentile(s, 50),
        "p95": _percentile(s, 95),
        "p99": _percentile(s, 99),
        "max": max(s),
    }


def _time_calls(call, iterations):
    samples = []
    for _ in range(iterations):
        start = time.perf_counter()
        resp = call()
        elapsed_ms = (time.perf_counter() - start) * 1000
        if resp.status_code != 200:
            raise RuntimeError(f"unexpected status {resp.status_code}: {resp.get_data(as_text=True)[:200]}")
        samples.append(elapsed_ms)
    return samples


def run(iterations, warmup):
    flask_app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///:memory:"
    flask_app.config["TESTING"] = True

    with flask_app.app_context():
        db.create_all()
        load_models()

        client = flask_app.test_client()

        # Provision an admin (predict needs a token; bias-audit needs admin role).
        client.post(
            "/auth/register",
            json={"username": "bench", "email": "bench@nhs.uk", "password": BENCH_LOGIN_CRED},
        )
        user = User.query.filter_by(username="bench").first()
        user.role = "admin"
        db.session.commit()
        token = client.post(
            "/auth/login",
            json={"username": "bench", "password": BENCH_LOGIN_CRED},
        ).get_json()["token"]
        headers = {"Authorization": f"Bearer {token}"}

        endpoints = {
            "POST /api/predict": lambda: client.post("/api/predict", headers=headers, json=SAMPLE_PATIENT),
            "GET /api/bias-audit": lambda: client.get("/api/bias-audit", headers=headers),
        }

        results = {}
        for name, call in endpoints.items():
            _time_calls(call, warmup)  # warm caches / lazy imports
            samples = _time_calls(call, iterations)
            results[name] = _summarise(samples)
        return results


def _print_table(results, iterations, warmup):
    print(f"\nNFR-02 latency benchmark  (iterations={iterations}, warmup={warmup})")
    print("Measures in-process server handling latency (network excluded). Times in ms.\n")
    cols = ["endpoint", "n", "min", "mean", "p50", "p95", "p99", "max"]
    print(f"{cols[0]:<22}" + "".join(f"{c:>9}" for c in cols[1:]))
    print("-" * (22 + 9 * 7))
    for name, st in results.items():
        print(
            f"{name:<22}{st['n']:>9}" + "".join(f"{st[k]:>9.1f}" for k in ["min", "mean", "p50", "p95", "p99", "max"])
        )
    print()


def main():
    ap = argparse.ArgumentParser(description="NFR-02 latency benchmark for /predict and /bias-audit.")
    ap.add_argument("-n", "--iterations", type=int, default=200, help="timed requests per endpoint (default 200)")
    ap.add_argument("-w", "--warmup", type=int, default=20, help="untimed warmup requests per endpoint (default 20)")
    ap.add_argument("--json", metavar="PATH", help="write the results as JSON to PATH")
    args = ap.parse_args()

    results = run(args.iterations, args.warmup)
    _print_table(results, args.iterations, args.warmup)

    if args.json:
        payload = {
            "iterations": args.iterations,
            "warmup": args.warmup,
            "measured": "in-process Flask test client (network excluded)",
            "unit": "milliseconds",
            "results": results,
        }
        with open(args.json, "w") as f:
            json.dump(payload, f, indent=2)
        print(f"Wrote {args.json}")


if __name__ == "__main__":
    main()
