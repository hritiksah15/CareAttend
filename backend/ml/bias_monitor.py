import pandas as pd
import joblib

from ml.data_generator import FEATURE_NAMES, derive_age_group


class BiasMonitor:
    def __init__(self, model_dir="models"):
        self.model = joblib.load(f"{model_dir}/model.joblib")
        self.scaler = joblib.load(f"{model_dir}/scaler.joblib")
        self.test_data = pd.read_csv(f"{model_dir}/test_data.csv")

    def run_audit(self):
        df = self.test_data.copy()
        X = df[FEATURE_NAMES].values
        y_true = df["NoShow"].values
        X_scaled = self.scaler.transform(X)
        y_pred = self.model.predict(X_scaled)

        df["y_pred"] = y_pred
        df["AgeGroup"] = df["Age"].apply(derive_age_group)
        self.test_data = df

        results = {
            "age_group": self._audit_group("AgeGroup", y_true, y_pred),
            "gender": self._audit_group("Gender", y_true, y_pred, {0: "Female", 1: "Male"}),
            "imd_band": self._audit_imd(y_true, y_pred),
            "overall_metrics": self._overall_metrics(y_true, y_pred),
        }
        return results

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
        self.test_data["IMDBand"] = pd.cut(
            self.test_data["IMDDecile"],
            bins=[0, 3, 7, 10],
            labels=["Most Deprived (1-3)", "Middle (4-7)", "Least Deprived (8-10)"]
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
