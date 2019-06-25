#!/bin/bash

source config.sh
source scripts/molfunctions.sh
source scripts/util.sh
source scripts/depcheck.sh

function molgenUsage {
    cat templates/molgenUsage.txt
}

function molgenCheckdeps {
    checkAmbertools return 1
    checkObabel return 1
    checkGaussian || return 1
}

function molgenFrcmod {
    genMol2 ../$ligfile > ${residue}.mol2 && \
    prepGaussian ${residue}.mol2 $residue && \
    g16 ${residue}.com 
    parseGaussian ${residue}.gesp $residue && \
    genFrcmod ${residue}_opt.mol2 $residue || return 1
    echo "Please, modify the molecule/${residue}.frcmod file."
    confirm "Type Y or y when you're done: "
}

function molgenMD {
    genVacuumMDSystem $residue $leaprc && \
    runMD ../templates/vac_min.in $residue && \
    runMD ../templates/vac_md.in $residue vac_min/${residue}.rst || return 1
    echo "Please, check the molecule behaves as expected in vacuum md."
    echo "You can load the trajectory by:"
    echo "    vmd -f molecule/vac_md/${residue}.prmtop molecule/vac_md/${residue}.mdcrd"
    confirm "Type Y or y to continue: "
}

function molgenGenOff {
    genLigOff ${residue} $leaprc && \
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
        md)
            molgenMD || return 1
            ;&
        genoff)
            molgenGenOff || return 1
            ;;
        *)
            echo $"Usage: $0 [{check|frcmod|md|genoff}]" >&2
            return 1
    esac
    cd $CWD
}

# entry point

molgen $1