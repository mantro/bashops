#!/bin/bash
set -euo pipefail

cd /root/bashops
cd src
shellcheck -x ./*
