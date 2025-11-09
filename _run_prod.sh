#!/bin/bash
while true; do
    sleep 24h
    echo '*** Reloading NGINX config ***'
    nginx -s reload
done & nginx -g "daemon off;"
