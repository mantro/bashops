# bashops

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
```
