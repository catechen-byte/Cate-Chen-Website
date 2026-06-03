# Personal website + projects monorepo

Next.js personal site at the repo root. Research and coding projects live under `projects/`.

## Quick start

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Structure

| Path | Purpose |
|------|---------|
| `app/` | Next.js App Router pages |
| `components/` | Shared UI |
| `content/` | MDX/Markdown for blog, projects, research |
| `lib/` | Content loaders, Supabase helpers |
| `public/` | Static assets and downloadable artifacts |
| `projects/ubi-ai-welfare/` | UBI × AI welfare R analysis project |

## Content

Add Markdown files with frontmatter to:

- `content/blog/`
- `content/projects/`
- `content/research/`

## Deploy

Connect this repo to [Vercel](https://vercel.com) (Framework: Next.js). See `DEPLOY.md` for GitHub CLI and domain steps.

## Optional admin

Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY`, then visit `/admin` for draft editing.
