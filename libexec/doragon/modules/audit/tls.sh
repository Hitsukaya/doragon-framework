#!/usr/bin/env bash
set -euo pipefail

doragon_audit_tls() {
    section "TLS"

    local tls_ports nginx_config cert openssl_version crypto_policy fips_mode
    tls_ports="$(detect_tls_ports_config | paste -sd ',' -)"
    port="${tls_ports%%,*}"

    if [[ -n "$tls_ports" ]]; then
        ok "Configured TLS port(s): ${tls_ports}"
    else
        warn "No TLS port configured"
        return
    fi

    nginx_config="$(nginx -T 2>/dev/null)"

    if grep -q 'ssl_certificate' <<< "$nginx_config"; then
        ok "TLS certificate directive detected"
    else
        warn "TLS certificate directive not detected"
        return
    fi
    echo

    while IFS= read -r cert; do
        [[ -z "$cert" ]] && continue

        local domain expiry
        domain="$(basename "$(dirname "$cert")")"
        expiry="$(openssl x509 -enddate -noout -in "$cert" 2>/dev/null | cut -d= -f2)"
        echo
        ok "${domain}"
        info "expires: ${expiry}"
    done < <(find /etc/letsencrypt/live -mindepth 1 -maxdepth 2 -name fullchain.pem 2>/dev/null | sort)

    echo

    section "TLS & CRYPTO"

    openssl_version="$(openssl version | awk '{print $2}')"
    crypto_policy="$(update-crypto-policies --show 2>/dev/null || echo "unknown")"
    fips_mode="$(cat /proc/sys/crypto/fips_enabled 2>/dev/null || echo "0")"

    if [[ -n "$openssl_version" ]]; then
        ok "OpenSSL: ${openssl_version}"
    else
        warn "OpenSSL version not detected"
    fi

    if openssl version | grep -qE "OpenSSL (3|4)"; then
        ok "TLSv1.3 supported"
    else
        warn "TLSv1.3 support not confirmed"
    fi

    info "Crypto policy: ${crypto_policy}"

    if [[ "$fips_mode" == "1" ]]; then
        ok "FIPS mode: enabled"
    else
        ok "FIPS mode: disabled"
    fi

  echo
  info "nginx ssl_protocols: $(echo "$nginx_config" | awk '/ssl_protocols/ {for (i=2;i<=NF;i++) printf "%s ", $i; print ""; exit}' | sed 's/;//g')"

}

