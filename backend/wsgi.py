#!/usr/bin/env python3
"""Production WSGI entrypoint for Care Attend.

Run with a real WSGI server, e.g.:

    gunicorn --bind 0.0.0.0:5000 --workers 2 wsgi:app

Importing ``app`` alone does NOT load the ML models or ensure the database —
that work only ran inside ``app.py``'s ``if __name__ == "__main__"`` block, so a
WSGI server importing the module would serve a backend where ``predictor`` is
None and ``/predict`` 500s. This module performs that startup wiring at import
time so the app is fully initialised before the first request is served.
"""

from app import app, load_models, ensure_database

load_models()
ensure_database()

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000)
