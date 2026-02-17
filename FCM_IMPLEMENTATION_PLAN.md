# Firebase Cloud Messaging (FCM) Implementation Plan

This document outlines the steps to implement FCM for **Manual Notifications (Scenario 1)** and **Serverless Notifications (Scenario 2)** in the Fertilityshare app.

## Phase 1: Client-Side Setup (COMPLETED ✅)

### 1. Add Dependencies
*   `firebase_core`, `firebase_messaging`, `firebase_analytics`, and `cloud_firestore` added to `pubspec.yaml`. (Done)

### 2. Android Configuration
*   `google-services.json` is in `android/app/`. (Done)
*   `google-services` plugin is applied in `android/settings.gradle` and `app/build.gradle`. (Done)
*   `compileSdk` and `targetSdk` set to 36 for plugin compatibility. (Done)

### 3. Flutter Initialization (`lib/main.dart`)
*   Firebase initialized in `main()`. (Done)
*   Background message handler (`_firebaseMessagingBackgroundHandler`) implemented. (Done)
*   User permissions request logic added. (Done)
*   Token retrieval and Firestore storage (`device_tokens` collection) implemented. (Done)

### 4. Notification Handling
*   Foreground SnackBar notifications added. (Done)
*   Background/Terminated tap handling implemented (refreshes WebView). (Done)
*   Fixed `logEvent` type mismatch error for `messageId`. (Done)

---

## Phase 2: Scenario 1 - Manual Notifications (READY FOR TESTING 🧪)

### 1. Verification Steps
1.  Run the app on a physical device or emulator with Google Play Services.
2.  Copy the **FCM Token** from the debug console (it is printed when the app starts).
3.  Go to **Firebase Console > Engage > Messaging**.
4.  Click **"Create your first campaign"** > **"Firebase Cloud Messaging messages"**.
5.  Enter a Title and Text.
6.  Click **"Send test message"**, paste your token, and click **"+"**.
7.  Verify delivery in:
    *   **Foreground**: App shows a SnackBar.
    *   **Background**: System notification appears; tapping it refreshes the WebView.

---

## Phase 3: Scenario 2 - Serverless (Cloud Functions) (ACTION REQUIRED ⚡)

### 1. Storage of Tokens (COMPLETED ✅)
*   The app automatically saves the FCM token to Firestore in the `device_tokens` collection when it starts.

### 2. Firebase Functions Setup
1.  Install Firebase CLI: `npm install -g firebase-tools`.
2.  Login: `firebase login`.
3.  Initialize Functions in the project root: `firebase init functions`.
    *   Select your project.
    *   Choose **JavaScript**.
    *   Choose **No** to "overwrite package.json" (if applicable).
4.  Copy the content of `functions_index_example.js` into the newly created `functions/index.js`.

### 3. Deployment
1.  Navigate to the functions folder: `cd functions`.
2.  Deploy: `firebase deploy --only functions`.

### 4. Automated Testing
1.  Once deployed, delete your token document from the `device_tokens` collection in Firestore.
2.  Restart the app.
3.  The app will recreate the document, which triggers the `sendWelcomeNotification` Cloud Function.
4.  You should receive a "Welcome to Fertilityshare!" notification automatically.
