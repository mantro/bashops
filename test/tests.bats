#!/usr/bin/env bats
set -euo pipefail

if [[ -z "${GPG_USER:-}" ]]; then
    echo "Please specify a GPG_USER (with private key)"
    exit 1
fi

cd "$BATS_TEST_DIRNAME"
TMP_DIR="$BATS_TEST_DIRNAME/tmp"

function setup() {
    rm -rf "$TMP_DIR" || :
    mkdir "$TMP_DIR"

    cp -R "../src" "$TMP_DIR"
    cd "$TMP_DIR"
    run git init
    run mkdir -p "ops/secrets"
    source src/bashops.sh
}

function teardown() {
    rm -rf "$TMP_DIR" || :
    :
}

@test "bashops loads colors.sh" {
    type clr_green
}

@test "bashops correctly identifies git root" {

    [ "$BASHOPS_GITROOT" = "$TMP_DIR" ]
}

@test "bashops correctly identifies secrets dir" {

    cd "$TMP_DIR/ops/secrets"

    [[ "$TMP_DIR/ops/secrets" = "$BASHOPS_SECRETS_DIR" ]]
}

@test "bashops correctly identifies unencrypted .gpg files" {

    cd "$TMP_DIR/ops/secrets"
    run touch something.gpg

    set +e
    $(bashops_mergesecrets >&3)
    RET="$?"
    set -e

    [ "$RET" -ne 0 ]
}

@test "bashops correctly decryptes .gpg files" {

    cd "$TMP_DIR/ops/secrets"
    run mkdir global
    echo "works: true" > global/global.yaml

    cd "$TMP_DIR"
    yes | blackbox_initialize >/dev/null || :

    blackbox_addadmin "$GPG_USER" >/dev/null
    blackbox_register_new_file "ops/secrets/global/global.yaml" >/dev/null
    blackbox_decrypt_all_files >/dev/null

    set +e
    $(bashops_mergesecrets >&3)
    RET="$?"
    set -e

    [ "$RET" -eq 0 ]

    YAML=$(cat $TMP_DIR/ops/secrets/global/global.yaml)
    [ "$YAML" = "works: true" ]
}

@test "bashops correctly merges .gpg files" {

    cd "$TMP_DIR/ops/secrets"
    run mkdir "global"
    echo "value: 1" > global/global.yaml
    run mkdir "local"
    echo "value: 2" > local/local.yaml

    cd "$TMP_DIR"
    yes | blackbox_initialize >/dev/null || :

    blackbox_addadmin "$GPG_USER" >/dev/null
    blackbox_register_new_file "ops/secrets/global/global.yaml" >/dev/null
    blackbox_register_new_file "ops/secrets/local/local.yaml" >/dev/null
    blackbox_decrypt_all_files >/dev/null

    set +e
    $(bashops_mergesecrets >/dev/null)
    RET="$?"
    set -e

    [ "$RET" -eq 0 ]

    VAL1=$(yq r $BASHOPS_SECRETS_FILE 'global.value')
    [ "$VAL1" -eq 1 ]

    VAL2=$(yq r $BASHOPS_SECRETS_FILE 'local.value')
    [ "$VAL2" -eq 2 ]
}
