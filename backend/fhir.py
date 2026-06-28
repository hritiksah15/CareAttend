"""FHIR R4 resource adapters for the CareAttend integration boundary.

These helpers intentionally map existing prototype data into FHIR-shaped JSON;
they are not a live NHS Spine, EMIS, or SystmOne connector.
"""

FHIR_NHS_NUMBER_SYSTEM = "https://fhir.nhs.uk/Id/nhs-number"
FHIR_CAREATTEND_EXTENSION_BASE = "https://careattend.local/fhir/StructureDefinition"


def patient_to_fhir(nhs_number, patient):
    """Map a mock EHR patient dictionary to a minimal FHIR R4 Patient."""
    gender = "unknown"
    if patient.get("Gender") == 0:
        gender = "female"
    elif patient.get("Gender") == 1:
        gender = "male"

    return {
        "resourceType": "Patient",
        "id": str(nhs_number),
        "meta": {"profile": ["http://hl7.org/fhir/StructureDefinition/Patient"]},
        "identifier": [
            {
                "system": FHIR_NHS_NUMBER_SYSTEM,
                "value": str(nhs_number),
            }
        ],
        "name": [{"text": patient.get("name", "Mock patient")}],
        "gender": gender,
        "extension": _patient_extensions(patient),
    }


def appointment_to_fhir(appointment):
    """Map a persisted appointment row to a minimal FHIR R4 Appointment."""
    resource = {
        "resourceType": "Appointment",
        "id": str(appointment.id),
        "meta": {"profile": ["http://hl7.org/fhir/StructureDefinition/Appointment"]},
        "status": _appointment_status_to_fhir(appointment.status),
        "participant": [
            {
                "actor": {"reference": f"Patient/{appointment.patient_id}"},
                "status": "accepted",
            }
        ],
        "extension": _appointment_extensions(appointment),
    }

    start = _appointment_start(appointment.appointment_date, appointment.appointment_time)
    if start:
        resource["start"] = start
    if appointment.clinic:
        resource["serviceType"] = [{"text": appointment.clinic}]

    return resource


def _patient_extensions(patient):
    extension_fields = {
        "careattend-age": ("valueInteger", patient.get("Age")),
        "careattend-imd-decile": ("valueInteger", patient.get("IMDDecile")),
        "careattend-prior-dna-count": ("valueInteger", patient.get("PriorDNACount")),
        "careattend-hypertension": ("valueBoolean", _flag_value(patient.get("Hypertension"))),
        "careattend-diabetes": ("valueBoolean", _flag_value(patient.get("Diabetes"))),
        "careattend-disability": ("valueBoolean", _flag_value(patient.get("Disability"))),
    }
    return _extensions(extension_fields)


def _appointment_extensions(appointment):
    extension_fields = {
        "careattend-risk-probability": ("valueDecimal", appointment.probability),
        "careattend-risk-tier": ("valueString", appointment.risk_tier),
        "careattend-age-group": ("valueString", appointment.age_group),
    }
    return _extensions(extension_fields)


def _extensions(extension_fields):
    extensions = []
    for name, (value_key, value) in extension_fields.items():
        if value is None or value == "":
            continue
        extensions.append(
            {
                "url": f"{FHIR_CAREATTEND_EXTENSION_BASE}/{name}",
                value_key: value,
            }
        )
    return extensions


def _flag_value(value):
    if value is None or value == "":
        return None
    return bool(int(value))


def _appointment_start(appointment_date, appointment_time):
    if not appointment_date:
        return None
    if not appointment_time:
        return str(appointment_date)
    time_part = str(appointment_time)
    if len(time_part.split(":")) == 2:
        time_part = f"{time_part}:00"
    return f"{appointment_date}T{time_part}"


def _appointment_status_to_fhir(status):
    return {
        "scheduled": "booked",
        "confirmed": "booked",
        "attended": "fulfilled",
        "dna": "noshow",
        "cancelled": "cancelled",
        "rescheduled": "proposed",
    }.get(status, "booked")
