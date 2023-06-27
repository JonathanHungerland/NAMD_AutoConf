#!/bin/bash
MAINDIR=$( cd .. && pwd )
simname=6rko_no_uql

pardir="$(pwd)/parameters_Example2"
paramslist=( "${pardir}/par_all36_prot.prm" "${pardir}/par_all36_na.prm" "${pardir}/par_all36_carb.prm" "${pardir}/par_all36_lipid.prm" "${pardir}/par_all36_cgenff.prm" "${pardir}/toppar_all36*" "${pardir}/par_water_ions.str" "${pardir}/heme_met_his.prm" "${pardir}/quinones.prm" "${pardir}/toppar_hemeD.str")
inputfiles="$(pwd)/$simname"

GENERAL_pbc="on"
source $simname.pbc
GENERAL_pme="off"

GENERAL_margin=0
GENERAL_timestep="1.0"
GENERAL_rigidbonds="none"
GENERAL_dcdfreq=2500

GENERAL_constraints="on"
GENERAL_constraints="../../input/beta.pdb"

#Bash procedure defining how the run is executed.
simproc () {
    minimize "01" "NONE" "25000"
    slowNPT "02" "coordsandpbc" "25000"
    NPT "03" "coordsandpbc" "25000"
}
