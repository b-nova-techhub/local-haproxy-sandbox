#!/bin/bash

readonly IMAGE_TAG=b-nova-techup/haproxy:0.0.0

frontend_bind="8585"
backend_ip="127.0.0.1"
backend_port="80"

docker build --quiet=true --tag $IMAGE_TAG .

echo "Validating config file..."

docker run --rm -it -e FRONTEND_BIND=$frontend_bind -e BACKEND_IP=$backend_ip -e BACKEND_PORT=$backend_port $IMAGE_TAG haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg

echo "Starting proxy and echo-server..."

docker network create --driver=bridge cluster
docker run --rm -d --name echo --net cluster ealen/echo-server:latest
docker run --rm -d --name proxy --net cluster -p $frontend_bind:$frontend_bind -p 8404:8404 -e FRONTEND_BIND=$frontend_bind -e BACKEND_IP=$backend_ip -e BACKEND_PORT=$backend_port $IMAGE_TAG

set -B
for i in {1..10}; do
  curl -s -k 'GET' -H 'header info' -b 'body' '$backend_ip:'$frontend_bind'/id='$i
  sleep 1s
done

docker stop echo
docker stop proxy
docker network rm cluster
