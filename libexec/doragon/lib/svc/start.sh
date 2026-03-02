doragon_svc_start() {
  local name="${1:-}"
  [[ -z "$name" ]] && die "Usage: doragon svc start <name>"

  doragon_unit_exists "$name" || { warn "Service not installed: $name"; return 1; }

  systemctl start "$name" --no-pager && ok "Started: $name"
}

