cat > install.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

BIN_DST="/usr/bin/doragon"
BASE_DST="/usr/libexec/doragon"
CORE_DST="${BASE_DST}/core"
MODULES_DST="${BASE_DST}/modules"
ETC_DST="/etc/doragon"

backup="/var/backups/doragon/$(date +%F-%H%M%S)"

if [[ ${EUID:-0} -ne 0 ]]; then
  exec sudo bash "$0" "$@"
fi

echo "[INFO] Installing Doragon..."

mkdir -p "$backup" "$BASE_DST" "$CORE_DST" "$MODULES_DST" "$ETC_DST"

# --- backup existing ---
[[ -f "$BIN_DST" ]] && cp -a "$BIN_DST" "$backup/" || true
[[ -d "$BASE_DST" ]] && cp -a "$BASE_DST" "$backup/libexec" || true
[[ -d "$ETC_DST" ]] && cp -a "$ETC_DST" "$backup/etc" || true

# --- install binary ---
install -m 755 bin/doragon "$BIN_DST"

# --- install core ---
rm -rf "${CORE_DST:?}/"* 2>/dev/null || true
cp -a core/. "$CORE_DST/"

# --- install modules ---
rm -rf "${MODULES_DST:?}/"* 2>/dev/null || true
cp -a modules/. "$MODULES_DST/"

# --- permissions ---
find "$BASE_DST" -type f -name "*.sh" -exec chmod 755 {} \;

# --- install configs (only if missing) ---
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

echo "[INFO] Verifying installation..."
doragon status >/dev/null 2>&1 && echo "[OK] Doragon operational"
