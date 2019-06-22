#!/bin/bash

source config.sh
source scripts/molfunctions.sh
source scripts/files.sh
source scripts/util.sh
source scripts/depcheck.sh

function molgenUsage {
    cat templates/molgenUsage.txt
}

function molgenCheckdeps {
    checkAmbertools return 1
    checkObabel return 1
    # checkGaussian || return 1
}

function molgenFrcmod {
    genMol2 ../$ligfile > ${residue}.mol2
    prepGaussian ${residue}.mol2 $residue
    #this is just for testing localy
    #g09 ${residue}.com
    parseGaussian ${residue}.log $residue
    genFrcmod ${residue}_opt.mol2 $residue
    confirm "Please, modify the ${residue}.frcmod and type Y or y when you're done: " || return 1
}

function molgenMD {
    genVacuumMDSystem $residue $leaprc
    runMD ../templates/vac_min.in $residue
    runMD ../templates/vac_md.in $residue vac_min/${residue}.rst
    confirm "Please, check the molecule behaves as expected in vacuum md. Type Y or y to continue: " || return 1
}

function molgenGenOff {
    genLigOff ${residue} $leaprc
    mv ${residue}.off ../results/
}

function molgen {
    CWD="$PWD"
    mkdir -p molecule results
    cd molecule
    stage=${1:-check}
    case $stage in
        check)
            molgenCheckdeps || return 1
            ;&
        frcmod)
            molgenFrcmod || return 1
            ;&
        mdcheck)
            molgenMD || return 1
            ;&
        genoff)
            molgenGenOff || return 1
            ;;
        *)
            echo $"Usage: $0 [{check|frcmod|mdcheck|genoff}]" >&2
            return 1
    esac
    cd $CWD
}

# entry point

molgen $1