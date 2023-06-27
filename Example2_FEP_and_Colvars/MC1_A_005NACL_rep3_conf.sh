#!/bin/bash
MAINDIR=$( cd .. && pwd )
simname=MC1_A_005NACL_rep3

pardir="$(cd .. && pwd )/parameters_Example2"
paramslist=( "${pardir}/par_water_ions.str" "${pardir}/par_all36_carb.prm" "${pardir}/GALP.par" )

inputfiles="$( pwd )/$simname"
source "$simname.pbc"
GENERAL_useflexiblecell="no"

GENERAL_wrapall="off"
GENERAL_wrapwater="on"
GENERAL_margin=3
GENERAL_timestep=1
GENERAL_nonbondedfreq=1
GENERAL_fullelectfreq=2
GENERAL_dcdfreq=5000

FEP_alchfile="${inputfiles}.pdb"
FEP_alchequilsteps=2500
FEP_alchoutfreq=500
FEP_alchvdwshiftcoeff=4.0
FEP_alchvdwlambdaend=0.6
FEP_alcheleclambdastart=0.44
FEP_alchdecouple="off"

GENERAL_colvars="on"
GENERAL_colvarsconfig="$(pwd)/overlay_A_B_atoms.colvars"

#Bash procedure defining how the run is executed.
simproc () {
    FEPmin_minsteps=25000
    FEP_lambdawindow=0.004
    FEPmin "01" "NONE" 1000000

    FEP_lambdastart=0.0
    FEP_lambdaend=1.0
    FEP_lambdawindow=0.004
    GENERAL_restartfreq=20000
    FEP "02" "coordsandpbc" 20000
    
    FEP_lambdastart=1.0
    FEP_lambdaend=0.0
    FEP_lambdawindow=-0.004
    FEP "03" "coordsandpbc" 20000
}

echo "#Collective variables to overlay vanishing and appearing heavy atoms in the carbohydrate ring of N2P residue" > overlay_A_B_atoms.colvars
cat >> overlay_A_B_atoms.colvars <<ENDL
colvarsRestartFrequency $GENERAL_restartfreq
colvarsTrajFrequency    $GENERAL_dcdfreq
ENDL
for name in "C1" "C2" "C3" "C4" "C5" "O5"; do
    cat >> overlay_A_B_atoms.colvars <<ENDL
colvar {
    name dist_${name}
    distance { 
        group1 { psfSegID P1
                 atomNameResidueRange A${name} 2-2 }
        group2 { psfSegID P1
                 atomNameResidueRange B${name} 2-2 }
    }
}

harmonic {
    colvars dist_${name}
    forceConstant 20.0
    centers 0.0
}
     
ENDL
done

