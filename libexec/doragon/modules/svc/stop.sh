doragon_svc_stop() {
  local name="${1:-}"
  [[ -z "$name" ]] && die "Usage: doragon svc stop <name>"

  doragon_unit_exists "$name" || { warn "Service not installed: $name"; return 1; }

  systemctl stop "$name" --no-pager && ok "Stopped: $name"
}
