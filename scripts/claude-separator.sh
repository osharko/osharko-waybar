#!/usr/bin/env bash
# claude-separator.sh — mostra │ solo se Claude è configurato (almeno un credentials file)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ACCOUNTS_CONF="${SCRIPT_DIR}/claude-accounts.conf"

check_creds() {
  local path="$1"
  path="${path/#\~/$HOME}"
  [[ -f "${path}/.credentials.json" ]]
}

# Controlla account configurati
if [[ -f "$ACCOUNTS_CONF" ]]; then
  while IFS='|' read -r label path; do
    [[ "$label" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${label// }" ]] && continue
    if check_creds "$path"; then
      echo '{"text":"│","class":"visible"}'
      exit 0
    fi
  done < "$ACCOUNTS_CONF"
fi

# Fallback: account di default
if check_creds "$HOME/.claude"; then
  echo '{"text":"│","class":"visible"}'
  exit 0
fi

# Nessun account configurato — sparisci
echo '{"text":"","class":"hidden"}'
