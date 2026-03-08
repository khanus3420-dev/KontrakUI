# Building KONTRAK App for iPhone (iOS)

This guide will help you build and install the KONTRAK app on your iPhone.

---

## ⚠️ Important Note

- **APK** = Android Package (for Android phones)
- **IPA** = iOS App Archive (for iPhone/iPad)
- For iPhone, you need to build an **IPA file**, not APK

---

## Prerequisites

### 1. Mac Computer Required
- **You MUST have a Mac** (macOS) to build iOS apps
- iOS apps cannot be built on Windows or Linux
- Minimum macOS version: macOS 10.15 (Catalina) or later

### 2. Apple Developer Account
- **Free Account**: For testing on your own iPhone (7-day certificate)
- **Paid Account ($99/year)**: For App Store distribution and longer certificates
- Sign up at: https://developer.apple.com/programs/

### 3. Xcode Installation
- Download from Mac App Store (free, ~12GB)
- Install Xcode Command Line Tools:
  ```bash
  xcode-select --install
  ```

### 4. Flutter Setup
- Ensure Flutter is installed and configured
- Verify iOS setup:
  ```bash
  flutter doctor
  ```
- Fix any iOS-related issues shown

---

## Step-by-Step Build Process

### Step 1: Configure Environment Variables

Create a file `frontend/.env` or set environment variables:

```bash
# Supabase Configuration
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# API Configuration
API_BASE_URL=https://kontrakapi.onrender.com
```

### Step 2: Configure iOS Project

#### 2.1 Open iOS Project in Xcode

```bash
cd frontend
open ios/Runner.xcworkspace
```

#### 2.2 Configure Signing & Capabilities

1. In Xcode, select **Runner** project in left sidebar
2. Select **Runner** target
3. Go to **Signing & Capabilities** tab
4. Check **"Automatically manage signing"**
5. Select your **Team** (Apple Developer account)
6. Xcode will generate a provisioning profile automatically

#### 2.3 Update Bundle Identifier

1. In **Signing & Capabilities**, change **Bundle Identifier**
2. Use format: `com.yourcompany.kontrak` (must be unique)
3. Example: `com.khanoos.kontrak`

#### 2.4 Configure App Display Name

1. In Xcode, select **Runner** target
2. Go to **General** tab
3. Update **Display Name**: `KONTRAK`
4. Update **Version** and **Build** numbers

### Step 3: Configure Environment Variables in iOS

#### Option A: Using Dart Defines (Recommended)

Create a script or use command line:

```bash
cd frontend

flutter build ios --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=API_BASE_URL=https://kontrakapi.onrender.com
```

#### Option B: Update Config File Directly

Edit `frontend/lib/core/config.dart` and hardcode values temporarily:

```dart
class AppConfig {
  static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
  static const String apiBaseUrl = 'https://kontrakapi.onrender.com';
}
```

### Step 4: Build for iOS Device

#### 4.1 Connect Your iPhone

1. Connect iPhone to Mac via USB cable
2. Unlock iPhone and **Trust This Computer** if prompted
3. In Xcode, select your iPhone from device dropdown (top bar)

#### 4.2 Build and Install

**Method 1: Using Flutter Command**

```bash
cd frontend
flutter build ios --release
flutter install
```

**Method 2: Using Xcode (Recommended for first time)**

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your iPhone from device dropdown
3. Click **Play** button (▶️) or press `Cmd + R`
4. Xcode will build and install on your iPhone
5. On iPhone: Go to **Settings** → **General** → **VPN & Device Management**
6. Trust your developer certificate

---

## Building IPA File (For Distribution)

### For TestFlight/App Store

```bash
cd frontend

# Build iOS release
flutter build ios --release

# Archive in Xcode
# 1. Open ios/Runner.xcworkspace
# 2. Product → Archive
# 3. Wait for archive to complete
# 4. Click "Distribute App"
# 5. Choose distribution method (App Store, Ad Hoc, Enterprise)
```

### For Ad Hoc Distribution (Install on specific devices)

1. In Xcode: **Product** → **Archive**
2. After archive completes, click **Distribute App**
3. Select **Ad Hoc**
4. Select devices (add UDIDs of target iPhones)
5. Export IPA file
6. Share IPA file with users
7. Users install via iTunes/Finder or TestFlight

---

## Building APK for Android (Bonus)

Since you mentioned APK, here's how to build for Android:

### Prerequisites
- Android Studio installed
- Android SDK configured
- Java JDK installed

### Build Commands

```bash
cd frontend

# Build APK (for direct installation)
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=API_BASE_URL=https://kontrakapi.onrender.com

# APK will be at: build/app/outputs/flutter-apk/app-release.apk

# Build App Bundle (for Play Store)
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=API_BASE_URL=https://kontrakapi.onrender.com

# AAB will be at: build/app/outputs/bundle/release/app-release.aab
```

---

## Troubleshooting

### Issue: "No devices found"

**Solution:**
- Ensure iPhone is unlocked
- Trust the computer on iPhone
- Check USB cable connection
- Restart Xcode

### Issue: "Signing requires a development team"

**Solution:**
- Add Apple ID in Xcode → Preferences → Accounts
- Select team in Signing & Capabilities
- Or use free Apple ID (7-day certificates)

### Issue: "Failed to build iOS app"

**Solution:**
```bash
cd frontend/ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
flutter build ios --release
```

### Issue: "App won't install on iPhone"

**Solution:**
1. On iPhone: **Settings** → **General** → **VPN & Device Management**
2. Trust your developer certificate
3. Try installing again

### Issue: "Network error" or "API not reachable"

**Solution:**
- Verify environment variables are set correctly
- Check API base URL is accessible from iPhone
- Ensure backend is running and accessible
- Check iPhone's network connection

---

## Quick Reference Commands

### iOS Build Commands

```bash
# Clean build
flutter clean
flutter pub get

# Build for iOS (release)
flutter build ios --release

# Build and install on connected device
flutter install

# Build with environment variables
flutter build ios --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=API_BASE_URL=https://kontrakapi.onrender.com
```

### Android Build Commands

```bash
# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Build with environment variables
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=API_BASE_URL=https://kontrakapi.onrender.com
```

---

## Distribution Options

### 1. TestFlight (Recommended)
- Upload IPA to App Store Connect
- Invite testers via email
- Testers install via TestFlight app
- Valid for 90 days

### 2. Ad Hoc Distribution
- Build IPA with specific device UDIDs
- Share IPA file directly
- Install via iTunes/Finder
- Valid for 1 year (paid account)

### 3. Enterprise Distribution
- Requires Enterprise Developer account ($299/year)
- Distribute internally without App Store
- No device limit

### 4. App Store
- Submit for App Store review
- Public distribution
- Requires paid developer account

---

## Environment Variables Setup

### For Development

Create `frontend/.env` file (don't commit to git):

```bash
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=your-anon-key
API_BASE_URL=https://kontrakapi.onrender.com
```

### For Production Builds

Use `--dart-define` flags:

```bash
flutter build ios --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=API_BASE_URL=https://kontrakapi.onrender.com
```

---

## Files to Check Before Building

1. **`frontend/lib/core/config.dart`** - API and Supabase configuration
2. **`frontend/ios/Runner/Info.plist`** - iOS app configuration
3. **`frontend/pubspec.yaml`** - Dependencies and app metadata
4. **`frontend/ios/Runner.xcodeproj`** - Xcode project settings

---

## Next Steps After Building

1. **Test on Device**: Verify all features work on iPhone
2. **Test Login**: Ensure superadmin and builder admin login work
3. **Test Customer Onboarding**: Verify superadmin can create customers
4. **Test Offline**: Check if app handles network errors gracefully
5. **Performance**: Check app performance and memory usage

---

## Need Help?

Common issues:
- **"No signing certificate"**: Add Apple ID in Xcode → Preferences → Accounts
- **"Provisioning profile error"**: Enable "Automatically manage signing"
- **"Build failed"**: Run `pod install` in `ios` folder
- **"App crashes on launch"**: Check environment variables and API URLs

---

## Summary

**For iPhone:**
1. ✅ Use Mac computer
2. ✅ Install Xcode
3. ✅ Configure signing in Xcode
4. ✅ Build with `flutter build ios --release`
5. ✅ Install via Xcode or TestFlight

**For Android:**
1. ✅ Use any computer (Windows/Mac/Linux)
2. ✅ Install Android Studio
3. ✅ Build with `flutter build apk --release`
4. ✅ Install APK directly on Android phone

Good luck! 🚀
