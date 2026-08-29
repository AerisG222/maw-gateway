#!/bin/bash
#
# Validate the nginx config for an environment using the stock nginx image.
#
# Throwaway self-signed certs are generated at the paths the config references,
# because "nginx -t" loads certificate and key files as part of the test.
#
# usage: ./validate-config.sh [staging | prod]
set -euo pipefail

MAW_ENV=${1:-}
IMG=${NGINX_IMAGE:-docker.io/library/nginx:alpine}

if [ "${MAW_ENV}" != 'staging' -a "${MAW_ENV}" != 'prod' ]; then
    echo "usage: $0 [staging | prod]"
    exit 1
fi

ROOT=$(dirname "$(readlink -f "$0")")
WORK=$(mktemp -d)
trap 'rm -rf "${WORK}"' EXIT

"${ROOT}/stage-config.sh" "${MAW_ENV}" "${WORK}/conf"

mkdir -p "${WORK}"/{certs,letsencrypt,certbot,varcache,varrun,logs}

openssl dhparam -out "${WORK}/certs/dhparam2048.pem" 2048 2>/dev/null

make_cert() {
    openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj "/CN=$1" \
        -keyout "$2" -out "$3" 2>/dev/null
}

if [ "${MAW_ENV}" = 'prod' ]; then
    for d in www.mikeandwan.us media.mikeandwan.us photos.mikeandwan.us; do
        mkdir -p "${WORK}/letsencrypt/live/${d}"
        make_cert "${d}" "${WORK}/letsencrypt/live/${d}/privkey.pem" \
                         "${WORK}/letsencrypt/live/${d}/fullchain.pem"
        cp "${WORK}/letsencrypt/live/${d}/fullchain.pem" "${WORK}/letsencrypt/live/${d}/chain.pem"
    done
else
    for s in maw-www maw-media maw-photos; do
        make_cert "staging-${s}.mikeandwan.us" "${WORK}/certs/${s}.key" "${WORK}/certs/${s}.crt"
    done

    cp "${WORK}/certs/maw-www.crt" "${WORK}/certs/maw-ca.crt"
fi

# mirrors the securityContext / volumeMounts in deploy/templates/kube.yml.j2
podman run --rm \
    --read-only \
    --user 0:0 \
    --env NGINX_ENTRYPOINT_QUIET_LOGS=1 \
    --volume "${WORK}/conf:/etc/nginx/maw:ro,Z" \
    --volume "${WORK}/certs:/certs:ro,Z" \
    --volume "${WORK}/letsencrypt:/etc/letsencrypt:ro,Z" \
    --volume "${WORK}/certbot:/var/www/certbot:ro,Z" \
    --volume "${WORK}/varcache:/var/cache/nginx:Z" \
    --volume "${WORK}/varrun:/var/run:Z" \
    --volume "${WORK}/logs:/var/log/nginx:Z" \
        "${IMG}" \
            nginx -t -c /etc/nginx/maw/nginx.conf
