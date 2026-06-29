from ml.data_generator import derive_age_group


CONDITION_LABELS = {
    "Diabetes": "diabetes",
    "Alcoholism": "alcohol dependency",
    "Disability": "registered disability",
    "Hypertension": "hypertension",
}


INTERVENTION_RULES = {
    "high_prior_dna": {
        "title": "Proactive Phone Reminder",
        "description": "Patient has a history of missed appointments. Schedule a personal phone call 48 hours before the appointment.",
        "icon": "phone",
        "priority": 1,
    },
    "elderly_transport": {
        "title": "Transport Assistance",
        "description": "Arrange patient transport service or volunteer driver. Contact local community transport scheme.",
        "icon": "car",
        "priority": 1,
    },
    "carer_alert": {
        "title": "Carer / Family Alert",
        "description": "Notify the patient's registered carer or next of kin about the upcoming appointment.",
        "icon": "users",
        "priority": 2,
    },
    "clinical_triage": {
        "title": "Clinical Triage Escalation",
        "description": "Refer to clinical team for welfare review. Patient may have unaddressed health barriers.",
        "icon": "alert",
        "priority": 1,
    },
    "condition_review": {
        "title": "Condition-Aware Outreach Review",
        "description": "Review clinical barriers before contact. Age group and long-term condition flags may affect attendance support needs.",
        "icon": "stethoscope",
        "priority": 2,
    },
    "sms_followup": {
        "title": "Enhanced SMS Follow-up",
        "description": "Send additional SMS reminders at 72h, 48h, and 24h before the appointment with clear instructions.",
        "icon": "message",
        "priority": 3,
    },
    "disability_support": {
        "title": "Accessibility Accommodation",
        "description": "Confirm venue accessibility. Offer telephone or video consultation as an alternative.",
        "icon": "accessibility",
        "priority": 2,
    },
    "deprivation_support": {
        "title": "Social Support Referral",
        "description": "Consider referral to social prescribing link worker. Patient may face financial or social barriers.",
        "icon": "heart",
        "priority": 2,
    },
    "reschedule_offer": {
        "title": "Flexible Rescheduling",
        "description": "Offer to reschedule to a more convenient time or day. Long lead times increase DNA risk.",
        "icon": "calendar",
        "priority": 3,
    },
}


def active_conditions(patient_data):
    """Return human-readable active clinical condition flags."""
    conditions = []
    for field, label in CONDITION_LABELS.items():
        try:
            active = int(patient_data.get(field, 0)) == 1
        except (TypeError, ValueError):
            active = False
        if active:
            conditions.append(label)
    return conditions


def build_outreach_priority(patient_data, risk_tier):
    """Composite support priority.

    The DNA risk tier remains model-led. This separate layer ranks how quickly
    staff should review attendance-support actions, using age vulnerability,
    clinical condition burden, and practical access barriers. It must only
    escalate support; it is not a diagnosis or treatment allocation decision.
    """
    age = int(patient_data.get("Age", 0) or 0)
    age_group = derive_age_group(age)
    conditions = active_conditions(patient_data)
    score = 0
    drivers = []

    if risk_tier == "High":
        score += 3
        drivers.append("High DNA risk")
    elif risk_tier == "Medium":
        score += 1
        drivers.append("Medium DNA risk")

    if age >= 85:
        score += 3
        drivers.append("85+ age group")
    elif age >= 75:
        score += 2
        drivers.append("75-84 age group")
    elif age >= 65:
        score += 1
        drivers.append("65-74 age group")

    high_impact_conditions = {"diabetes", "alcohol dependency", "registered disability"}
    for condition in conditions:
        if condition in high_impact_conditions:
            score += 1
            drivers.append(condition)
    if "hypertension" in conditions and (age >= 65 or len(conditions) >= 2):
        score += 1
        drivers.append("hypertension")
    if len(conditions) >= 2:
        score += 1
        drivers.append("multiple condition flags")

    if patient_data.get("PriorDNACount", 0) >= 2:
        score += 1
        drivers.append("previous missed appointments")
    if patient_data.get("IMDDecile", 10) <= 3:
        score += 1
        drivers.append("high deprivation context")
    if patient_data.get("SMSReceived", 1) == 0:
        score += 1
        drivers.append("no SMS reminder")

    if score >= 5:
        level = "P1"
        label = "Priority 1 - urgent outreach review"
        action = "Review today and confirm the safest attendance support route."
    elif score >= 3:
        level = "P2"
        label = "Priority 2 - proactive outreach"
        action = "Contact before appointment and remove practical attendance barriers."
    else:
        level = "P3"
        label = "Priority 3 - routine reminder"
        action = "Use standard reminder workflow unless local context changes."

    return {
        "level": level,
        "label": label,
        "score": score,
        "age_group": age_group,
        "conditions": conditions,
        "drivers": drivers[:6],
        "action": action,
        "policy": "Composite support priority; DNA risk tier remains model-led and this does not allocate treatment.",
    }


def generate_interventions(patient_data, risk_probability, shap_values, risk_tier=None):
    """Build the ranked intervention list for a patient.

    risk_tier is the single source of truth for the clinical tier and should be
    supplied by the predictor (derived from the deployed operating threshold) so
    every endpoint reports the same tier for the same patient. It is only
    recomputed from the probability as a fallback when not provided.
    """
    interventions = []
    age = patient_data.get("Age", 0)
    age_group = derive_age_group(age)
    if risk_tier is None:
        risk_tier = _get_risk_tier(risk_probability)
    top_features = [sv["feature"] for sv in shap_values[:3]] if shap_values else []
    priority = build_outreach_priority(patient_data, risk_tier)
    has_age_condition_complexity = age >= 65 and bool(priority["conditions"])

    if patient_data.get("PriorDNACount", 0) >= 2 or "PriorDNACount" in top_features:
        interventions.append(INTERVENTION_RULES["high_prior_dna"])

    if age >= 65:
        interventions.append(INTERVENTION_RULES["elderly_transport"])
    if age >= 75:
        interventions.append(INTERVENTION_RULES["carer_alert"])
    if age >= 85 or (risk_tier == "High" and age >= 75):
        interventions.append(INTERVENTION_RULES["clinical_triage"])
    elif risk_tier in {"High", "Medium"} and has_age_condition_complexity:
        interventions.append(INTERVENTION_RULES["condition_review"])

    if patient_data.get("Disability", 0) == 1:
        interventions.append(INTERVENTION_RULES["disability_support"])

    if patient_data.get("IMDDecile", 10) <= 3:
        interventions.append(INTERVENTION_RULES["deprivation_support"])

    if patient_data.get("AppointmentLeadTimeDays", 0) > 14:
        interventions.append(INTERVENTION_RULES["reschedule_offer"])

    if patient_data.get("SMSReceived", 0) == 0:
        interventions.append(INTERVENTION_RULES["sms_followup"])

    if not interventions:
        interventions.append(INTERVENTION_RULES["sms_followup"])

    seen_titles = set()
    unique = []
    for iv in interventions:
        if iv["title"] not in seen_titles:
            seen_titles.add(iv["title"])
            unique.append(iv)
    unique.sort(key=lambda x: x["priority"])

    return unique[:5], risk_tier, age_group


def _get_risk_tier(probability):
    """Fallback tier from raw probability. The predictor's threshold-derived
    tier is authoritative — only used when no tier is passed in."""
    if probability <= 0.33:
        return "Low"
    elif probability <= 0.66:
        return "Medium"
    else:
        return "High"
