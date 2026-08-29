#!/bin/bash
#
# Assemble the nginx config tree for an environment into a destination directory.
# The result is what gets mounted at /etc/nginx/maw inside the container.
#
# This mirrors the "Stage nginx config" tasks in deploy/maw-gateway-playbook.yml,
# which do the same assembly on the remote host during a real deployment.
#
# usage: ./stage-config.sh [staging | prod] <destination-dir>
set -euo pipefail

MAW_ENV=${1:-}
DEST=${2:-}

if [ "${MAW_ENV}" != 'staging' -a "${MAW_ENV}" != 'prod' ]; then
    echo "usage: $0 [staging | prod] <destination-dir>"
    exit 1
fi

if [ "${DEST}" = '' ]; then
    echo "usage: $0 [staging | prod] <destination-dir>"
    exit 1
fi

SRC=$(dirname "$(readlink -f "$0")")/etc/nginx

mkdir -p "${DEST}/conf.d"

for f in nginx.conf tls.conf compression.conf cache-file-descriptors.conf; do
    cp "${SRC}/${f}" "${DEST}/${f}"
done

cp "${SRC}/${MAW_ENV}.proxy.conf" "${DEST}/proxy.conf"

for s in maw-media maw-photos maw-www; do
    cp "${SRC}/conf.d/${MAW_ENV}.${s}.conf" "${DEST}/conf.d/${s}.conf"
done
