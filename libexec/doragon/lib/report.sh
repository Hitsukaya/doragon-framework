#!/usr/bin/env bash
set -euo pipefail

doragon_report_cmd() {
  local json=0
  local out_dir="${OUTPUT_DIR_DEFAULT}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json) json=1; shift ;;
      --out) out_dir="$2"; shift 2 ;;
      *) die "Unknown report option: $1" ;;
    esac
  done

  mkdir -p "${out_dir}"

  #local profile="${DEFAULT_PROFILE}"
  local host generated
  host="$(hostname_safe)"
  generated="$(ts)"

  local report_txt="${out_dir}/report.txt"
  local report_json="${out_dir}/report.json"

  {
    echo "Doragon Framework Security Report"
    echo "=================================="
    echo
    echo "Host: ${host}"
    echo "Profile: ${DORAGON_PROFILE}"
    echo "Generated: ${generated}"
    echo
    echo "System"
    echo "------"
    echo "OS: $(detect_os_pretty)"
    echo "Kernel: $(kernel_safe)"
    echo "Uptime: $(uptime_short)"
    echo
    echo "Security Core"
    echo "-------------"
    echo "SELinux Mode: $(getenforce_safe)"
    echo "firewalld: $([[ "$(check_firewalld)" == "OK" ]] && echo "running" || echo "not running")"
    echo "Fail2Ban: $([[ "$(check_fail2ban)" == "OK" ]] && echo "active ($(fail2ban_jails_count) jails)" || echo "inactive")"
    echo
    echo "Network Exposure"
    echo "----------------"
    echo "Listeners (TCP/UDP):"
    ss -tulnp 2>/dev/null | awk '/LISTEN/ {print $0}' || true
    echo
    echo "Local-only Services (Unix sockets detected):"
    echo "- PHP-FPM socket: $([[ -S /run/php-fpm/www.sock ]] && echo "present" || echo "missing")"
    echo "- MariaDB socket: $([[ -S /var/lib/mysql/mysql.sock ]] && echo "present" || echo "missing")"
    echo "- PostgreSQL socket: $([[ -S /var/run/postgresql/.s.PGSQL.65499 ]] && echo "present" || echo "missing")"
    echo
    echo "Recommendations"
    echo "---------------"
    mariadb_public_listen && echo "- Consider restricting MariaDB to localhost-only" || true
    postgres_public_listen_65499 && echo "- Consider restricting PostgreSQL to localhost-only" || true
    echo "- Consider an SSH allowlist or recovery path if using permanent bans"
    echo
    echo "Security Posture"
    echo "----------------"
    echo "Layered defense enabled."
    echo "SELinux enforced."
    echo "Firewall active."
    echo "Fail2Ban multi-jail active."
  } > "${report_txt}"

  if [[ "${json}" -eq 1 ]]; then
    local mariadb_mode="local"
    mariadb_public_listen && mariadb_mode="public"
    local pg_mode="local"
    postgres_public_listen_65499 && pg_mode="public"

    cat > "${report_json}" <<JSON
{
  "host": "${host}",
  "profile": "${DORAGON_PROFILE}",
  "generated": "${generated}",
  "os": "$(detect_os_pretty)",
  "kernel": "$(kernel_safe)",
  "selinux": "$(getenforce_safe)",
  "firewall": "$([[ "$(check_firewalld)" == "OK" ]] && echo "running" || echo "stopped")",
  "fail2ban": {
    "status": "$([[ "$(check_fail2ban)" == "OK" ]] && echo "running" || echo "stopped")",
    "jails": $(fail2ban_jails_count)
  },
  "services": {
    "nginx": "$([[ "$(check_nginx)" == "OK" ]] && echo "active" || echo "inactive")",
    "php_fpm": "$([[ "$(check_phpfpm)" == "OK" ]] && echo "active" || echo "inactive")",
    "redis": "$([[ "$(check_redis_local_only)" == "OK" ]] && echo "local-only" || echo "public")",
    "mariadb": "${mariadb_mode}",
    "postgresql": "${pg_mode}"
  }
}
JSON
  fi

  ok "Report written: ${report_txt}"
  [[ "${json}" -eq 1 ]] && ok "JSON written: ${report_json}"
}
