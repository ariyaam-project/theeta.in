# Theeta — Android builds

| Version | File | Size | API | Notes |
|---------|------|------|-----|-------|
| 1.0.0 | [theeta-1.0.0.apk](./theeta-1.0.0.apk) | 52 MB | `https://auth.theeta.in` | Release build, debug-signed |

## Install

Sideload on an Android device (enable **Install unknown apps** for your file manager/browser):

```bash
adb install app/releases/theeta-1.0.0.apk
```

Or copy the APK to the phone and tap it.

## Build details

- **Type:** `flutter build apk --release`
- **API base:** baked to `https://auth.theeta.in` (the production API Worker — `apis/`, custom domain in `apis/wrangler.toml`)
- **Auth:** email / password (no Google sign-in in the app)
- **Signing:** debug key (default release `signingConfig`). Fine for testing/sideload — **not** Play Store.
- **applicationId:** `com.example.app` (placeholder — change before any store release)

## Rebuild

```bash
cd app
flutter build apk --release \
  --dart-define=THETA_API_BASE=https://auth.theeta.in
# output: build/app/outputs/flutter-apk/app-release.apk
cp build/app/outputs/flutter-apk/app-release.apk releases/theeta-<version>.apk
```

> Note: APKs are large binaries. Consider Git LFS (or GitHub Releases) if committing them to the repo.
