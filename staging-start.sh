#!/bin/bash

podman run --rm \
    --name staging-maw-gateway \
    --publish "8000:80" \
    --publish "8443:443" \
    --volume "/home/mmorano/maw-gateway/staging/certs/:/certs:ro,Z" \
    --volume "/home/mmorano/maw-gateway/staging/certbot-notused-in-staging:/certbot:ro,z" \
    --volume "/home/mmorano/maw-gateway/staging/certbot-challenge-notused-in-staging:/certbot-challenge:ro,z" \
    localhost/maw-gateway-staging
