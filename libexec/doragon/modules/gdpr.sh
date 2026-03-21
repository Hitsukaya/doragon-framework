#!/usr/bin/env bash
set -euo pipefail

doragon_gdpr_compliance() {

  section "GDPR COMPLIANCE"

  # Audit System
  doragon_audit_system

  # Audit Database
  doragon_audit_database

  # Audit Network
  doragon_audit_network

  # Audit SSH
  doragon_audit_ssh

  # Audit TLS
  doragon_audit_tls

IFS='|' read -r security_score score_status exit_code warn_count fail_count \
  < <(doragon_calculate_security_score)

local grade assessment issues actions
 grade="$(score_grade "$security_score")"
 assessment="$(score_assessment "$security_score" "$score_status")"

 echo
 section "GDPR SUMMARY"
 echo "Score: $(score_bar "$security_score") ${security_score}/100"
 echo "Grade: ${grade}"
 echo "Status: ${score_status}"
 echo "Assessment: ${assessment}"

 issues="$(top_issues || true)"

 if [[ -n "${issues}" ]]; then
   section "Issues"
   printf '%s\n' "${issues}" | sed 's/^/• /'
 fi

 return "${exit_code}"

}
