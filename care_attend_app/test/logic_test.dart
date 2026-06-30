import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:care_attend_app/utils/validators.dart';
import 'package:care_attend_app/nhs_theme.dart';
import 'package:care_attend_app/theme/design_tokens.dart';
import 'package:care_attend_app/utils/export.dart';
import 'package:care_attend_app/services/api_service.dart';

/// Pure-logic unit tests — no widgets, no network. Deterministic and fast.
void main() {
  group('passwordError (mirrors backend validate_password)', () {
    test('rejects too short', () {
      expect(passwordError('Ab1!'), isNotNull);
    });
    test('needs an uppercase letter', () {
      expect(passwordError('abcdefg1!'), 'Password needs an uppercase letter');
    });
    test('needs a lowercase letter', () {
      expect(passwordError('ABCDEFG1!'), 'Password needs a lowercase letter');
    });
    test('needs a number', () {
      expect(passwordError('Abcdefg!'), 'Password needs a number');
    });
    test('needs a symbol', () {
      expect(passwordError('Abcdefg1'), 'Password needs a symbol');
    });
    test('accepts a strong password', () {
      expect(passwordError('Abcdef1!'), isNull);
    });
  });

  group('NHSTheme.ageGroup buckets', () {
    test('boundaries', () {
      expect(NHSTheme.ageGroup(10), 'Under 18');
      expect(NHSTheme.ageGroup(17), 'Under 18');
      expect(NHSTheme.ageGroup(18), '18-64');
      expect(NHSTheme.ageGroup(64), '18-64');
      expect(NHSTheme.ageGroup(65), '65-74');
      expect(NHSTheme.ageGroup(74), '65-74');
      expect(NHSTheme.ageGroup(75), '75-84');
      expect(NHSTheme.ageGroup(84), '75-84');
      expect(NHSTheme.ageGroup(85), '85+');
      expect(NHSTheme.ageGroup(120), '85+');
    });
  });

  group('AppColors.riskColor tier mapping', () {
    test('maps each tier', () {
      expect(AppColors.riskColor('High'), AppColors.riskHigh);
      expect(AppColors.riskColor('Medium'), AppColors.riskMedium);
      expect(AppColors.riskColor('Low'), AppColors.riskLow);
    });
    test('is case-insensitive', () {
      expect(AppColors.riskColor('high'), AppColors.riskColor('High'));
    });
    test('falls back to Low for unknown tier', () {
      expect(AppColors.riskColor('???'), AppColors.riskLow);
    });
  });

  test('Batch CSV columns include required fields followed by optional flags',
      () {
    expect(Exporter.batchCsvColumns, [
      'Age',
      'Gender',
      'AppointmentLeadTimeDays',
      'SMSReceived',
      'PriorDNACount',
      'IMDDecile',
      'Hypertension',
      'Diabetes',
      'Alcoholism',
      'Disability',
    ]);
  });

  test('default API base URL is deployable and normalized', () {
    expect(ApiService.baseUrl, isNotEmpty);
    expect(ApiService.baseUrl.endsWith('/'), isFalse);
    expect(Uri.parse(ApiService.baseUrl).hasScheme, isTrue);
    if (!kIsWeb) {
      expect(ApiService.baseUrl, 'https://careattend-api.onrender.com');
    }
  });

  test('risk history keeps only the last five assessments', () {
    addTearDown(() => ApiService.riskHistory.clear());
    ApiService.riskHistory.clear();

    for (var i = 1; i <= 7; i++) {
      ApiService.recordRiskHistory({
        'percentage': i * 10,
        'risk_tier': i.isEven ? 'Low' : 'High',
      });
    }

    expect(ApiService.riskHistory.length, ApiService.riskHistoryLimit);
    expect(ApiService.riskHistory.first['percentage'], 30);
    expect(ApiService.riskHistory.last['percentage'], 70);
  });
}
