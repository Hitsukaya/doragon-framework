#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------------
# Doragon Discord module
#   - doragon discord send "<message>"
#   - doragon discord dashboard [--test|--force]
#   - doragon discord test
#   - doragon discord status
# ----------------------------------------------------------

doragon_discord_usage() {
  cat <<'USAGE'
Discord:
  doragon discord send "<message>"             # send simple message
  doragon discord dashboard [--test|--force]   # send server dashboard (only when changes unless --force)
  doragon discord test                         # sends a test message
  doragon discord status                       # shows webhook/config + systemd timer/service if present
  doragon discord config --webhook <url> [--cache-dir <path>]   # write /etc/doragon/discord.conf 

Config:
  /etc/doragon/discord.conf
    DORAGON_DISCORD_WEBHOOK="https://discord.com/api/webhooks/..."
    DORAGON_DISCORD_CACHE_DIR="/var/cache/doragon-discord"   (optional)
USAGE
}

_doragon_discord_sudo() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "sudo"
  else
    echo ""
  fi
}

doragon_discord_webhook() {
  echo "${DORAGON_DISCORD_WEBHOOK:-}"
}

doragon_discord_cache_dir() {
  echo "${DORAGON_DISCORD_CACHE_DIR:-/var/cache/doragon-discord}"
}

_doragon_json_escape() {
  # JSON escape string safely (no jq required)
  python3 - <<'PY' "$1"
import json,sys
print(json.dumps(sys.argv[1])[1:-1])
PY
}

doragon_discord_send() {
  local msg="${1:-}"
  [[ -z "$msg" ]] && die 'Usage: doragon discord send "<message>"'

  local webhook
  webhook="$(doragon_discord_webhook)"
  [[ -z "$webhook" ]] && die "DORAGON_DISCORD_WEBHOOK not configured in /etc/doragon/discord.conf"

  local esc
  esc="$(_doragon_json_escape "$msg")"

  curl -fsS -X POST \
    -H "Content-Type: application/json" \
    -d "{\"content\":\"${esc}\",\"allowed_mentions\":{\"parse\":[]}}" \
    "$webhook" >/dev/null

  ok "Discord message sent"
}

doragon_discord_test() {
  doragon_discord_send "✅ Doragon Discord test: OK ($(hostname) @ $(date '+%F %T'))"
}

doragon_discord_dashboard() {
  local force=0
  for a in "$@"; do
    [[ "$a" == "--test" || "$a" == "--force" ]] && force=1
  done

  local webhook
  webhook="$(doragon_discord_webhook)"
  [[ -z "$webhook" ]] && die "DORAGON_DISCORD_WEBHOOK not configured in /etc/doragon/discord.conf"

  local cache_dir
  cache_dir="$(doragon_discord_cache_dir)"
  local SUDO
  SUDO="$(_doragon_discord_sudo)"

  $SUDO mkdir -p "$cache_dir"

  # --- Metrics ---
  local uptime_info total_load mem_info disk_info web_conns fw_status selinux_mode
  uptime_info="$(uptime -p 2>/dev/null | sed 's/^up //')"
  total_load="$(cut -d ' ' -f1-3 /proc/loadavg 2>/dev/null || echo '-')"
  mem_info="$(free -h 2>/dev/null | awk '/^Mem:/ {gsub(/i/,"",$3); gsub(/i/,"",$2); print $3 " / " $2}' || echo '-')"
  disk_info="$(df -h / 2>/dev/null | awk 'NR==2{gsub(/i/,""); print "Used: "$3" | Available: "$4" ("$5")"}' || echo '-')"
  web_conns="$(ss -ant 2>/dev/null | awk '$1=="ESTAB" && ($4 ~ /:80$|:443$/ || $5 ~ /:80$|:443$/){c++} END{print c+0}')"
  fw_status="$(firewall-cmd --state 2>/dev/null || echo "inactive")"
  selinux_mode="$(getenforce 2>/dev/null || echo "N/A")"

  # --- Services (FIX: newline-uri reale, nu "\n") ---
  local critical_services=(sshd nginx fail2ban mariadb mysqld postgresql php-fpm redis)
  local svc_list=""
  local svc status
  for svc in "${critical_services[@]}"; do
    status="$(systemctl is-active "$svc" 2>/dev/null || echo "not-found")"
    svc_list+=$"**${svc^^}**: \`${status}\`"$'\n'
  done

  # --- Fail2ban jails (detect + cache bans) ---
  local tmp_json
  tmp_json="$(mktemp /tmp/doragon-f2b-XXXX.json)"
  local new_data=0

  local jails
  jails="$($SUDO fail2ban-client status 2>/dev/null | sed -n 's/.*Jail list:\s*//p' | tr ',' ' ' || true)"

  # default empty json
  echo "[]" >"$tmp_json"

  if [[ -n "${jails// }" ]]; then
    echo "[" >"$tmp_json"
    local first=1
    local jail current cache_file count ips

    for jail in $jails; do
      jail="$(echo "$jail" | xargs)"
      [[ -z "$jail" ]] && continue

      cache_file="${cache_dir}/fail2ban-${jail}.txt"
      current="$($SUDO fail2ban-client status "$jail" 2>/dev/null | sed -n 's/.*Banned IP list:\s*//p' | xargs || true)"

      if [[ "${force}" -eq 1 ]]; then
        new_data=1
      else
        if [[ ! -f "$cache_file" ]] || [[ "$(cat "$cache_file" 2>/dev/null || true)" != "$current" ]]; then
          new_data=1
        fi
      fi

      $SUDO bash -c "printf '%s' \"\$1\" > \"\$2\"" -- "$current" "$cache_file"

      count="$(wc -w <<<"$current" | awk '{print $1}')"
      ips="$(tr ' ' '|' <<<"$current")"

      [[ $first -eq 0 ]] && echo "," >>"$tmp_json"

      # JSON safe
      local jail_json ips_json
      jail_json="$(python3 - <<PY
import json
print(json.dumps("$jail"))
PY
)"
      ips_json="$(python3 - <<PY
import json
print(json.dumps("$ips"))
PY
)"
      echo "{\"name\": ${jail_json}, \"count\": ${count}, \"ips\": ${ips_json}}" >>"$tmp_json"
      first=0
    done
    echo "]" >>"$tmp_json"
  fi

  # SELinux AVC last 5 (today)
  local selinux_logs
  selinux_logs="$($SUDO ausearch -m avc -ts today 2>/dev/null | tail -n 5 || true)"
  [[ -z "$selinux_logs" ]] && selinux_logs="No security denials detected today."

  # Send only if changes or forced/test
  if [[ $new_data -eq 0 ]]; then
    info "No Fail2Ban changes detected (use --force to send anyway)."
    rm -f "$tmp_json"
    return 0
  fi

  local payload_file
  payload_file="$(mktemp /tmp/doragon-discord-XXXX.json)"

  python3 - <<'PY' \
    "$payload_file" "$tmp_json" \
    "$uptime_info" "$total_load" "$mem_info" "$disk_info" "$web_conns" \
    "$svc_list" "$fw_status" "$selinux_mode" "$selinux_logs"
import json,sys,datetime

out, f2b_json = sys.argv[1], sys.argv[2]
uptime_info, total_load, mem_info, disk_info, web_conns = sys.argv[3:8]
svc_list, fw_status, selinux_mode, selinux_logs = sys.argv[8:12]

try:
  with open(f2b_json,"r") as f:
    jails = json.load(f)
except Exception:
  jails = []

fields = [
  {
    "name":"💻 SYSTEM & RESOURCES",
    "value":(
      f"**Uptime:** {uptime_info}\n"
      f"**Load:** `{total_load}`\n"
      f"**RAM:** `{mem_info}`\n"
      f"**Disk:** `{disk_info}`\n"
      f"**Web Traffic:** `{web_conns} active`\n"
      "━━━━━━━━━━━━━━━━━━"
    ),
    "inline":False
  },
  {
    "name":"⚙️ SERVICES & SECURITY",
    "value":(
      f"{svc_list}\n"
      f"**Firewall:** `{fw_status.upper()}` | **SELinux:** `{selinux_mode}`\n"
      "━━━━━━━━━━━━━━━━━━"
    ),
    "inline":False
  }
]

for j in jails:
  name = str(j.get("name","?")).upper()
  count = int(j.get("count",0))
  ips = (j.get("ips","") or "")
  if count > 0:
    display_ips = ips[:400] + ("..." if len(ips) > 400 else "")
    fields.append({
      "name":f"🛡️ JAIL: {name} ({count} IPs)",
      "value":f"```\n{display_ips}\n```",
      "inline":False
    })
  else:
    fields.append({"name":f"🛡️ JAIL: {name}","value":"`No active bans`","inline":False})

fields.append({"name":"🛡️ SELINUX AUDIT","value":f"```\n{selinux_logs[:800]}\n```","inline":False})

payload = {
  "allowed_mentions":{"parse":[]},
  "embeds":[{
    "title":"⚔️ DORAGON | STATUS SERVER",
    "color":3447003,
    "fields":fields,
    "footer":{"text":f"Hitsukaya Core • {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"}
  }]
}

with open(out,"w") as f:
  json.dump(payload,f)
PY

  curl -fsS -X POST -H "Content-Type: application/json" --data @"$payload_file" "$webhook" >/dev/null
  ok "Discord dashboard sent"

  rm -f "$tmp_json" "$payload_file"
}

_doragon_discord_require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    exec sudo "$0" discord "$@"
  fi
}

doragon_discord_config_set() {
  local webhook="" cache_dir=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --webhook)   webhook="${2:-}"; shift 2;;
      --cache-dir) cache_dir="${2:-}"; shift 2;;
      -h|--help|"")
        die "Usage: doragon discord config --webhook <url> [--cache-dir <path>]"
        ;;
      *)
        die "Unknown option: $1 (Usage: doragon discord config --webhook <url> [--cache-dir <path>])"
        ;;
    esac
  done

  [[ -z "$webhook" ]] && die "Usage: doragon discord config --webhook <url> [--cache-dir <path>]"

  # escalate
  _doragon_discord_require_root config --webhook "$webhook" ${cache_dir:+--cache-dir "$cache_dir"}

  # basic validation
  [[ "$webhook" == https://discord.com/api/webhooks/* ]] || \
    die "Invalid webhook. Expected: https://discord.com/api/webhooks/..."

  if [[ -n "$cache_dir" ]]; then
    [[ "$cache_dir" == /* ]] || die "--cache-dir must be an absolute path"
  else
    cache_dir="/var/cache/doragon-discord"
  fi

  mkdir -p /etc/doragon

  local conf="/etc/doragon/discord.conf"
  if [[ -f "$conf" ]]; then
    cp -a "$conf" "${conf}.bak-$(date +%Y%m%d-%H%M%S)"
  fi

  cat > "$conf" <<EOF
# Doragon Discord config (SECRET)

DORAGON_DISCORD_WEBHOOK="${webhook}"
DORAGON_DISCORD_CACHE_DIR="${cache_dir}"
EOF

  chown root:root "$conf"
  chmod 0600 "$conf"

  ok "Saved Discord config to /etc/doragon/discord.conf"
  info "Cache dir: ${cache_dir}"
}

doragon_discord_status() {
  local webhook
  webhook="$(doragon_discord_webhook)"

  echo "Discord status"
  echo "-------------"

 # if [[ -n "$webhook" ]]; then
 #   ok "Webhook: configured"
 # else
 #   warn "Webhook: NOT configured (set DORAGON_DISCORD_WEBHOOK in /etc/doragon/discord.conf)"
 # fi

  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    warn "Webhook: root-only (run with sudo to verify)"
  else
    if [[ -n "$webhook" ]]; then
      ok "Webhook: configured"
    else
      warn "Webhook: NOT configured"
    fi
  fi

  local cache_dir
  cache_dir="$(doragon_discord_cache_dir)"
  info "Cache dir: $cache_dir"

  systemctl status fail2ban-discord.timer 2>/dev/null | head -n 25 || true
}

doragon_discord_cmd() {
  local sub="${1:-}"
  shift || true

  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "[INFO] Discord integration uses a root-only secret in /etc/doragon/discord.conf"
    echo "[INFO] Re-run with sudo: sudo doragon discord ${sub} $*"
    exit 2
  fi

  case "$sub" in
    send) doragon_discord_send "$@" ;;
    dashboard) doragon_discord_dashboard "$@" ;;
    test) doragon_discord_test ;;
    status) doragon_discord_status ;;
    config) doragon_discord_config_set "$@" ;;
    -h|--help|"") doragon_discord_usage ;;
    *) die "Unknown discord command: $sub. Run: doragon discord --help" ;;
  esac
}
