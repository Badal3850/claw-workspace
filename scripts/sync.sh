#!/bin/bash
# Backward-compatible entry point for a bounded scheduled memory sync.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/agent-cycle.sh"
