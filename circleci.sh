#!/bin/bash
set -euo pipefail

echo "###> "
echo "###> Install packages"
echo "###> "
apk add shellcheck git gnupg curl

echo "###> "
echo "###> Install BATS"
echo "###> "
cd /tmp
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local

echo "###> "
echo "###> Prepare GNUPG"
echo "###> "
gpg2 --batch --gen-key <<EOF
%no-protection
Key-Type:1
Key-Length:2048
Subkey-Type:1
Subkey-Length:2048
Name-Real: CircleCI
Name-Email: circleci@circleci.com
Expire-Date:0
EOF
export GPG_USER="circleci@circleci.com"

echo "###> "
echo "###> Install blackbox"
echo "###> "
VERSION="1.20200429"
LINK="https://github.com/StackExchange/blackbox/archive/v${VERSION}.tar.gz"
curl -sL "$LINK" | tar xzv --strip-components=2 "blackbox-${VERSION}/bin" -C /usr/local/bin

echo "###> "
echo "###> Install yq"
echo "###> "
wget -O /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/3.3.2/yq_linux_amd64"
chmod 750 /usr/local/bin/yq

echo "###> "
echo "###> Git configuration (for git init)"
echo "###> "
git config --global user.email "circleci@circleci.com"
git config --global user.name "CircleCI"

cd /root/bashops
cd src
shellcheck -x ./*

cd /root/bashops
./run_tests.sh
