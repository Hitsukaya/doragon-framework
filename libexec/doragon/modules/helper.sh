#!/usr/bin/env bash
set -euo pipefail

doragon_helper_usage() {
  cat <<'USAGE'
Helper commands:
  doragon helper                # Show quick system helper commands
  doragon helper laravel        # Laravel specific ownership + SELinux fixes
USAGE
}

doragon_helper_main() {

cat <<'EOF'
-------------------------------------------------------------------
SYSTEM HELPER CHECK  ----- Doragon Framework -----
-------------------------------------------------------------------

FILE & DIRECTORY OWNERSHIP
--------------------------
- sudo chown -R nginx:nginx /path/to/app/storage
- sudo chown -R nginx:nginx /path/to/app/bootstrap/cache
- sudo chown -h nginx:nginx /path/to/app/public/storage  # symlink

- sudo find /path/to/app/storage -type d -exec chmod 775 {} \;
- sudo find /path/to/app/storage -type f -exec chmod 664 {} \;
- sudo find /path/to/app/bootstrap/cache -type d -exec chmod 775 {} \;
- sudo find /path/to/app/bootstrap/cache -type f -exec chmod 664 {} \;

Make file livewire-tmp
- sudo mkdir -p storage/framework/livewire-tmp
- sudo chown -R nginx:nginx storage/framework/livewire-tmp
- sudo chmod 775 storage/framework/livewire-tmp

SELINUX CONTEXT
--------------------------
- ls -ldZ /path/to/app/storage
- ls -ldZ /path/to/app/bootstrap/cache
- ls -ldZ /path/to/app/public/storage

Fix context if needed
- sudo semanage fcontext -a -t httpd_sys_rw_content_t "/path/to/app/storage(/.*)?"
- sudo semanage fcontext -a -t httpd_sys_rw_content_t "/path/to/app/bootstrap/cache(/.*)?"
- sudo semanage fcontext -a -t httpd_sys_rw_content_t "/path/to/app/public/storage(/.*)?"
- sudo restorecon -Rv /path/to/app/storage
- sudo restorecon -Rv /path/to/app/bootstrap/cache
- sudo restorecon -Rv /path/to/app/public/storage

WEB SERVER
----------
- sudo systemctl restart nginx
- sudo systemctl restart php-fpm

BACKUP / FILES
--------------
- tar -czvf backup.tar.gz /path/to/folder
- tar -xzvf backup.tar.gz -C /restore/path

EOF
}

doragon_helper_cmd() {
  local sub="${1:-}"
  shift || true

  case "$sub" in
    "" )
      doragon_helper_main
      ;;
    laravel)
      doragon_helper_main
      ;;
    -h|--help)
      doragon_helper_usage
      ;;
    *)
      die "Unknown helper command: $sub"
      ;;
  esac
}
