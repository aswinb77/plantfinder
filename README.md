# Plant Analyzer

Plant Analyzer is a Flutter app for identifying plants using the camera and a Firebase-backed plant catalog. It combines live camera scanning, Google ML Kit image labeling, and Firestore data retrieval to deliver plant details and pricing.

## Key Features

- Live plant scanning using camera input
- Plant identification via ML model and image labeling
- Firestore-powered plant catalog and search
- Admin panel for adding and editing plant records
- Dynamic size-based pricing calculation
- Cross-platform Flutter support for Android, iOS, web, desktop

## Project Structure

- `lib/main.dart` — app entrypoint and Firebase initialization
- `lib/screens/home_screen.dart` — search UI and plant catalog display
- `lib/screens/plant_scanner_screen.dart` — camera scanning and result sheet
- `lib/services/ml_service.dart` — image label extraction and similarity matching
- `lib/services/database_service.dart` — Firestore queries and plant storage
- `lib/models/plant_model.dart` — plant data model and price logic

## Setup

1. Install Flutter and required platform tooling.
2. Run `flutter pub get`.
3. Configure Firebase for your platforms:
   - `flutterfire configure` to generate `firebase_options.dart`
   - Add Firebase configuration files for Android and iOS
4. Ensure Firestore has a `plants` collection with plant records.

## Run

```bash
flutter pub get
flutter run
```

## Notes

- The app uses `camera`, `cloud_firestore`, `firebase_core`, `google_mlkit_image_labeling`, and `tflite_flutter`.
- `firebase_options.dart` is expected to be generated and configured separately.
- The scanner currently identifies plants by comparing image labels against stored plant signatures.

## Dependencies

- Flutter SDK `^3.11.1`
- `camera`
- `cloud_firestore`
- `firebase_core`
- `google_mlkit_image_labeling`
- `tflite_flutter`

## License

This repository does not include a license file. Add one if needed for distribution.
