# Prefer the real user, not root (when running via sudo)
detect_effective_user() {
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    echo "${SUDO_USER}"
  else
    echo "${USER:-root}"
  fi
}

# Detect effective sshd config (Includes + defaults + Match blocks via -C)
detect_sshd_option() {
  local opt="$1"
  local ctx_user="${2:-$(detect_effective_user)}"

  local sshd_bin
  sshd_bin="$(command -v sshd 2>/dev/null || echo /usr/sbin/sshd)"

  # NOTE:
  # - sshd -T should be run with sudo to read full config reliably
  # - -C user=... matters when you have "Match User ..."
  sudo -n "$sshd_bin" -T -C "user=${ctx_user},host=localhost,addr=127.0.0.1" 2>/dev/null \
    | awk -v o="$opt" '$1==o{print $2; exit}'
}

detect_sshd_ports_runtime() {
  ss -tulnp 2>/dev/null \
    | awk '/LISTEN/ && /sshd/ {print $5}' \
    | awk -F: '{print $NF}' \
    | sort -n | uniq
}

doragon_audit_ssh() {
  local ctx_user
  ctx_user="$(detect_effective_user)"

  # ports runtime
  local ports_runtime
  ports_runtime="$(detect_sshd_ports_runtime | paste -sd, -)"
  [[ -z "$ports_runtime" ]] && ports_runtime="?"

  section "SSH"
  info "Ports (runtime): ${ports_runtime}"
  info "Context user: ${ctx_user}"
  echo

  # Read options for USER context (important with Match User)
  local permit_root password_auth pubkey_auth max_auth login_grace
  permit_root="$(detect_sshd_option permitrootlogin "${ctx_user}" || true)"
  password_auth="$(detect_sshd_option passwordauthentication "${ctx_user}" || true)"
  pubkey_auth="$(detect_sshd_option pubkeyauthentication "${ctx_user}" || true)"
  max_auth="$(detect_sshd_option maxauthtries "${ctx_user}" || true)"
  login_grace="$(detect_sshd_option logingracetime "${ctx_user}" || true)"

  # Also read GLOBAL context (root) so you can see overrides clearly
  local password_auth_global
  password_auth_global="$(detect_sshd_option passwordauthentication root || true)"

  # PermitRootLogin (user ctx)
  [[ "${permit_root}" == "no" ]] \
    && ok "PermitRootLogin (user ctx): no" \
    || warn "PermitRootLogin (user ctx): ${permit_root:-unknown}"

  # PasswordAuthentication (user ctx)
  [[ "${password_auth}" == "no" ]] \
    && ok "PasswordAuthentication (user ctx): no" \
    || warn "PasswordAuthentication (user ctx): ${password_auth:-unknown}"

  # show global/root ctx too (helps debug cloud-init overrides)
  info "PasswordAuthentication (global/root ctx): ${password_auth_global:-unknown}"

  # PubkeyAuthentication (user ctx)
  [[ "${pubkey_auth}" == "yes" ]] \
    && ok "PubkeyAuthentication (user ctx): yes" \
    || warn "PubkeyAuthentication (user ctx): ${pubkey_auth:-unknown}"

  # MaxAuthTries (user ctx)
  if [[ -n "${max_auth}" && "${max_auth}" =~ ^[0-9]+$ && "${max_auth}" -le 6 ]]; then
    ok "MaxAuthTries (user ctx): ${max_auth}"
  else
    warn "MaxAuthTries (user ctx): ${max_auth:-unknown}"
  fi

  # LoginGraceTime (user ctx)
  [[ -n "${login_grace}" ]] \
    && info "LoginGraceTime (user ctx): ${login_grace}" \
    || warn "LoginGraceTime (user ctx): unknown"
}
