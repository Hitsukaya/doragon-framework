doragon_f2b_status() {
  local one_jail="${1:-}"

  local SUDO=""
  [[ "${EUID}" -ne 0 ]] && SUDO="sudo"

  command -v fail2ban-client >/dev/null 2>&1 || { warn "Doragon: Fail2Ban not installed."; return 1; }

  section "Doragon Fail2ban Status"

  if [[ -n "${one_jail}" ]]; then
    ${SUDO} fail2ban-client status "${one_jail}" || warn "Jail '${one_jail}' not found or not running."
    return 0
  fi

  ${SUDO} fail2ban-client status || true
  echo

  local jails=""
  jails="$(doragon_f2b_list_jails "${SUDO}" || true)"

  if [[ -n "${jails}" ]]; then
    local jail
    for jail in ${jails}; do
      section "${jail}"
      ${SUDO} fail2ban-client status "${jail}" || warn "Jail '${jail}' not found or not running."
      echo
    done
    return 0
  fi

  local jail
  for jail in "${DORAGON_F2B_JAILS_DEFAULT[@]}"; do
    section "${jail}"
    ${SUDO} fail2ban-client status "${jail}" || warn "Jail '${jail}' not found or not running."
    echo
  done
}

