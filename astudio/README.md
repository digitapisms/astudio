# Actor Studio Global – Setup Guide

Modern talent marketplace for artists, producers, and editorial staff.  
Flutter (mobile + web) + Supabase (auth/database/storage) + Firebase Messaging (planned).

## 1. Prerequisites

- Flutter 3.19+ with web/desktop enabled
- Supabase project
- Firebase project (for future push notifications)
- Optional: Vercel/Firebase Hosting for web

## 2. Environment variables

Create `astudio/.env` (or use `--dart-define`) with:

```
SUPABASE_URL=https://<project>.supabase.co
SUPABASE_ANON_KEY=<public-anon-key>
```

> Remember to keep `.env` out of version control.

## 3. Database schema & security

1. Open Supabase Dashboard → SQL Editor  
2. Paste and run `supabase/schema.sql`
3. This creates:
   - `profiles` table with role/status fields
   - `profile_reviews` audit trail
   - `castings`, `applications`
   - Row Level Security (RLS) policies for:
     - Artist/producer self-service
     - Admin/editor/staff management
     - Public read access to approved profiles

## 4. User roles & approval flow

| Role      | Purpose                               | Access                                              |
|-----------|----------------------------------------|-----------------------------------------------------|
| `artist`  | Talent profiles                        | Can edit their pending profile                      |
| `producer`| Casting creators                       | Post jobs, review applicants                        |
| `admin`   | Full control                           | Approve/reject profiles, manage castings            |
| `editor`  | Editorial staff                        | Same as admin except critical settings              |
| `viewer`  | Read-only internal users               | Browse dashboards                                   |
| `staff`   | Support accounts                       | Similar to editor                                   |

- New signups default to `artist` or `producer` and enter `pending` status
- Admin/editor/staff accounts can be created manually or via the seed script below
- Only approved profiles become visible in search/dashboards

### 4.1 Seeded demo accounts

Run `supabase/seed_users.sql` in the Supabase SQL editor (after running `schema.sql`).  
This script creates three demo accounts and forces their profiles to `approved` status so you can log in immediately.

| Role   | Email                     | Password   |
|--------|---------------------------|------------|
| Admin  | `admin@actorstudio.global`  | `Admin@123` |
| Editor | `editor@actorstudio.global` | `Editor@123` |
| Viewer | `viewer@actorstudio.global` | `Viewer@123` |

> **Security note:** These credentials are for local/demo usage only.  
> Update or delete them before deploying to production.

## 5. Google OAuth (optional but recommended)

1. In Supabase Dashboard → Authentication → Providers → enable **Google**
2. Add redirect URLs:
   - `https://<project>.supabase.co/auth/v1/callback`
   - `http://localhost:5000/auth/v1/callback` (adjust dev port)
3. Update OAuth credentials in Google Cloud Console
4. Flutter config: nothing else required (handled via `supabase_flutter`)

## 6. Running the app

```bash
cd astudio
flutter pub get
flutter run -d chrome   # or any supported device
```

## 7. Admin/staff workflow

- Admin dashboard route: `/admin`
- Pending approvals route: `/pending`
- Rejected profiles route: `/rejected`
- Approvals log stored in `profile_reviews`

## 8. Google Sign-In test checklist

- Ensure Supabase project is **Active** (not paused)
- Verify `.env` values match Supabase settings
- Check browser console for CORS errors
- Redirect URI must match Supabase auth provider settings exactly

## 9. Troubleshooting

See `TROUBLESHOOTING.md` for:
- “Failed to fetch” network errors
- RLS / permission issues (`PGRST205`, `42501`)
- Supabase project paused / CORS misconfiguration

## 10. Next steps (not yet implemented)

- Messaging & notifications (Supabase Realtime + Firebase Cloud Messaging)
- Payments (bank transfer workflow, Easypaisa, Alfa, Stripe)
- Advanced search, saved filters, featured placements
- QA automation and deployment pipelines
