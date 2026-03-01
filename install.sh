cat > install.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

BIN_DST="/usr/bin/doragon"
LIB_DST="/usr/libexec/doragon/lib"
ETC_DST="/etc/doragon"

backup="/var/backups/doragon/$(date +%F-%H%M%S)"

if [[ ${EUID:-0} -ne 0 ]]; then
  exec sudo bash "$0" "$@"
fi

mkdir -p "$backup" "$LIB_DST" "$ETC_DST"

# backup existing
[[ -f "$BIN_DST" ]] && cp -a "$BIN_DST" "$backup/" || true
[[ -d "$LIB_DST" ]] && cp -a "$LIB_DST" "$backup/lib" || true
[[ -d "$ETC_DST" ]] && cp -a "$ETC_DST" "$backup/etc" || true

# install
install -m 755 bin/doragon "$BIN_DST"
install -m 644 libexec/doragon/lib/*.sh "$LIB_DST/"

# install configs only if missing
for f in etc/*.example; do
  [[ -e "$f" ]] || continue
  base="$(basename "$f" .example)"
  if [[ ! -f "$ETC_DST/$base" ]]; then
    install -m 640 "$f" "$ETC_DST/$base"
    echo "[OK] Installed config: $ETC_DST/$base"
  else
    echo "[SKIP] Config exists: $ETC_DST/$base"
  fi
done

echo "[OK] Installed Doragon (backup: $backup)"
doragon version 2>/dev/null || true
EOF

chmod +x install.sh
