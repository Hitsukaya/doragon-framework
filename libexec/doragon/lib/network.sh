#!/usr/bin/env bash
set -euo pipefail

doragon_net_usage() {
  cat <<'USAGE'
Network commands:
  doragon net ports [--short]   # ss -tulnp (root; Doragon sudo)
  doragon net ip                # ip a

Options:
  --short   Show compact listen table (proto, addr, port, process)

USAGE
}

_doragon_net_ports_require_root() {
  if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" net ports "$@"
  fi
}

doragon_net_ports_full() {
  ss -tulnp
}

doragon_net_ports_short() {
  # Compact: proto  addr  port  process
  # Parses ss output lines like:
  # LISTEN 0 4096 0.0.0.0:2607 0.0.0.0:* users:(("sshd",pid=...,fd=...))
  ss -H -tulnp | awk '
    {
      proto=$1;
      local=$5;

      # Extract port (last : part)
      port=local;
      sub(/^.*:/, "", port);

      # Extract addr (remove last :port)
      addr=local;
      sub(/:[^:]+$/, "", addr);

      # Extract process name from users:(("name"
      proc="-";
      if (match($0, /users:\(\("([^"]+)"/, m)) proc=m[1];

      printf "%-5s %-25s %-6s %s\n", proto, addr, port, proc;
    }
  ' | sort -k3,3n
}

doragon_net_ports() {
  _doragon_net_ports_require_root "$@"

  local opt="${1:-}"
  case "$opt" in
    --short)
      doragon_net_ports_short
      ;;
    "" )
      doragon_net_ports_full
      ;;
    *)
      die "Unknown option for 'doragon net ports': $opt. Try: doragon net --help"
      ;;
  esac
}

doragon_net_ip() {
  ip a
}

doragon_net_cmd() {
  local sub="${1:-}"
  shift || true

  case "$sub" in
    ports)
      doragon_net_ports "$@"
      ;;
    ip)
      doragon_net_ip
      ;;
    -h|--help|"")
      doragon_net_usage
      ;;
    *)
      die "Unknown net subcommand: $sub. Try: doragon net --help"
      ;;
  esac
}
