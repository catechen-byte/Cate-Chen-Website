#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v gh >/dev/null 2>&1; then
  echo "Install GitHub CLI: https://cli.github.com/"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Log in to GitHub first:"
  echo "  gh auth login"
  exit 1
fi

if [ -z "$(git config user.name || true)" ]; then
  read -r -p "Git user.name: " name
  git config user.name "$name"
fi

if [ -z "$(git config user.email || true)" ]; then
  read -r -p "Git user.email: " email
  git config user.email "$email"
fi

if [ ! -d .git ]; then
  git init
  git branch -M main
fi

git add .
git commit -m "Initial personal website" || true

REPO_NAME="${1:-personal-website}"
VISIBILITY="${2:-private}"

if git remote get-url origin >/dev/null 2>&1; then
  echo "Remote origin already set. Pushing..."
  git push -u origin main
else
  gh repo create "$REPO_NAME" "--$VISIBILITY" --source=. --remote=origin --push
fi

echo ""
echo "Next: import $REPO_NAME on https://vercel.com/new and add your custom domain."
echo "See DEPLOY.md for environment variables and Supabase admin setup."
