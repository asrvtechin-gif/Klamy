# Klamy local Gemini server

This gateway sends claim questions to the laptop's Ollama instance using only `qwen3-vl:latest`. It verifies Firebase sign-in, reads the signed-in user's claim and vault records from Realtime Database, downloads only that user's Cloudinary documents, and never calls Gemini or another hosted model.

The Qwen tag installed on the development laptop is `qwen3-vl:latest` (8.8B parameters). Keep Ollama bound to its default loopback address. The public tunnel must point to this authenticated gateway on port 8000, never to Ollama's port 11434.

## One-time setup on Windows

1. Confirm Ollama and the model are installed:

   ```powershell
   ollama list
   ollama run qwen3-vl:latest "Reply with exactly: LOCAL_MODEL_READY"
   ```

2. In Firebase Console, create a Firebase Admin SDK service-account key for project `klamy-8789e`. Keep the JSON outside the repository, for example under `%USERPROFILE%\.klamy\admin-sdk.json`. This key has powerful Firebase access: do not share it, put it in the Flutter app, or commit it to Git.

3. Open PowerShell in this folder (`local_ai_server`) and install the Python packages:

   ```powershell
   py -3.14 -m venv .venv
   .\.venv\Scripts\Activate.ps1
   pip install -r requirements.txt
   ```

4. Set the server environment for this PowerShell window. Update the credential path to where the downloaded JSON was saved:

   ```powershell
   $env:FIREBASE_PROJECT_ID = "klamy-8789e"
   $env:FIREBASE_DATABASE_URL = "https://klamy-8789e-default-rtdb.firebaseio.com"
   $env:GOOGLE_APPLICATION_CREDENTIALS = "$env:USERPROFILE\.klamy\admin-sdk.json"
   ```

5. Start the gateway:

   Double-click or run `run_server.bat`, or in PowerShell run:
   ```powershell
   .\.venv\Scripts\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```

   Check `http://127.0.0.1:8000/health`; it should return `{"status":"ok","provider":"local_qwen"}`.

## Connecting from phone / web

### Option A: USB connected phone (Fastest & Most Stable - No Cloudflare Tunnel Needed!)
If your Android phone is connected via USB:
1. Run:
   ```powershell
   adb reverse tcp:8000 tcp:8000
   ```
   (`run_server.bat` automatically runs this for you!)
2. Simply launch the app:
   ```powershell
   flutter run
   ```
   (No `--dart-define` needed! The app defaults to `http://127.0.0.1:8000`).

### Option B: Cloudflare Tunnel (For remote devices)
1. In a separate PowerShell window, start the tunnel:
   ```powershell
   cloudflared tunnel --url http://localhost:8000
   ```
   **IMPORTANT:** Keep this PowerShell window open! If you close it, the tunnel stops and Cloudflare will show:
   *"The host is configured as a Cloudflare Tunnel, but Cloudflare is currently unable to reach it."*

2. Copy the generated `https://xxxx.trycloudflare.com` URL and run the app:
   ```powershell
   flutter run --dart-define=LOCAL_AI_API_URL=https://xxxx.trycloudflare.com
   ```

### Option C: Flutter Web
Run directly with Chrome:
```powershell
flutter run -d chrome
```

The gateway allows localhost browser origins and the default Firebase Hosting origins for this project. If you use a custom web domain, set `WEB_ALLOWED_ORIGINS` in the gateway terminal to its exact origin (scheme and host, no path), for example `https://app.example.com`, then restart the gateway.

Install that build on the phones and sign in with Firebase. For each new temporary tunnel URL, rebuild/reinstall the app with its new value. For a stable app deployment, configure a named Cloudflare Tunnel and stable hostname, then build with that hostname.

## What must stay online

Keep the laptop powered on, awake, and online. Ollama, the FastAPI window, and the `cloudflared` window must all keep running. If any stops, new AI requests from phones will fail until it is restarted. The mobile app continues saving chat messages to Firebase Realtime Database; local Qwen generates the response on the laptop. PDF text is extracted locally; scanned PDF pages and images are sent to Qwen-VL on the laptop as images.

## Security notes

- The Flutter app sends a Firebase ID token, claim ID, message, and recent chat turns over HTTPS to the tunnel.
- The gateway verifies the token and then loads the claim and document URLs from `users/{uid}` in Firebase. It does not trust claim metadata or file URLs supplied by the phone.
- Files are accepted from Cloudinary HTTPS URLs only, with a 10 MB limit. Requests and document content are not logged by this server.
- Firebase Admin credentials stay on the laptop. The Ollama port stays on loopback.
- Keep the model tag fixed to `qwen3-vl:latest`; this server does not fall back to Gemini or a cloud model.
