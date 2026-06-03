# Local setup

Homebrew is at `/opt/homebrew`. Shell config: `~/.zprofile` and `~/.zshrc` (run `source ~/.zshrc` in open terminals).

| Tool | Command | Notes |
|------|---------|--------|
| Node.js | `node`, `npm`, `npx` | v22 for the Next.js site |
| GitHub CLI | `gh` | Deploy steps in `DEPLOY.md` |
| Pandoc | `pandoc` | R PDF reports in `projects/ubi-ai-welfare/` |
| Python pip | `python3 -m pip` | Python 3.14 at `/usr/local/bin/python3` |

Open a **new terminal** (or run `source ~/.zshrc`), then:

```bash
cd ~/Desktop/My\ Coding\ Project
npm install
npm run dev
```

### Optional: Homebrew

Homebrew needs your Mac password (Administrator). In Terminal:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then follow the on-screen `eval` line, and you can use `brew install gh node pandoc` if you prefer.

### GitHub CLI login

```bash
gh auth login
```
