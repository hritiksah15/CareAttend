from ml.data_generator import derive_age_group


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


def generate_interventions(patient_data, risk_probability, shap_values):
    interventions = []
    age = patient_data.get("Age", 0)
    age_group = derive_age_group(age)
    risk_tier = _get_risk_tier(risk_probability)
    top_features = [sv["feature"] for sv in shap_values[:3]] if shap_values else []

    if patient_data.get("PriorDNACount", 0) >= 2 or "PriorDNACount" in top_features:
        interventions.append(INTERVENTION_RULES["high_prior_dna"])

    if age >= 65:
        interventions.append(INTERVENTION_RULES["elderly_transport"])
    if age >= 75:
        interventions.append(INTERVENTION_RULES["carer_alert"])
    if age >= 85 or (risk_tier == "High" and age >= 75):
        interventions.append(INTERVENTION_RULES["clinical_triage"])

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
    if probability <= 0.33:
        return "Low"
    elif probability <= 0.66:
        return "Medium"
    else:
        return "High"
