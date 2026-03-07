doragon_audit_database() {

  section "DATABASE"

  if mariadb_service_active; then
    if mariadb_any_listen; then
      if mariadb_local_only; then
        ok "MariaDB: localhost-only (3306)"
      else
        warn "MariaDB: listening on public interface (recommended: localhost-only)"
        warn_count=$((warn_count+1))
      fi
    else
      if mariadb_socket_present; then
        ok "MariaDB: socket-only (mysql.sock)"
      else
        warn "MariaDB: running, but no listener/socket detected"
        warn_count=$((warn_count+1))
      fi
    fi
   else
    info "MariaDB: not running"
  fi

 if postgres_service_active; then
   if postgres_any_listen; then
     if postgres_local_only; then
       ok "PostgreSQL: localhost-only (65499)"
     else
       warn "PostgreSQL: listening on public interface (recommended: localhost-only)"
       warn_count=$((warn_count+1))
     fi
   else
     if postgres_socket_present; then
       ok "PostgreSQL: socket-only (.s.PGSQL.65499)"
     else
       warn "PostgreSQL: running, but no listener/socket detected"
       warn_count=$((warn_count+1))
     fi
   fi
 else
   info "PostgreSQL: not running"
 fi
}
