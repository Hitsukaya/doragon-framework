#!/usr/bin/env bash
set -euo pipefail

doragon_f2b_usage() {
  cat <<'USAGE'
Doragon f2b commands:

  doragon f2b status                          # show status for default jail list
  doragon f2b status <jail>                   # show status for one jail
  doragon f2b bans [N]                        # show last N bans (default 5)
  doragon f2b nginx-errors [N]                # show last N nginx errors (default 10)
  doragon f2b tail                            # tail -f fail2ban log

  doragon f2b unban <IP>                      # unban IP in all jails
  doragon f2b unban-jail <jail> <IP>          # unban IP from one jail

  doragon f2b set-list <set|jail>             # (debug) show ipset members (auto: f2b-<name>)
  doragon f2b unban-set <set|jail> <IP>       # (debug) remove IP from ipset (auto: f2b-<name>)

  Examples:
    doragon f2b set-list sshd
    doragon f2b set-list f2b-sshd
    doragon f2b unban-set sshd 1.2.3.4

USAGE
}

doragon_f2b_cmd() {
  local sub="${1:-help}"
  shift || true

  case "${sub}" in
    status)       doragon_f2b_status "${@:-}" ;;
    bans)         doragon_f2b_last_bans "${1:-5}" ;;
    nginx-errors) doragon_f2b_nginx_errors "${1:-10}" ;;
    tail)         doragon_f2b_tail ;;

    unban)        doragon_f2b_unban_global "$@" ;;
    unban-jail)   doragon_f2b_unban_jail "$@" ;;

    set-list)     doragon_f2b_set_list "$@" ;;
    unban-set)    doragon_f2b_unban_set "$@" ;;

    -h|--help|help) doragon_f2b_usage ;;
    *) die "Unknown f2b subcommand: ${sub}. Try: doragon f2b --help" ;;
  esac
}
