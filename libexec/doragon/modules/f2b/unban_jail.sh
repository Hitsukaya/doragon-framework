doragon_f2b_unban_jail() {
  local jail="${1:-}"
  local ip="${2:-}"
  [[ -z "$jail" || -z "$ip" ]] && die "Usage: doragon f2b unban-jail <jail> <IP>"

  doragon_require_root "unban-jail $jail $ip"
  doragon_f2b_is_ipv4 "$ip" || die "Invalid IPv4: $ip"
  command -v fail2ban-client >/dev/null 2>&1 || die "fail2ban-client not found."

  fail2ban-client set "$jail" unbanip "$ip" >/dev/null 2>&1 \
    && ok "Unbanned $ip in jail '$jail'" \
    || warn "Failed (jail missing? ip not banned?)"
}
