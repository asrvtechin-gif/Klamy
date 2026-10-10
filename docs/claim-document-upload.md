# Direct Cloudinary document uploads

Claim details are entered manually in steps 1 and 2. All required fields must be filled before leaving a step; a policy document is required in step 3. The admission date must be within the policy start and end dates. Step 3 uploads PDF/JPG/JPEG/PNG files directly from the app to Cloudinary using an unsigned upload preset.

## Cloudinary setup (one time)

1. In Cloudinary Console, open **Settings → Upload → Upload presets** and create an upload preset named `klamy5` (exact lowercase spelling).
2. Set its signing mode to **Unsigned**.
3. Restrict allowed formats to `pdf,jpg,jpeg,png`; configure the asset access and folder defaults you want.
4. Copy the preset name. The app already has the supplied Cloud name; the preset name is public client configuration. The API Key and API Secret are not used for unsigned uploads and must never be put in the Flutter app.

Run the app with your values:

```powershell
flutter run --dart-define=CLOUDINARY_UPLOAD_PRESET=your-unsigned-preset
```

For a release build, provide the same `--dart-define` value to the Flutter build command. The app enforces a 10 MB per-file limit and sends each selected document to `https://api.cloudinary.com/v1_1/<cloud-name>/auto/upload`. Cloudinary returns `public_id` and `secure_url`; these are attached to the claim saved in RTDB.

Unsigned direct uploads require an unsigned preset and are intentionally limited by Cloudinary. Keep the preset restricted to the file types and settings needed by this app. Cloudinary's client-side upload guide: https://cloudinary.com/documentation/client_side_uploading

## Claim data

After each successful Cloudinary upload, its file name, category, `public_id`, and secure URL are immediately written to `users/<firebase-uid>/documents/<document-id>`. The Documents Vault listens to that path and shows the uploaded files live, including before the claim is submitted. On Submit Claim, policy and claim details plus the document references are written to `users/<firebase-uid>/claims/<claim-id>`, and each document record is linked to that claim. The app also creates a pending review action at `users/<firebase-uid>/actions/<action-id>`. Claims and actions screens subscribe to their user-scoped paths, so their lists and home counts update live.

Deploy the included user-scoped database rules before using the flow:

```powershell
firebase deploy --only database
```

The app uses the RTDB URL configured in `lib/firebase_options.dart`. Authenticated reads and writes are restricted to the matching user's UID by `database.rules.json`.

## Gemini claim assistant

Tapping the Recent Claim card opens the Klamy assistant. It summarizes the saved claim, suggests supporting documents, lets the user upload a suggested file directly to Cloudinary and link it to the claim, and provides a claim-specific chat. Suggested document categories are checked against the live Documents Vault records and shown as Uploaded or Missing. The assistant downloads linked Cloudinary PDFs and JPG/PNG images and attaches their bytes to Firebase AI Logic for review. Inline document data is capped at 12 MB per request; documents that cannot be downloaded or fit are called out as unavailable so the assistant does not claim to have read them. A newly uploaded claim document triggers a refreshed summary. Suggestions are guidance and should be confirmed with the insurer.

In Firebase Console, enable Firebase AI Logic and the Gemini Developer API for this Firebase project. The app calls Gemini through the official `firebase_ai` SDK; do not add a Gemini API key to Flutter. See the Firebase AI Logic Flutter setup: https://firebase.google.com/docs/ai-logic/get-started?platform=flutter

## Firebase App Check

The Flutter app activates App Check after Firebase initialization. Debug Android/iOS builds use the App Check debug provider; release builds use Play Integrity on Android and App Attest with Device Check fallback on Apple platforms. For debug builds, run the app, copy its App Check debug token from the device logs, and add it under Firebase Console > App Check > Apps > Manage debug tokens. Keep that token private and out of source control. Register the Android/iOS apps in App Check with their production providers before enabling enforcement. See https://firebase.google.com/docs/app-check/flutter/default-providers and https://firebase.google.com/docs/app-check/flutter/debug-provider.

For web, create/register a reCAPTCHA v3 App Check provider in Firebase Console, then run/build with its site key:

```powershell
flutter run --dart-define=FIREBASE_APPCHECK_WEB_SITE_KEY=your-recaptcha-v3-site-key
```


