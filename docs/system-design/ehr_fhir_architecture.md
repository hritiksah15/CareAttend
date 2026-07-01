# EHR and FHIR R4 Integration Architecture

Status: prototype integration boundary implemented; live EHR connectivity not claimed.

## Implemented Surface

CareAttend now exposes FHIR-shaped read endpoints over data the prototype already owns:

| Endpoint | Source | FHIR resource | Access |
| --- | --- | --- | --- |
| `GET /api/ehr/fhir/patients/{nhs_number}` | Mock EHR dictionary | `Patient` | Staff/Admin |
| `GET /api/ehr/fhir/appointments/{appointment_id}` | Persisted appointment record | `Appointment` | Staff/Admin, owner scoped |

The adapter lives in `backend/fhir.py`. It maps existing data into minimal FHIR R4 JSON without pretending to be a live NHS connector.

## Resource Mapping

### Patient

| CareAttend field | FHIR field |
| --- | --- |
| NHS number key | `Patient.id`, `Patient.identifier[system=https://fhir.nhs.uk/Id/nhs-number]` |
| `name` | `Patient.name[0].text` |
| `Gender` | `Patient.gender` (`0=female`, `1=male`) |
| `Age`, `IMDDecile`, `PriorDNACount`, condition flags | CareAttend extension URLs |

### Appointment

| CareAttend field | FHIR field |
| --- | --- |
| `AppointmentRecord.id` | `Appointment.id` |
| `status` | `Appointment.status` (`scheduled/confirmed=booked`, `attended=fulfilled`, `dna=noshow`) |
| `appointment_date` + `appointment_time` | `Appointment.start` |
| `clinic` | `Appointment.serviceType.text` |
| `patient_id` | `Appointment.participant.actor.reference` |
| `probability`, `risk_tier`, `age_group` | CareAttend extension URLs |

## Connector Boundary

Production EHR integration should be implemented behind a connector interface:

1. `PatientLookupConnector`: NHS number or local patient identifier -> FHIR `Patient`.
2. `AppointmentConnector`: clinic/date -> FHIR `Appointment` bundle.
3. `Observation/ConditionConnector`: optional structured clinical flags where a DPIA and data-sharing agreement allow it.
4. `WritebackConnector`: optional task/outreach note writeback, disabled until IG and clinical safety approval.

Target production adapters would sit behind the same contract:

| Adapter | Purpose | Production prerequisites |
| --- | --- | --- |
| Mock adapter | Demo and tests | Already implemented |
| FHIR server adapter | Standards-based integration | OAuth2, TLS, audit logging, DPIA, DCB0129 |
| EMIS/SystmOne adapter | GP system integration | Vendor approval, IG review, environment access |
| CSV bridge | Low-risk pilot import/export | Data-processing agreement, retention controls |

## Security and Information Governance

- No live patient connector is enabled in this prototype.
- Prototype appointment FHIR export is owner scoped to the current staff/admin user.
- Prediction inputs are still not persisted as raw patient records.
- Before live NHS data access, the project needs a completed DPIA, data-sharing agreement, clinical safety case, connector penetration test, and operational audit policy.

## Test Evidence

FHIR endpoint behaviour is covered in `backend/tests/test_new_endpoints.py`:

- Mock EHR patient -> FHIR `Patient`.
- Persisted appointment -> FHIR `Appointment`.
- Cross-user appointment FHIR lookup returns `404`.
