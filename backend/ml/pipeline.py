import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split, GridSearchCV, StratifiedKFold
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    classification_report, confusion_matrix, f1_score,
    recall_score, precision_score, roc_auc_score, accuracy_score
)
from imblearn.over_sampling import SMOTE
import joblib
import os

try:
    from xgboost import XGBClassifier
    HAS_XGBOOST = True
except ImportError:
    HAS_XGBOOST = False

try:
    from lightgbm import LGBMClassifier
    HAS_LIGHTGBM = True
except ImportError:
    HAS_LIGHTGBM = False

from ml.data_generator import (
    generate_synthetic_dataset, generate_ctgan_uk_supplement, FEATURE_NAMES
)


def train_and_evaluate(save_dir="models"):
    os.makedirs(save_dir, exist_ok=True)

    print("Generating synthetic dataset...")
    df_base = generate_synthetic_dataset(n_samples=12000)
    print(f"Base dataset: {len(df_base)} records, DNA rate: {df_base['NoShow'].mean():.2%}")

    print("Generating CTGAN UK demographic supplement...")
    df_ctgan = generate_ctgan_uk_supplement(n_samples=3000)
    print(f"CTGAN supplement: {len(df_ctgan)} records, DNA rate: {df_ctgan['NoShow'].mean():.2%}")

    df = pd.concat([df_base, df_ctgan], ignore_index=True)
    df.to_csv("data/synthetic_dataset.csv", index=False)
    print(f"Combined dataset: {len(df)} records, DNA rate: {df['NoShow'].mean():.2%}")

    X = df[FEATURE_NAMES].values
    y = df["NoShow"].values

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    print(f"Train: {len(X_train)}, Test: {len(X_test)}")

    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)

    smote = SMOTE(random_state=42)
    X_train_res, y_train_res = smote.fit_resample(X_train_scaled, y_train)
    print(f"After SMOTE: {len(X_train_res)} (balanced)")

    all_metrics = {}

    # ── 1. Logistic Regression ──
    print("\n--- Logistic Regression ---")
    lr = LogisticRegression(max_iter=1000, random_state=42)
    lr.fit(X_train_res, y_train_res)
    all_metrics["Logistic Regression"] = _evaluate(lr, X_test_scaled, y_test, "Logistic Regression")
    joblib.dump(lr, os.path.join(save_dir, "lr_pipeline.joblib"))

    # ── 2. Random Forest ──
    print("\n--- Random Forest ---")
    rf_grid = {
        "n_estimators": [100, 200],
        "max_depth": [10, 15, 20],
        "min_samples_split": [5, 10],
        "class_weight": ["balanced", None],
    }
    rf_base = RandomForestClassifier(random_state=42)
    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
    rf_search = GridSearchCV(rf_base, rf_grid, cv=cv, scoring="f1", n_jobs=1, verbose=0)
    rf_search.fit(X_train_res, y_train_res)
    rf = rf_search.best_estimator_
    print(f"Best RF params: {rf_search.best_params_}")
    all_metrics["Random Forest"] = _evaluate(rf, X_test_scaled, y_test, "Random Forest")
    joblib.dump(rf, os.path.join(save_dir, "rf_pipeline.joblib"))

    # ── 3. XGBoost ──
    if HAS_XGBOOST:
        print("\n--- XGBoost ---")
        xgb = XGBClassifier(
            n_estimators=200, max_depth=8, learning_rate=0.1,
            subsample=0.8, colsample_bytree=0.8,
            scale_pos_weight=(y_train_res == 0).sum() / max((y_train_res == 1).sum(), 1),
            random_state=42, eval_metric="logloss", verbosity=0,
        )
        xgb.fit(X_train_res, y_train_res)
        all_metrics["XGBoost"] = _evaluate(xgb, X_test_scaled, y_test, "XGBoost")
        joblib.dump(xgb, os.path.join(save_dir, "xgb_pipeline.joblib"))
    else:
        print("\nXGBoost not installed, skipping.")

    # ── 4. LightGBM ──
    if HAS_LIGHTGBM:
        print("\n--- LightGBM ---")
        lgbm = LGBMClassifier(
            n_estimators=200, max_depth=8, learning_rate=0.1,
            subsample=0.8, colsample_bytree=0.8,
            is_unbalance=True, random_state=42, verbose=-1,
        )
        lgbm.fit(X_train_res, y_train_res)
        all_metrics["LightGBM"] = _evaluate(lgbm, X_test_scaled, y_test, "LightGBM")
        joblib.dump(lgbm, os.path.join(save_dir, "lgbm_pipeline.joblib"))
    else:
        print("\nLightGBM not installed, skipping.")

    # ── Select best model by F1 ──
    best_name = max(all_metrics, key=lambda k: all_metrics[k]["f1"])
    models = {
        "Logistic Regression": lr,
        "Random Forest": rf,
    }
    if HAS_XGBOOST:
        models["XGBoost"] = xgb
    if HAS_LIGHTGBM:
        models["LightGBM"] = lgbm
    best_model = models[best_name]

    # ── Threshold optimisation ──
    print(f"\n--- Optimising decision threshold for {best_name} ---")
    best_threshold, threshold_metrics = _optimise_threshold(
        best_model, X_test_scaled, y_test
    )
    print(f"Optimal threshold: {best_threshold:.2f}")
    print(f"F1: {threshold_metrics['f1']:.4f} | Recall: {threshold_metrics['recall']:.4f} | "
          f"Precision: {threshold_metrics['precision']:.4f} | ROC-AUC: {threshold_metrics['roc_auc']:.4f}")

    print(f"\n=== Selected Model: {best_name} (threshold={best_threshold:.2f}) ===")

    # ── Save selected model as primary ──
    joblib.dump(best_model, os.path.join(save_dir, "model.joblib"))
    joblib.dump(scaler, os.path.join(save_dir, "scaler.joblib"))
    joblib.dump(best_threshold, os.path.join(save_dir, "threshold.joblib"))

    test_data = pd.DataFrame(X_test, columns=FEATURE_NAMES)
    test_data["NoShow"] = y_test
    test_data.to_csv(os.path.join(save_dir, "test_data.csv"), index=False)

    np.save(os.path.join(save_dir, "X_train_sample.npy"),
            X_train_scaled[:200])

    # ── Print comparison table ──
    print("\n" + "=" * 70)
    print(f"{'Model':<25} {'F1':>8} {'Recall':>8} {'Precision':>8} {'ROC-AUC':>8} {'Acc':>8}")
    print("-" * 70)
    for name, m in all_metrics.items():
        marker = " ***" if name == best_name else ""
        print(f"{name:<25} {m['f1']:>8.4f} {m['recall']:>8.4f} {m['precision']:>8.4f} "
              f"{m['roc_auc']:>8.4f} {m['accuracy']:>8.4f}{marker}")
    print("=" * 70)

    results = {
        "selected_model": best_name,
        "all_metrics": {k: _serialise_metrics(v) for k, v in all_metrics.items()},
        "lr_metrics": _serialise_metrics(all_metrics.get("Logistic Regression", {})),
        "rf_metrics": _serialise_metrics(all_metrics.get("Random Forest", {})),
        "xgb_metrics": _serialise_metrics(all_metrics.get("XGBoost", {})) if "XGBoost" in all_metrics else None,
        "lgbm_metrics": _serialise_metrics(all_metrics.get("LightGBM", {})) if "LightGBM" in all_metrics else None,
        "best_metrics": threshold_metrics,
        "train_size": len(X_train),
        "test_size": len(X_test),
        "dna_rate": float(df["NoShow"].mean()),
        "threshold": float(best_threshold),
        "models_trained": list(all_metrics.keys()),
    }
    return results


def _evaluate(model, X_test, y_test, name):
    y_pred = model.predict(X_test)
    y_prob = model.predict_proba(X_test)[:, 1]

    f1 = f1_score(y_test, y_pred)
    recall = recall_score(y_test, y_pred)
    precision = precision_score(y_test, y_pred)
    roc_auc = roc_auc_score(y_test, y_prob)
    acc = accuracy_score(y_test, y_pred)
    cm = confusion_matrix(y_test, y_pred)

    print(f"F1: {f1:.4f} | Recall: {recall:.4f} | Precision: {precision:.4f} | "
          f"ROC-AUC: {roc_auc:.4f} | Acc: {acc:.4f}")
    print(f"Confusion Matrix:\n{cm}")
    print(classification_report(y_test, y_pred, target_names=["Attend", "DNA"]))

    return {
        "f1": f1, "recall": recall, "precision": precision,
        "roc_auc": roc_auc, "accuracy": acc,
        "confusion_matrix": cm.tolist(),
    }


def _serialise_metrics(m):
    if not m:
        return None
    return {k: (float(v) if isinstance(v, (np.floating, float)) else v) for k, v in m.items()}


def _optimise_threshold(model, X_test, y_test):
    y_prob = model.predict_proba(X_test)[:, 1]
    best_f1 = 0
    best_t = 0.5
    for t in np.arange(0.15, 0.65, 0.01):
        y_pred = (y_prob >= t).astype(int)
        f1 = f1_score(y_test, y_pred)
        if f1 > best_f1:
            best_f1 = f1
            best_t = t

    y_pred = (y_prob >= best_t).astype(int)
    return best_t, {
        "f1": float(f1_score(y_test, y_pred)),
        "recall": float(recall_score(y_test, y_pred)),
        "precision": float(precision_score(y_test, y_pred)),
        "roc_auc": float(roc_auc_score(y_test, y_prob)),
        "accuracy": float(accuracy_score(y_test, y_pred)),
        "confusion_matrix": confusion_matrix(y_test, y_pred).tolist(),
        "threshold": float(best_t),
    }
