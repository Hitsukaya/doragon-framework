#!/usr/bin/env bash
set -euo pipefail

check_selinux() {
  local mode
  mode="$(getenforce_safe)"
  if [[ "${mode}" == "Enforcing" ]]; then
    echo "OK"
  elif [[ "${mode}" == "Permissive" || "${mode}" == "Disabled" ]]; then
    echo "FAIL"
  else
    echo "WARN"
  fi
}

check_firewalld() {
  if service_active firewalld; then echo "OK"; else echo "FAIL"; fi
}

check_fail2ban() {
  if service_active fail2ban; then echo "OK"; else echo "WARN"; fi
}

fail2ban_jails_count() {
  command -v fail2ban-client >/dev/null 2>&1 || { echo "0"; return 0; }

  fail2ban-client status 2>/dev/null \
    | awk -F: '/Number of jail/ {
        v=$2
        gsub(/^[ \t]+|[ \t]+$/, "", v)
        print v
        exit
      }' || echo "0"
}


detect_sshd_port_config() {
  # Returns first configured Port from effective sshd config.
  # Fallback: 22
  local sshd_bin="/usr/sbin/sshd"
  command -v sshd >/dev/null 2>&1 && sshd_bin="$(command -v sshd)"

  if [[ -x "$sshd_bin" ]]; then
    local ports
    ports="$("$sshd_bin" -T -C user=root,host=localhost,addr=127.0.0.1 2>/dev/null \
      | awk '$1=="port"{print $2}')"

    if [[ -n "${ports:-}" ]]; then
      echo "$ports" | head -n 1
      return 0
    fi
  fi

  echo "22"
}

detect_sshd_ports_runtime() {
  # Returns unique runtime ports (one per line) where sshd is LISTEN-ing.
  # Output can be empty if sshd not running.
  ss -tulnp 2>/dev/null | awk '
    $1=="tcp" && $2=="LISTEN" && $NF ~ /"sshd"/ {
      # local address in column 5: 0.0.0.0:2607 or [::]:2607
      gsub(/^\[/,"",$5); gsub(/\]$/,"",$5);
      n=split($5,a,":");
      print a[n];
    }' | awk 'NF' | sort -u
}

check_sshd_port() {
  local cfg_port runtime_ports permitrootlogin ports_joined

  cfg_port="$(detect_sshd_port_config 2>/dev/null || echo "22")"
  runtime_ports="$(detect_sshd_ports_runtime 2>/dev/null || true)"
  permitrootlogin="$(detect_sshd_option permitrootlogin 2>/dev/null || true)"
   [[ -n "${permitrootlogin:-}" ]] || permitrootlogin="unknown"

  if [[ -z "${runtime_ports:-}" ]]; then
    printf 'SSHD not listening (configured=%s) (PermitRootLogin=%s)\n' "$cfg_port" "$permitrootlogin"
    return 1
  fi

  if printf '%s\n' "$runtime_ports" | grep -qx "$cfg_port"; then
    printf 'SSH Port: %s (PermitRootLogin=%s)\n' "$cfg_port" "$permitrootlogin"
    return 0
  fi

  ports_joined="$(printf '%s\n' "$runtime_ports" | paste -sd, -)"
  printf 'SSH Port mismatch: configured=%s, listening=%s (PermitRootLogin=%s)\n' "$cfg_port" "$ports_joined" "$permitrootlogin"
  return 1

}

detect_sshd_option() {
  local opt="$1"
  local user sshd_bin
  user="$(id -un)"
  local sshd_bin
  sshd_bin="$(command -v sshd 2>/dev/null || echo /usr/sbin/sshd)"

  "$sshd_bin" -T -C "user=${user},host=localhost,addr=127.0.0.1" 2>/dev/null \
    | awk -v o="$opt" '$1==o{print $2; exit}'
}


check_nginx() {
  if service_active nginx; then echo "OK"; else echo "WARN"; fi
}

check_phpfpm() {
  if service_active php-fpm; then echo "OK"; else echo "WARN"; fi
}

check_phpfpm_socket() {
  local sock="/run/php-fpm/www.sock"
  [[ -S "${sock}" ]] && echo "OK" || echo "WARN"
}

check_redis_local_only() {
  if ! ss -tulnp 2>/dev/null | grep -qE 'redis-server'; then
    echo "OK"
    return 0
  fi
  if ss -tulnp 2>/dev/null | grep -qE '127\.0\.0\.1:6379.*redis-server|\[::1\]:6379.*redis-server|::1:6379.*redis-server'; then
    echo "OK"
  else
    echo "WARN"
  fi
}

mariadb_service_active() {
  systemctl is-active --quiet mariadb 2>/dev/null
}

mariadb_any_listen() {
  ss -H -tulnp 2>/dev/null | grep -qE 'LISTEN.*:3306.*(mariadbd|mysqld)'
}

mariadb_local_only() {
  ss -H -tulnp 2>/dev/null | grep -qE 'LISTEN.*(127\.0\.0\.1:3306|\[::1\]:3306).*(mariadbd|mysqld)'
}

mariadb_socket_present() {
  [[ -S /var/lib/mysql/mysql.sock ]]
}

maridb_public_listen() {
  is_port_public_bind 3306
}

postgres_service_active() {
  systemctl is-active --quiet postgresql 2>/dev/null && return 0
  systemctl is-active --quiet postgresql-15 2>/dev/null && return 0
  systemctl is-active --quiet postgresql-16 2>/dev/null && return 0
  return 1
}

postgres_any_listen() {
  ss -tulnp 2>/dev/null | grep -qE 'LISTEN.*:65499.*(postmaster|postgres)'
}

postgres_local_only() {
  ss -H -tulnp 2>/dev/null | grep -qE 'LISTEN.*(127\.0\.0\.1:65499|\[::1\]:65499).*(postmaster|postgres)'
}

postgres_socket_present() {
  [[ -S /var/run/postgresql/.s.PGSQL.65499 ]]
}

postgres_public_listen_65499() {
  is_port_public_bind 65499
}


is_port_public_bind() {
  # $1 = port
  local port="$1"
  ss -tuln 2>/dev/null | awk -v p=":$port" '
    $1 ~ /^tcp/ && $2=="LISTEN" && $5 ~ p"$" {
      if ($5 ~ /^0\.0\.0\.0/ || $5 ~ /^\[::\]/) { found=1 }
    }
    END{ exit(found?0:1) }
  '
}

open_ports_summary() {
  local ports=()
  local ssh_ports

  ss -tulnp 2>/dev/null | grep -qE 'LISTEN.*:80.*nginx'  && ports+=("80")
  ss -tulnp 2>/dev/null | grep -qE 'LISTEN.*:443.*nginx' && ports+=("443")

  ssh_ports="$(detect_sshd_ports_runtime || true)"
  if [[ -n "${ssh_ports:-}" ]]; then
    while IFS= read -r p; do
      [[ -n "$p" ]] && ports+=("$p")
    done <<< "$ssh_ports"
  fi

#  ((${#ports[@]}==0)) && echo "-" || (IFS=", "; echo "${ports[*]}")

  if ((${#ports[@]}==0)); then
    echo "-"
  else
    printf "%s\n" "${ports[@]}" | sort -n | uniq | paste -sd, -
  fi
}

# ---------------- Resources (read-only) ----------------

uptime_days() {
  awk '{printf "%d", ($1/86400)}' /proc/uptime 2>/dev/null || echo "0"
}

loadavg_short() {
  awk '{print $1" "$2" "$3}' /proc/loadavg 2>/dev/null || echo "unknown"
}

rootfs_usage_line() {
  df -hP / 2>/dev/null | awk 'NR==2{print $5" used, "$4" free"}' || echo "unknown"
}

mem_usage_line() {
  free -h 2>/dev/null | awk '$1=="Mem:"{print "used "$3" / total "$2" (avail "$7")"; exit 0}' || echo "unknown"
}

swap_line() {
  local total
  total="$(free -b 2>/dev/null | awk '$1=="Swap:"{print $2; exit 0}' || echo 0)"
  total="${total:-0}"
  if [[ "$total" =~ ^[0-9]+$ ]] && (( total > 0 )); then
    free -h 2>/dev/null | awk '$1=="Swap:"{print "enabled "$2; exit 0}' || echo "enabled"
  else
    echo "disabled"
  fi
}

swap_status() {
  # returns OK if enabled, WARN if disabled
  local total
  total="$(free -b 2>/dev/null | awk '$1=="Swap:"{print $2; exit 0}' || echo 0)"
  total="${total:-0}"
  if [[ "$total" =~ ^[0-9]+$ ]] && (( total > 0 )); then
    echo "OK"
  else
    echo "WARN"
  fi
}
