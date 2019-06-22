#!/bin/bash

function checkFile {
    [[ -f ${1} ]] || (echo "File not found '${1}'" && return 1)
}

function selfPath {
    dirname "$( readlink -f $0 )"
}