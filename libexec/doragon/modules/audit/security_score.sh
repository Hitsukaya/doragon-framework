doragon_calculate_security_score() {

  local security_score=100
  local status="OK"
  local exit_code=0
  local warn_count=0
  local fail_count=0

  [[ "$(check_selinux)" == "FAIL" ]] && fail_count=$((fail_count+1))
  [[ "$(check_firewalld)" == "FAIL" ]] && fail_count=$((fail_count+1))
  [[ "$(check_fail2ban)" == "WARN" ]] && warn_count=$((warn_count+1))
  [[ "$(check_nginx)" == "WARN" ]] && warn_count=$((warn_count+1))
  [[ "$(check_phpfpm)" == "WARN" ]] && warn_count=$((warn_count+1))
  [[ "$(check_phpfpm_socket)" == "WARN" ]] && warn_count=$((warn_count+1))
  [[ "$(check_redis_local_only)" == "WARN" ]] && warn_count=$((warn_count+1))
  [[ "$(check_tls)" == "WARN" ]] && warn_count=$((warn_count+1))

  mariadb_public_listen && warn_count=$((warn_count+1))
  postgres_public_listen_65499 && warn_count=$((warn_count+1))

  [[ "$(check_selinux)" != "OK" ]] && security_score=$((security_score-15))
  [[ "$(check_firewalld)" != "OK" ]] && security_score=$((security_score-20))
  [[ "$(check_fail2ban)" != "OK" ]] && security_score=$((security_score-10))

  (( warn_count > 0 )) && security_score=$((security_score - (warn_count * 5)))
  (( security_score < 0 )) && security_score=0

  if (( fail_count > 0 )); then
    status="FAIL"
    exit_code=2
  elif (( warn_count > 0 )); then
    status="WARN"
    exit_code=1
  fi

  printf '%s|%s|%s|%s|%s\n' \
    "$security_score" \
    "$status" \
    "$exit_code" \
    "$warn_count" \
    "$fail_count"
}

score_assessment() {
  local score="${1:-0}"
  local status="${2:-OK}"

  if [[ "$status" == "FAIL" ]]; then
    echo "Critical issues detected. Immediate hardening is recommended."
  elif (( score >= 100 )); then
    echo "Rank SS — Emperor Dragon security achieved. Stay sharp."
  elif (( score >= 95 )); then
    echo "Strong security baseline with minor adjustments recommended."
  elif (( score >= 85 )); then
    echo "Good security posture, but improvements are recommended."
  elif (( score >= 70 )); then
    echo "Moderate security posture. Review exposed services and hardening."
  else
    echo "Weak security posture. Immediate review and remediation recommended."
  fi
}

score_grade() {
  local score="${1:-0}"

  if (( score >= 100 )); then
    echo "SS"
  elif (( score >= 98 )); then
    echo "A+"
  elif (( score >= 95 )); then
    echo "A"
  elif (( score >= 90 )); then
    echo "B+"
  elif (( score >= 85 )); then
    echo "B"
  elif (( score >= 75 )); then
    echo "C"
  elif (( score >= 60 )); then
    echo "D"
  else
    echo "F"
  fi
}

top_issues() {
  mariadb_public_listen && echo "MariaDB listening on public interface (recommended: localhost-only)"
  postgres_public_listen_65499 && echo "PostgreSQL listening on public interface (recommended: localhost-only)"

  local password_auth
  password_auth="$(detect_sshd_option passwordauthentication 2>/dev/null || true)"
  [[ "${password_auth:-}" == "yes" ]] && echo "PasswordAuthentication enabled"
}

next_actions() {
  mariadb_public_listen && echo "Restrict MariaDB bind-address to 127.0.0.1"
  postgres_public_listen_65499 && echo "Restrict PostgreSQL listen_addresses to localhost"

  local password_auth
  password_auth="$(detect_sshd_option passwordauthentication 2>/dev/null || true)"
  [[ "${password_auth:-}" == "yes" ]] && echo "Disable PasswordAuthentication in sshd_config if SSH keys are enforced"
}
