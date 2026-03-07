doragon_f2b_last_bans() {
  local n="${1:-5}"
  local SUDO=""
  [[ "${EUID}" -ne 0 ]] && SUDO="sudo"

  section "===== Last ${n} Doragon F2B Bans ====="
  ${SUDO} grep -E " Ban " /var/log/fail2ban.log 2>/dev/null | tail -n "${n}" \
    || warn "No bans found or /var/log/fail2ban.log not readable."
}
