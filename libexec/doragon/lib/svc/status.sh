doragon_svc_status() {
  local name="${1:-}"
  [[ -z "$name" ]] && die "Usage: doragon svc status <name>"
  doragon_unit_exists "$name" || { warn "Service not installed: $name"; return 1; }
  systemctl status "$name" --no-pager
}
