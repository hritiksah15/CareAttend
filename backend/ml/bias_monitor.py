import pandas as pd
import joblib
import os

from ml.data_generator import FEATURE_NAMES, derive_age_group


# Maximum tolerated disparity between demographic groups before the audit
# raises a governance breach. 0.10 follows the fairness band used in the
# project's reporting (Caton & Haas, 2024). A breach is a *flag for human
# review*, not an automated model change: deciding care by a protected
# attribute (e.g. a per-group threshold) could be direct discrimination under
# the Equality Act 2010, so mitigation here is governance, not group cutoffs.
FAIRNESS_TOLERANCE = 0.10


class BiasMonitor:
    def __init__(self, model_dir="models"):
        calibrated_model_path = os.path.join(model_dir, "model_calibrated.joblib")
        base_model_path = os.path.join(model_dir, "model.joblib")
        if os.path.exists(calibrated_model_path):
            self.model = joblib.load(calibrated_model_path)
            self.model_source = "calibrated"
        else:
            self.model = joblib.load(base_model_path)
            self.model_source = "base"
        self.scaler = joblib.load(f"{model_dir}/scaler.joblib")
        # Audit at the same operating point the app actually deploys: the
        # calibrated model uses its own re-derived threshold, not the base
        # model's threshold (which is tuned on a different probability scale).
        self.threshold = self._load_threshold(model_dir)
        self.test_data = pd.read_csv(f"{model_dir}/test_data.csv")

    def _load_threshold(self, model_dir):
        if self.model_source == "calibrated":
            cal_path = os.path.join(model_dir, "threshold_calibrated.joblib")
            if os.path.exists(cal_path):
                return float(joblib.load(cal_path))
        try:
            return float(joblib.load(os.path.join(model_dir, "threshold.joblib")))
        except FileNotFoundError:
            return 0.66

    def run_audit(self):
        df = self.test_data.copy(deep=True).reset_index(drop=True)
        X = df[FEATURE_NAMES].values
        y_true = df["NoShow"].values
        X_scaled = self.scaler.transform(X)
        y_prob = self.model.predict_proba(X_scaled)[:, 1]
        y_pred = (y_prob >= self.threshold).astype(int)

        df.loc[:, "y_pred"] = y_pred
        df.loc[:, "AgeGroup"] = df["Age"].apply(derive_age_group)
        self.test_data = df

        results = {
            "age_group": self._audit_group("AgeGroup", y_true, y_pred),
            "gender": self._audit_group("Gender", y_true, y_pred, {0: "Female", 1: "Male"}),
            "imd_band": self._audit_imd(y_true, y_pred),
            "overall_metrics": self._overall_metrics(y_true, y_pred),
            "model_source": self.model_source,
            "threshold": round(self.threshold, 4),
        }
        results["governance"] = self._governance_summary(results)
        return results

    def _governance_summary(self, results):
        """Aggregate per-attribute fairness checks into one governance verdict.

        Monitoring only — flags breaches for human oversight. Does NOT alter the
        model or apply protected-attribute thresholds (Equality Act risk).
        """
        attributes = {
            "age_group": "Age group",
            "gender": "Gender",
            "imd_band": "Deprivation (IMD)",
        }
        breaches = []
        for key, label in attributes.items():
            block = results.get(key, {})
            dp = block.get("demographic_parity_diff")
            eo = block.get("equalised_odds_diff")
            if dp is not None and dp > FAIRNESS_TOLERANCE:
                breaches.append(
                    {
                        "attribute": label,
                        "metric": "demographic_parity",
                        "value": round(dp, 4),
                        "tolerance": FAIRNESS_TOLERANCE,
                        "excess": round(dp - FAIRNESS_TOLERANCE, 4),
                    }
                )
            if eo is not None and eo > FAIRNESS_TOLERANCE:
                breaches.append(
                    {
                        "attribute": label,
                        "metric": "equalised_odds",
                        "value": round(eo, 4),
                        "tolerance": FAIRNESS_TOLERANCE,
                        "excess": round(eo - FAIRNESS_TOLERANCE, 4),
                    }
                )

        verdict = "PASS" if not breaches else "ACTION_REQUIRED"
        if breaches:
            flagged = sorted({b["attribute"] for b in breaches})
            recommended_actions = [
                f"Manually review intervention allocation for: {', '.join(flagged)}.",
                "Apply human oversight before acting on model scores for the flagged group(s).",
                "Record the breach and rationale in the governance log; consider model retraining "
                "with reweighing if the disparity persists across audits.",
                "Do NOT set a per-group decision threshold on a protected attribute "
                "(potential direct discrimination under the Equality Act 2010).",
            ]
        else:
            recommended_actions = [
                f"All demographic disparities within the {FAIRNESS_TOLERANCE:.0%} tolerance. "
                "Continue routine monitoring."
            ]

        return {
            "verdict": verdict,
            "tolerance": FAIRNESS_TOLERANCE,
            "breach_count": len(breaches),
            "breaches": breaches,
            "recommended_actions": recommended_actions,
        }

    def _audit_group(self, column, y_true, y_pred, label_map=None):
        groups = self.test_data[column].unique()
        group_metrics = {}

        for g in sorted(groups, key=str):
            mask = self.test_data[column] == g
            gt = y_true[mask]
            gp = y_pred[mask]
            if len(gt) == 0:
                continue

            label = label_map[g] if label_map and g in label_map else str(g)
            ppr = float(gp.mean()) if len(gp) > 0 else 0
            tpr = float(gp[gt == 1].mean()) if (gt == 1).sum() > 0 else 0
            fpr = float(gp[gt == 0].mean()) if (gt == 0).sum() > 0 else 0

            group_metrics[label] = {
                "count": int(mask.sum()),
                "positive_prediction_rate": round(ppr, 4),
                "true_positive_rate": round(tpr, 4),
                "false_positive_rate": round(fpr, 4),
            }

        dp_diff = self._demographic_parity_diff(group_metrics)
        eo_diff = self._equalised_odds_diff(group_metrics)

        return {
            "groups": group_metrics,
            "demographic_parity_diff": round(dp_diff, 4),
            "equalised_odds_diff": round(eo_diff, 4),
            "dp_status": "Pass" if dp_diff <= 0.10 else "Fail",
            "eo_status": "Pass" if eo_diff <= 0.10 else "Fail",
        }

    def _audit_imd(self, y_true, y_pred):
        self.test_data.loc[:, "IMDBand"] = pd.cut(
            self.test_data["IMDDecile"],
            bins=[0, 3, 7, 10],
            labels=["Most Deprived (1-3)", "Middle (4-7)", "Least Deprived (8-10)"],
        )
        return self._audit_group("IMDBand", y_true, y_pred)

    @staticmethod
    def _demographic_parity_diff(group_metrics):
        rates = [m["positive_prediction_rate"] for m in group_metrics.values()]
        return max(rates) - min(rates) if rates else 0

    @staticmethod
    def _equalised_odds_diff(group_metrics):
        tprs = [m["true_positive_rate"] for m in group_metrics.values()]
        fprs = [m["false_positive_rate"] for m in group_metrics.values()]
        tpr_diff = (max(tprs) - min(tprs)) if tprs else 0
        fpr_diff = (max(fprs) - min(fprs)) if fprs else 0
        return max(tpr_diff, fpr_diff)

    @staticmethod
    def _overall_metrics(y_true, y_pred):
        tp = int(((y_pred == 1) & (y_true == 1)).sum())
        tn = int(((y_pred == 0) & (y_true == 0)).sum())
        fp = int(((y_pred == 1) & (y_true == 0)).sum())
        fn = int(((y_pred == 0) & (y_true == 1)).sum())
        precision = tp / (tp + fp) if (tp + fp) > 0 else 0
        recall = tp / (tp + fn) if (tp + fn) > 0 else 0
        f1 = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0
        return {
            "precision": round(precision, 4),
            "recall": round(recall, 4),
            "f1_score": round(f1, 4),
            "confusion_matrix": {"tp": tp, "tn": tn, "fp": fp, "fn": fn},
            "total_samples": len(y_true),
        }
