# Pay101 Android App

A native Android shell (Kotlin + WebView) for https://pay101.io.

## Features
- Branded splash screen and adaptive launcher icon
- Loads pay101.io and the partner portal (`*.pay101.io`, `*.pay101.uk`) inside the app; every other link opens in the browser or the right app (mailto:, tel:, UPI, etc.)
- HTTPS only — plain HTTP and mixed content are blocked
- Login sessions kept between launches (cookies saved)
- Pull to refresh, top progress bar, and hardware back button goes back through pages
- Offline screen with a Retry button
- File uploads (e.g. KYC documents) and file downloads (statements, reports) via Android's Download Manager
- Opens `https://pay101.io/...` links from other apps directly in the app

## Build the APK

### Option A: Android Studio (easiest)
1. Install Android Studio (Ladybug or newer).
2. **File → Open** → select this folder. Let Gradle sync.
3. **Build → Build App Bundle(s) / APK(s) → Build APK(s)**.
4. APK: `app/build/outputs/apk/debug/app-debug.apk`

### Option B: Command line
Requires JDK 17+ and the Android SDK (`ANDROID_HOME` set).
```
./gradlew assembleDebug
```

### Option C: GitHub (no local setup)
Push this folder to a GitHub repo. The included workflow (`.github/workflows/build-apk.yml`) builds the APK on every push to `main`. Download it from **Actions → latest run → Artifacts**.

## Customize
- Brand colour: `app/src/main/res/values/colors.xml` (`brand`)
- Icon: Android Studio → right-click `res` → **New → Image Asset** → use the Pay101 logo
- Start URL / allowed domains: top of `MainActivity.kt`
- App ID / version: `app/build.gradle.kts`

## Releasing to Play Store
1. **Build → Generate Signed App Bundle / APK** and create a keystore. Keep it safe; you can't update the app without it.
2. Upload the `.aab` to Google Play Console.
3. For the `pay101.io` links to open in the app automatically, host `/.well-known/assetlinks.json` on pay101.io with your signing certificate's SHA-256 fingerprint.
