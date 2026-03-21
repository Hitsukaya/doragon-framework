doragon_f2b_unban_global() {
  local ip="${1:-}"
  [[ -z "$ip" ]] && die "Usage: doragon f2b unban <IP>"

  doragon_require_root "unban $ip"
  doragon_f2b_is_ipv4 "$ip" || die "Invalid IPv4: $ip"
  command -v fail2ban-client >/dev/null 2>&1 || die "fail2ban-client not found."

  local SUDO=""
  [[ "${EUID}" -ne 0 ]] && SUDO="sudo"

  ${SUDO} fail2ban-client unban "$ip" >/dev/null 2>&1 || true
  ok "Unbanned $ip (global) via fail2ban-client"
}
