"""Pytest bootstrap — isolate the test database from the real one.

CRITICAL: this forces every test run onto a throwaway SQLite database BEFORE
`app.py` reads DATABASE_URL. Without it, running pytest while DATABASE_URL
points at PostgreSQL let the fixtures' `db.drop_all()` teardown wipe the real
`careattend` database. This module guarantees tests can never touch PostgreSQL.

conftest.py is imported by pytest before any test module, so the environment is
set before `from app import app` runs anywhere.
"""

import os
import tempfile

# A throwaway, file-backed SQLite DB shared across all test modules.
_TEST_DB_PATH = os.path.join(tempfile.gettempdir(), "careattend_test.sqlite")
os.environ["DATABASE_URL"] = f"sqlite:///{_TEST_DB_PATH}"
os.environ["FLASK_DEBUG"] = "0"

# Hard stop: never allow a test session to target PostgreSQL.
assert os.environ["DATABASE_URL"].startswith("sqlite"), \
    "Test database must be SQLite — refusing to run against a real database."
