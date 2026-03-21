doragon_svc_disable() {
  local name="${1:-}"
  [[ -z "$name" ]] && die "Usage: doragon svc disable <name>"

  doragon_unit_exists "$name" || { warn "Service not installed: $name"; return 1; }

  systemctl disable "$name" --no-pager && ok "Disabled: $name"
}
