#!/usr/bin/env bash
set -euo pipefail

# Reads /etc/doragon/sftp.conf if doragon_load_config exists (from config.sh)
_doragon_sftp_load_config() {
  if declare -F doragon_load_config >/dev/null 2>&1; then
    doragon_load_config || true
  fi
}

doragon_sftp_usage() {
  cat <<'USAGE'
SFTP toggle:
  doragon sftp on
  doragon sftp off
  doragon sftp status
  doragon sftp config --user <user> --target <path>

Config:
  Uses /etc/doragon/sftp.conf:
    DORAGON_SFTP_TARGET="/home/user/"
    DORAGON_SFTP_USER="user"

Overrides:
  You can still override via environment variables:
    DORAGON_SFTP_TARGET=/path
    DORAGON_SFTP_USER=user

Notes:
  - 'on/off/config' require root (Doragon will sudo automatically).
USAGE
}

_doragon_sftp_require_root() {
  if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" sftp "$@"
  fi
}

_doragon_sftp_target() {
  _doragon_sftp_load_config
  [[ -n "${DORAGON_SFTP_TARGET:-}" ]] || die "DORAGON_SFTP_TARGET not set. Run: doragon sftp config --user <user> --target <path>"
  echo "$DORAGON_SFTP_TARGET"
}

_doragon_sftp_user() {
  _doragon_sftp_load_config
  [[ -n "${DORAGON_SFTP_USER:-}" ]] || die "DORAGON_SFTP_USER not set. Run: doragon sftp config --user <user> --target <path>"
  echo "$DORAGON_SFTP_USER"
}

doragon_sftp_config_set() {
  local user="" target=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --user)   user="${2:-}"; shift 2;;
      --target) target="${2:-}"; shift 2;;
      -h|--help|"")
        die "Usage: doragon sftp config --user <user> --target <path>"
        ;;
      *)
        die "Unknown option: $1 (Usage: doragon sftp config --user <user> --target <path>)"
        ;;
    esac
  done

  [[ -z "$user" || -z "$target" ]] && die "Usage: doragon sftp config --user <user> --target <path>"

  _doragon_sftp_require_root config --user "$user" --target "$target"

  # safety checks (recommended)
  id "$user" >/dev/null 2>&1 || die "User does not exist: $user"
  [[ -d "$target" ]] || die "Target directory does not exist: $target"
  [[ "$target" != "/" ]] || die "Refusing to use '/' as target"
  [[ -n "$target" ]] || die "Target cannot be empty"

  mkdir -p /etc/doragon

  local conf="/etc/doragon/sftp.conf"
  local tmp
  tmp="$(mktemp)"

  # Backup if file exists
  if [[ -f "$conf" ]]; then
    cp -a "$conf" "${conf}.bak-$(date +%Y%m%d-%H%M%S)"
  else
    # create a minimal header if new
    cat > "$conf" <<'EOF'

EOF
  fi

  awk -v new_target="$target" -v new_user="$user" '
    BEGIN { found_target=0; found_user=0 }
    {
      if ($0 ~ /^[[:space:]]*DORAGON_SFTP_TARGET=/) { print "DORAGON_SFTP_TARGET=\"" new_target "\""; found_target=1; next }
      if ($0 ~ /^[[:space:]]*DORAGON_SFTP_USER=/)   { print "DORAGON_SFTP_USER=\"" new_user "\"";     found_user=1; next }
      print $0
    }
    END {
      if (!found_target || !found_user) {
        print ""
        print "# SFTP"
        if (!found_target) print "DORAGON_SFTP_TARGET=\"" new_target "\""
        if (!found_user)   print "DORAGON_SFTP_USER=\"" new_user "\""
      }
    }
  ' "$conf" > "$tmp"

  mv -f "$tmp" "$conf"
  chmod 0600 "$conf"

  ok "Saved SFTP config to /etc/doragon/sftp.conf (updated keys only)"
  info "DORAGON_SFTP_TARGET=${target}"
  info "DORAGON_SFTP_USER=${user}"
}

doragon_sftp_on() {
  _doragon_sftp_require_root on

  local target user
  target="$(_doragon_sftp_target)"
  user="$(_doragon_sftp_user)"

  info "[+] Enabling SFTP write access for ${user} on ${target}"
  setfacl -R -m "u:${user}:rwx" "$target"
  setfacl -R -d -m "u:${user}:rwx" "$target"
  ok "SFTP write access ENABLED"
}

doragon_sftp_off() {
  _doragon_sftp_require_root off

  local target user
  target="$(_doragon_sftp_target)"
  user="$(_doragon_sftp_user)"

  info "[-] Disabling SFTP write access for ${user} on ${target}"
  setfacl -R -x "u:${user}" "$target"
  setfacl -R -k "$target"
  ok "SFTP write access DISABLED"
}

doragon_sftp_status() {
  local target user
  target="$(_doragon_sftp_target)"
  user="$(_doragon_sftp_user)"

  section "SFTP ACL status"
  info "Target: ${target}"
  info "User:   ${user}"
  getfacl "$target" | head -n 60 || true

  section "SFTP CHECK"
  if getfacl "$target" 2>/dev/null | grep -q "user:${user}:rwx"; then
  info  "SFTP write access ENABLED for ${user}"
  else
  info "SFTP write access DISABLED for ${user}"
  fi

}

doragon_sftp_cmd() {
  local sub="${1:-}"
  shift || true

  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    info "Doragon SFTP module requires root privileges."
    info "SSH configuration can only be modified by root."
    info "Re-run with: sudo doragon sftp ${sub} $*"
    exit 2
  fi

  case "$sub" in
    on) doragon_sftp_on ;;
    off) doragon_sftp_off ;;
    status) doragon_sftp_status ;;
    config) doragon_sftp_config_set "$@" ;;
    -h|--help|"") doragon_sftp_usage ;;
    *)
      die "Unknown sftp command: $sub. Run: doragon sftp --help"
      ;;
  esac
}
