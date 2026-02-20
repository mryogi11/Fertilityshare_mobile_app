# Build Stability & Dependency Reference

This document serves as a reference for the specific, working configuration of the Fertilityshare project. Due to the use of cutting-edge and custom-modified Flutter SDK components, the project requires a very specific toolchain to build successfully.

## Successful Build Configuration (As of Feb 2025)

| Component | Version | File Location |
| :--- | :--- | :--- |
| **Android Gradle Plugin (AGP)** | `9.0.1` | `android/settings.gradle` |
| **Gradle Wrapper** | `9.2.1` | `android/gradle/wrapper/gradle-wrapper.properties` |
| **Kotlin (Android)** | `2.1.0` | `android/settings.gradle` |
| **Compile SDK** | `36` | `android/app/build.gradle` |
| **Target SDK** | `35` | `android/app/build.gradle` |
| **Min SDK** | `24` | `android/app/build.gradle` |

## Critical Dependencies (pubspec.yaml)

To prevent Dart compilation errors and ensure compatibility with AGP 9.0.1, use these exact or higher versions:

*   `flutter_local_notifications`: `^20.1.0` (Critical for correct API resolution)
*   `webview_flutter_android`: `^4.10.11` (Provides modern Android WebView features)
*   `quick_actions`: `^1.0.10`
*   `connectivity_plus`: `^6.1.1`
*   `in_app_review`: `^2.0.9`
*   `firebase_core`: `^4.4.0`
*   `firebase_messaging`: `^16.1.1`

## Important Troubleshooting Notes

### 1. Manual Flutter SDK Modifications
The project currently relies on a Flutter SDK that has been manually modified (specifically in `flutter_tools/gradle/...`). **Do not revert or update the Flutter SDK** without verifying compatibility with the AGP 9.0.1/Gradle 9.2.1 toolchain.

### 2. "Too many positional arguments" Error
If you see errors in `lib/main.dart` regarding `flutterLocalNotificationsPlugin.initialize` or `flutterLocalNotificationsPlugin.show` having "0 arguments allowed", it is a definitive symptom of a **Gradle version mismatch** or a **corrupted build cache**.
*   **Fix:** Ensure `android/settings.gradle` is using AGP `9.0.1` and `gradle-wrapper.properties` is using `9.2.1`.
*   **Command:** Run `flutter clean` and `flutter pub get`.

### 3. Avoid Downgrading
Attempting to downgrade to "stable" versions (e.g., AGP 8.x or Gradle 8.x) will break the project because the current code and the modified SDK components are specifically tuned for the AGP 9.x/Gradle 9.x preview environment.

### 4. Plugin Registration
If new plugins do not work as expected on Android, ensure that `MainActivity.kt` includes the `configureFlutterEngine` override with `GeneratedPluginRegistrant.registerWith(flutterEngine)`.

---
**Note:** Always check `git status` before committing to ensure no unintended version changes (like an accidental downgrade to AGP 8.7.3) have been applied to the Android build files.
