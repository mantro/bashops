# bashops

## Purpose

bashops is a baseline for an idiomatic approach to working with [Blackbox](https://github.com/StackExchange/blackbox).

bashops introduces a lightweight structure to organize your secrets and some convenience methods to access them from your scripts.

By design it allows for an easy usage from `helm`, `ansible` and `plain bash scripts`.

## Idea

Imagine the following repo structure

```bash
.
|-- .bashops  # the files from this repo
|-- frontend
|-- server
|-- secrets
| |-- global
| | |-- database.yaml
| | |-- services.yaml
| |-- test
| | |-- test.yaml
| |-- prod
| | |-- prod.yaml
```

`secrets/global/database.yaml`:
```yaml
db_host: postgres
db_port: 5432
```

`secrets/global/services.yaml`:
```yaml
svc_host: service
svc_port: 80
```

`secrets/test/test.yaml`:
```yaml
basic_auth: true
```

`secrets/prod/prod.yaml`:
```yaml
basic_auth: false
```

The idea is combine these files into one `merged.yaml`.

```yaml
global:
  db_host: postgres
  db_port: 5432
  svc_host: service
  svc_port: 80
test:
  basic_auth: true
prod:
  basic_auth: false
target:
  basic_auth: true
```

If we know which `target` you have, an additional `target` key will be introduced:

```yaml
#...
target:
  basic_auth: false
```


## Installation

```bash

# go to gitroot
mkdir .bashops
cd .bashops

# download files
curl \
    -O https://raw.githubusercontent.com/mantro/bashops/master/src/.gitignore \
    -O https://raw.githubusercontent.com/mantro/bashops/master/src/bashops.sh \
    -O https://raw.githubusercontent.com/mantro/bashops/master/src/colors.sh
```

## Usage

Add it to your scripts

```bash
#!/bin/bash
set -euo pipefail

# go to directory of your current script
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1

# and source it (relatively to that directory)
source ../../.bashops/bashops.sh

# create the merged file
bashops_mergesecrets

# specify a target (create target key)
bashops_mergesecret "test"

# read a key from within bash
BASIC_AUTH=$(bashops_readsecret target.basic_auth)
echo "Basic auth enabled: $BASIC_AUTH"

# you would get a warning if bashops_readsecret does not yield a value
NOT_EXISTING=$(bashops_readsecret target.does.not.exist)

# you can reference the secrets file (to use in helm)
helm install --values "$BASHOPS_SECRETS_FILE" something from/somewhere

# or within ansible
ansible-playbook -i inventory playbook.yml -e @"$SECRETS_FILE"

```
