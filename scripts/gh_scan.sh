#!/bin/bash

# Scan all github repositories for the list of organizations, and report security issues

DISABLED_REPO_MESSAGES=("Dependabot alerts are disabled for this repository." "Dependabot alerts are not available for archived repositories.")
EXIT_CODE=0
ORG_LIST=("cicd-tools-org" "grocerypanic" "music-metadata-analysis" "niall-byrne" "niallbyrne-ca" "osx-provisioner" "pi-portal" "url-short-cuts")

check_disabled() {
  #: $1  The github scan results

  local DISABLED_REPO_MESSAGE
  local PARSED_MESSAGE

  PARSED_MESSAGE="$(echo "${1}" | jq -r ".message" 2> /dev/null)"

  for DISABLED_REPO_MESSAGE in "${DISABLED_REPO_MESSAGES[@]}"; do
    if [[ "${PARSED_MESSAGE}" == "${DISABLED_REPO_MESSAGE}" ]]; then
      return 0
    fi
  done

  return 1
}

scan_organization() {
  #: $1  The github organization to scan

  local API_HOST
  local API_REPO
  local HOST
  local REPO

  API_HOST="api.github.com/repos"
  HOST="github.com"

  while read -r REPO; do
    echo "Scanning: ${REPO}"
    API_REPO="${REPO/${HOST}/${API_HOST}}/dependabot/alerts?state=open"
    SCAN="$(gh api -H 'Accept: application/vnd.github.v3.raw+json' "${API_REPO}" 2> /dev/null)"
    if check_disabled "${SCAN}"; then
      continue
    fi
    if [[ "${SCAN}" != "[]" ]]; then
      echo "**** ^^ CHECK THIS REPOSITORY! ****"
      EXIT_CODE=127
    fi
  done <<< "$(gh repo list "${1}" --json url --jq .[].url)"

}

main() {

  local ORGANIZATION

  for ORGANIZATION in "${ORG_LIST[@]}"; do
    scan_organization "${ORGANIZATION}"
  done

  echo "EXIT CODE: ${EXIT_CODE}"
  exit "${EXIT_CODE}"

}

main "$@"
