#!/bin/bash

# Exit on error
set -e

# Ensure logs are redirected to Docker log system
ln -sf /dev/stdout /var/log/nginx/access.log
ln -sf /dev/stderr /var/log/nginx/error.log

nginx -t

# Start nginx in foreground (as PID 1)
exec nginx -g "daemon off;"

