#!/bin/bash

function checkBinary {
    which ${1} || { echo "File not found '${1}'"; return 1; }
}


#check for AMBER dependencies

function checkAmbertools {
    echo "Checking ambertools vars and binaries..."
    [[ -z "$AMBERHOME" ]] && { echo "AMBERHOME is not set" ; return 1 ; }
    binaries="tleap cpptraj parmchk2 antechamber"
    for bin in $binaries; do
        checkBinary $bin || return 1
    done
    echo "[SUCCESS]"
}


#check for OpenBabel dependencies

function checkObabel {
    echo "Checking openbabel and format plugins..."
    checkBinary obabel || return 1
    [[ $(obabel -L formats | egrep '^smi --' -c) -eq 1 ]] || \
        { echo "format plugin for smi not found"; return 1; }
    [[ $(obabel -L formats | egrep '^mol2 --' -c) -eq 1 ]] || \
        { echo "format plugin for mol2 not found"; return 1; }
    echo "[SUCCESS]"
}


#check for gaussian dependencies

function checkGaussian {
    echo "Checking gaussian..."
    checkBinary g09 || return 1
    echo "[SUCCESS]"
}
