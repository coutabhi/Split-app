# Connecting OfficeSplit to Supabase

Follow these steps once. It takes about 5 minutes and is free.

1. **Create an account and project**
   - Go to https://supabase.com and sign up (email is enough, no credit card).
   - Click **New project**. Pick any name (e.g. "officesplit") and a database
     password (you won't need to remember it — Supabase handles it), and any
     region close to your team. Wait ~2 minutes for it to finish provisioning.

2. **Run the database schema**
   - In your new project, open the **SQL Editor** (left sidebar) → **New query**.
   - Open `supabase/schema.sql` from this repo, copy its entire contents, paste
     it into the editor, and click **Run**. This creates all the tables,
     security rules, and realtime sync — nothing else to configure.

3. **Get your project's API credentials**
   - Go to **Project Settings** (gear icon) → **API**.
   - Copy the **Project URL** (looks like `https://xxxxxxxx.supabase.co`).
   - Copy the **anon / public** key (a long string starting with `eyJ...`).
     This key is *meant* to be public — it's safe to share here; the real
     security is the row-level policies the schema just set up.

4. **Send me those two values** (Project URL and anon key) and I'll wire them
   into the app, add sign-up/login, and ship you a new APK that syncs
   everyone's data live.

That's it — email/password sign-up is enabled by default in Supabase, so
there's nothing else to turn on.
