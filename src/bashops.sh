#!/bin/bash
set -euo pipefail

if ! command -v yq >/dev/null; then
    echo "Cannot find yq, please install it before"
    exit 1
fi

# change into the directory of this script
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
BASHOPS_DIR="$(pwd)"
export BASHOPS_DIR

# Load color support
source "./colors.sh"

BASHOPS_GITROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo -n '')"
[[ -z "${BASHOPS_GITROOT:-}" ]] && clr_red "Not git repo found, bailing" && exit 1
export BASHOPS_GITROOT

#  __     __         _       _     _
#  \ \   / /_ _ _ __(_) __ _| |__ | | ___  ___
#   \ \ / / _` | '__| |/ _` | '_ \| |/ _ \/ __|
#    \ V / (_| | |  | | (_| | |_) | |  __/\__ \
#     \_/ \__,_|_|  |_|\__,_|_.__/|_|\___||___/
#

# add config mechanism?
# . "config.sh"

[[ -z "${BASHOPS_SECRETS_DIR:-}" ]] && BASHOPS_SECRETS_DIR="$BASHOPS_GITROOT/ops/secrets"
export BASHOPS_SECRETS_DIR

[[ -z "${BASHOPS_SECRETS_FILE:-}" ]] && BASHOPS_SECRETS_FILE="$BASHOPS_DIR/.secrets.yaml"
export BASHOPS_SECRETS_FILE

#   _____                 _   _
#  |  ___|   _ _ __   ___| |_(_) ___  _ __  ___
#  | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
#  |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
#  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
#

function bashops_checkdecrypted() {

    FILES=$(find "$BASHOPS_SECRETS_DIR" -name '*.gpg')

    [[ -z "$FILES" ]] && clr_yellow "Cannot find any gpg file in $BASHOPS_SECRETS_DIR?" && exit 1

    while read -r file; do

        yaml=${file%.gpg}
        [[ ! -f "$yaml" ]] && {
            clr_red "Cannot find $yaml although $file exists, did you forget to decrypt?"
            exit 1
        }

    done <<<"$FILES"
}

function bashops_mergesecrets() {

    bashops_checkdecrypted

    # delete file first
    rm "$BASHOPS_SECRETS_FILE" 2>/dev/null || :

    # add header
    echo "# this file is auto generated" >"$BASHOPS_SECRETS_FILE"
    echo "# DO NOT check the file into git" >>"$BASHOPS_SECRETS_FILE"

    # merge files

    cd "$BASHOPS_SECRETS_DIR"
    for dir in *; do
        [[ ! -d "$dir" ]] && continue

        MERGED=$(find "$dir" -type f -name '*.yaml' -print0 | xargs -0 yq merge -a)
        {
            echo
            echo "# from: $dir"
        } >>"$BASHOPS_SECRETS_FILE"

        echo "$MERGED" | yq prefix - "$dir" >>"$BASHOPS_SECRETS_FILE"
    done
}

function bashops_readsecret() {
    OUTPUT=$(yq r "$BASHOPS_SECRETS_FILE" "${1}")
    [[ -z "$OUTPUT" ]] && clr_yellow "Warning: secret ${1} yielded empty string" 1>&2
    echo "$OUTPUT"
}

function bashops_mergetarget() {
    [[ -z "$1" ]] && clr_red "Please specify a target, e.g. test" && exit 1

    SETTINGS=$(bashops_readsecret "$1")
    [[ -z "$SETTINGS" ]] && clr_red "Cannot read settings for $1 from secrets" && exit 1

    # make current target available under "target"
    yq r "$BASHOPS_SECRETS_FILE" "$1" | yq p - target | yq m -a -i "$BASHOPS_SECRETS_FILE" -

    return 0
}

function bashops_ensurekubecontext() {

    CTX=$(kubectl config view --minify --output 'jsonpath={..current-context}')
    [[ "$SKIP_CHECK" != "yes" ]] &&
        echo "Current context: ${CTX}. Continue? (yes/no): " &&
        read -r YES &&
        [[ $YES != "yes" ]] &&
        echo "Aborting." &&
        exit 1

    :
}

function HEADER() {
    clr_green "###>"
    clr_green "###> $*"
    clr_green "###>"
}
