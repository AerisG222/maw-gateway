#!/bin/bash
while true; do
    sleep 6h
    echo '*** Reloading NGINX config ***'
    nginx -s reload
done & nginx -g "daemon off;"
