# Setting Up Codemagic for iOS Builds (No Mac Required)

This guide will help you build KONTRAK for iPhone using Codemagic's free cloud Mac service.

---

## Prerequisites

1. ✅ Git repository (GitHub, GitLab, or Bitbucket)
2. ✅ Codemagic account (free at https://codemagic.io)
3. ✅ Your environment variables ready

---

## Step-by-Step Setup

### Step 1: Push Code to Git Repository

If you haven't already:

```bash
cd c:\CODE\Contracter
git init
git add .
git commit -m "Initial commit"
git remote add origin YOUR_GIT_REPO_URL
git push -u origin main
```

**Supported Git Providers:**
- GitHub
- GitLab
- Bitbucket
- GitLab Self-hosted
- Bitbucket Server

---

### Step 2: Sign Up for Codemagic

1. Go to: https://codemagic.io/signup
2. Sign up with your Git provider (GitHub/GitLab/Bitbucket)
3. Authorize Codemagic to access your repositories

---

### Step 3: Add Your App

1. **Click "Add application"** in Codemagic dashboard
2. **Select your Git provider** (GitHub/GitLab/Bitbucket)
3. **Choose your repository** (`Contracter` or your repo name)
4. **Select Flutter** as project type
5. **Click "Finish"**

---

### Step 4: Configure Environment Variables

1. In Codemagic dashboard, go to **Teams** → **Environment Variables**
2. Click **"Add variable"** and add:

   ```
   Name: SUPABASE_URL
   Value: https://YOUR-PROJECT.supabase.co
   Group: app_config
   ```

   ```
   Name: SUPABASE_ANON_KEY
   Value: your-anon-key-here
   Group: app_config
   ```

   ```
   Name: API_BASE_URL
   Value: https://kontrakapi.onrender.com
   Group: app_config
   ```

3. **Save** all variables

**Note**: Mark sensitive variables (like API keys) as **"Secure"** to hide them in logs.

---

### Step 5: Configure Build Settings

1. In your app dashboard, click **"Start new build"**
2. **Select workflow**: Choose "iOS workflow" (or create new)
3. **Configure**:
   - **Flutter version**: Stable (latest)
   - **Xcode version**: Latest
   - **Build type**: Release
   - **Environment variables**: Select `app_config` group

---

### Step 6: Update Codemagic Config (Optional)

The `.codemagic.yaml` file I created will be automatically detected.

**If you need to customize**, edit `frontend/.codemagic.yaml`:

```yaml
workflows:
  ios-workflow:
    name: KONTRAK iOS Build
    environment:
      groups:
        - app_config  # Your environment variables group
```

---

### Step 7: Start Build

1. Click **"Start new build"**
2. Select **"iOS workflow"**
3. Select **branch** (usually `main` or `master`)
4. Click **"Start build"**

**Build time**: Usually 10-15 minutes

---

### Step 8: Download IPA

1. **Wait for build to complete** (you'll get email notification)
2. **Go to build details** page
3. **Download IPA** from artifacts section
4. **IPA file**: `KONTRAK.ipa`

---

## Installing IPA on iPhone

### Option 1: TestFlight (Recommended)

1. **Upload IPA to App Store Connect**:
   - Go to https://appstoreconnect.apple.com
   - Create app (if not exists)
   - Upload IPA via Transporter app or Xcode
   - Process for TestFlight

2. **Add Testers**:
   - Go to TestFlight tab
   - Add internal/external testers
   - Testers install via TestFlight app

### Option 2: Direct Install (Ad Hoc)

1. **Register device UDID** in Apple Developer account
2. **Build with device provisioning**:
   - Update `.codemagic.yaml` to include device UDIDs
   - Rebuild with Ad Hoc distribution

3. **Install IPA**:
   - Use **AltStore** (free, requires computer)
   - Use **3uTools** (Windows tool)
   - Use **iTunes/Finder** (Mac only)

### Option 3: Enterprise Distribution

- Requires Enterprise Developer account ($299/year)
- No device limit
- Direct installation

---

## Automated Builds

### Trigger on Git Push

1. In Codemagic, go to **App settings**
2. Enable **"Build on push"**
3. Select **branches** to trigger builds
4. Every push will trigger automatic build

### Scheduled Builds

1. In workflow settings, add **"Scheduled builds"**
2. Set schedule (daily, weekly, etc.)
3. Automatically build and notify you

---

## Cost & Limits

### Free Tier
- ✅ **500 build minutes/month**
- ✅ **Unlimited builds** (within minutes limit)
- ✅ **Public repositories**: Unlimited
- ✅ **Private repositories**: Limited

### Paid Plans
- **Starter**: $75/month (2000 build minutes)
- **Professional**: $225/month (5000 build minutes)

**For most users**: Free tier is sufficient!

---

## Troubleshooting

### Build Fails: "Signing Error"

**Solution**: 
- Add your Apple Developer account in Codemagic
- Go to **Teams** → **Code signing identities**
- Upload your certificates and provisioning profiles

### Build Fails: "Environment Variables Not Found"

**Solution**:
- Verify variables are in `app_config` group
- Check variable names match exactly (case-sensitive)
- Ensure variables are marked as "Secure" if needed

### Build Succeeds but IPA Missing

**Solution**:
- Check build logs for IPA creation step
- Verify `Create IPA` script ran successfully
- Check artifacts section in build details

### "No Mac Available" Error

**Solution**:
- Free tier has limited Mac instances
- Try again later or upgrade plan
- Use GitHub Actions as alternative

---

## Alternative: GitHub Actions

If Codemagic doesn't work, use GitHub Actions (free for public repos):

1. **Push code to GitHub**
2. **Add secrets** in GitHub repository:
   - Go to Settings → Secrets → Actions
   - Add: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL`

3. **Workflow file**: `.github/workflows/build-ios.yml` (already created)
4. **Trigger build**: Push to main branch or manual trigger
5. **Download IPA**: From Actions → Artifacts

---

## Quick Reference

### Codemagic Dashboard
- **URL**: https://codemagic.io
- **Documentation**: https://docs.codemagic.io

### Build Commands (in Codemagic)
```bash
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=API_BASE_URL="$API_BASE_URL"
```

### Download IPA
- Build details → Artifacts → Download `KONTRAK.ipa`

---

## Next Steps

1. ✅ Push code to Git repository
2. ✅ Sign up for Codemagic
3. ✅ Add environment variables
4. ✅ Start first build
5. ✅ Download IPA
6. ✅ Install on iPhone via TestFlight

---

## Support

- **Codemagic Docs**: https://docs.codemagic.io
- **Codemagic Community**: https://codemagic.io/community
- **Flutter iOS Guide**: https://docs.flutter.dev/deployment/ios

Good luck! 🚀
