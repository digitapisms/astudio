# Deployment Guide - Actor Studio

This guide explains how to deploy your Flutter web app so clients can access it online.

## Quick Start - Deploy to Vercel (Recommended - Easiest)

### Step 1: Build the Web App
```bash
flutter build web --release
```

### Step 2: Deploy to Vercel
1. Go to [vercel.com](https://vercel.com) and sign up/login
2. Click "Add New Project"
3. Import your GitHub repository: `digitapisms/astudio`
4. Configure:
   - **Framework Preset**: Other
   - **Root Directory**: `astudio` (if your repo has nested structure)
   - **Build Command**: `flutter build web --release`
   - **Output Directory**: `build/web`
5. Add Environment Variables:
   - `SUPABASE_URL`: Your Supabase project URL
   - `SUPABASE_ANON_KEY`: Your Supabase anon key
6. Click "Deploy"

Your app will be live at: `https://your-project.vercel.app`

---

## Alternative: Deploy to Netlify

### Step 1: Build
```bash
flutter build web --release
```

### Step 2: Deploy
1. Go to [netlify.com](https://netlify.com) and sign up
2. Drag and drop the `build/web` folder, OR
3. Connect to GitHub:
   - Click "New site from Git"
   - Select your repository
   - Build settings:
     - Build command: `flutter build web --release`
     - Publish directory: `build/web`
   - Add environment variables (same as Vercel)
4. Deploy!

---

## Alternative: Deploy to Firebase Hosting

### Step 1: Install Firebase CLI
```bash
npm install -g firebase-tools
```

### Step 2: Login and Initialize
```bash
firebase login
firebase init hosting
```

### Step 3: Configure
- Select "Flutter Web" or "Existing app"
- Public directory: `build/web`
- Single-page app: Yes
- GitHub auto-deploys: Optional

### Step 4: Build and Deploy
```bash
flutter build web --release
firebase deploy
```

---

## Alternative: GitHub Pages (Free but Limited)

### Step 1: Build for GitHub Pages
```bash
flutter build web --release --base-href "/astudio/"
```

### Step 2: Deploy
1. Go to your GitHub repo → Settings → Pages
2. Source: Deploy from a branch
3. Branch: `main` or `gh-pages`
4. Folder: `/build/web`
5. Save

**Note**: You'll need to update the base href in your build command to match your repository name.

---

## For Client Demo - Quick Options

### Option A: Share Build Folder
1. Build the app: `flutter build web --release`
2. Zip the `build/web` folder
3. Share with client (they can open `index.html` locally)
4. **Note**: They'll need to set up `.env` or you can hardcode credentials for demo

### Option B: Use ngrok (Temporary URL)
1. Run locally: `flutter run -d chrome`
2. Install ngrok: `npm install -g ngrok`
3. Run: `ngrok http 5000` (or your Flutter port)
4. Share the ngrok URL with client
5. **Note**: URL expires when you close ngrok

### Option C: Deploy to Vercel/Netlify (Best for Client)
- Follow the Vercel steps above
- Client gets a permanent URL
- Professional and reliable

---

## Environment Variables Setup

For all hosting platforms, you need to add these environment variables:

- `SUPABASE_URL`: `https://wnlukjwvcdrhxpgwdbvg.supabase.co`
- `SUPABASE_ANON_KEY`: Your anon key from Supabase

**Important**: 
- Never commit `.env` file to GitHub
- Always use environment variables in hosting platforms
- The app reads from `flutter_dotenv` which works with build-time variables

---

## Troubleshooting

### Build Fails
- Run `flutter clean` then `flutter pub get`
- Check Flutter version: `flutter --version` (need 3.19+)

### App Doesn't Load
- Check browser console for errors
- Verify environment variables are set
- Check Supabase project is active (not paused)

### CORS Errors
- Ensure Supabase project allows your domain
- Add your domain to Supabase Dashboard → Settings → API

---

## Recommended: Vercel (Easiest)

**Why Vercel?**
- ✅ Free tier is generous
- ✅ Automatic deployments from GitHub
- ✅ Easy environment variable setup
- ✅ Fast CDN
- ✅ Custom domains
- ✅ Perfect for client demos

**Quick Deploy Command** (if you have Vercel CLI):
```bash
npm i -g vercel
cd build/web
vercel --prod
```

---

## Next Steps After Deployment

1. **Add Custom Domain** (optional)
   - Vercel/Netlify allow custom domains
   - Update DNS settings

2. **Set Up CI/CD**
   - Auto-deploy on every push to main
   - Vercel/Netlify do this automatically

3. **Monitor Performance**
   - Check Vercel/Netlify analytics
   - Monitor Supabase usage

4. **Share with Client**
   - Send them the deployment URL
   - They can access it from any device/browser

