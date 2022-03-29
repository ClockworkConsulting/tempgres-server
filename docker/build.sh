#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
CONTEXT_DIR="${ROOT_DIR}"

DOCKER_BUILDKIT=1 docker build -f "${CONTEXT_DIR}/docker/Dockerfile" -t tempgres:latest "${CONTEXT_DIR}"
