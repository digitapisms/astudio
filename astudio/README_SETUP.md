# Setup Instructions

## Environment Configuration

The app requires Supabase credentials to run. You have two options:

### Option 1: Using .env file (Recommended for development)

1. Create a `.env` file in the `astudio` directory (same level as `pubspec.yaml`)
2. Add your Supabase credentials:

```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key-here
```

3. Make sure the `.env` file is in the root of the `astudio` folder (not in `lib` or `web`)

### Option 2: Using --dart-define flags

Run the app with:

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=https://your-project-id.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Getting Your Supabase Credentials

1. Go to https://supabase.com and sign in
2. Create a new project or select an existing one
3. Go to Project Settings → API
4. Copy:
   - **Project URL** → Use as `SUPABASE_URL`
   - **anon/public key** → Use as `SUPABASE_ANON_KEY`

## Running the App

After setting up credentials:

```bash
cd astudio
flutter run -d chrome
```

## Troubleshooting

### White Screen Issue

If you see a white screen:

1. **Check browser console** (F12 → Console tab) for errors
2. Verify `.env` file is in the correct location (`astudio/.env`)
3. Check that `.env` file has no extra spaces or quotes around values
4. Make sure you've run `flutter pub get` after adding `.env` to `pubspec.yaml`
5. Try hot restart (press `R` in terminal) or full restart

### Configuration Error Screen

If you see a "Configuration Error" screen:
- Your `.env` file is not being loaded
- Check the file location and format
- Try using `--dart-define` flags instead

## Database Setup

After running the app, you need to set up the database schema:

1. Go to your Supabase project → SQL Editor
2. Copy and paste the contents of `supabase/schema.sql`
3. Run the SQL script

This will create all necessary tables and security policies.

