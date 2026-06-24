"""Simulated reminder-delivery provider.

CareAttend does not integrate a live SMS/email gateway — doing so needs an
information-governance review and a real provider contract (out of scope for
this prototype). This module models the *delivery lifecycle* honestly so the
operational loop (scheduled -> sent -> actioned, with failure + retry) is
auditable and testable, without ever claiming a message actually reached a
patient.

Swap `SimulatedProvider` for a real adapter (same `send` signature) to wire in
a production gateway later.
"""

import secrets

VALID_CHANNELS = ("sms", "email")


class DeliveryResult:
    def __init__(self, success, provider_ref=None, failure_reason=None):
        self.success = success
        self.provider_ref = provider_ref
        self.failure_reason = failure_reason


class SimulatedProvider:
    """Deterministic-by-default stub. Succeeds unless asked to fail, so demos
    and tests are reproducible. `force_failure` models a gateway error path."""

    name = "simulated"

    def send(self, *, patient_id, channel, message=None, force_failure=False):
        if channel not in VALID_CHANNELS:
            return DeliveryResult(False, failure_reason=f"Unsupported channel '{channel}'")
        if force_failure:
            return DeliveryResult(False, failure_reason="Simulated provider error (gateway unavailable)")
        ref = f"sim_{secrets.token_hex(8)}"
        return DeliveryResult(True, provider_ref=ref)


# Default provider instance used by the app. Replace with a real adapter to ship.
provider = SimulatedProvider()
