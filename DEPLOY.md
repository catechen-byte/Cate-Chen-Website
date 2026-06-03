# Deploy guide

## 1. GitHub CLI login

Install GitHub CLI if needed:

```bash
# macOS — pick one:
brew install gh
# or download from https://cli.github.com/
```

Log in:

```bash
gh auth login
gh auth status
```

Set Git identity if missing:

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

## 2. First push

From the repo root:

```bash
git init
git branch -M main
git add .
git commit -m "Initial personal website"
gh repo create personal-website --private --source=. --remote=origin --push
```

Use `--public` when you are ready for a public repo.

## 3. Vercel

1. Sign in at [vercel.com](https://vercel.com) with GitHub.
2. **Add New Project** → import `personal-website`.
3. Framework preset: **Next.js** (auto-detected).
4. Root directory: repo root.
5. Deploy.

### Environment variables (optional)

| Variable | Purpose |
|----------|---------|
| `NEXT_PUBLIC_SITE_URL` | Canonical URL for sitemap/RSS (e.g. `https://yourdomain.com`) |
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase project URL for `/admin` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anon key |
| `ADMIN_EMAIL` | Only this email can use admin drafts |

## 4. Custom domain

In Vercel → Project → **Settings → Domains**, add your domain and follow DNS instructions.

Update `NEXT_PUBLIC_SITE_URL` to match the live domain, then redeploy.

## 5. Supabase admin (optional)

1. Create a free project at [supabase.com](https://supabase.com).
2. Run `supabase/migrations/001_admin_drafts.sql` in the SQL editor.
3. Enable Email auth (magic link).
4. Add env vars in Vercel and redeploy.
5. Visit `/admin` on your site.

Drafts stay in Supabase until you **Export MDX** and commit files under `content/`.
