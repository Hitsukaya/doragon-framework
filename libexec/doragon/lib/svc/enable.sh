doragon_svc_enable() {
  local name="${1:-}"
  [[ -z "$name" ]] && die "Usage: doragon svc enable <name>"

  doragon_unit_exists "$name" || { warn "Service not installed: $name"; return 1; }

  systemctl enable "$name" --no-pager && ok "Enabled: $name"
}
