#!/usr/bin/env bash
# Launch the app with --dart-define vars loaded from .env
# Usage: ./scripts/run.sh [device-id] [extra flutter args...]
#
# Examples:
#   ./scripts/run.sh                          # pick device interactively
#   ./scripts/run.sh 00008150-000E7C6A1EF0401C  # Raoof's iPhone
#   ./scripts/run.sh chrome
#   ./scripts/run.sh macos

set -euo pipefail
cd "$(dirname "$0")/.."

ENV_FILE=".env"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: $ENV_FILE not found. Copy .env.example and fill in your keys."
  exit 1
fi

# Read .env into --dart-define flags
DART_DEFINES=""
while IFS='=' read -r key value; do
  [[ -z "$key" || "$key" == \#* ]] && continue
  DART_DEFINES="$DART_DEFINES --dart-define=$key=$value"
done < "$ENV_FILE"

DEVICE_ARG=""
if [[ -n "${1:-}" ]]; then
  DEVICE_ARG="-d $1"
  shift
fi

echo "Launching with dart-defines from .env..."
flutter run $DEVICE_ARG $DART_DEFINES "$@"
