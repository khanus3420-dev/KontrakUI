# Setting Up GitHub Actions for iOS Builds (Free, No Mac Required)

This guide will help you build KONTRAK for iPhone using GitHub Actions (free for public repositories).

---

## Prerequisites

1. ✅ GitHub account (free)
2. ✅ Code pushed to GitHub repository
3. ✅ Your environment variables ready

---

## Step-by-Step Setup

### Step 1: Push Code to GitHub

If you haven't already:

```bash
cd c:\CODE\Contracter
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

---

### Step 2: Add GitHub Secrets

1. **Go to your GitHub repository**
2. **Settings** → **Secrets and variables** → **Actions**
3. **Click "New repository secret"** and add:

   **Secret 1:**
   - Name: `SUPABASE_URL`
   - Value: `https://YOUR-PROJECT.supabase.co`
   - Click "Add secret"

   **Secret 2:**
   - Name: `SUPABASE_ANON_KEY`
   - Value: `your-anon-key-here`
   - Click "Add secret"

   **Secret 3:**
   - Name: `API_BASE_URL`
   - Value: `https://kontrakapi.onrender.com`
   - Click "Add secret"

**Note**: Secrets are encrypted and hidden in logs.

---

### Step 3: Workflow File Already Created

The workflow file `.github/workflows/build-ios.yml` is already created in your project.

**What it does:**
- ✅ Runs on macOS (free Mac runner)
- ✅ Sets up Flutter
- ✅ Installs dependencies
- ✅ Builds iOS app
- ✅ Creates IPA file
- ✅ Uploads IPA as artifact

---

### Step 4: Commit and Push Workflow File

```bash
cd c:\CODE\Contracter
git add .github/workflows/build-ios.yml
git commit -m "Add iOS build workflow"
git push
```

**Or** if the file already exists, just push your code:

```bash
git add .
git commit -m "Update code"
git push
```

---

### Step 5: Trigger Build

**Option A: Automatic (on push)**
- Push any code to `main` or `master` branch
- Build will start automatically

**Option B: Manual trigger**
1. Go to **Actions** tab in GitHub
2. Select **"Build iOS App"** workflow
3. Click **"Run workflow"**
4. Select branch: `main`
5. Click **"Run workflow"**

---

### Step 6: Monitor Build

1. **Go to Actions tab** in GitHub repository
2. **Click on running workflow** to see progress
3. **Wait for completion** (usually 10-15 minutes)
4. **Check logs** if build fails

---

### Step 7: Download IPA

1. **After build completes**, go to workflow run
2. **Scroll down** to "Artifacts" section
3. **Click "kontrak-ios-ipa"** to download
4. **Extract ZIP** file
5. **IPA file**: `KONTRAK.ipa`

---

## Installing IPA on iPhone

### Option 1: TestFlight (Recommended)

1. **Upload IPA to App Store Connect**:
   - Go to https://appstoreconnect.apple.com
   - Create app (if not exists)
   - Upload IPA via **Transporter** app (Mac/Windows)
   - Process for TestFlight

2. **Add Testers**:
   - Go to TestFlight tab
   - Add internal/external testers
   - Testers install via TestFlight app

### Option 2: Direct Install (Requires Signing)

**Note**: GitHub Actions builds without code signing by default.

**To sign IPA**:
1. Add Apple Developer certificates to GitHub Secrets
2. Update workflow to sign IPA
3. Or use Codemagic (easier signing setup)

### Option 3: Use AltStore (Free, Windows Compatible)

1. **Download AltStore**: https://altstore.io
2. **Install AltServer** on Windows
3. **Connect iPhone** via USB
4. **Install AltStore** on iPhone
5. **Install IPA** via AltStore

---

## Workflow Customization

### Build on Specific Branches Only

Edit `.github/workflows/build-ios.yml`:

```yaml
on:
  push:
    branches:
      - main
      - release/*
```

### Build on Schedule

Add to workflow:

```yaml
on:
  schedule:
    - cron: '0 0 * * 0'  # Every Sunday at midnight
```

### Build Only on Tags

```yaml
on:
  push:
    tags:
      - 'v*'
```

---

## Cost & Limits

### Free Tier (Public Repos)
- ✅ **Unlimited build minutes**
- ✅ **Unlimited builds**
- ✅ **2000 minutes/month** for private repos

### Paid Plans
- **Team**: $4/user/month (3000 minutes)
- **Enterprise**: Custom pricing

**For public repos**: Completely free! 🎉

---

## Troubleshooting

### Build Fails: "Flutter not found"

**Solution**: 
- Check workflow uses `subosito/flutter-action@v2`
- Verify Flutter version is specified

### Build Fails: "CocoaPods error"

**Solution**:
- Check `pod install` step completed
- Verify `ios/Podfile` exists
- Check build logs for specific error

### Build Succeeds but No IPA

**Solution**:
- Check "Create IPA" step in logs
- Verify artifact upload step ran
- Check artifacts section in workflow run

### "Secrets not found"

**Solution**:
- Verify secrets are added correctly
- Check secret names match exactly (case-sensitive)
- Ensure secrets are in correct repository

### Build Takes Too Long

**Solution**:
- Free runners can be slow during peak times
- Consider upgrading to paid plan
- Or use Codemagic (faster free tier)

---

## Advanced: Code Signing

To sign IPA for distribution:

1. **Export certificates** from Keychain (Mac) or Apple Developer portal
2. **Add to GitHub Secrets**:
   - `APPLE_CERTIFICATE` (base64 encoded)
   - `APPLE_CERTIFICATE_PASSWORD`
   - `APPLE_PROVISIONING_PROFILE` (base64 encoded)

3. **Update workflow** to import and use certificates

**Note**: This requires Mac to export certificates initially.

---

## Quick Reference

### Workflow File Location
```
.github/workflows/build-ios.yml
```

### Secrets Location
```
GitHub Repo → Settings → Secrets and variables → Actions
```

### Build Status
```
GitHub Repo → Actions tab
```

### Download IPA
```
Actions → Workflow run → Artifacts → kontrak-ios-ipa
```

---

## Alternative: Codemagic

If GitHub Actions doesn't work for you:

- **Easier setup**: Visual UI, no YAML editing
- **Better signing**: Built-in code signing setup
- **Faster builds**: Optimized Mac runners
- **Free tier**: 500 minutes/month

**See**: `CODEMAGIC_SETUP.md`

---

## Next Steps

1. ✅ Push code to GitHub
2. ✅ Add secrets
3. ✅ Push workflow file
4. ✅ Trigger build
5. ✅ Download IPA
6. ✅ Install on iPhone

---

## Support

- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **Flutter iOS Guide**: https://docs.flutter.dev/deployment/ios
- **Workflow Examples**: https://github.com/actions

Good luck! 🚀
