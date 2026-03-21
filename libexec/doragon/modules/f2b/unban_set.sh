doragon_f2b_unban_set() {
  local name="${1:-}"
  local ip="${2:-}"

  [[ -z "$name" || -z "$ip" ]] && { echo "[ERR] Usage: doragon f2b unban-set <set|jail> <IP>" >&2; return 2; }

  doragon_f2b_is_ipv4 "$ip" || { echo "[ERR] Invalid IPv4: $ip" >&2; return 2; }
  command -v ipset >/dev/null 2>&1 || { echo "[ERR] ipset not installed." >&2; return 1; }

  local SUDO=""
  [[ "${EUID:-$(id -u)}" -ne 0 ]] && SUDO="sudo"

  local set_name
  set_name="$(doragon_f2b_setname_norm "$name")" || { echo "[ERR] Invalid set/jail name." >&2; return 2; }

  $SUDO ipset list "$set_name" >/dev/null 2>&1 || { echo "[ERR] ipset '$set_name' does not exist." >&2; return 1; }
  $SUDO ipset test "$set_name" "$ip" >/dev/null 2>&1 || { echo "[WARN] IP $ip not found in set '$set_name'."; return 0; }

  $SUDO ipset del "$set_name" "$ip"
  info "[OK] Removed $ip from ipset '$set_name'"
}
