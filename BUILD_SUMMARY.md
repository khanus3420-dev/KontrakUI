# KONTRAK App Build Summary

## 📱 Platform Comparison

| Platform | File Type | Requires | Build Command |
|----------|-----------|----------|---------------|
| **iPhone** | IPA | Mac + Xcode | `flutter build ios --release` |
| **Android** | APK | Any OS + Android Studio | `flutter build apk --release` |

---

## 🍎 For iPhone (iOS)

### ⚠️ Important Requirements
- **Mac computer required** (cannot build on Windows/Linux)
- Xcode installed (free from Mac App Store)
- Apple Developer account (free for testing, $99/year for distribution)

### Quick Steps

1. **Open in Xcode**:
   ```bash
   cd frontend
   open ios/Runner.xcworkspace
   ```

2. **Configure Signing**:
   - Xcode → Runner → Signing & Capabilities
   - Enable "Automatically manage signing"
   - Select your Team

3. **Build & Install**:
   - Connect iPhone via USB
   - Select iPhone from device dropdown
   - Click Play button (▶️) or `Cmd + R`
   - Trust certificate on iPhone: Settings → General → VPN & Device Management

### Full Guide
See: **`BUILD_IOS_GUIDE.md`**

---

## 🤖 For Android

### Requirements
- Any computer (Windows/Mac/Linux)
- Android Studio installed
- Android SDK configured

### Quick Steps

1. **Build APK**:
   ```bash
   cd frontend
   flutter build apk --release \
     --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=your-anon-key \
     --dart-define=API_BASE_URL=https://kontrakapi.onrender.com
   ```

2. **Install APK**:
   - Location: `build/app/outputs/flutter-apk/app-release.apk`
   - Copy to Android phone
   - Enable "Install from Unknown Sources"
   - Install APK

### Full Guide
See: **`BUILD_APK_GUIDE.md`**

---

## 🚀 Quick Build Scripts

### iOS (Mac)
```bash
cd frontend
chmod +x build_ios.sh
./build_ios.sh
```

### Android (Mac/Linux)
```bash
cd frontend
chmod +x build_apk.sh
./build_apk.sh
```

### Android (Windows)
```cmd
cd frontend
build_apk.bat
```

---

## 📋 Environment Variables

Set these before building (or use `--dart-define`):

```bash
SUPABASE_URL=https://YOUR-PROJECT.supabase.co
SUPABASE_ANON_KEY=your-anon-key
API_BASE_URL=https://kontrakapi.onrender.com
```

---

## 📁 Build Output Locations

### iOS
- **IPA**: Created via Xcode Archive
- **Build folder**: `frontend/build/ios/iphoneos/Runner.app`

### Android
- **APK**: `frontend/build/app/outputs/flutter-apk/app-release.apk`
- **AAB** (Play Store): `frontend/build/app/outputs/bundle/release/app-release.aab`

---

## ✅ Verification Checklist

After building, verify:
- [ ] App installs successfully
- [ ] Login works (superadmin and builder admin)
- [ ] API connection works
- [ ] Customer Onboarding accessible (superadmin)
- [ ] Customer Management screen loads
- [ ] All features functional

---

## 🆘 Common Issues

### iOS
- **"No signing certificate"** → Add Apple ID in Xcode Preferences
- **"App won't install"** → Trust certificate in iPhone Settings
- **"Build failed"** → Run `pod install` in `ios` folder

### Android
- **"Gradle build failed"** → Run `./gradlew clean` in `android` folder
- **"SDK not found"** → Set `ANDROID_HOME` environment variable
- **"License not accepted"** → Run `flutter doctor --android-licenses`

---

## 📚 Documentation Files

- **`BUILD_IOS_GUIDE.md`** - Complete iPhone build guide
- **`BUILD_APK_GUIDE.md`** - Complete Android APK guide
- **`BUILD_QUICK_START.md`** - Quick reference for both platforms
- **`build_ios.sh`** - iOS build script (Mac)
- **`build_apk.sh`** - Android build script (Mac/Linux)
- **`build_apk.bat`** - Android build script (Windows)

---

## 💡 Tips

1. **Test First**: Build debug version first to test:
   ```bash
   flutter run --release
   ```

2. **Check Config**: Verify `lib/core/config.dart` has correct defaults

3. **Network**: Ensure backend API is accessible from device

4. **Permissions**: Check iOS Info.plist and Android manifest for required permissions

---

Good luck building! 🎉
