# Quick Start: Building KONTRAK App

## For iPhone (iOS) - Requires Mac

### Prerequisites
- ✅ Mac computer
- ✅ Xcode installed
- ✅ Apple Developer account (free or paid)

### Quick Build Steps

1. **Set Environment Variables** (replace with your values):
   ```bash
   export SUPABASE_URL="https://YOUR-PROJECT.supabase.co"
   export SUPABASE_ANON_KEY="your-anon-key"
   export API_BASE_URL="https://kontrakapi.onrender.com"
   ```

2. **Build iOS App**:
   ```bash
   cd frontend
   flutter clean
   flutter pub get
   flutter build ios --release \
     --dart-define=SUPABASE_URL="$SUPABASE_URL" \
     --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
     --dart-define=API_BASE_URL="$API_BASE_URL"
   ```

3. **Install on iPhone**:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Connect iPhone via USB
   - Select iPhone from device dropdown
   - Click Play button (▶️)
   - On iPhone: Trust developer certificate in Settings

**Detailed Guide:** See `BUILD_IOS_GUIDE.md`

---

## For Android - Any Computer

### Prerequisites
- ✅ Android Studio installed
- ✅ Android SDK configured
- ✅ Flutter setup complete

### Quick Build Steps

1. **Set Environment Variables**:
   ```bash
   export SUPABASE_URL="https://YOUR-PROJECT.supabase.co"
   export SUPABASE_ANON_KEY="your-anon-key"
   export API_BASE_URL="https://kontrakapi.onrender.com"
   ```

2. **Build APK**:
   ```bash
   cd frontend
   flutter clean
   flutter pub get
   flutter build apk --release \
     --dart-define=SUPABASE_URL="$SUPABASE_URL" \
     --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
     --dart-define=API_BASE_URL="$API_BASE_URL"
   ```

3. **Install APK**:
   - APK location: `build/app/outputs/flutter-apk/app-release.apk`
   - Copy to Android phone
   - Enable "Install from Unknown Sources"
   - Install APK

**Detailed Guide:** See `BUILD_APK_GUIDE.md`

---

## Using Build Scripts

### iOS (Mac only)
```bash
cd frontend
chmod +x build_ios.sh
./build_ios.sh
```

### Android
```bash
cd frontend
chmod +x build_apk.sh
./build_apk.sh
```

---

## Important Notes

### For iPhone:
- ⚠️ **Must use Mac** - iOS apps cannot be built on Windows/Linux
- ⚠️ **APK ≠ iPhone** - APK is for Android only
- ✅ For iPhone, you build an **IPA file** (not APK)

### For Android:
- ✅ Can build on Windows, Mac, or Linux
- ✅ APK can be installed directly on Android devices
- ✅ No special certificates needed for testing

---

## Environment Variables

Replace these with your actual values:

```bash
SUPABASE_URL=https://YOUR-PROJECT.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
API_BASE_URL=https://kontrakapi.onrender.com
```

Get these from:
- **Supabase Dashboard** → Settings → API
- **Backend URL** → Your Render deployment URL

---

## Troubleshooting

### iOS Build Fails
```bash
cd frontend/ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

### Android Build Fails
```bash
cd frontend/android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### App Won't Connect to API
- Verify environment variables are set correctly
- Check API base URL is accessible
- Ensure backend is running on Render

---

## Need More Help?

- **iOS Guide**: `BUILD_IOS_GUIDE.md` (detailed iPhone instructions)
- **Android Guide**: `BUILD_APK_GUIDE.md` (detailed APK instructions)
