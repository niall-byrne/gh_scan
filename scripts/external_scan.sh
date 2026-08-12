#!/bin/bash

# Clone the configured external repositories and run their associated security checks

set -eo pipefail

declare -A configuration

configure_external_dependencies() {
  poetry self add "poetry-plugin-export>=1.8"
}

deploy_key_insert() {
  echo "${EXTERNAL_DEPLOY_KEY}" > deploy_key
  chmod 600 deploy_key
}

deploy_key_remove() {
  if [[ -e deploy_key ]]; then
    rm deploy_key
  fi
}

external_scanner() {
  # $1: the external repository clone URL
  # $2: the command to execute

  local temp_dir

  temp_dir="$(mktemp -d)"

  deploy_key_insert

  trap "deploy_key_remove" ERR

  GIT_SSH_COMMAND="ssh -i deploy_key -o IdentitiesOnly=yes -o StrictHostKeyChecking=no" git clone "${1}" "${temp_dir}" > /dev/null

  deploy_key_remove

  trap - ERR
  trap 'rm -rf "${temp_dir}"' EXIT

  pushd "${temp_dir}" > /dev/null
  ${2}
  popd > /dev/null
}

main() {
  local key
  local value

  configure_external_dependencies

  for key in "${!configuration[@]}"; do
    value="${configuration[${key}]}"

    echo
    echo "Scanning '${key}' ..."
    external_scanner "${key}" "${value}"
    echo
  done
}

main
