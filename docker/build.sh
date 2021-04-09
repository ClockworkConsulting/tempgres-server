#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTEXT_DIR="$(realpath ${SCRIPT_DIR}/..)"

DOCKER_BUILDKIT=1 docker build -f docker/Dockerfile -t tempgres:latest "${CONTEXT_DIR}"
