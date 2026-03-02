doragon_svc_reload() {
  local name="${1:-}"
  [[ -z "$name" ]] && die "Usage: doragon svc reload <name>"

  doragon_unit_exists "$name" || { warn "Service not installed: $name"; return 1; }

  if systemctl reload "$name" --no-pager; then
    ok "Reloaded: $name"
  else
    warn "Reload failed: $name (trying restart)"
    systemctl restart "$name" --no-pager
    ok "Restarted: $name"
  fi
}
