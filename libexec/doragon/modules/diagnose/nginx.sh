detect_nginx_cert_paths() {
    sudo nginx -T 2>/dev/null | awk '
        $1 ~ /^ssl_certificate$/ {
            path=$2
            sub(/;.*/, "", path)
            print path
        }
    ' | sort -u
}

detect_live_cert_paths() {
    find /etc/letsencrypt/live -mindepth 1 -maxdepth 2 -name fullchain.pem 2>/dev/null | sort -u
}

detect_orphaned_cert_paths() {
    local live_file nginx_file
    live_file="$(mktemp)"
    nginx_file="$(mktemp)"

    trap 'rm -f "$live_file" "$nginx_file"' RETURN

    detect_live_cert_paths > "$live_file"
    detect_nginx_cert_paths > "$nginx_file"

    comm -23 "$live_file" "$nginx_file"
}

detect_orphaned_cert_domains() {
    detect_orphaned_cert_paths | while IFS= read -r cert; do
        [[ -z "$cert" ]] && continue
        basename "$(dirname "$cert")"
    done
}

detect_missing_nginx_cert_paths() {
    detect_nginx_cert_paths | while IFS= read -r cert; do
        [[ -z "$cert" ]] && continue
        [[ -f "$cert" ]] || echo "$cert"
    done
}

detect_missing_nginx_cert_domains() {
    detect_missing_nginx_cert_paths | while IFS= read -r cert; do
        [[ -z "$cert" ]] && continue
        basename "$(dirname "$cert")"
    done
}

doragon_diagnose_nginx_certs() {
    section "NGINX CERTIFICATES"

    local found=0

    while IFS= read -r cert; do
        [[ -z "$cert" ]] && continue
        found=1
        ok "$(basename "$(dirname "$cert")")"
    done < <(detect_nginx_cert_paths)

    [[ "$found" -eq 0 ]] && info "No nginx ssl_certificate directives detected"

    echo
    section "ORPHANED CERTIFICATES"

    found=0
    while IFS= read -r domain; do
        [[ -z "$domain" ]] && continue
        found=1
        warn "${domain} certificate exists but is not referenced by nginx"
    done < <(detect_orphaned_cert_domains)

    [[ "$found" -eq 0 ]] && ok "No orphaned certificates detected"

    echo
    section "MISSING CERTIFICATES"

    found=0
    while IFS= read -r cert; do
        [[ -z "$cert" ]] && continue
        found=1
        fail "Nginx references missing certificate: ${cert}"
    done < <(detect_missing_nginx_cert_paths)

    [[ "$found" -eq 0 ]] && ok "No missing nginx certificate paths detected"
}
