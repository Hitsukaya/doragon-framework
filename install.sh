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

# --- backup existing ---
[[ -f "$BIN_DST" ]] && cp -a "$BIN_DST" "$backup/" || true
[[ -d "$LIB_DST" ]] && cp -a "$LIB_DST" "$backup/lib" || true
[[ -d "$ETC_DST" ]] && cp -a "$ETC_DST" "$backup/etc" || true

# --- install binary ---
install -m 755 bin/doragon "$BIN_DST"

# --- install libs (recursive) ---
# copy whole tree so modular folders (e.g. f2b/, svc/, etc.) are included
rm -rf "${LIB_DST:?}/"* 2>/dev/null || true
cp -a libexec/doragon/lib/. "$LIB_DST/"

# ensure scripts are executable (only *.sh and no directories)
find "$LIB_DST" -type f -name "*.sh" -exec chmod 755 {} \;
# configs/readme inside lib tree (if any) can remain 644; adjust only if you have them

# --- install configs only if missing ---
shopt -s nullglob
for f in etc/*.example; do
  base="$(basename "$f" .example)"
  if [[ ! -f "$ETC_DST/$base" ]]; then
    install -m 640 "$f" "$ETC_DST/$base"
    echo "[OK] Installed config: $ETC_DST/$base"
  else
    echo "[SKIP] Config exists: $ETC_DST/$base"
  fi
done
shopt -u nullglob

echo "[OK] Installed Doragon (backup: $backup)"

# sanity check
command -v doragon >/dev/null 2>&1 && doragon version 2>/dev/null || true
EOF

chmod +x install.sh
