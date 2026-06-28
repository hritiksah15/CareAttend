# CareAttend Flutter App

Cross-platform Flutter client for CareAttend. It shares the Flask backend with
the web client and implements the clinical workflow in a mobile/tablet-friendly
surface: assessment, results, dashboard, clinic list, batch scoring, bias,
ethics, slot optimisation, patient nudges, admin controls, profile, offline
state, notifications, i18n, and export.

## Run

```bash
flutter pub get
flutter run
```

Use a local backend on `http://127.0.0.1:5000` for web/desktop/iOS simulator, or
`http://10.0.2.2:5000` for Android emulator. Override with:

```bash
flutter run --dart-define=API_BASE=http://127.0.0.1:5000
```

## Verify

```bash
flutter analyze
flutter test
flutter build web
```

Current evidence: `flutter analyze` clean, 28 Flutter tests passing, and
`flutter build web` succeeds.
