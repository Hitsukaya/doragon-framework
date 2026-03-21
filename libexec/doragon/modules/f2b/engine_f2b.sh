#!/usr/bin/env bash
#set -euo pipefail

DORAGON_F2B_JAILS_DEFAULT=(
  sshd
  postgresql
  nginx-http-auth
  laravel-scan
  nginx-error
  nginx-blocked
  nginx-blocked-suspicious
  nginx-scanner
  nginx-ratelimit
  laravel-wordpress
  phpmyadmin
  recidive
  nginx-ssl-handshake-protection
  nginx-exchange-scan
  nginx-livewire
  convertor
  nginx-envscan
)

doragon_f2b_setname_norm() {
  local name="${1:-}"
  [[ -z "$name" ]] && return 1
  [[ "$name" == f2b-* ]] && echo "$name" || echo "f2b-$name"
}

doragon_f2b_list_jails() {
  local runner="${1:-}"
  if [[ -n "$runner" ]]; then
    $runner fail2ban-client status 2>/dev/null \
      | awk -F: '/Jail list/ {gsub(/,/, "", $2); print $2}'
  else
    fail2ban-client status 2>/dev/null \
      | awk -F: '/Jail list/ {gsub(/,/, "", $2); print $2}'
  fi
}

doragon_f2b_is_ipv4() {
  local ip="${1:-}"
  [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  local IFS=.; local a b c d
  read -r a b c d <<<"$ip"
  [[ $a -le 255 && $b -le 255 && $c -le 255 && $d -le 255 ]]
}
