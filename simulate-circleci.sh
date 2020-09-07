#!/bin/bash
set -euo pipefail

GITROOT="$(git rev-parse --show-toplevel)"

docker run \
    -v "${GITROOT}:/root/bashops" \
    alpine:3.12.0 \
    /bin/sh -c "apk add bash shellcheck && cd /root/bashops && /bin/bash ./circleci.sh"
