#!/usr/bin/env python3
"""Train Care Attend ML models and save artifacts."""

import os
import json
from ml.pipeline import train_and_evaluate


def main():
    os.makedirs("data", exist_ok=True)
    os.makedirs("models", exist_ok=True)

    print("=" * 60)
    print("  Care Attend - Model Training Pipeline")
    print("=" * 60)

    results = train_and_evaluate(save_dir="models")

    with open("models/training_results.json", "w") as f:
        json.dump(results, f, indent=2)
        f.write("\n")

    print("\n" + "=" * 60)
    print("  Training Complete!")
    print("=" * 60)
    print(f"  Selected model: {results['selected_model']}")
    print(f"  F1-score:       {results['best_metrics']['f1']:.4f}")
    print(f"  Recall:         {results['best_metrics']['recall']:.4f}")
    print(f"  Precision:      {results['best_metrics']['precision']:.4f}")
    print(f"  ROC-AUC:        {results['best_metrics']['roc_auc']:.4f}")
    print("\n  Artifacts saved to models/")
    print("  Run 'python app.py' to start the web application.")
    print("=" * 60)


if __name__ == "__main__":
    main()
