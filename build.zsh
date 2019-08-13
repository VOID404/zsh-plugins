#!/bin/zsh
mkdir -p "${PWD}/completion"

kubectl completion zsh >! "${PWD}/completion/_kubectl"
helm completion zsh >! "${PWD}/completion/_helm"

fpath+="${PWD}/completion"
