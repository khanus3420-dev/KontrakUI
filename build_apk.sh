#!/bin/bash

# Build KONTRAK APK for Android
# Usage: ./build_apk.sh

echo "=========================================="
echo "Building KONTRAK APK for Android"
echo "=========================================="

# Set your environment variables here
SUPABASE_URL="${SUPABASE_URL:-https://YOUR-PROJECT.supabase.co}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-YOUR_SUPABASE_ANON_KEY}"
API_BASE_URL="${API_BASE_URL:-https://kontrakapi.onrender.com}"

echo "Configuration:"
echo "  SUPABASE_URL: $SUPABASE_URL"
echo "  API_BASE_URL: $API_BASE_URL"
echo ""

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean
flutter pub get

# Build APK release
echo ""
echo "Building APK release..."
flutter build apk --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=API_BASE_URL="$API_BASE_URL"

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ Build successful!"
    echo "=========================================="
    echo ""
    echo "APK location:"
    echo "  build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "To install on Android device:"
    echo "1. Copy APK to your Android phone"
    echo "2. Enable 'Install from Unknown Sources'"
    echo "3. Open APK file and install"
    echo ""
    echo "Or use ADB:"
    echo "  adb install build/app/outputs/flutter-apk/app-release.apk"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "❌ Build failed!"
    echo "=========================================="
    echo "Check errors above and try again."
    exit 1
fi
