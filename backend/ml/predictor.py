import numpy as np
import joblib
import shap

from ml.data_generator import FEATURE_NAMES, PLAIN_ENGLISH_NAMES


class CareAttendPredictor:
    def __init__(self, model_dir="models"):
        self.model = joblib.load(f"{model_dir}/model.joblib")
        self.scaler = joblib.load(f"{model_dir}/scaler.joblib")
        self.background_data = np.load(f"{model_dir}/X_train_sample.npy")
        try:
            self.threshold = joblib.load(f"{model_dir}/threshold.joblib")
        except FileNotFoundError:
            self.threshold = 0.5
        self._init_explainer()

    def _init_explainer(self):
        if hasattr(self.model, "estimators_"):
            self.explainer = shap.TreeExplainer(
                self.model,
                data=self.background_data,
                feature_names=FEATURE_NAMES,
            )
        else:
            self.explainer = shap.LinearExplainer(
                self.model,
                masker=self.background_data,
                feature_names=FEATURE_NAMES,
            )

    def predict(self, patient_data):
        features = self._extract_features(patient_data)
        features_scaled = self.scaler.transform(features.reshape(1, -1))

        probability = float(self.model.predict_proba(features_scaled)[0][1])
        shap_values = self._compute_shap(features_scaled)

        return {
            "probability": round(probability, 4),
            "percentage": round(probability * 100, 1),
            "risk_tier": self._risk_tier(probability),
            "shap_values": shap_values,
        }

    def _extract_features(self, data):
        return np.array([
            data.get("Age", 0),
            data.get("Gender", 0),
            data.get("AppointmentLeadTimeDays", 0),
            data.get("SMSReceived", 0),
            data.get("PriorDNACount", 0),
            data.get("Hypertension", 0),
            data.get("Diabetes", 0),
            data.get("Alcoholism", 0),
            data.get("Disability", 0),
            data.get("IMDDecile", 5),
        ], dtype=float)

    def _compute_shap(self, features_scaled):
        sv = self.explainer.shap_values(features_scaled)
        if isinstance(sv, list):
            values = sv[1][0]
        elif sv.ndim == 3:
            values = sv[0, :, 1]
        else:
            values = sv[0]

        indexed = [(FEATURE_NAMES[i], float(values[i])) for i in range(len(FEATURE_NAMES))]
        indexed.sort(key=lambda x: abs(x[1]), reverse=True)

        result = []
        for feat_name, val in indexed[:5]:
            result.append({
                "feature": feat_name,
                "label": PLAIN_ENGLISH_NAMES.get(feat_name, feat_name),
                "value": round(val, 4),
                "direction": "risk-increasing" if val > 0 else "risk-reducing",
            })
        return result

    @staticmethod
    def _risk_tier(prob):
        if prob <= 0.33:
            return "Low"
        elif prob <= 0.66:
            return "Medium"
        else:
            return "High"
