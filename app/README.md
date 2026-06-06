# Theta Flutter App

Flutter client for saving shared Instagram reels into the Theta API pipeline.

## Local Run

Start the local services first:

```bash
cd ../apis
npm run dev -- --ip 0.0.0.0 --port 8787

cd ../worker
uvicorn app.main:app --host 0.0.0.0 --port 8001
```

Then run Flutter. For Google login, pass the OAuth web client ID that matches
`GOOGLE_CLIENT_ID` in the Worker env:

```bash
flutter run \
  --dart-define=THETA_API_BASE=https://aerosol-reformer-twirl.ngrok-free.dev \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<google-web-client-id>
```

API base defaults:

- Android emulator: `http://10.0.2.2:8787`
- Real phone / iOS simulator / macOS default: `https://aerosol-reformer-twirl.ngrok-free.dev`

For iOS, also pass the iOS OAuth client ID if Google Sign-In is not configured
through app files:

```bash
flutter run \
  --dart-define=GOOGLE_CLIENT_ID=<google-ios-client-id> \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<google-web-client-id>
```

## Auth

The app uses native Google Sign-In to get a Google ID token, then exchanges it
with `POST /api/auth/google/native`. The Worker returns a Theta bearer token,
which is stored in `shared_preferences` and sent as `Authorization: Bearer ...`.

The login screen still exposes `Use dev login` for local testing through
`POST /api/dev/login`.

## Reel Flow

When a reel is shared into the app or pasted manually:

1. Flutter parses the Instagram URL.
2. Flutter calls `POST /api/reels`.
3. Cloudflare Worker saves the user reel reference and queues the canonical reel.
4. Cloudflare Worker triggers FastAPI with `POST /v1/jobs/trigger`.
5. FastAPI downloads/transcribes/analyzes and posts results back.
6. Pull-to-refresh in Flutter reloads saved reels and details.
