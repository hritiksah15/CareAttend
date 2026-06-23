import numpy as np
import joblib
import shap
import os

from ml.data_generator import FEATURE_NAMES, PLAIN_ENGLISH_NAMES


class CareAttendPredictor:
    def __init__(self, model_dir="models"):
        base_model_path = os.path.join(model_dir, "model.joblib")
        calibrated_model_path = os.path.join(model_dir, "model_calibrated.joblib")

        self.explanation_model = joblib.load(base_model_path)
        if os.path.exists(calibrated_model_path):
            self.model = joblib.load(calibrated_model_path)
            self.model_source = "calibrated"
        else:
            self.model = self.explanation_model
            self.model_source = "base"

        self.scaler = joblib.load(f"{model_dir}/scaler.joblib")
        self.background_data = np.load(f"{model_dir}/X_train_sample.npy")
        # The operating threshold must match the model that actually scores.
        # threshold.joblib is tuned on the base model's raw probabilities;
        # calibration rescales those probabilities, so the calibrated model
        # needs its own threshold (threshold_calibrated.joblib) or it would
        # apply the base cutoff to rescaled scores and collapse recall.
        self.threshold = self._load_threshold(model_dir)
        self._init_explainer()

    def _load_threshold(self, model_dir):
        if self.model_source == "calibrated":
            cal_path = os.path.join(model_dir, "threshold_calibrated.joblib")
            if os.path.exists(cal_path):
                return joblib.load(cal_path)
        try:
            return joblib.load(os.path.join(model_dir, "threshold.joblib"))
        except FileNotFoundError:
            return 0.66

    def _init_explainer(self):
        if hasattr(self.explanation_model, "estimators_"):
            self.explainer = shap.TreeExplainer(
                self.explanation_model,
                data=self.background_data,
                feature_names=FEATURE_NAMES,
            )
        else:
            self.explainer = shap.LinearExplainer(
                self.explanation_model,
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
            "risk_tier": self._risk_tier(probability, self.threshold),
            "shap_values": shap_values,
            "model_source": self.model_source,
            "threshold": round(float(self.threshold), 4),
        }

    def _extract_features(self, data):
        return np.array(
            [
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
            ],
            dtype=float,
        )

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
            result.append(
                {
                    "feature": feat_name,
                    "label": PLAIN_ENGLISH_NAMES.get(feat_name, feat_name),
                    "value": round(val, 4),
                    "direction": "risk-increasing" if val > 0 else "risk-reducing",
                }
            )
        return result

    @staticmethod
    def _risk_tier(prob, high_threshold=0.66):
        high_threshold = float(high_threshold)
        low_threshold = min(0.33, high_threshold / 2)
        if prob <= low_threshold:
            return "Low"
        elif prob < high_threshold:
            return "Medium"
        else:
            return "High"
