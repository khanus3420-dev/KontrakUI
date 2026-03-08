# Fix: 404 Error After Login

## Problem

Getting `404 Not Found` error when trying to load projects after login:
```
Failed to load projects: DioException [bad response]: 404
```

## Root Cause

The API base URL was incorrectly configured, causing duplicate `/api/v1` in the URL:
- `apiBaseUrl` was set to: `https://kontrakapi.onrender.com/api/v1`
- API calls use: `/api/v1/projects/`
- Final URL became: `https://kontrakapi.onrender.com/api/v1/api/v1/projects/` ❌

## Solution Applied

### 1. Fixed API Base URL

**File:** `frontend/lib/core/config.dart`

Changed:
```dart
// Before (WRONG)
defaultValue: 'https://kontrakapi.onrender.com/api/v1'

// After (CORRECT)
defaultValue: 'https://kontrakapi.onrender.com'
```

### 2. Fixed Auth Login Endpoint

**File:** `frontend/lib/data/auth/auth_repository.dart`

Changed:
```dart
// Before
'/auth/login'

// After
'/api/v1/auth/login'
```

## How It Works Now

- **Base URL:** `https://kontrakapi.onrender.com`
- **API Calls:** `/api/v1/projects/`, `/api/v1/auth/login`, etc.
- **Final URLs:** `https://kontrakapi.onrender.com/api/v1/projects/` ✅

## Testing

After these changes:

1. **Hot Restart** your Flutter app (not just hot reload)
2. Try logging in again
3. Projects should load successfully

## Verify API Endpoints

All API endpoints should now work correctly:

- ✅ Login: `POST /api/v1/auth/login`
- ✅ Projects: `GET /api/v1/projects/`
- ✅ Analytics: `GET /api/v1/analytics/monthly-expenses`
- ✅ Notifications: `POST /api/v1/notifications/devices`

## If Still Getting 404

1. **Check Render deployment:**
   - Make sure backend is deployed and running
   - Check Render logs for errors

2. **Verify API Base URL:**
   - Make sure you're using the correct Render URL
   - Check if it's `https://kontrakapi.onrender.com` (no trailing slash)

3. **Check Network Tab:**
   - Open browser DevTools → Network tab
   - See what URL is actually being called
   - Verify it matches: `https://kontrakapi.onrender.com/api/v1/projects/`

4. **Verify Backend Routes:**
   - Check `backend/app/main.py` - routes should be registered
   - Verify `api_v1_prefix = "/api/v1"` in config

## Environment Variables

If you're using `--dart-define` for API_BASE_URL, make sure it doesn't include `/api/v1`:

```bash
# Correct
flutter run --dart-define=API_BASE_URL=https://kontrakapi.onrender.com

# Wrong
flutter run --dart-define=API_BASE_URL=https://kontrakapi.onrender.com/api/v1
```
