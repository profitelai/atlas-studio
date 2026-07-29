# Atlas — discovery scan (Roadmap step 1)

The deterministic, **read-only** discovery layer from the proposal. Plain shell, no AI,
near-zero cost. It builds one living map of your servers and reusable packages so your
build-agents reuse what exists instead of rebuilding it (and missing a part).

**It never writes to your servers or copies your code.** It reads and points.

## Layout
```
atlas/
  INDEX.md          # the map an agent loads first (generated)
  inventory/        # one Markdown file per server (generated)
  packages/         # CATALOG.md (shallow) + <name>.md deep manifests (on demand)
  skills/           # "clone this correctly" recipes (added per package)
  bin/
    collect.sh        # read-only collector — runs ON a host, prints a Markdown map
    scan-server.sh    # runs collect.sh over SSH, saves inventory/<name>.md
    scan-packages.sh  # shallow pass over one git host (gh), writes packages/CATALOG.md
    build-index.sh    # regenerates INDEX.md
```

## Quick start
```bash
cd atlas
chmod +x bin/*.sh

# 1) Map this machine, to see the output shape:
bin/scan-server.sh local

# 2) Map a real server (SSH key must work non-interactively):
bin/scan-server.sh deploy@server1.example.com prod-web

# 3) Map several at once — one "user@host name" per line:
#    (lines starting with # are ignored)
bin/scan-server.sh -f hosts.txt

# 4) Shallow-list your packages from your git host:
bin/scan-packages.sh your-github-org

# INDEX.md is rebuilt automatically after a server scan.
```

## What the server scan captures
vhosts (nginx + Apache `server_name` / roots), web roots **with nested-app detection**
(`.env`, `wp-config.php`, `package.json`, `composer.json`, `manage.py`, `Dockerfile`,
`docker-compose`, `.git`), listening ports + owning process, enabled systemd services,
pm2/supervisor apps, MySQL/Postgres database lists, **every crontab and systemd timer
(where existing backups live)**, and TLS cert expiry via certbot.

Run as root for the fullest picture (other users' crontabs, DB lists) — but it works
unprivileged and clearly marks anything it had to skip.

## Notes
- `scan-server.sh` uses `ssh -o BatchMode=yes` (no prompts) so multi-host runs never
  hang. For a host that needs a password/passphrase, run it interactively:
  `ATLAS_INTERACTIVE=1 bin/scan-server.sh myhost` — SSH will prompt you.
- Deep package manifests are **never pre-built** — you add `packages/<name>.md` the
  first time you reuse a package, and that cost is repaid by not rebuilding it.
