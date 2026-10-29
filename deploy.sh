#!/usr/bin/env bash
# Production deploy: builds the Docker image, swaps the running container,
# and rolls back to the previous image if the new one fails its health check.
#
# Usage: ./deploy.sh
# Env overrides: APP_NAME, HOST_PORT, ENV_FILE, HEALTH_TIMEOUT
set -euo pipefail

APP_NAME="${APP_NAME:-nextjs-demo}"
HOST_PORT="${HOST_PORT:-3000}"
ENV_FILE="${ENV_FILE:-.env.production}"
HEALTH_TIMEOUT="${HEALTH_TIMEOUT:-60}"

cd "$(dirname "$0")"

TAG="$(git rev-parse --short HEAD 2>/dev/null || date +%Y%m%d%H%M%S)"
IMAGE="$APP_NAME:$TAG"
PREV_IMAGE="$(docker inspect --format '{{.Config.Image}}' "$APP_NAME" 2>/dev/null || true)"

log() { printf '\033[1;34m[deploy]\033[0m %s\n' "$*"; }

run_container() {
  local image="$1"
  local env_args=()
  [[ -f "$ENV_FILE" ]] && env_args=(--env-file "$ENV_FILE")
  docker rm -f "$APP_NAME" >/dev/null 2>&1 || true
  docker run -d \
    --name "$APP_NAME" \
    --restart unless-stopped \
    -p "$HOST_PORT:3000" \
    ${env_args[@]+"${env_args[@]}"} \
    "$image" >/dev/null
}

wait_healthy() {
  local deadline=$((SECONDS + HEALTH_TIMEOUT))
  until curl -fsS "http://127.0.0.1:$HOST_PORT/api/health" >/dev/null 2>&1; do
    if (( SECONDS >= deadline )); then
      return 1
    fi
    sleep 2
  done
}

log "Building $IMAGE"
docker build -t "$IMAGE" -t "$APP_NAME:latest" .

log "Starting $IMAGE on port $HOST_PORT"
run_container "$IMAGE"

if wait_healthy; then
  log "Deployed $IMAGE — http://127.0.0.1:$HOST_PORT"
  docker image prune -f >/dev/null
  exit 0
fi

log "Health check failed for $IMAGE"
docker logs --tail 50 "$APP_NAME" || true

if [[ -n "$PREV_IMAGE" && "$PREV_IMAGE" != "$IMAGE" ]]; then
  log "Rolling back to $PREV_IMAGE"
  run_container "$PREV_IMAGE"
  wait_healthy && log "Rollback succeeded" || log "Rollback also failed"
fi
exit 1
