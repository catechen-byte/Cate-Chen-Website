#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export PATH="/tmp/node-local/bin:${PATH:-}"

echo "This script deploys to Vercel after GitHub is connected."
echo "Ensure the repo is pushed: ./scripts/setup-github.sh"
echo ""

if ! npx vercel whoami >/dev/null 2>&1; then
  echo "Log in to Vercel:"
  npx vercel login
fi

read -r -p "Production domain (optional, press Enter to skip): " domain

npx vercel --prod

if [ -n "$domain" ]; then
  npx vercel domains add "$domain"
  echo "Set NEXT_PUBLIC_SITE_URL=https://$domain in Vercel project settings, then redeploy."
fi

echo "Done. Add custom DNS records from the Vercel dashboard if you attached a domain."
