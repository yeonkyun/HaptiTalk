#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
cd "$SCRIPT_DIR"

echo "Stopping Jaeger monitoring"
docker-compose down

echo "Jaeger monitoring has been stopped" 