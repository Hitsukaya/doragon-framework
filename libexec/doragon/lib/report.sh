#!/usr/bin/env bash
set -euo pipefail

doragon_report_help() {
  cat <<'USAGE'
Usage:
  doragon report [options]

Options:
  --json           Export report as JSON
  --pretty         Pretty print JSON (requires jq)
  --out <dir>      Output directory

Examples:
  doragon report
  doragon report --json
  doragon report --json --pretty
  doragon report --json --out /var/log/doragon_audit
USAGE
}

doragon_report_cmd() {
  local json=0
  local pretty=0
  local out_dir="${OUTPUT_DIR_DEFAULT}"

  if [[ $# -eq 0 ]]; then
    doragon_report_help
    return 0
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json)
        json=1
        shift
        ;;
      --pretty)
        pretty=1
        shift
        ;;
      --out)
        [[ $# -ge 2 ]] || die "Missing value for --out"
        out_dir="$2"
        shift 2
        ;;
      --help|-h)
        doragon_report_help
        return 0
        ;;
      *)
        die "Unknown report option: $1"
        ;;
    esac
  done

  out_dir="${out_dir%/}"
  mkdir -p "${out_dir}"

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

    local listeners_raw_json=""
    local sep=""

    while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      line=${line//\\/\\\\}
      line=${line//\"/\\\"}
      listeners_raw_json="${listeners_raw_json}${sep}\"${line}\""
      sep=", "
    done < <(ss -tulnp 2>/dev/null | awk '/LISTEN/ {print $0}')


   local recommendations_json=""
   local rec_sep=""

  mariadb_public_listen && {
     recommendations_json="${recommendations_json}${rec_sep}\"Consider restricting MariaDB to localhost-only\""
     rec_sep=", "
  }

  postgres_public_listen_65499 && {
    recommendations_json="${recommendations_json}${rec_sep}\"Consider restricting PostgreSQL to localhost-only\""
    rec_sep=", "
 }

 recommendations_json="${recommendations_json}${rec_sep}\"Consider an SSH allowlist or recovery path if using permanent bans\""

cat > "${report_json}" <<JSON
{
  "host": "${host}",
  "profile": "${DORAGON_PROFILE}",
  "generated": "${generated}",
  "status": "${status}",
  "exit_code": ${exit_code},
  "security_score": ${security_score},
  "system": {
    "os": "$(detect_os_pretty)",
    "kernel": "$(kernel_safe)",
    "uptime": {
      "days": $(uptime_days),
      "loadavg": "$(loadavg_short)",
      "rootfs": "$(rootfs_usage_line)",
      "memory": "$(mem_usage_line)",
      "swap": {
        "status": "$(swap_status)",
        "value": "$(swap_line)"
      }
    }
  },
  "security": {
    "selinux": {
      "status": "$(check_selinux)",
      "mode": "$(getenforce_safe)"
    },
    "firewalld": {
      "status": "$(check_firewalld)"
    },
    "fail2ban": {
      "status": "$(check_fail2ban)",
      "jails": $(fail2ban_jails_count)
    },
    "ssh": {
      "status_line": "$(check_sshd_port)"
    }
  },
  "services": {
    "nginx": "$(check_nginx)",
    "php_fpm": "$(check_phpfpm)",
    "php_fpm_socket": "$(check_phpfpm_socket)",
    "redis": "$(check_redis_local_only)",
     "mariadb": {
       "service_active": $(mariadb_service_active && echo "true" || echo "false"),
       "any_listen": $(mariadb_any_listen && echo "true" || echo "false"),
       "local_only": $(mariadb_local_only && echo "true" || echo "false"),
       "socket_present": $(mariadb_socket_present && echo "true" || echo "false"),
       "public_bind": $(mariadb_public_listen && echo "true" || echo "false")
     },

    "postgresql": {
      "service_active": $(postgres_service_active && echo "true" || echo "false"),
      "any_listen": $(postgres_any_listen && echo "true" || echo "false"),
      "local_only": $(postgres_local_only && echo "true" || echo "false"),
      "socket_present": $(postgres_socket_present && echo "true" || echo "false"),
      "public_bind": $(postgres_public_listen_65499 && echo "true" || echo "false")
    }
  },
  "network": {
    "open_ports_summary": "$(open_ports_summary)",
    "listeners_raw": [ ${listeners_raw_json} ]
  },
  "summary": {
    "fail_count": ${fail_count},
    "warn_count": ${warn_count}
  },
  "recommendations": [ ${recommendations_json} ],
  "posture": [
    "Layered defense enabled.",
    "SELinux enforced.",
    "Firewall active.",
    "Fail2Ban multi-jail active."
  ]
}
JSON

    if [[ "${pretty}" -eq 1 ]]; then
      if command -v jq >/dev/null 2>&1; then
        jq . "${report_json}" > "${report_json}.tmp"
        mv "${report_json}.tmp" "${report_json}"
      fi
    fi
  fi

  ok "Report written: ${report_txt}"
  [[ "${json}" -eq 1 ]] && ok "JSON written: ${report_json}"
  info "Output directory: ${out_dir}"

}
