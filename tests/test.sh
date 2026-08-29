#!/usr/bin/env bash
# Validates this plugin's manifest against Omarchy's plugin schema.
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v omarchy >/dev/null 2>&1; then
  echo "omarchy CLI not found on PATH — this repo's tests only run on an Omarchy system." >&2
  exit 1
fi

omarchy plugin validate .
