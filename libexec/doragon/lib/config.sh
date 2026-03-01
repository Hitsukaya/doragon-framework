#!/usr/bin/env bash
set -euo pipefail

DORAGON_CONF="${DORAGON_CONF:-/etc/doragon/doragon.conf}"

_doragon_load_one_file() {
  local f="$1"
  [[ -r "$f" ]] || return 0

  while IFS= read -r line || [[ -n "$line" ]]; do
    # strip comments (simple: everything after #)
    line="${line%%#*}"

    # trim leading/trailing whitespace (safe, no xargs)
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"

    [[ -z "$line" ]] && continue

    # accept only KEY=VALUE where KEY is A-Z0-9_
    if [[ "$line" =~ ^([A-Z0-9_]+)=(.*)$ ]]; then
      local key="${BASH_REMATCH[1]}"
      local val="${BASH_REMATCH[2]}"

      # trim whitespace around value
      val="${val#"${val%%[![:space:]]*}"}"
      val="${val%"${val##*[![:space:]]}"}"

      # remove surrounding quotes if present
      if [[ "$val" =~ ^\"(.*)\"$ ]]; then
        val="${BASH_REMATCH[1]}"
      elif [[ "$val" =~ ^\'(.*)\'$ ]]; then
        val="${BASH_REMATCH[1]}"
      fi

      # assign without eval (no command execution)
      printf -v "$key" '%s' "$val"
      export "$key"
    fi
  done < "$f"
}

doragon_load_config() {
  # 1) global
  _doragon_load_one_file "$DORAGON_CONF"

  # 2) sftp toggle config
  _doragon_load_one_file "/etc/doragon/sftp.conf"

  # 3) discord secret config
  _doragon_load_one_file "/etc/doragon/discord.conf"
}

doragon_print_header() {
  [[ "${DORAGON_HEADER_PRINTED:-0}" == "1" ]] && return 0
  DORAGON_HEADER_PRINTED=1

  local host date_str
  host="$(hostname_safe)"
  date_str="$(ts)"

  doragon_banner
  echo "${DORAGON_NAME:-unknown} version ${DORAGON_VERSION:-unknown} Date:${date_str} Host:${host} Profile:${DORAGON_PROFILE:-unknown}"
  doragon_description
  echo
}


doragon_version() {
   echo "${DORAGON_NAME:-unknown} version ${DORAGON_VERSION:-unknown}"
}

doragon_banner() {
cat <<'EOF'
    ____  ____  ____  ___   __________  _   __
   / __ \/ __ \/ __ \/   | / ____/ __ \/ | / /
  / / / / / / / /_/ / /| |/ / __/ / / /  |/ /
 / /_/ / /_/ / _, _/ ___ / /_/ / /_/ / /|  /
/_____/\____/_/ |_/_/  |_\____/\____/_/ |_/

EOF
}

doragon_description() {
cat <<'EOF'
STABILITY • SIMPLICITY • SECURE BY ARCHITECTURE

Doragon Framework is a lightweight, self-hosted deployment and
security framework for Linux VPS servers.
EOF
}
