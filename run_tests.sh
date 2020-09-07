#!/bin/bash

if ! command -v bats &>/dev/null; then
    echo "bats not found (brew install bats-core?)"
    exit 1
fi

bats -t test/*
