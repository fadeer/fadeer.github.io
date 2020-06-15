#!/bin/bash
set -e
export DOCKER_BUILDKIT=1

proxy="10.10.1.99:2379"

docker build \
    --build-arg http_proxy="http://${proxy}" \
    --build-arg https_proxy="http://${proxy}" \
    -t github-pages:latest .

# docker run -t --rm -v "$PWD":/blog -p "4000:4000" github-pages
