doragon_f2b_nginx_errors() {
  local n="${1:-10}"
  local SUDO=""
  [[ "${EUID}" -ne 0 ]] && SUDO="sudo"

  echo "===== Last ${n} Doragon Nginx Errors ====="
  ${SUDO} tail -n "${n}" /var/log/nginx/error.log 2>/dev/null || warn "nginx error log not readable."
}
