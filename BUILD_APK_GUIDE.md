# Building KONTRAK APK for Android

This guide will help you build an APK file to install KONTRAK on Android devices.

---

## Prerequisites

### 1. Android Studio
- Download from: https://developer.android.com/studio
- Install Android SDK (API level 21 or higher)
- Install Android SDK Build-Tools

### 2. Flutter Setup
- Ensure Flutter is installed
- Verify Android setup:
  ```bash
  flutter doctor
  ```
- Accept Android licenses:
  ```bash
  flutter doctor --android-licenses
  ```

### 3. Java JDK
- Install Java JDK 11 or higher
- Set `JAVA_HOME` environment variable

---

## Step-by-Step Build Process

### Step 1: Configure Environment Variables

#### Option A: Using Dart Defines (Recommended)

```bash
cd frontend

flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=API_BASE_URL=https://kontrakapi.onrender.com
```

#### Option B: Update Config File

Edit `frontend/lib/core/config.dart`:

```dart
class AppConfig {
  static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
  static const String apiBaseUrl = 'https://kontrakapi.onrender.com';
}
```

### Step 2: Configure Android App

#### 2.1 Update App Name and Package

Edit `frontend/android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        applicationId "com.khanoos.kontrak"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode 1
        versionName "1.0.0"
    }
}
```

#### 2.2 Configure App Icon (Optional)

Replace icon files in:
- `frontend/android/app/src/main/res/mipmap-*/ic_launcher.png`

### Step 3: Build APK

#### 3.1 Clean Previous Builds

```bash
cd frontend
flutter clean
flutter pub get
```

#### 3.2 Build Release APK

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=API_BASE_URL=https://kontrakapi.onrender.com
```

#### 3.3 APK Location

After build completes, APK will be at:
```
frontend/build/app/outputs/flutter-apk/app-release.apk
```

### Step 4: Install APK on Android Device

#### Method 1: Direct Transfer
1. Copy `app-release.apk` to Android phone
2. On phone: Enable **"Install from Unknown Sources"**
3. Open APK file and install

#### Method 2: Using ADB
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

#### Method 3: Using USB
1. Connect phone via USB
2. Enable USB debugging
3. Run: `flutter install`

---

## Building Split APKs (Optional)

For smaller APK size, build split APKs:

```bash
flutter build apk --split-per-abi --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=API_BASE_URL=https://kontrakapi.onrender.com
```

This creates separate APKs for:
- `app-armeabi-v7a-release.apk` (32-bit)
- `app-arm64-v8a-release.apk` (64-bit)
- `app-x86_64-release.apk` (x86_64)

---

## Building App Bundle (For Play Store)

For Google Play Store distribution:

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=API_BASE_URL=https://kontrakapi.onrender.com
```

AAB file location:
```
frontend/build/app/outputs/bundle/release/app-release.aab
```

---

## Signing APK (For Distribution)

### Generate Keystore

```bash
keytool -genkey -v -keystore ~/kontrak-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias kontrak
```

### Configure Signing

Create `frontend/android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=kontrak
storeFile=/path/to/kontrak-key.jks
```

Update `frontend/android/app/build.gradle`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

---

## Troubleshooting

### Issue: "Gradle build failed"

**Solution:**
```bash
cd frontend/android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

### Issue: "SDK location not found"

**Solution:**
- Set `ANDROID_HOME` environment variable
- Or create `local.properties` in `android` folder:
  ```properties
  sdk.dir=/path/to/Android/sdk
  ```

### Issue: "License not accepted"

**Solution:**
```bash
flutter doctor --android-licenses
# Accept all licenses
```

### Issue: "Build tools not found"

**Solution:**
- Open Android Studio
- SDK Manager → SDK Tools
- Install Android SDK Build-Tools

---

## Quick Build Script

Create `build_apk.sh`:

```bash
#!/bin/bash

cd frontend

flutter clean
flutter pub get

flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=API_BASE_URL=https://kontrakapi.onrender.com

echo "APK built at: build/app/outputs/flutter-apk/app-release.apk"
```

Make executable:
```bash
chmod +x build_apk.sh
./build_apk.sh
```

---

## Summary

**Quick Build:**
```bash
cd frontend
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=API_BASE_URL=https://kontrakapi.onrender.com
```

**APK Location:** `build/app/outputs/flutter-apk/app-release.apk`

**Install:** Copy to Android phone and install, or use `adb install`
