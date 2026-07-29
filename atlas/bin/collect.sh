#!/usr/bin/env bash
# Atlas · collect.sh — deterministic, READ-ONLY server discovery.
# Runs ON a Linux host, prints a Markdown inventory to stdout.
# No AI, no writes to the host. Safe to run anywhere.
#
# Some sections are richer with root (reading other users' cron, DB lists,
# process owners). It never *requires* root — it notes when data was skipped.

set -uo pipefail
LC_ALL=C

have() { command -v "$1" >/dev/null 2>&1; }
say()  { printf '%s\n' "$*"; }
code() { say '```'; cat; say '```'; }          # wrap stdin in a fenced block
head2(){ say ""; say "## $*"; say ""; }
head3(){ say ""; say "### $*"; }
none() { say "_none found_"; }

HOSTN="$(hostname -f 2>/dev/null || hostname 2>/dev/null || echo unknown)"
NOWTS="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
AMROOT=no; [ "$(id -u 2>/dev/null || echo 1)" = "0" ] && AMROOT=yes

say "# Inventory — ${HOSTN}"
say ""
say "- **Scanned (UTC):** ${NOWTS}"
say "- **Collector:** atlas/collect.sh (read-only, deterministic)"
say "- **Ran as root:** ${AMROOT}"

# ── Machine ────────────────────────────────────────────────────────────
head2 "Machine"
if [ -r /etc/os-release ]; then . /etc/os-release; say "- **OS:** ${PRETTY_NAME:-unknown}"; fi
say "- **Kernel:** $(uname -sr 2>/dev/null)"
say "- **Arch:** $(uname -m 2>/dev/null)"
have nproc && say "- **CPUs:** $(nproc)"
have free  && say "- **Memory:** $(free -h 2>/dev/null | awk '/^Mem:/{print $2" total, "$3" used"}')"
have uptime && say "- **Uptime:** $(uptime -p 2>/dev/null || uptime)"

# ── Disk ───────────────────────────────────────────────────────────────
head2 "Disk"
if have df; then df -hP 2>/dev/null | grep -vE 'tmpfs|devtmpfs|overlay|udev|map ' | code; else none; fi

# ── Web servers & vhosts ───────────────────────────────────────────────
# This is where "sites-inside-sites" hide. Read every vhost config directly.
head2 "Web servers & virtual hosts"

head3 "nginx"
if have nginx; then
  say "- version: $(nginx -v 2>&1 | sed 's#.*/##')"
  { grep -RhoE '^[[:space:]]*server_name[[:space:]]+[^;]+' /etc/nginx/ 2>/dev/null \
      | sed -E 's/^[[:space:]]*server_name[[:space:]]+//; s/[[:space:]]+/ /g' | tr ' ' '\n' \
      | grep -vE '^(_|)$' | sort -u; } > /tmp/.atlas_ng 2>/dev/null
  if [ -s /tmp/.atlas_ng ]; then say ""; say "server_names:"; sed 's/^/  - /' /tmp/.atlas_ng; else say "_no server_name directives readable_"; fi
  { grep -RhoE '^[[:space:]]*root[[:space:]]+[^;]+' /etc/nginx/ 2>/dev/null \
      | sed -E 's/^[[:space:]]*root[[:space:]]+//' | sort -u; } > /tmp/.atlas_ngr 2>/dev/null
  if [ -s /tmp/.atlas_ngr ]; then say ""; say "roots:"; sed 's/^/  - /' /tmp/.atlas_ngr; fi
  rm -f /tmp/.atlas_ng /tmp/.atlas_ngr 2>/dev/null
else
  say "_not installed_"
fi

head3 "Apache"
APACHE_BIN=""; for b in apache2 httpd apache2ctl httpd; do have "$b" && { APACHE_BIN="$b"; break; }; done
if [ -n "$APACHE_BIN" ]; then
  say "- binary: $APACHE_BIN"
  { grep -RhE '^[[:space:]]*(ServerName|ServerAlias)[[:space:]]+' /etc/apache2/ /etc/httpd/ 2>/dev/null \
      | sed -E 's/#.*$//; s/^[[:space:]]*(ServerName|ServerAlias)[[:space:]]+//; s/:[0-9]+//g' \
      | tr ' \t' '\n\n' | grep -vE '^[[:space:]]*$|^(ServerName|ServerAlias)$' | sort -u; } > /tmp/.atlas_ap 2>/dev/null
  if [ -s /tmp/.atlas_ap ]; then say ""; say "server_names:"; sed 's/^/  - /' /tmp/.atlas_ap; else say "_no ServerName directives readable_"; fi
  { grep -RhE '^[[:space:]]*DocumentRoot[[:space:]]+' /etc/apache2/ /etc/httpd/ 2>/dev/null \
      | sed -E 's/#.*$//; s/^[[:space:]]*DocumentRoot[[:space:]]+//' | tr -d '"' \
      | grep -vE '^[[:space:]]*$' | sort -u; } > /tmp/.atlas_apr 2>/dev/null
  if [ -s /tmp/.atlas_apr ]; then say ""; say "document_roots:"; sed 's/^/  - /' /tmp/.atlas_apr; fi
  rm -f /tmp/.atlas_ap /tmp/.atlas_apr 2>/dev/null
else
  say "_not installed_"
fi

# ── Web roots & nested apps ────────────────────────────────────────────
# Walk common web roots, flag app markers. This catches apps-inside-apps.
head2 "Web roots & apps on disk"
ROOTS=""
for d in /var/www /srv/www /srv /home/*/public_html /home/*/www /usr/share/nginx/html; do
  [ -d "$d" ] && ROOTS="$ROOTS $d"
done
if [ -z "${ROOTS// }" ]; then
  none
else
  say "Marker files (.env, wp-config.php, package.json, composer.json, manage.py, Dockerfile,"
  say "docker-compose*, .git) reveal a real app — including ones nested inside another site."
  for r in $ROOTS; do
    head3 "$r"
    find "$r" -maxdepth 5 \
      \( -name node_modules -o -name vendor -o -name .next -o -name .cache \
         -o -name dist -o -name .turbo -o -name .venv -o -name venv \) -prune -o \
      \( -name '.env' -o -name 'wp-config.php' -o -name 'package.json' \
         -o -name 'composer.json' -o -name 'manage.py' -o -name 'Dockerfile' \
         -o -name 'docker-compose.yml' -o -name 'docker-compose.yaml' \
         -o -name 'artisan' -o -name '.git' \) \
      -printf '%h\t%f\n' 2>/dev/null | sort -u | awk -F'\t' '
        { apps[$1]=apps[$1]" "$2 }
        END { if (length(apps)==0) print "  _no app markers found_";
              else for (a in apps) printf "  - %s →%s\n", a, apps[a] }' | sort
  done
fi

# ── Listening services ─────────────────────────────────────────────────
head2 "Listening ports"
if have ss; then
  ss -tlnpH 2>/dev/null | awk '{print $4"\t"$NF}' | sed -E 's/users:\(\("//; s/".*process//' | sort -u | code
elif have netstat; then
  netstat -tlnp 2>/dev/null | awk 'NR>2{print $4"\t"$NF}' | sort -u | code
else
  none
fi

# ── Services (systemd) ─────────────────────────────────────────────────
head2 "Enabled services (systemd)"
if have systemctl; then
  systemctl list-unit-files --type=service --state=enabled --no-legend 2>/dev/null \
    | awk '{print $1}' | sort | code
else
  none
fi

head3 "Process managers"
have pm2 && { say "**pm2:**"; pm2 jlist 2>/dev/null | { have jq && jq -r '.[] | "  - "+.name+" ("+.pm2_env.status+")"' 2>/dev/null || cat; } ; }
have supervisorctl && { say "**supervisor:**"; supervisorctl status 2>/dev/null | code; }
have pm2 || have supervisorctl || say "_none detected (pm2 / supervisor)_"

# ── Databases ──────────────────────────────────────────────────────────
head2 "Databases"
head3 "MySQL / MariaDB"
if have mysql; then
  if mysql -N -e 'SHOW DATABASES;' 2>/dev/null > /tmp/.atlas_my; then
    grep -vE '^(information_schema|performance_schema|mysql|sys)$' /tmp/.atlas_my | sed 's/^/  - /'
    [ -s /tmp/.atlas_my ] || none
  else
    say "_present, but needs credentials to list databases (run with a readable ~/.my.cnf or as root)_"
  fi
  rm -f /tmp/.atlas_my 2>/dev/null
else say "_not installed_"; fi
head3 "PostgreSQL"
if have psql; then
  if sudo -n true 2>/dev/null && id postgres >/dev/null 2>&1; then
    sudo -n -u postgres psql -Atc "SELECT datname FROM pg_database WHERE datistemplate=false;" 2>/dev/null | sed 's/^/  - /' || say "_present, could not list_"
  else
    say "_present, but needs the postgres role to list databases_"
  fi
else say "_not installed_"; fi

# ── Scheduled jobs (existing backups live here) ────────────────────────
head2 "Scheduled jobs (cron / timers)"
head3 "This user's crontab"
crontab -l 2>/dev/null | grep -vE '^\s*#|^\s*$' | code || none
head3 "System cron"
{ for f in /etc/crontab /etc/cron.d/*; do [ -r "$f" ] && grep -vE '^\s*#|^\s*$' "$f" 2>/dev/null; done; } | code
if [ "$AMROOT" = yes ]; then
  head3 "All users' crontabs"
  for u in $(cut -d: -f1 /etc/passwd 2>/dev/null); do
    c=$(crontab -l -u "$u" 2>/dev/null | grep -vE '^\s*#|^\s*$'); [ -n "$c" ] && { say "**$u:**"; printf '%s\n' "$c" | sed 's/^/    /'; }
  done
else
  say ""; say "_run as root to read every user's crontab (backup jobs often live under a service user)_"
fi
head3 "systemd timers"
have systemctl && systemctl list-timers --all --no-legend 2>/dev/null | awk '{print $NF}' | grep -v '^$' | sort -u | code || none

# ── TLS certificates ───────────────────────────────────────────────────
head2 "TLS certificates"
if have certbot; then
  certbot certificates 2>/dev/null | grep -E 'Certificate Name|Domains|Expiry' | code || say "_certbot present, no certs or needs root_"
else
  say "_certbot not installed — cert expiry not enumerated_"
fi

say ""
say "---"
say "_End of inventory. This file is a source of truth: agents read it before doing work._"
