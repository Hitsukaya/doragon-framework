#!/usr/bin/env bash
set -euo pipefail

doragon_status() {
  echo

  info "STATUS"
  info ""

  ok "Uptime: $(uptime_days) days"
  ok "Load Avg (1/5/15): $(loadavg_short)"
  ok "Disk /: $(rootfs_usage_line)"
  ok "Memory: $(mem_usage_line)"

  if [[ "$(swap_status)" == "OK" ]]; then
    ok "Swap: $(swap_line)"
  else
    warn "Swap: $(swap_line)"
  fi

  echo

  local os_ok=1
  if is_almalinux_9; then
    ok "OS Detected: $(detect_os_pretty)"
  else
    fail "OS Detected: $(detect_os_pretty) (supported: AlmaLinux 9.x)"
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
    OK) ok "firewalld: running" ;;
    *)  fail "firewalld: NOT running" ;;
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
     warn_count=$((warn_count+1))
  fi

  [[ "$(check_nginx)" == "OK" ]] && ok "Nginx: active" || warn "Nginx: not active"
  [[ "$(check_phpfpm)" == "OK" ]] && ok "PHP-FPM: active (unix socket detected)" || warn "PHP-FPM: not active"
  [[ "$(check_phpfpm_socket)" == "OK" ]] || warn "PHP-FPM socket missing (/run/php-fpm/www.sock)"
  [[ "$(check_redis_local_only)" == "OK" ]] && ok "Redis: local-only (127.0.0.1)" || warn "Redis: not local-only"
  echo

  local warn_count=0
  local fail_count=0

  if mariadb_service_active; then
    if mariadb_any_listen; then
      if mariadb_local_only; then
        ok "MariaDB: localhost-only (3306)"
      else
        warn "MariaDB: listening on public interface (recommended: localhost-only)"
        warn_count=$((warn_count+1))
      fi
    else
      if mariadb_socket_present; then
        ok "MariaDB: socket-only (mysql.sock)"
      else
        warn "MariaDB: running, but no listener/socket detected"
        warn_count=$((warn_count+1))
      fi
    fi
   else
    info "MariaDB: not running"
  fi

 if postgres_service_active; then
   if postgres_any_listen; then
     if postgres_local_only; then
       ok "PostgreSQL: localhost-only (65499)"
     else
       warn "PostgreSQL: listening on public interface (recommended: localhost-only)"
       warn_count=$((warn_count+1))
     fi
   else
     if postgres_socket_present; then
       ok "PostgreSQL: socket-only (.s.PGSQL.65499)"
     else
       warn "PostgreSQL: running, but no listener/socket detected"
       warn_count=$((warn_count+1))
     fi
   fi
 else
   info "PostgreSQL: not running"
 fi

  echo
  ok "Open Ports: $(open_ports_summary)"

  local score=100
  [[ "$(check_selinux)" != "OK" ]] && score=$((score-15))
  [[ "$(check_firewalld)" != "OK" ]] && score=$((score-20))
  [[ "$(check_fail2ban)" != "OK" ]] && score=$((score-10))
  ((warn_count>=1)) && score=$((score-5))

  ((score<0)) && score=0

  echo
  echo "Security Score: ${score} / 100"

  local status="OK"
  local exit_code=0
  if ((fail_count>0)); then
    status="FAIL"
    exit_code=2
  elif ((warn_count>0)) || [[ "${os_ok}" -eq 0 ]]; then
    status="WARN (non-critical adjustments recommended)"
    exit_code=1
  fi

  echo "Status: ${status}"
  echo "Exit Code: ${exit_code}"
  exit "${exit_code}"
}
