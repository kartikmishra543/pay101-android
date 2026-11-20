# Pay101 Mobile Apps (Android + iOS)

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

---

# iOS app (`ios/` folder)

SwiftUI + WKWebView with the same behaviour as Android: splash screen, pay101 domains in-app,
other links open in Safari or the right app, HTTPS only, saved login, pull to refresh,
swipe back/forward, offline screen with Retry, file uploads, and JS alerts. Requires iOS 15+.

## Run on a Mac (Xcode)
1. Install Xcode from the Mac App Store.
2. Open `ios/Pay101.xcodeproj`.
3. Select the **Pay101** target → **Signing & Capabilities** → choose your Apple ID as Team
   (a free Apple ID works for testing on your own iPhone; the app then lasts 7 days).
4. Pick a simulator or your connected iPhone and press **▶ Run**.

`Pay101.xcodeproj` is generated from `ios/project.yml` by CI. To regenerate it yourself:
`brew install xcodegen && cd ios && xcodegen generate`.

## Install without a Mac (Windows/Linux laptop)
CI publishes an unsigned build at
https://github.com/kartikmishra543/pay101-android/releases/download/ios-latest/Pay101-unsigned.ipa
Install it on your iPhone with **Sideloadly** (sideloadly.io) or **AltStore** (altstore.io) using
your Apple ID. With a free Apple ID it must be refreshed every 7 days.

## App Store
Needs an Apple Developer account ($99/year) and a Mac (or a CI signing setup).
Apple can reject apps that are only a website wrapper (guideline 4.2), so plan to add
native value before submitting, e.g. Face ID login lock, push notifications for payouts and settlements.
