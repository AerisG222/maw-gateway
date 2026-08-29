#!/bin/bash
#
# Run the gateway locally against the stock nginx image. There is no image to
# build - the config is assembled onto disk and mounted into the container.
set -euo pipefail

ROOT=$(dirname "$(readlink -f "$0")")
STAGING_ROOT=/home/mmorano/maw-gateway/staging
CONF="${STAGING_ROOT}/nginx-conf"

"${ROOT}/stage-config.sh" staging "${CONF}"

podman run --rm \
    --name staging-maw-gateway \
    --publish "8000:8000" \
    --publish "8443:8443" \
    --volume "${CONF}:/etc/nginx/maw:ro,Z" \
    --volume "${STAGING_ROOT}/certs/:/certs:ro,Z" \
    --volume "${STAGING_ROOT}/certbot-notused-in-staging:/certbot:ro,z" \
    --volume "${STAGING_ROOT}/certbot-challenge-notused-in-staging:/certbot-challenge:ro,z" \
    docker.io/library/nginx:alpine \
        nginx -c /etc/nginx/maw/nginx.conf -g 'daemon off;'
