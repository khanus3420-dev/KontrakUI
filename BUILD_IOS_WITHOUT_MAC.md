# Building iOS App Without a Mac Computer

Since you don't have a Mac, here are your options to build KONTRAK for iPhone:

---

## Option 1: Cloud Mac Services (Recommended)

### A. Codemagic (Easiest - Free Tier Available)
**Best for:** Automated builds with free tier

1. **Sign up**: https://codemagic.io/signup
2. **Connect your Git repository** (GitHub/GitLab/Bitbucket)
3. **Configure build**:
   - Platform: iOS
   - Select your Flutter project
   - Add environment variables:
     ```
     SUPABASE_URL=https://YOUR-PROJECT.supabase.co
     SUPABASE_ANON_KEY=your-anon-key
     API_BASE_URL=https://kontrakapi.onrender.com
     ```
4. **Build**: Click "Start new build"
5. **Download IPA**: After build completes, download IPA file
6. **Install**: Use TestFlight or install directly on iPhone

**Pricing**: Free tier includes 500 build minutes/month

**Setup Guide**: See `CODEMAGIC_SETUP.md` (I'll create this)

---

### B. GitHub Actions (Free for Public Repos)
**Best for:** If your code is on GitHub

1. **Create workflow file**: `.github/workflows/build-ios.yml`
2. **Configure**: Add your environment variables as GitHub Secrets
3. **Trigger**: Push to repository or manually trigger
4. **Download**: IPA artifact from Actions tab

**Pricing**: Free for public repos, 2000 minutes/month for private repos

**Setup**: I'll create a workflow file for you

---

### C. AppCircle (Free Tier Available)
**Best for:** Simple setup, good free tier

1. **Sign up**: https://appcircle.io
2. **Connect repository**
3. **Configure iOS build**
4. **Build and download IPA**

**Pricing**: Free tier available

---

### D. MacStadium / AWS Mac Instances (Paid)
**Best for:** Full control, remote Mac access

- **MacStadium**: Rent a Mac in the cloud (~$99/month)
- **AWS EC2 Mac**: Pay-per-use Mac instances
- **MacinCloud**: Remote Mac access (~$20-50/month)

**Note**: More expensive but gives you full Mac access

---

## Option 2: Use Someone Else's Mac

### Steps:
1. **Share your code** (via Git repository or USB drive)
2. **On their Mac**:
   ```bash
   git clone YOUR_REPO
   cd frontend
   flutter build ios --release \
     --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=your-anon-key \
     --dart-define=API_BASE_URL=https://kontrakapi.onrender.com
   ```
3. **Open in Xcode**: `open ios/Runner.xcworkspace`
4. **Archive and export IPA**
5. **Share IPA file** with you

---

## Option 3: Build for Android Instead (Easiest)

Since you're on Windows, you can build for Android immediately:

### Quick Android Build:
```bash
cd frontend
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=API_BASE_URL=https://kontrakapi.onrender.com
```

**APK Location**: `build/app/outputs/flutter-apk/app-release.apk`

**Install**: Copy to Android phone and install

**See**: `BUILD_APK_GUIDE.md` for detailed instructions

---

## Option 4: Use Flutter Build Services

### A. Fastlane (with CI/CD)
- Integrate with GitHub Actions or GitLab CI
- Automated builds and distribution

### B. Bitrise
- Free tier available
- Good for mobile CI/CD

---

## Recommended Solution: Codemagic

**Why Codemagic?**
- ✅ Free tier (500 build minutes/month)
- ✅ Easy setup (no Mac needed)
- ✅ Automatic builds
- ✅ TestFlight integration
- ✅ Direct IPA download
- ✅ Great Flutter support

**Quick Setup**:
1. Push your code to GitHub/GitLab/Bitbucket
2. Sign up at codemagic.io
3. Connect repository
4. Configure iOS build
5. Build and download IPA

---

## Alternative: TestFlight via App Store Connect

If you have an Apple Developer account ($99/year):

1. **Use cloud Mac service** to build IPA
2. **Upload to App Store Connect**
3. **Distribute via TestFlight** (free beta testing)
4. **Testers install via TestFlight app** (no Mac needed for them)

---

## Cost Comparison

| Solution | Cost | Setup Time | Best For |
|----------|------|------------|----------|
| **Codemagic** | Free (500 min/month) | 10 min | Most users |
| **GitHub Actions** | Free (public) | 15 min | GitHub users |
| **AppCircle** | Free tier | 10 min | Simple needs |
| **MacStadium** | ~$99/month | 30 min | Full Mac access |
| **Use Friend's Mac** | Free | 1 hour | One-time build |
| **Build Android** | Free | 5 min | Android users |

---

## Next Steps

1. **If you need iPhone app**: Use Codemagic (free, easiest)
2. **If Android works**: Build APK on Windows (immediate)
3. **If you have budget**: Rent MacStadium for full control

Would you like me to:
- ✅ Set up Codemagic configuration file?
- ✅ Create GitHub Actions workflow?
- ✅ Help build Android APK instead?

---

## Quick Decision Guide

**Choose Codemagic if:**
- You want free, easy iOS builds
- You have code on Git (GitHub/GitLab/Bitbucket)
- You need regular builds

**Choose GitHub Actions if:**
- Your code is already on GitHub
- You want free CI/CD
- You're comfortable with YAML configs

**Choose Android if:**
- You can use Android phone
- You want immediate solution
- You don't specifically need iPhone

**Choose MacStadium if:**
- You need full Mac access
- You have budget ($99/month)
- You want maximum control

---

Let me know which option you prefer, and I'll help you set it up! 🚀
