#!/bin/bash
function genMol2 {
    smifile=${1:-lig.smi}
    ph=${2:-7.2}
    checkFile $smifile || return 1
    obabel -ismi $smifile -omol2 --gen3D | obabel -imol2 -omol2 -d --p $ph
}

function getMol2Atoms {
    infile=${1}
    checkFile $infile || return 1
    cat $infile | sed -n '/@<TRIPOS>ATOM/,/@<TRIPOS>BOND/p' | head -n -1 | tail -n +2
}

function getMol2Title {
    infile=${1}
    checkFile $infile || return 1
    awk 'NR==2  {print}' $infile
}

function calcMol2Charge {
    inligfile=${1}
    checkFile $infile || return 1
    getMol2Atoms $inligfile | awk '{sum += $NF} END {print sum}'
}

function prepGaussian {
    infile=${1}
    checkFile $infile || return 1
    outfile=${2:-infile%%.mol2}.com
    charge=$(calcMol2Charge $infile)
    title=$(getMol2Title $infile)
    antechamber -i $infile -fi mol2 -o $outfile -fo gcrt -nc "$charge" -ch $title
}

function parseGaussian {
    infile=${1}
    checkFile $infile || return 1
    title=${2:-"LIG"}
    outfile=${2:-infile%%.log}_opt.mol2
    mkdir $title
    cd $title
    antechamber -i ../$infile -fi gout -o ../$outfile -fo mol2 -c resp -rn $title -at amber
    cd ..
    rm -rf $title
}

function genFrcmod {
    infile=${1}
    checkFile $infile || return 1
    title=${2:-"LIG"}
    parmfile=${3:-"$AMBERHOME/dat/leap/parm/parm10.dat"}
    parmchk2 -i $infile -f mol2 -o ${title}.frcmod -p $parmfile
}

function genVacuumMDSystem {
    residue=${1:-LIG}
    leaprc=${2:-"$AMBERHOME/dat/leap/cmd/leaprc.protein.ff14SB"}
    tleap -f $leaprc -f - <<EOF
${residue}parm = loadAmberParams ${residue}.frcmod
$residue = loadMol2 ${residue}_opt.mol2
check $residue
saveAmberParm $residue ${residue}.prmtop ${residue}.crd
quit
EOF
    
}

function runMD {
    infile=${1}
    residue=${2:-LIG}
    crdfile=${3:-"${residue}.crd"}
    topfile=${4:-"${residue}.prmtop"}
    rstfile=${5:-"${residue}.rst"}
    trjfile=${6:-"${residue}.mdcrd"}
    checkFile $crdfile
    checkFile $topfile
    checkFile $infile
    bname=$(basename ${infile%%.in})
    mkdir ${bname} -p
    cp $infile $crdfile $topfile ${bname}
    infile=$(basename ${infile})
    crdfile=$(basename ${crdfile})
    topfile=$(basename ${topfile})
    outfile=${infile%%.in}.out
    cd ${bname}
    sander -O -i $infile -o $outfile -p $topfile -c $crdfile -x $trjfile -r $rstfile || return 1
    cd ..
}

function genLigOff {
    residue=${1:-LIG}
    leaprc=${2:-"$AMBERHOME/dat/leap/cmd/leaprc.protein.ff14SB"}
    tleap -f $leaprc -f - <<EOF
${residue}parm = loadAmberParams ${residue}.frcmod
$residue = loadMol2 ${residue}_opt.mol2
check $residue
saveOff $residue ${residue}.off
saveOff ${residue}parm ${residue}.off
quit
EOF
}