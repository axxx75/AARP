#!/usr/bin/env bash
set -euo pipefail

# AARP currently has no package dependencies, generated client, or database
# migration that needs reconciliation after a task merge.
#
# Keep this hook explicit and idempotent so the Replit post-merge lifecycle can
# complete successfully today and provide a single place for future setup.
exit 0