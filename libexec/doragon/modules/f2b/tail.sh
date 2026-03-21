doragon_f2b_tail() {
  local SUDO=""
  [[ "${EUID}" -ne 0 ]] && SUDO="sudo"

  section "TAIL Doragon Fail2Ban LOG (Ctrl+C to stop)"
  ${SUDO} tail -f /var/log/fail2ban.log
}

