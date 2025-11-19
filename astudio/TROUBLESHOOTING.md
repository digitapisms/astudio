# Troubleshooting Guide

## "Failed to fetch" / Network Errors

If you're seeing errors like:
- `Client exception: failed to fetch`
- `Network error: Unable to connect to Supabase`
- CORS errors in browser console

### Solution 1: Verify Supabase Project Status

1. Go to https://supabase.com/dashboard
2. Check if your project is **Active** (not paused)
3. If paused, click "Restore project" to reactivate it

### Solution 2: Check Your Supabase URL

1. In Supabase Dashboard → Project Settings → API
2. Copy the **Project URL** (should look like: `https://xxxxx.supabase.co`)
3. Verify it matches your `.env` file exactly:
   ```
   SUPABASE_URL=https://xxxxx.supabase.co
   ```
   - No trailing slash
   - Must start with `https://`
   - Must end with `.supabase.co`

### Solution 3: Configure CORS (if needed)

Supabase projects should have CORS enabled by default, but if you're still having issues:

1. Go to Supabase Dashboard → Project Settings → API
2. Under "CORS Configuration", ensure your local development URL is allowed:
   - `http://localhost:xxxxx` (where xxxxx is your Flutter web port)
   - Or use `*` for development (not recommended for production)

### Solution 4: Check Browser Console

1. Open Chrome DevTools (F12)
2. Go to Console tab
3. Look for specific CORS or network errors
4. Check Network tab to see the actual request/response

### Solution 5: Verify Environment Variables

1. Make sure `.env` file is in the correct location: `astudio/.env`
2. Check file format (no quotes, no extra spaces):
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   ```
3. Restart Flutter app after changing `.env`

### Solution 6: Test Supabase Connection

Try accessing your Supabase project URL directly in browser:
- `https://your-project-id.supabase.co`
- Should show a Supabase welcome page or API info

If this doesn't load, your project might be paused or the URL is incorrect.

## Common Error Messages

### "Could not find the table 'public.profiles'"
**Solution:** Run the SQL schema in Supabase SQL Editor (see `supabase/schema.sql`)

### "Missing Supabase configuration"
**Solution:** Create `.env` file with `SUPABASE_URL` and `SUPABASE_ANON_KEY`

### "Invalid API key"
**Solution:** Verify `SUPABASE_ANON_KEY` in `.env` matches the anon/public key from Supabase Dashboard

### White screen on web
**Solution:** Check browser console (F12) for errors. The app now shows error screens instead of white screens.

## Still Having Issues?

1. Check Flutter terminal output for detailed error messages
2. Check browser console (F12 → Console) for JavaScript errors
3. Verify Supabase project is active and accessible
4. Try using `--dart-define` flags instead of `.env` file:
   ```bash
   flutter run -d chrome --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=...
   ```

