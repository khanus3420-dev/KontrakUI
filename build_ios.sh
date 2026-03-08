#!/bin/bash

# Build KONTRAK for iOS (iPhone)
# Usage: ./build_ios.sh

echo "=========================================="
echo "Building KONTRAK for iOS"
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

# Build iOS release
echo ""
echo "Building iOS release..."
flutter build ios --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=API_BASE_URL="$API_BASE_URL"

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ Build successful!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "1. Open ios/Runner.xcworkspace in Xcode"
    echo "2. Connect your iPhone via USB"
    echo "3. Select your iPhone from device dropdown"
    echo "4. Click Play button (▶️) or press Cmd+R"
    echo "5. On iPhone: Trust developer certificate in Settings"
    echo ""
    echo "Or build IPA for distribution:"
    echo "1. Product → Archive in Xcode"
    echo "2. Distribute App → Choose method"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "❌ Build failed!"
    echo "=========================================="
    echo "Check errors above and try again."
    exit 1
fi
