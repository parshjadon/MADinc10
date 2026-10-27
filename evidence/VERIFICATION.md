# Verification record

Executed by the coding assistant on October 27, 2026.

- Flutter 3.47.2; Dart 3.13.2; Windows host.
- `flutter analyze`: No issues found.
- `flutter test --reporter expanded`: 8 tests passed.
- `flutter test tool/evidence_test.dart --update-goldens --reporter expanded`: 1 evidence-rendering test passed; eight PNGs generated.
- `flutter build apk --release`: succeeded; reported APK size 46.5 MB.
- Android build-tools 36.0.0 `apksigner verify --verbose`: Verifies; APK Signature Scheme v2 verified; one signer.
- `aapt dump badging`: package `edu.gsu.mad.signup_app`, version `1.0.0` (code 1), label `TrailMates`, minimum Android SDK 24, target SDK 36.
- Architectures: arm64-v8a, armeabi-v7a, x86_64.
- Permission listing contains only the generated package-specific `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`; no Internet permission.
- Signing: Flutter template's debug key applied to the release variant.

No Android device or configured emulator was available for an installation or airplane-mode run. PNGs are Flutter widget test renders, not device screenshots. No instructor authorship check was performed. The supplied publication destination is https://github.com/parshjadon/MADinc10.
