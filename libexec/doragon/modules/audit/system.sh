doragon_audit_system(){
  section "SYSTEM"
  local os_ok=1
  if is_almalinux_9; then
    ok "OS Detected: $(detect_os_pretty)"
  else
    fail "OS Detected: $(detect_os_pretty) (supported: RHEL / AlmaLinux 9.x / Planned support FreeBSD)"
    os_ok=0
  fi

  local selinux_mode
  selinux_mode="$(getenforce_safe)"
  case "$(check_selinux)" in
    OK)   ok "SELinux Mode: ${selinux_mode}" ;;
    WARN) warn "SELinux Mode: ${selinux_mode}" ;;
    FAIL) fail "SELinux Mode: ${selinux_mode}" ;;
  esac

  case "$(check_firewalld)" in
    OK) ok "Firewalld: running" ;;
    *)  fail "Firewalld: NOT running" ;;
  esac

  local jails
  jails="$(fail2ban_jails_count)"
  case "$(check_fail2ban)" in
    OK) ok "Fail2Ban: running (${jails} jails active)" ;;
    *)  warn "Fail2Ban: not running / not installed" ;;
  esac

  local ssh
  if ssh="$(check_sshd_port)"; then
     ok "$ssh"
  else
     warn "$ssh"
  fi

  local tls
  local tls_ports
  tls_ports="$(detect_tls_ports_config | paste -sd ',' -)"
  case "$(check_tls)" in
    OK)  ok "TLS Port: ${tls_ports}" ;;
    WARN) warn "TLS: Not running & not listening" ;;
  esac

  if [[ "$(swap_status)" == "OK" ]]; then
    ok "Swap: $(swap_line)"
  else
    warn "Swap: $(swap_line)"
  fi

  [[ "$(check_nginx)" == "OK" ]] && ok "Nginx: active" || warn "Nginx: not active"
  [[ "$(check_phpfpm)" == "OK" ]] && ok "PHP-FPM: active (unix socket detected)" || warn "PHP-FPM: not active"
  [[ "$(check_phpfpm_socket)" == "OK" ]] || warn "PHP-FPM socket missing (/run/php-fpm/www.sock)"
  [[ "$(check_redis_local_only)" == "OK" ]] && ok "Redis: local-only (127.0.0.1)" || warn "Redis: not local-only"
}
