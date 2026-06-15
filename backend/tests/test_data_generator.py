"""Tests for the data generation module (FR-01, R01, R08)."""

import pytest
import numpy as np
from ml.data_generator import (
    generate_synthetic_dataset,
    generate_ctgan_uk_supplement,
    derive_age_group,
    FEATURE_NAMES,
    PLAIN_ENGLISH_NAMES,
)


class TestSyntheticDataset:
    def test_correct_size(self):
        df = generate_synthetic_dataset(n_samples=500)
        assert len(df) == 500

    def test_columns_present(self):
        df = generate_synthetic_dataset(n_samples=100)
        for col in FEATURE_NAMES + ["NoShow"]:
            assert col in df.columns

    def test_age_range(self):
        df = generate_synthetic_dataset(n_samples=1000)
        assert df["Age"].min() >= 0
        assert df["Age"].max() <= 105

    def test_imd_range(self):
        df = generate_synthetic_dataset(n_samples=1000)
        assert df["IMDDecile"].min() >= 1
        assert df["IMDDecile"].max() <= 10

    def test_binary_columns(self):
        df = generate_synthetic_dataset(n_samples=1000)
        for col in ["Gender", "SMSReceived", "Hypertension", "Diabetes",
                     "Alcoholism", "Disability", "NoShow"]:
            assert set(df[col].unique()).issubset({0, 1})

    def test_dna_rate_reasonable(self):
        df = generate_synthetic_dataset(n_samples=5000)
        rate = df["NoShow"].mean()
        assert 0.10 <= rate <= 0.50

    def test_reproducibility(self):
        df1 = generate_synthetic_dataset(n_samples=100, random_state=42)
        df2 = generate_synthetic_dataset(n_samples=100, random_state=42)
        assert df1.equals(df2)


class TestCTGANSupplement:
    def test_correct_size(self):
        df = generate_ctgan_uk_supplement(n_samples=200)
        assert len(df) == 200

    def test_columns_match_base(self):
        df = generate_ctgan_uk_supplement(n_samples=100)
        for col in FEATURE_NAMES + ["NoShow"]:
            assert col in df.columns

    def test_elderly_heavy(self):
        # rural_elderly is the elderly-skewed trust profile (elderly_pct=0.55);
        # the default urban_deprived profile is intentionally younger.
        df = generate_ctgan_uk_supplement(n_samples=1000, trust_profile="rural_elderly")
        elderly_pct = (df["Age"] >= 65).mean()
        assert elderly_pct > 0.35

    def test_higher_dna_rate(self):
        df = generate_ctgan_uk_supplement(n_samples=2000)
        rate = df["NoShow"].mean()
        assert rate > 0.25


class TestAgeGroup:
    @pytest.mark.parametrize("age,expected", [
        (5, "Under 18"),
        (17, "Under 18"),
        (18, "18-64"),
        (64, "18-64"),
        (65, "65-74"),
        (74, "65-74"),
        (75, "75-84"),
        (84, "75-84"),
        (85, "85+"),
        (100, "85+"),
    ])
    def test_age_group_boundaries(self, age, expected):
        assert derive_age_group(age) == expected


class TestFeatureNames:
    def test_all_features_have_labels(self):
        for f in FEATURE_NAMES:
            assert f in PLAIN_ENGLISH_NAMES

    def test_feature_count(self):
        assert len(FEATURE_NAMES) == 10
