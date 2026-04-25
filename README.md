# 🌿 HabitFlow

A shared habit tracker for teams, families, or communities — with per-user calendars, monthly breakdowns, a live leaderboard, and admin-only user management.

**Stack:** Plain HTML + Vanilla JS · Supabase (Auth + Database) · GitHub Pages (hosting)

---

## 📁 File Structure

```
habitflow/
├── index.html          ← Login page (magic link + password)
├── app.html            ← Main habit tracking app
├── admin.html          ← Admin panel (invite & manage users)
├── js/
│   └── supabase.js     ← Shared Supabase client config
└── supabase_schema.sql ← Paste this into Supabase SQL editor
```

---

## 🚀 Setup Guide

### Step 1 — Create a Supabase project

1. Go to [supabase.com](https://supabase.com) → **New project**
2. Choose a name, region, and strong database password → **Create project**
3. Wait ~2 minutes for it to provision

### Step 2 — Run the database schema

1. In your Supabase dashboard, go to **SQL Editor** (left sidebar)
2. Click **+ New query**
3. Paste the entire contents of `supabase_schema.sql`
4. Click **Run** (▶)

You should see "Success. No rows returned."

### Step 3 — Configure your API keys

1. In Supabase: go to **Settings → API**
2. Copy **Project URL** and **anon public** key
3. Open `js/supabase.js` and replace:

```js
const SUPABASE_URL      = 'https://YOUR_PROJECT.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY';
```

### Step 4 — Configure Supabase Auth

1. In Supabase: **Authentication → URL Configuration**
2. Set **Site URL** to your GitHub Pages URL:  
   `https://YOUR_USERNAME.github.io/habitflow`
3. Add the same URL to **Redirect URLs** (click **+ Add URL**)
4. Also add `http://localhost:3000` if testing locally

5. In **Authentication → Email Templates**, you can customize the invite email to say "HabitFlow" instead of the default Supabase branding.

### Step 5 — Deploy to GitHub Pages

1. Create a new GitHub repo (e.g. `habitflow`)
2. Push these files to the repo root:
   ```bash
   git init
   git add .
   git commit -m "initial HabitFlow deploy"
   git remote add origin https://github.com/YOUR_USERNAME/habitflow.git
   git push -u origin main
   ```
3. In GitHub: **Settings → Pages → Source → Deploy from branch: main / root**
4. Your app will be live at: `https://YOUR_USERNAME.github.io/habitflow`

### Step 6 — Create your first admin account

1. Go to your live app → enter your email → click **Send magic link**
2. Click the link in your email to sign in
3. In Supabase **SQL Editor**, run:
   ```sql
   update public.profiles
   set role = 'admin'
   where email = 'your@email.com';
   ```
4. Refresh the app — you'll now see **Admin panel** in the sidebar

---

## 👤 User Management

### Inviting users (Admin only)

1. Sign in as admin → click **⚙️ Admin panel** in the sidebar
2. Enter the new user's name + email → **Send invite**
3. They'll receive a magic-link email to join

> **Note:** The invite uses Supabase's magic link. If you have Row Level Security enabled and the admin API isn't accessible from the client, the OTP (one-time password) fallback is used — the user receives a sign-in link and their profile is auto-created on first login.

### Role management

From the Admin panel you can:
- **Make admin** — promote a member to admin
- **Demote** — remove admin privileges
- **Remove** — delete a user and all their habit data

---

## ✨ Features

| Feature | Details |
|---|---|
| **Magic link login** | Passwordless email sign-in |
| **Password login** | Standard email+password (if you enable it in Supabase) |
| **Per-user habit calendars** | Monthly grid with click-to-done, shift-click-to-skip |
| **Own vs others** | Members see only their own tab; admins see everyone |
| **Summary tab** | Live leaderboard + monthly breakdown table (admin only) |
| **Add/remove habits** | Each user manages their own habits |
| **Real-time sync** | Supabase Realtime updates across browser tabs |
| **Admin panel** | Invite, promote, demote, remove users |
| **Row Level Security** | Users can only modify their own data |

---

## 🔐 Security notes

- **RLS is enabled** on all tables — users cannot access or modify each other's data
- Admins can read all data (needed for the Summary tab and leaderboard)
- The `anon` key in `supabase.js` is safe to expose publicly — it's limited by RLS
- Never commit your **service_role** key to a public repo

---

## 🛠 Local development

You can use any static file server:

```bash
# Python
python3 -m http.server 3000

# Node
npx serve .
```

Then open `http://localhost:3000`

Remember to add `http://localhost:3000` to your Supabase redirect URLs (Settings → Auth → URL Configuration).

---

## 📅 Multi-year support

The app currently shows data for the current year. To view a different year, you can extend `state.currentYear` in `app.html` with a year selector in the topbar.

---

## 🐛 Troubleshooting

| Issue | Fix |
|---|---|
| "Invalid login credentials" | Check your Supabase URL/anon key in `js/supabase.js` |
| Magic link doesn't redirect | Add your site URL to Supabase → Auth → Redirect URLs |
| Admin panel shows "Access denied" | Run the SQL to set your role to 'admin' |
| Invite email not arriving | Check Supabase → Auth → Logs; check spam folder |
| Data not saving | Check browser console; verify RLS policies were applied |
