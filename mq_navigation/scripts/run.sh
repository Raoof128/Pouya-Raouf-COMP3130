#!/usr/bin/env bash
# Launch the app with --dart-define vars loaded from .env
# Usage: ./scripts/run.sh [device-id] [extra flutter args...]
#
# Examples:
#   ./scripts/run.sh                            # pick device interactively
#   ./scripts/run.sh 00008150-000E7C6A1EF0401C  # specific device
#   ./scripts/run.sh chrome
#   ./scripts/run.sh macos

set -euo pipefail
cd "$(dirname "$0")/.."

ENV_FILE=".env"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: $ENV_FILE not found."
  echo "  cp .env.example .env   # then fill in your keys"
  exit 1
fi

DEVICE_ARG=""
if [[ -n "${1:-}" ]]; then
  DEVICE_ARG="-d $1"
  shift
fi

echo "Launching with dart-defines from .env..."
flutter run $DEVICE_ARG --dart-define-from-file="$ENV_FILE" "$@"
