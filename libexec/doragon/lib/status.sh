#!/usr/bin/env bash
set -euo pipefail

doragon_status() {
  local warn_count=0
  local fail_count=0
  local os_ok=1

  section "STATUS"
  ok "Uptime: $(uptime_days) days"
  ok "Load Avg (1/5/15): $(loadavg_short)"
  ok "Disk /: $(rootfs_usage_line)"
  ok "Memory: $(mem_usage_line)"

  if [[ "$(swap_status)" == "OK" ]]; then
    ok "Swap: $(swap_line)"
  else
    warn "Swap: $(swap_line)"
    warn_count=$((warn_count+1))
  fi

  # Audit System
  doragon_audit_system

  # Audit Database
  doragon_audit_database

  # Audit Network
  doragon_audit_network

  # Audit SSH
  doragon_audit_ssh


IFS='|' read -r security_score score_status exit_code warn_count fail_count \
  < <(doragon_calculate_security_score)


 section "SECURITY SCORE"

 local grade assessment issues actions
 grade="$(score_grade "$security_score")"
 assessment="$(score_assessment "$security_score" "$score_status")"

 echo "Score: $(score_bar "$security_score") ${security_score}/100"
 echo "Grade: ${grade}"
 echo "Status: ${score_status}"
 echo "Assessment: ${assessment}"

 issues="$(top_issues || true)"

 if [[ -n "${issues}" ]]; then
   section "Top Issues"
   printf '%s\n' "${issues}" | sed 's/^/• /'
 fi

 actions="$(next_actions | head -n 5 || true)"

  if [[ -n "${actions}" ]]; then
   section "Next Actions"
   printf '%s\n' "${actions}" | sed 's/^/• /'
  fi

 return "${exit_code}"

}
