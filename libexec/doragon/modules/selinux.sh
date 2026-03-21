#!/usr/bin/env bash
set -euo pipefail

require_cmd() {
  local c="$1"
  command -v "$c" >/dev/null 2>&1 || die "Missing command: $c"
}

selinux_mode() {
  if command -v getenforce >/dev/null 2>&1; then
    getenforce 2>/dev/null || echo "unknown"
  else
    echo "unknown"
  fi
}

# ------- AVC actions -------

doragon_selinux_avc_today() {
  require_cmd ausearch

  section "SELinux AVC (today)"
  info "SELinux Mode: $(selinux_mode)"

  if ! sudo ausearch -m avc -ts today >/dev/null 2>&1; then
    ok "No AVC messages found today (or audit not accessible)."
    return 0
  fi

  sudo ausearch -m avc -ts today || true
}

doragon_selinux_avc_count_today() {
  require_cmd ausearch

  local n
  n="$(sudo ausearch -m avc -ts today 2>/dev/null | grep -c "type=AVC" || true)"
  echo "${n}"
}

doragon_selinux_avc_summary_today() {
  require_cmd aureport

  section "SELinux AVC summary (today)"
  info "SELinux Mode: $(selinux_mode)"

  if ! sudo ausearch -m avc -ts today >/dev/null 2>&1; then
    ok "No AVC messages found today (or audit not accessible)."
    return 0
  fi

  sudo ausearch -m avc -ts today | sudo aureport -f || true
}

doragon_selinux_avc_grep_today() {
  require_cmd ausearch
  local pattern="${1:-}"
  [[ -z "$pattern" ]] && die "Usage: doragon selinux avc grep <pattern>"

  sudo ausearch -m avc -ts today 2>/dev/null | grep -i --color=auto "$pattern" || true
}

doragon_selinux_avc_services_today() {
  require_cmd ausearch

  section "SELinux AVC by common services (today)"
  sudo ausearch -m avc -ts today -c sh -c php -c nginx 2>/dev/null || true
}

doragon_selinux_avc_allow_today() {
  require_cmd audit2allow
  require_cmd ausearch

  section "SELinux audit2allow (today)"
  info "WARNING: review rules before applying. This only prints suggestions."

  sudo ausearch -m avc -ts today 2>/dev/null | sudo audit2allow || true
}

# ------- main command router -------

doragon_selinux_cmd() {
  local sub="${1:-}"
  shift || true

  case "$sub" in
    status)
      local mode
      mode="$(selinux_mode)"
      echo "SELinux: ${mode}"
      ;;
    avc)
      local action="${1:-}"
      shift || true
      case "$action" in
        today|"")
          doragon_selinux_avc_today
          ;;
        count)
          doragon_selinux_avc_count_today
          ;;
        summary)
          doragon_selinux_avc_summary_today
          ;;
        grep)
          doragon_selinux_avc_grep_today "$@"
          ;;
        services)
          doragon_selinux_avc_services_today
          ;;
        allow)
          doragon_selinux_avc_allow_today
          ;;
        *)
          die "Unknown: doragon selinux avc ${action}. Try: today|count|summary|grep|services|allow"
          ;;
      esac
      ;;
    -h|--help|"")
      cat <<'USAGE'
Usage:
  doragon selinux status
  doragon selinux avc today
  doragon selinux avc count
  doragon selinux avc summary
  doragon selinux avc grep <pattern>
  doragon selinux avc services
  doragon selinux avc allow

Notes:
  - 'avc *' uses sudo (audit logs are privileged).
  - 'allow' prints audit2allow suggestions only.
USAGE
      ;;
    *)
      die "Unknown selinux command: ${sub}. Run: doragon selinux --help"
      ;;
  esac
}
