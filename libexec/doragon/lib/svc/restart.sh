doragon_svc_restart() {
  local name="${1:-}"
  [[ -z "$name" ]] && die "Usage: doragon svc restart <name>"

  doragon_unit_exists "$name" || { warn "Service not installed: $name"; return 1; }

  if systemctl restart "$name" --no-pager; then
    ok "Restarted: $name"
  else
    die "Restart failed: $name"
  fi
}

