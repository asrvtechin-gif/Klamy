# Push notifications

Klamy registers an FCM token for the signed-in user under
`users/{uid}/fcmTokens`. The notification page listens to
`users/{uid}/notifications` in Realtime Database. A notification needs an FCM
notification payload with a title and body. Optional data fields:

```json
{
  "category": "Claims",
  "actionTab": "2"
}
```

`category` can be `Claims`, `Reminders`, or `System`. `actionTab` maps to the
Home, Documents, Claims, Actions, and Profile tabs (`0` through `4`). Send
messages from a trusted server using Firebase Admin SDK or use Firebase
Console for a manual device test. Do not send from the Flutter client with a
server key.

While Klamy is open, FCM messages are saved to Realtime Database and displayed
as local notifications. In the background, notification payloads are shown by
the operating system; tapping one opens Klamy's Notifications page and records
it there. Users grant notification permission from the bell button on that
page. Read state and dismiss/clear actions are synced to Realtime Database.

## Platform setup

- **Android:** The project creates the `klamy_claim_updates` channel and asks
  for Android 13+ notification permission. The FCM registration token is
  stored after sign-in.
- **iOS:** Enable **Push Notifications** and **Background Modes > Remote
  notifications** for the Runner target in Xcode, and upload an APNs
  authentication key in Firebase Console. The app plist already declares the
  remote notification background mode.
- **Web:** In Firebase Console, generate a Web Push certificate and run/build
  with `--dart-define=FIREBASE_MESSAGING_WEB_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY`.
  Web push requires HTTPS (localhost is allowed for development). The
  `web/firebase-messaging-sw.js` worker handles background display.

After changing Realtime Database rules, deploy them with
`firebase deploy --only database` if your Firebase project uses this repository's
`database.rules.json`.
