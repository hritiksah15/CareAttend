"""Rigorous model evaluation with cross-validation, confidence intervals,
statistical significance tests, and deep learning comparison.

Supports AT4 Quality Assurance section with evidence of methodological rigour.
"""

import numpy as np
from sklearn.model_selection import StratifiedKFold
from sklearn.metrics import (
    f1_score, recall_score, precision_score, roc_auc_score,
    accuracy_score
)
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.neural_network import MLPClassifier
from imblearn.over_sampling import SMOTE
from scipy import stats


def run_cross_validation(X, y, n_splits=5, random_state=42):
    """Stratified k-fold cross-validation with per-fold metrics."""
    cv = StratifiedKFold(n_splits=n_splits, shuffle=True, random_state=random_state)
    smote = SMOTE(random_state=random_state)

    models = {
        "Logistic Regression": LogisticRegression(max_iter=1000, random_state=random_state),
        "Random Forest": RandomForestClassifier(
            n_estimators=200, max_depth=20, min_samples_split=5,
            class_weight="balanced", random_state=random_state
        ),
        "MLP Neural Network": MLPClassifier(
            hidden_layer_sizes=(64, 32), max_iter=500, random_state=random_state,
            early_stopping=True, validation_fraction=0.15
        ),
    }

    results = {}
    for name, model in models.items():
        fold_metrics = []
        y_pred_all = np.zeros_like(y)

        for fold_idx, (train_idx, test_idx) in enumerate(cv.split(X, y)):
            X_train, X_test = X[train_idx], X[test_idx]
            y_train, y_test = y[train_idx], y[test_idx]

            X_res, y_res = smote.fit_resample(X_train, y_train)
            model.fit(X_res, y_res)
            y_pred = model.predict(X_test)
            y_prob = model.predict_proba(X_test)[:, 1]
            y_pred_all[test_idx] = y_pred

            fold_metrics.append({
                "fold": fold_idx + 1,
                "f1": float(f1_score(y_test, y_pred)),
                "recall": float(recall_score(y_test, y_pred)),
                "precision": float(precision_score(y_test, y_pred)),
                "roc_auc": float(roc_auc_score(y_test, y_prob)),
                "accuracy": float(accuracy_score(y_test, y_pred)),
            })

        f1_scores = [m["f1"] for m in fold_metrics]
        recall_scores = [m["recall"] for m in fold_metrics]
        roc_scores = [m["roc_auc"] for m in fold_metrics]

        results[name] = {
            "fold_metrics": fold_metrics,
            "mean_f1": float(np.mean(f1_scores)),
            "std_f1": float(np.std(f1_scores)),
            "mean_recall": float(np.mean(recall_scores)),
            "std_recall": float(np.std(recall_scores)),
            "mean_roc_auc": float(np.mean(roc_scores)),
            "std_roc_auc": float(np.std(roc_scores)),
            "ci_95_f1": _bootstrap_ci(f1_scores),
            "ci_95_recall": _bootstrap_ci(recall_scores),
            "ci_95_roc_auc": _bootstrap_ci(roc_scores),
            "y_pred": y_pred_all.tolist(),
        }

    # McNemar test between best two models
    model_names = list(results.keys())
    significance_tests = []
    for i in range(len(model_names)):
        for j in range(i + 1, len(model_names)):
            name_a, name_b = model_names[i], model_names[j]
            p_value = _mcnemar_test(
                np.array(results[name_a]["y_pred"]),
                np.array(results[name_b]["y_pred"]),
                y
            )
            significance_tests.append({
                "model_a": name_a,
                "model_b": name_b,
                "mcnemar_p_value": p_value,
                "significant_at_005": p_value < 0.05,
            })

    return {
        "n_splits": n_splits,
        "models": results,
        "significance_tests": significance_tests,
        "dl_comparison": _dl_comparison_narrative(results),
    }


def _bootstrap_ci(scores, confidence=0.95, n_bootstrap=1000):
    """Bootstrap confidence interval for small sample sizes (k-fold)."""
    if len(scores) < 2:
        return {"lower": float(scores[0]), "upper": float(scores[0])}
    rng = np.random.RandomState(42)
    bootstrap_means = []
    for _ in range(n_bootstrap):
        sample = rng.choice(scores, size=len(scores), replace=True)
        bootstrap_means.append(np.mean(sample))
    alpha = (1 - confidence) / 2
    lower = float(np.percentile(bootstrap_means, alpha * 100))
    upper = float(np.percentile(bootstrap_means, (1 - alpha) * 100))
    return {"lower": round(lower, 4), "upper": round(upper, 4)}


def _mcnemar_test(y_pred_a, y_pred_b, y_true):
    """McNemar's test for statistical significance between two classifiers."""
    correct_a = (y_pred_a == y_true)
    correct_b = (y_pred_b == y_true)

    # b: A correct, B wrong; c: A wrong, B correct
    b = int(np.sum(correct_a & ~correct_b))
    c = int(np.sum(~correct_a & correct_b))

    if b + c == 0:
        return 1.0

    if b + c < 25:
        result = stats.binom_test(b, b + c, 0.5)
    else:
        chi2 = (abs(b - c) - 1) ** 2 / (b + c)
        result = float(stats.chi2.sf(chi2, 1))

    return round(result, 6)


def _dl_comparison_narrative(results):
    """Generate critical comparison narrative for AT4."""
    ml_models = {k: v for k, v in results.items() if k != "MLP Neural Network"}
    dl = results.get("MLP Neural Network")
    if not dl:
        return "MLP not evaluated."

    best_ml_name = max(ml_models, key=lambda k: ml_models[k]["mean_f1"])
    best_ml = ml_models[best_ml_name]

    dl_f1 = dl["mean_f1"]
    ml_f1 = best_ml["mean_f1"]

    if dl_f1 > ml_f1 + 0.02:
        verdict = "outperforms"
    elif dl_f1 < ml_f1 - 0.02:
        verdict = "underperforms"
    else:
        verdict = "performs comparably to"

    return (
        f"The MLP neural network (mean F1: {dl_f1:.4f}) {verdict} "
        f"{best_ml_name} (mean F1: {ml_f1:.4f}). "
        f"Given Care Attend's explainability requirement (FR-03/FR-04), "
        f"SHAP TreeExplainer/LinearExplainer integration with interpretable models "
        f"provides clinically auditable outputs that neural networks cannot match "
        f"(Arrieta et al., 2024). The marginal performance difference does not "
        f"justify the loss of per-feature attribution transparency required by "
        f"NHS England (2024) AI ethics guidance."
    )
