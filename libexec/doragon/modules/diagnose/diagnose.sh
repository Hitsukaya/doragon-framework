#!/usr/bin/env bash
set -euo pipefail

doragon_diagnose_usage() {
    cat <<'USAGE'
Usage:
  doragon diagnose <target>

Targets:
  nginx       Diagnose nginx configuration and TLS usage
  tls         Diagnose TLS runtime and certificates
  database    Diagnose database exposure and bindings
  help        Show this help

USAGE
}

doragon_diagnose_cmd() {
    local target="${1:-}"
    shift || true

    case "$target" in
        nginx)
            doragon_diagnose_nginx_certs "$@"
            ;;
        tls)
            doragon_diagnose_tls "$@"
            ;;
        database|db)
            doragon_diagnose_database "$@"
            ;;
        -h|help|--help|"")
            doragon_diagnose_usage
            ;;
        *)
         die "[ERR] Unknown diagnose target: $target Run: doragon diagnose --help" >&2
         ;;
    esac
}
