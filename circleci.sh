#!/bin/bash
set -euo pipefail

apk add --no-cache shellcheck

cd /root/bashops
cd src
shellcheck -x ./*
