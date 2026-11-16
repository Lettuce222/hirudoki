#!/usr/bin/env bash
set -o errexit

# Fail-safe probe for acceptance testing: abort before any migration or disk access.
if [ "${DEPLOYMENT_FAILURE_PROBE:-0}" = "1" ]; then
  echo "Intentional pre-deploy failure probe. Existing deployment must remain active."
  exit 1
fi

bin/rails db:migrate
