#!/bin/bash
LC_NUMERIC="en_US.UTF-8"

main () {
default_settings
source $1
mkcd $simname
simproc
}

#All simulation stages can be executed by
#[name] [stagenumber] [inputtype] [numsteps]
#stagenumber is expected in the form 01 02 etc.
#if inputtype is: "NONE", then nothing from a previous stage is reused
#if inputtype is: "coordsonly", then only the coordinates and velocities
#                  are restored. pbc is taken from the values xpbc, ypc and zpbc
#if inputtype is: any other string, then pbc, coordinates and velocities are restored
#                 from the previous stage.
#
###############       Defined simulation stages:         ############################
#minimize    : minimization for numsteps in NVT ensemble.
#
#NVT         : running for numsteps in NVT ensemble.
#
#NPT         : running for numsteps in the NPT ensemble with standard pressure control where
#              langevinPistonPeriod 200.0    and   langevinPistonDecay 50.0    are used.
#
#slow_NPT    : running for numsteps in the NPT ensemble with slowly reacting barostat. the values
#              langevinPistonPeriod 1000.0   and   langevinPistonDecay 250.0   are used.
#
#breathing   : heating from $GENERAL_temperature to $breath_in_temp and back over a total of numsteps steps
#              with incremental temperature increase/decrease of $breath_increment while maintaining
#              constant pressure with the standard barostat.
#TREX        : (watch for number of necessary replicas)
#
#REST2       : (watch for number of necessary replicas, though less than for TREX)
#
#cPH (needs fixing, weirdly no switching at last try)
#

default_settings () {
    #from VMD build of polymers
    resnames="GLCA GALN GLCP"
    polbuild_fromsel_text="name C3 O3 C4 O4"
    polbuild_tosel_text="name C1 O1 HO1 H1"

    #for restarts from wall-time aborts
    firstrun="to_be_done"

    #GENERAL settings used here to steer behaviour of the script.
    GENERAL_restarttype="simple"

    #output settings
    GENERAL_restartfreq=25000
    GENERAL_dcdfreq=5000
    GENERAL_veldcdfreq=0
    GENERAL_xstfreq=5000
    GENERAL_outputenergies=10000
    GENERAL_outputpressure=10000

    ## NAMD SECTION ##
    #Defines general settings as GENERAL_<NAMD keyword> with all lowercase letters, but replacing "-" by "_".
    GENERAL_margin=0
    GENERAL_timestep="1"
    GENERAL_rigidbonds="none"
    GENERAL_nonbondedfreq="1"
    GENERAL_fullelectfrequency="2"
    GENERAL_stepspercycle="20"
    GENERAL_pairlistspercycle="2"

    #interaction distances and scaling
    GENERAL_exclude="scaled1-4"
    GENERAL_1_4scaling="1.0"
    GENERAL_cutoff="12.0"
    GENERAL_switching="on"
    GENERAL_switchdist="10.0"
    GENERAL_pairlistdist="13.5"

    #implicit solvent settings
    GENERAL_gbis="off"
    GENERAL_solventdielectric="78.5"
    GENERAL_ionconcentration="0.15"

    #periodic boundary concitions
    GENERAL_pbc="on"
    xorigin=0
    yorigin=0
    zorigin=0
    GENERAL_wrapall="on"
    GENERAL_sphericalbccenter="0.0 0.0 0.0"
    GENERAL_sphericalbcr1="20.0"
    GENERAL_sphericalbck1="5.0"
    GENERAL_sphericalbcexp1="2"

    GENERAL_custompbc="off"

    #tclBC
    GENERAL_tclbc="off"
    GENERAL_tclbcscript="$MAINDIR/02_Simulation_Setup/zWalls_tclBC.tcl"
    GENERAL_tclbcargs="2.0 -10.0 75.0"

    #full electrostatics
    GENERAL_pme="yes"
    GENERAL_pmegridspacing="1.0"
    GENERAL_msm="no"
    GENERAL_msmgridspacing=2.5
    GENERAL_msmquality=0
    GENERAL_msmxmin=""
    GENERAL_msmxmax=""
    GENERAL_msmymin=""
    GENERAL_msmymax=""
    GENERAL_msmzmin=""
    GENERAL_msmzmax=""

    #standard temperature settings
    GENERAL_temperature=300
    GENERAL_langevin="yes"
    GENERAL_langevindamping="5.0"
    GENERAL_langevinhydrogen="off"

    #standard pressure settings
    GENERAL_usegrouppressure="yes"
    GENERAL_useflexiblecell="yes"
    GENERAL_langevinpiston="on"
    GENERAL_langevinpistontarget="1.01325"
    GENERAL_langevinpistonperiod="200.0"
    GENERAL_langevinpistondecay="50.0"

    GENERAL_excludefrompressure="off"
    GENERAL_excludefrompressurefile="Setting GENERAL_excludefrompressurefile required."
    GENERAL_excludefrompressurecol="O"

    slowNPT_usegrouppressure=$GENERAL_usegrouppressure
    slowNPT_useflexiblecell=$GENERAL_useflexiblecell
    slowNPT_langevinpistontarget=$GENERAL_langevinpistonperiod
    slowNPT_langevinpistonperiod=10000
    slowNPT_langevinpistondecay=2500

    #atom constraints
    GENERAL_constraints="off"
    GENERAL_consexp=2
    GENERAL_consref="Setting GENERAL_consref required"
    GENERAL_conskfile="Setting GENERAL_consref required"
    GENERAL_conskcol="B"
    GENERAL_constraintscaling=1.0
    GENERAL_selectconstraints="off"
    GENERAL_selectconstrx="off"
    GENERAL_selectconstry="off"
    GENERAL_selectconstrz="off"

    #fixed atoms
    GENERAL_fixedatoms="off"
    GENERAL_fixedatomsforces="off"
    GENERAL_fixedatomsfile="Setting GENERAL_fixedatomsfile required."
    GENERAL_fixedatomscol="B"

    #constant force
    GENERAL_constantforce="no"
    GENERAL_consforcefile="Setting GENERAL_consforcefile required"

    #SMD
    GENERAL_smd="off"
    GENERAL_smdfile="Setting GENERAL_smdfile required"
    GENERAL_smdk=10
    GENERAL_smdk2=0
    GENERAL_smdvel="5e-3"
    GENERAL_smddir="1.0 0.0 0.0"
    GENERAL_smdoutputfreq=5000

    #colvars settigns
    GENERAL_colvars="off"
    GENERAL_colvarsconfig="NONE"

    #FEP settings
    FEP_pdb="$inputfiles.pdb"
    FEP_psf="$inputfiles.psf"
    FEP_alchfile="$inputfiles.pdb"
    FEP_alchcol="B"
    FEP_alchoutfreq=$( perl -E "say $GENERAL_dcdfreq/$GENERAL_stepspercycle" )
    FEP_alchvdwlambdaend=0.7
    FEP_alcheleclambdastart=0.4
    FEP_alchvdwshiftcoeff=6.0
    FEP_alchdecouple="on"
    FEP_alchequilsteps=$GENERAL_dcdfreq
    FEP_lambdastart=0.0
    FEP_lambdaend=1.0
    FEP_lambdawindow="Setting FEP_lambdawindow required"

   #FEPmin settings
   FEPmin_pressurecontrol="on"
}


minimize () {
    local simstage=$1
    local simrep=${1}_01
    local inputtype=$2
    local numsteps=$3

    if [ $( find . -type d -regex "./${simstage}.*" ) ]; then
        echo "Stage ${simstage} already exists."
        cd ${simstage}_minimize
        stage_runner $simstage
        return
    fi
    mkcd ${simstage}_minimize
    header $simstage $inputtype
    parameter_settings
    pressure_control
    cat >> $simrep.conf <<ENDL
#Perform minimization
langevinTemp $GENERAL_temperature
langevinPistonTemp $GENERAL_temperature
minimize [expr $numsteps - (\$currenttimestep - \$last_stage_last_step)]
ENDL
echo "Running minimize with stage number $simstage"
stage_runner $simstage
}

heating () {
    local simstage=$1
    local simrep=${1}_01
    local inputtype=$2
    local numsteps=$3

    if [ $( find . -type d -regex "./${simstage}.*" ) ]; then
        echo "Stage ${simstage} already exists."
        cd ${simstage}_heating
        stage_runner $simstage
        return
    fi
    mkcd ${simstage}_heating
    header $simstage $inputtype
    parameter_settings
    pressure_control
    cat >> $simrep.conf <<ENDL
set steps_per_temp [expr {${numsteps}/(2*(${HEATING_targettemperature}-${HEATING_starttemperature})/${HEATING_increment})}]
#make sure steps_per_temp is a multiple of GENERAL_stepspercycle
set steps_per_temp [expr {\$steps_per_temp - ( \$steps_per_temp % $GENERAL_stepspercycle )}]
set expected_step \${last_stage_last_step}
set temperature $HEATING_starttemperature
langevinTemp \$temperature
langevinPistonTemp \$temperature
run 0
print "Starting heating."
print "Last_stage_last_step is \${last_stage_last_step}."
print "Currenttimestep is \${currenttimestep}."
print "Steps_per_temp is \${steps_per_temp}."
for {set temp \$temperature} {\$temp<=$HEATING_targettemperature} {incr temp ${HEATING_increment}} {
    langevinTemp \$temp
    langevinPistonTemp \$temp
    set steps_to_do [expr {\${expected_step}-\${currenttimestep}+\${steps_per_temp}} ]
    if { \${steps_to_do} > 0 } {
        run \${steps_to_do}
        set currenttimestep [expr \${expected_step}+\${steps_to_do} ]
        set expected_step [expr \${expected_step}+\${steps_per_temp} ]
    } else {
        set expected_step [expr \${expected_step}+\${steps_per_temp} ]
    }
}
ENDL
echo "Running heating with stage number $simstage"
stage_runner $simstage
}

cooling () {
    local simstage=$1
    local simrep=${1}_01
    local inputtype=$2
    local numsteps=$3

    if [ $( find . -type d -regex "./${simstage}.*" ) ]; then
        echo "Stage ${simstage} already exists."
        cd ${simstage}_cooling
        stage_runner $simstage
        return
    fi
    mkcd ${simstage}_cooling
    header $simstage $inputtype
    parameter_settings
    pressure_control
    cat >> $simrep.conf <<ENDL
set steps_per_temp [expr {${numsteps}/(2*(${COOLING_starttemperature}-${COOLING_targettemperature})/${COOLING_increment})}]
#make sure steps_per_temp is a multiple of GENERAL_stepspercycle
set steps_per_temp [expr {\$steps_per_temp - ( \$steps_per_temp % $GENERAL_stepspercycle )}]
set expected_step \${last_stage_last_step}
set temperature $COOLING_starttemperature
langevinTemp \$temperature
langevinPistonTemp \$temperature
run 0
print "Starting cooling."
print "Last_stage_last_step is \${last_stage_last_step}."
print "Currenttimestep is \${currenttimestep}."
print "Steps_per_temp is \${steps_per_temp}."
for {set temp \$temperature} {\$temp>=$COOLING_targettemperature} {incr temp -${COOLING_increment}} {
    langevinTemp \$temp
    langevinPistonTemp \$temp
    set steps_to_do [expr {\${expected_step}-\${currenttimestep}+\${steps_per_temp}} ]
    if { \${steps_to_do} > 0 } {
        run \${steps_to_do}
        set currenttimestep [expr \${expected_step}+\${steps_to_do} ]
        set expected_step [expr \${expected_step}+\${steps_per_temp} ]
    } else {
        set expected_step [expr \${expected_step}+\${steps_per_temp} ]
    }
}
ENDL
echo "Running cooling with stage number $simstage"
stage_runner $simstage
}

breathing () {
    #breathing is essentially a direct version of heating + cooling in one stage
    local simstage=$1
    local simrep=${1}_01
    local inputtype=$2
    local numsteps=$3

    if [ $( find . -type d -regex "./${simstage}.*" ) ]; then
        echo "Stage ${simstage} already exists."
        cd ${simstage}_breathing
        stage_runner $simstage
        return
    fi
    mkcd ${simstage}_breathing
    header $simstage $inputtype
    parameter_settings
    pressure_control
    cat >> $simrep.conf <<ENDL
#Run a breath-in and breath-out of an annealing procedure
set steps_per_temp [expr {${numsteps}/(2*(${breath_in_temp}-${temperature})/${breath_increment})}]
#make sure steps_per_temp is a multiple of GENERAL_stepspercycle
set steps_per_temp [expr {\$steps_per_temp - ( \$steps_per_temp % $GENERAL_stepspercycle )}]
set expected_step \${last_stage_last_step}
set temperature $GENERAL_temperature
langevinTemp \$temperature
langevinPistonTemp \$temperature
run 0
print "Starting heating."
print "Last_stage_last_step is \${last_stage_last_step}."
print "Currenttimestep is \${currenttimestep}."
print "Steps_per_temp is \${steps_per_temp}."
for {set temp \$temperature} {\$temp<=$breath_in_temp} {incr temp ${breath_increment}} {
    langevinTemp \$temp
    langevinPistonTemp \$temp
    set steps_to_do [expr {\${expected_step}-\${currenttimestep}+\${steps_per_temp}} ]
    if { \${steps_to_do} > 0 } {
        run \${steps_to_do}
        set currenttimestep [expr \${expected_step}+\${steps_to_do} ]
        set expected_step [expr \${expected_step}+\${steps_per_temp} ]
    } else {
        set expected_step [expr \${expected_step}+\${steps_per_temp} ]
    }
}
print "Starting cooling."
for {set temp $breath_in_temp} {\$temp>=\$temperature} {incr temp -${breath_increment}} {
    langevinTemp \$temp
    langevinPistonTemp \$temp
    set steps_to_do [expr {\${expected_step}-\${currenttimestep}+\${steps_per_temp}} ]
    if { \${steps_to_do} > 0 } {
        run \${steps_to_do}
        set currenttimestep [expr \${expected_step}+\${steps_to_do} ]
        set expected_step [expr \${expected_step}+\${steps_per_temp} ]
    } else {
        set expected_step [expr \${expected_step}+\${steps_per_temp} ]
    }
}
ENDL
echo "Running breathing with stage number $simstage"
stage_runner $simstage
}

NVT () {
    local simstage=$1
    local simrep=${1}_01
    local inputtype=$2
    local numsteps=$3

    if [ $( find . -type d -regex "./${simstage}.*" ) ]; then
        echo "Stage ${simstage} already exists."
        cd ${simstage}_NVT
        stage_runner $simstage
        return
    fi
    mkcd ${simstage}_NVT
    header $simstage $inputtype
    parameter_settings
    cat >> $simrep.conf <<ENDL
langevinTemp $GENERAL_temperature
run [expr $numsteps - (\$currenttimestep - \$last_stage_last_step)]
ENDL
echo "Running NVT with stage number $simstage"
stage_runner $simstage
}

NPT () {
    #Give the desired duration in nanoseconds. Assuming 1fs timestep.
    local simstage=$1
    local simrep=${1}_01
    local inputtype=$2
    local numsteps=$3

    if [ $( find . -type d -regex "./${simstage}.*" ) ]; then
        echo "Stage ${simstage} already exists."
        cd ${simstage}_NPT
        stage_runner $simstage
        return
    fi
    mkcd ${simstage}_NPT
    header $simstage $inputtype
    parameter_settings
    pressure_control
    cat >> $simrep.conf <<ENDL
langevinTemp $GENERAL_temperature
langevinPistonTemp $GENERAL_temperature
run [expr $numsteps - (\$currenttimestep - \$last_stage_last_step)]
ENDL
echo "Running NPT with stage number $simstage"
stage_runner $simstage
}

slowNPT () {
    local simstage=$1
    local inputtype=$2
    local numsteps=$3
    local simrep=${1}_01

    if [ $( find . -type d -regex "./${simstage}.*" ) ]; then
        echo "Stage ${simstage} already exists."
        cd ${simstage}_slowNPT
        stage_runner $simstage
        return
    fi
    mkcd ${simstage}_slowNPT
    header $simstage $inputtype
    parameter_settings
    cat >> $simrep.conf <<ENDL
#Constant pressure control
useGroupPressure      ${slowNPT_usegrouppressure}
useFlexibleCell       ${slowNPT_useflexiblecell}

langevinPiston         on
langevinPistonTarget  ${slowNPT_langevinpistontarget}
langevinPistonPeriod  ${slowNPT_langevinpistonperiod}
langevinPistonDecay   ${slowNPT_langevinpistondecay}

langevinTemp $GENERAL_temperature
langevinPistonTemp $GENERAL_temperature
run [expr $numsteps - (\$currenttimestep - \$last_stage_last_step)]
ENDL
echo "Running slowNPT with stage number $simstage"
stage_runner $simstage
}

FEPmin () {
    local simstage=$1
    local inputtype=$2
    local numsteps=$3
    local simrep=${1}_01

    if [ $( find . -type d -regex "./${simstage}.*" ) ]; then
        echo "Stage ${simstage} already exists."
        cd ${simstage}_FEPmin
        stage_runner $simstage
        return
    fi
    mkcd ${simstage}_FEPmin

    header $simstage $inputtype
    parameter_settings
    if [ "${FEPmin_pressurecontrol}" == "on" ]; then
       pressure_control
    fi

cat >> $simrep.conf <<ENDL
langevinTemp $GENERAL_temperature
langevinPistonTemp $GENERAL_temperature

source $MAINDIR/02_Simulation_Setup/fep.tcl

#FEP parameters
alch                on
alchType            FEP
alchFile            $FEP_alchfile
alchCol             $FEP_alchcol
alchOutfile         $simrep.fepout
alchOutFreq         $FEP_alchoutfreq

alchVdwLambdaEnd    $FEP_alchvdwlambdaend
alchElecLambdaStart $FEP_alcheleclambdastart
alchVdwShiftCoeff   $FEP_alchvdwshiftcoeff
alchDecouple        $FEP_alchdecouple

alchEquilSteps      $FEP_alchequilsteps

set LambdaStart     $FEP_lambdastart
set LambdaEnd       $FEP_lambdaend
set LambdaWindow    $FEP_lambdawindow
set numsteps        $numsteps
runFEPmin 0.0 0.0 0.0 \$numsteps $FEPmin_minsteps $GENERAL_temperature
ENDL
echo "Running FEPmin with stage number $simstage"
stage_runner $simstage
}

FEP () {
    local simstage=$1
    local inputtype=$2
    local numsteps=$3
    local simrep=${1}_01

    if [ $( find . -type d -regex "./${simstage}.*" ) ]; then
        echo "Stage ${simstage} already exists."
        cd ${simstage}_FEP
        stage_runner $simstage
        return
    fi
    mkcd ${simstage}_FEP

    header $simstage $inputtype
    sed -i -E "s|firsttimestep .*||g" $simrep.conf
    parameter_settings

cat >> $simrep.conf <<ENDL
langevinTemp $GENERAL_temperature

source $MAINDIR/02_Simulation_Setup/fep.tcl

#FEP parameters
alch                on
alchType            FEP
alchFile            $FEP_alchfile
alchCol             $FEP_alchcol
alchOutfile         $simrep.fepout
alchOutFreq         $FEP_alchoutfreq

alchVdwLambdaEnd    $FEP_alchvdwlambdaend
alchElecLambdaStart $FEP_alcheleclambdastart
alchVdwShiftCoeff   $FEP_alchvdwshiftcoeff
alchDecouple        $FEP_alchdecouple

alchEquilSteps      $FEP_alchequilsteps

set LambdaStart     $FEP_lambdastart
set LambdaEnd       $FEP_lambdaend
set LambdaWindow    $FEP_lambdawindow
set numsteps        $numsteps
runFEP \$LambdaStart \$LambdaEnd \$LambdaWindow \$numsteps
ENDL
echo "Running FEP with stage number $simstage"
stage_runner $simstage
}

TREX () {
    local simstage=$1
    local inputtype=$2
    local numsteps=$3
    local simrep=${1}_01
    if [ "$( find . -type d -regex "./${simstage}.*" )" ]; then
        echo "Stage ${simstage} already exists."
        cd ${simstage}_TREX
        replica_runner $simstage $TREX_numreplicas
        return
    fi
    mkcd ${simstage}_TREX
    header $simstage $inputtype
    parameter_settings
    mv $simrep.conf replica_base.namd
    rmlist=( "outputname" "#Output" "restartfreq" "dcdfreq" 
             "xstfreq"   "outputEnergies" "outputPressure" )
    for rmval in ${rmlist[@]}; do
        sed -i -E "s/${rmval}.*//g" replica_base.namd
    done
    sed -i "s/firsttimestep/set\ first_timestep/g" replica_base.namd
    cat >> $simrep.conf <<ENDL
set initial_pdb_file "$inputfiles.pdb"
set psf_file "$inputfiles.psf"
set resnames "$resnames"
set polbuild_fromsel_text "$polbuild_fromsel_text"
set polbuild_tosel_text "$polbuild_tosel_text"
source replica.conf
if { ! [catch numPes] } { source $MAINDIR/02_Simulation_Setup/replica.tcl }
ENDL
    REPLICA_runs_per_frame=$(( ${GENERAL_dcdfreq} / ${TREX_steps_per_run} ))
    cat >> replica.conf <<ENDL
set numsteps $numsteps
set dcdfreq ${GENERAL_dcdfreq}
set num_replicas ${TREX_numreplicas}
set min_temp ${TREX_mintemp}
set max_temp ${TREX_maxtemp}
set steps_per_run ${TREX_steps_per_run}
set num_runs [expr \${numsteps} / \${steps_per_run} ]
set runs_per_frame [expr \${num_runs}/(\${numsteps}/\${dcdfreq})]
set frames_per_restart [expr ${GENERAL_restartfreq}/${GENERAL_dcdfreq}]
set namd_config_file "replica_base.namd"
set output_root "%s/${simrep}"
ENDL
echo "Running TREX with stage number $simstage"
replica_runner $simstage $TREX_numreplicas
}

REST2 () {
    local simstage=$1
    local inputtype=$2
    local numsteps=$3
    local simrep=${1}_01
    if [ "$( find . -type d -regex "./${simstage}.*" )" ]; then
        echo "Stage ${simstage} already exists. Continuing with next stage."
        #cd ${simstage}_REST2
        #replica_runner $simstage $REST2_numreplicas
        return
    fi
    mkcd ${simstage}_REST2

    #Create the rest2_base.namd
    header $simstage $inputtype
    parameter_settings
    mv $simrep.conf rest2_base.namd
    rmlist=( "outputname" "#Output" "restartfreq" "dcdfreq" 
             "xstfreq"   "outputEnergies" "outputPressure" )
    for rmval in ${rmlist[@]}; do
        sed -i -E "s/${rmval}.*//g" rest2_base.namd
    done
    sed -i "s/firsttimestep/set\ first_timestep/g" rest2_base.namd
    cat >> rest2_base.namd <<ENDL
langevinTemp $GENERAL_temperature
soluteScaling on
soluteScalingCol B
soluteScalingFile ${REST2_solutescalingfile}
ENDL

    #Create the input file.
    cat >> $simrep.conf <<ENDL
set initial_pdb_file "$inputfiles.pdb"
set psf_file "$inputfiles.psf"
set resnames "$resnames"
set polbuild_fromsel_text "$polbuild_fromsel_text"
set polbuild_tosel_text "$polbuild_tosel_text"
source replica.conf
if { ! [catch numPes] } { source $MAINDIR/02_Simulation_Setup/rest2_remd.tcl }
ENDL
    #Create the replica.conf file
    REPLICA_runs_per_frame=$(( ${GENERAL_dcdfreq} / ${REST2_steps_per_run} ))
    cat >> replica.conf <<ENDL
set numsteps $numsteps
set dcdfreq ${GENERAL_dcdfreq}
set num_replicas ${REST2_numreplicas}
set min_temp ${REST2_mintemp}
set max_temp ${REST2_maxtemp}
set TEMP ${GENERAL_temperature}
set steps_per_run ${REST2_steps_per_run}
set num_runs [expr \${numsteps} / \${steps_per_run} ]
set runs_per_frame [expr \${dcdfreq} / \${steps_per_run} ]
set frames_per_restart [expr ${GENERAL_restartfreq}/${GENERAL_dcdfreq}]
set namd_config_file "rest2_base.namd"
set output_root "%s/${simrep}"
ENDL
echo "Running REST2 with stage number $simstage"
replica_runner $simstage $REST2_numreplicas
}

cpH () {
    local simstage=$1
    local inputtype=$2
    local simrep=${1}_01
    if [ "$( find . -type d -regex "./${simstage}.*" )" ]; then
        echo "Stage ${simstage} already exists."
        cd ${simstage}_cpH
        stage_runner $simstage
        return
    fi
    mkcd ${simstage}_cpH
    header $simstage $inputtype
    parameter_settings
cat >> $simrep.conf <<ENDL
langevinTemp $GENERAL_temperature
package ifneeded psfgen 1.6.5 [list load $MAINDIR/02_Simulation_Setup/libpsfgen.so ]
source $MAINDIR/02_Simulation_Setup/namdcph.tcl
topology $cpH_topology 
cphConfigFile $cpH_conf 
pH $cpH_pH
cphNumstepsPerSwitch $cpH_NumStepsPerSwitch
cphNumMinSteps 500
cphRun $cpH_StepsPerCycle $cpH_NumCycles
exit
ENDL
$replicaexecution ++local ${simrep}.conf > ${simstage}_01.log || echo "Non-zero NAMD Exit."
cd ..
}

header () {
    local simstage=${1}
    local simrep=${1}_01
    local inputtype=$2

#Always necessary inputs
cat > $simrep.conf <<ENDL
structure $inputfiles.psf
coordinates $inputfiles.pdb
outputname $simrep

proc get_first_ts { xscfile } {
   set fd [open \$xscfile r]
   gets \$fd
   gets \$fd
   gets \$fd line
   set ts [lindex \$line 0]
   close \$fd
   return \$ts
}
ENDL

if [ "$inputtype" != "NONE" ]; then
    inputfrom=$( find_inputname $simstage )
    #laststep=$( grep -Eo "RESTART FILE AT STEP.*" $inputfrom.log | tail -n 1 | awk '{print $5}' )
    #echo "set last_stage_last_step $laststep" >> $simrep.conf
    echo "set last_stage_last_step [get_first_ts $inputfrom.restart.xsc]" >> $simrep.conf
else
    echo "set last_stage_last_step 0" >> $simrep.conf
fi

#Handle pbc
if [ "${GENERAL_pbc}" == "off" ]; then
    echo "#no periodic boundary conditions" >> $simrep.conf
    echo ""
elif [ "${GENERAL_pbc}" == "spherical" ]; then
    cat >> $simrep.conf <<ENDL
sphericalBC on
sphericalBCcenter ${GENERAL_sphericalbccenter}
sphericalBCr1 ${GENERAL_sphericalbcr1}
sphericalBCk1 ${GENERAL_sphericalbck1}
sphericalBCexp1 ${GENERAL_sphericalbcexp1}
ENDL
elif [ "$inputtype" = "coordsonly" ] || [ "$inputtype" = "NONE" ] && [ "$GENERAL_custompbc" = "off" ]; then
cat >> $simrep.conf <<ENDL
cellBasisVector1 $xpbc 0 0
cellBasisVector2 0 $ypbc 0
cellBasisVector3 0 0 $zpbc
cellOrigin $xorigin $yorigin $zorigin

ENDL
elif [ "$inputtype" = "coordsonly" ] || [ "$inputtype" = "NONE" ] && [ "$GENERAL_custompbc" = "on" ]; then
for line in ${GENERAL_custompbclist[@]}; do
echo "$line" >> $simrep.conf
done
else
    echo "extendedSystem $inputfrom.restart.xsc" >> $simrep.conf
    echo ""
fi

#Handle coordinate input.
if [ "$inputtype" = "NONE" ]; then
    echo "temperature $GENERAL_temperature" >> $simrep.conf
    echo "set currenttimestep 0" >> $simrep.conf
    echo "firsttimestep \$currenttimestep" >> $simrep.conf
    return
fi
if [ "$inputtype" = "pbconly" ]; then
echo "temperature $GENERAL_temperature" >> $simrep.conf
else
cat >> $simrep.conf <<ENDL

#Input to restart from a previous simulation
binCoordinates $inputfrom.restart.coor
binVelocities  $inputfrom.restart.vel
ENDL
fi
cat >> $simrep.conf <<ENDL
#get correct time step
set currenttimestep [get_first_ts $inputfrom.restart.xsc]
firsttimestep \$currenttimestep
ENDL
}

parameter_settings () {
if [ ! -z ${CUDA_NAMD3+x} ]; then
    if [ "$CUDA_NAMD3" = "on" ]; then
        echo "CUDASOAIntegrate on" >> $simrep.conf
        old_namdexecution=$namdexecution
        namdexecution=$namd3gpu_execution
    elif [ "$CUDA_NAMD3" = "off" ]; then
        echo "CUDASOAIntegrate off" >> $simprep.conf
        if [ -z ${old_namdexecution} ]; then
            namdexecution=$old_namdexecution
        fi
    fi
fi
cat >> $simrep.conf <<ENDL
margin ${GENERAL_margin}

#Parameters
paraTypeCharmm on
ENDL
for param in ${paramslist[@]}; do
    echo "parameters $param" >> $simrep.conf
done
cat >> $simrep.conf <<ENDL

#Force field settings
exclude             $GENERAL_exclude
1-4scaling          ${GENERAL_1_4scaling}
cutoff              $GENERAL_cutoff
switching           $GENERAL_switching
switchdist          $GENERAL_switchdist
pairlistdist        $GENERAL_pairlistdist

#Integrator
timestep            $GENERAL_timestep
rigidBonds          $GENERAL_rigidbonds
nonbondedFreq       $GENERAL_nonbondedfreq
fullElectFrequency  $GENERAL_fullelectfrequency
stepsPerCycle       $GENERAL_stepspercycle
pairlistsPerCycle   $GENERAL_pairlistspercycle

#Constant temperature control
langevin            $GENERAL_langevin
langevinDamping     $GENERAL_langevindamping
langevinHydrogen    $GENERAL_langevinhydrogen

ENDL
if [ "${GENERAL_pme}" == "yes" ]; then
cat >> $simrep.conf <<ENDL
#PME electrostatics
PME                 $GENERAL_pme
PMEGridSpacing      $GENERAL_pmegridspacing

ENDL
elif [ "${GENERAL_msm}" == "yes" ]; then
cat >> $simrep.conf <<ENDL
#MSM full electrostatics"
MSM                 $GENERAL_msm
MSMGridSpacing      $GENERAL_msmgridspacing
MSMQuality          $GENERAL_msmquality
ENDL
nmdparam=( "MSMxmin" "MSMxmax" "MSMymin" "MSMymax" "MSMzmin" "MSMzmax" )
setparam=( "$GENERAL_msmxmin" "$GENERAL_msmxmax" "$GENERAL_msmymin" "$GENERAL_msmymax" "$GENERAL_msmzmin" "$GENERAL_msmzmax" )
for index in "${!nmdparam[@]}"; do
    if [ ! -z "${setparam[${index}]}" ]; then
        echo "${nmdparam[$index]}   ${setparam[$index]}" >> $simrep.conf
    fi
done
fi
if [ "${GENERAL_gbis}" == "on" ]; then
cat >> $simrep.conf <<ENDL
#implicit solvent
GBIS                $GENERAL_gbis
solventDielectric   $GENERAL_solventdielectric
ionConcentration    $GENERAL_ionconcentration

ENDL
fi
if [ "${GENERAL_pbc}" == "on" ]; then
    echo "wrapAll             $GENERAL_wrapall" >> $simrep.conf
fi
if [ "${GENERAL_tclbc}" == "on" ]; then
cat >> $simrep.conf <<ENDL
tclBC               on
tclBCScript {
    set tclBCScript ${GENERAL_tclbcscript}
    source \$tclBCScript
}
tclBCArgs { ${GENERAL_tclbcargs} }

ENDL
fi
if [ "${GENERAL_colvars}" == "on" ]; then
    echo "colvars             on" >> $simrep.conf
    echo "colvarsConfig       ${GENERAL_colvarsconfig}" >> $simrep.conf
fi
if [ "${GENERAL_constraints}" == "on" ]; then
cat >> $simrep.conf <<ENDL
constraints         on
consexp             $GENERAL_consexp
consref             $GENERAL_consref
conskfile           $GENERAL_conskfile
conskcol            $GENERAL_conskcol
constraintScaling   $GENERAL_constraintscaling
ENDL
    if [ "$GENERAL_selectconstraints" == "on" ]; then
cat >> $simrep.conf <<ENDL
selectConstraints   on
selectConstrX       $GENERAL_selectconstrx
selectConstrY       $GENERAL_selectconstry
selectConstrZ       $GENERAL_selectconstrz
ENDL
    fi
fi
if [ "${GENERAL_fixedatoms}" == "on" ]; then
cat >> $simrep.conf <<ENDL
fixedAtoms          on
fixedAtomsForces    ${GENERAL_fixedatomsforces}
fixedAtomsFile      ${GENERAL_fixedatomsfile}
fixedAtomsCol       ${GENERAL_fixedatomscol}

ENDL
fi
if [ "${GENERAL_constantforce}" == "yes" ]; then
echo "constantforce       yes" >> $simrep.conf
echo "consforcefile       $GENERAL_consforcefile" >> $simrep.conf
echo " " >> $simrep.conf
fi
if [ "${GENERAL_smd}" == "on" ]; then
cat >> $simrep.conf <<ENDL
SMD                 on
SMDFile             ${GENERAL_smdfile}
SMDk                ${GENERAL_smdk}
SMDk2               ${GENERAL_smdk2}
SMDVel              ${GENERAL_smdvel}
SMDDir              ${GENERAL_smddir}
SMDOutputFreq       ${GENERAL_smdoutputfreq}

ENDL
fi
cat >> $simrep.conf <<ENDL

#Output
restartfreq         $GENERAL_restartfreq
dcdfreq             $GENERAL_dcdfreq
ENDL
if [ "$GENERAL_veldcdfreq" -gt 0 ]; then
    echo "veldcdfreq          $GENERAL_veldcdfreq" >> $simrep.conf
fi
cat >> $simrep.conf <<ENDL
xstfreq             $GENERAL_xstfreq
outputEnergies      $GENERAL_outputenergies
outputPressure      $GENERAL_outputpressure

ENDL
}

pressure_control () {
    cat >> $simrep.conf <<ENDL
#Constant pressure control
useGroupPressure    $GENERAL_usegrouppressure
useFlexibleCell     $GENERAL_useflexiblecell

langevinPiston          $GENERAL_langevinpiston
langevinPistonTarget    $GENERAL_langevinpistontarget
langevinPistonPeriod    $GENERAL_langevinpistonperiod
langevinPistonDecay     $GENERAL_langevinpistondecay

ENDL
if [ $GENERAL_excludefrompressure = "on" ]; then
cat >> $simrep.conf <<ENDL
#Exclude certain atoms from pressure rescaling (but they are still contributing to Virial)
ExcludeFromPressure     on
ExcludeFromPressureFile $GENERAL_excludefrompressurefile
ExcludeFromPressureCol  $GENERAL_excludefrompressurecol

ENDL
fi
}

mkcd ()
{
  mkdir -p -- "$1" && cd -P -- "$1"
}

find_inputname () {
    local thisstage=$( stripLeadingZeros $1 )
    local formerstage=$(( $thisstage - 1 ))
    #Uses the fact that stage 02_01, 02_02,... are sorted alphabetically
    if [ "$formerstage" -lt "10" ]; then
        coor=$( find ../0${formerstage}_*/*.restart.coor | tail -n 1 )
    else
        coor=$( find ../${formerstage}_*/*.restart.coor | tail -n 1 )
    fi
    local input=$( echo $coor | sed -E "s/\.restart\.coor//g" )
    echo -n "$input"
}

find_inputname2 () {
    coor=$( find ./${1}_*.restart.coor | tail -n 1 )
    if [[ ${coor} == "" ]]; then
        echo "No restart file within stage ${1} found."
        #cannot simply exit because this function is called in a new shell as $( ... )
        kill $TOP_ID
    fi
    local input=$( echo $coor | sed -E "s/\.restart\.coor//g" | sed -E "s/\.\///g" )
    echo -n "$input"
}

stripLeadingZeros () {
    shopt -s extglob
    retVal="${1##+(0)}"
    [[ -z "${retVal}" ]] && retVal=0
    echo -n "${retVal}"
}

check_correct_termination () {
    local currentstage=$1
    local logfile=$( find ./${currentstage}_*.log | tail -n 1 )
    #refer to restart file like this to also catch replica restart files.
    local restartfile=$( echo ${logfile} | sed -E "s|\.log||g" )
    local restartfile=$( find ${restartfile}*restart*coor | tail -n 1 )
    local lf=$( basename $logfile )

    if ! [ -f ${restartfile} ] && [ ${firstrun} == "to_be_done" ]; then
        echo -n "Restartfile $restartfile corresponding to logfile ${logfile} was not found. Moving logfile $logfile to old_$lf In case of walltime-abort, suggesting restart from previous stage."
	    mv $logfile old_$lf  
    elif [[ $( grep "restart from a recent checkpoint" ${logfile} ) ]]; then
        echo -n "NEEDS RESTART"
    elif [[ $( grep "ERROR: Constraint failure in RATTLE algorithm" ${logfile} ) ]]; then
        echo -n "Fatal error in RATTLE algorithm. Moving logfile $logfile to old_$lf , setting GENERAL_timestep=1 and GENERAL_rigidbonds=none, then doing restart from previous stage."
        mv $logfile old_$lf
        GENERAL_timestep="1"
        GENERAL_rigidbonds="none"
    elif [[ $( grep "ERROR: Exiting prematurely" ${logfile} ) ]]; then
        if [[ $( grep "WRITING RESTART" ${logfile} ) ]]; then
            echo -n "A fatal error occured. Since restart files were written, trying restart."
        else
            echo -n "A fatal error occured and no restart files were written."
        fi
    elif [[ $( grep "End of program" ${logfile} ) ]]; then
        echo -n "Probably correct termination."
    else 
        echo -n "TERMINATION TYPE NOT COVERED. Could be due to walltime-abort, trying restart."
    fi 
}

check_replica_termination () {
    local currentstage=$1
    local replicas=$2
    r1=$(($replicas - 1))
    echo $( check_correct_termination "0/${currentstage}" ) > replica_check.tmp
    for i in $( seq 1 $r1 ); do
        echo $( check_correct_termination "${i}/${currentstage}" ) >> replica_check.tmp
    done
}

restarter () {
    #if GENERAL_restarttype == "simple"
    #   --> Restarts the current stage until the numsteps in that stage have been calculated.
    #if GENERAL_restarttype == "errorfree"
    #   --> Restarts the current stage until numsteps have been calculated without needing a restart.
    if [[ "$GENERAL_restarttype" == "never" ]]; then
            echo "Entered restart function but set GENERAL_restarttype=never, exiting."
            exit
    fi
    local currentstage=$1
    input=$( find_inputname2 $currentstage )
    current_stage_rep=$( echo $input | sed -E "s/${currentstage}_//g" )
    current_stage_rep2=$( stripLeadingZeros $current_stage_rep )
    next_rep=$(( ${current_stage_rep2} + 1 ))

    echo "Initialized automatic restarting of stage $currentstage from last restart point in ${currentstage}_${current_stage_rep}."

    if [ "$next_rep" -lt "10" ]; then
        next=${currentstage}_0${next_rep}
    else
        next=${currentstage}_${next_rep}
    fi
    next_conf="${next}.conf"
    cp "${currentstage}_${current_stage_rep}.conf" "${next_conf}"
    next_log=$( echo $next_conf | sed -E "s/\.conf/\.log/g" )
    res=${currentstage}_${current_stage_rep}

    if [[ "${GENERAL_restarttype}" == "simple" ]]; then
        #Change all restart files to be referring to the current stagerep except for last_stage_last_step reference
        save_last_stage_last_step=$( grep "set last_stage_last_step" ${next_conf} )
        sed -i -E "s|\ [^ ]*\.restart\.|\ ${res}\.restart\.|g" ${next_conf}
        sed -i -E "s|set\ last_stage_last_step .*|${save_last_stage_last_step}|g" ${next_conf}
    elif [[ "${GENERAL_restarttype}" == "errorfree" ]]; then
        sed -i -E "s/\ [^ ]*\.restart\./\ ${res}\.restart\./g" ${next_conf}
    fi

    #Change outputname
    sed -i -E "s/outputname\ ${res}/outputname\ ${next}/g" ${next_conf}

    #This is the step of which the last restart file was created
    laststep=$( grep -Eo "RESTART FILE AT STEP.*" ${res}.log | tail -n 1 | awk '{print $5}' )
    if [[ ${laststep} == "" ]]; then
        echo "Variable laststep is empty: No restart file was written in the last simulation stage_repetition. Exiting."
        exit 2;
    fi

    #In case the inputtype was "NONE", the following will still allow a restart within the current stage.
    sed -i -E "s/set\ currenttimestep\ 0/set\ currenttimestep\ $laststep\nbincoordinates\ ${res}\.restart\.coor\nbinvelocities\ ${res}\.restart\.vel/g" ${next_conf}

    $namdexecution $next_conf &> $next_log || echo "Non-zero NAMD Exit."
    firstrun="is_done"
}

automatic_replica_restarter () {
#!This is unifinished!
    local currentstage=$1
    input=$( find_inputname2 $currentstage )
    current_stage_rep=$( echo $input | sed -E "s/${currentstage}_//g" )
    current_stage_rep2=$( stripLeadingZeros $current_stage_rep )
    next_rep=$(( ${current_stage_rep2} + 1 ))

    echo "Initialized automatic restarting of stage $currentstage from last restart point in ${currentstage}_${current_stage_rep}."

    if [ "$next_rep" -lt "10" ]; then
        next_conf="${currentstage}_0${next_rep}.conf"
        next=${currentstage}_0${next_rep}
    else
        next_conf="${currentstage}_${next_rep}.conf"
        next=${currentstage}_${next_rep}
    fi
    cp ${currentstage}_${current_stage_rep}.conf ${next_conf}
    next_log=$( echo $next_conf | sed -E "s/\.conf/\.log/g" )
    #Create the next job.conf
    cat ${next_conf} << ENDL
source replica.conf
set restarttcl [glob $output_root.${currenstage}_${current_stage_rep}.restart*.tcl ]
source \$restarttcl
set doneruns [regexp {[0-9]+} [regexp {restart[0-9]+\.tcl} \$restarttcl ]]
set num_runs [expr ${num_runs} - ${done_runs} ]
if { ! [catch numPes] } { source $MAINDIR/02_Simulation_Setup/replica.tcl }
ENDL
}

print_stage_check () {
    local stage=$1
    local stage_check=$2
    local logfile=$( find ./${stage}_*.log | tail -n 1 )
    echo "Stage check for ${stage} reads $logfile and gets: $stage_check."
    if ! [[ "$stage_check" == *"correct termination"* ]]; then
        echo "Last 10 lines of $logfile:"
        tail -n 10 $logfile
    fi
}

stage_runner () {
    local stage=$1
    if [ -f "./${stage}_01.log" ]; then
        stage_check=$( check_correct_termination ${stage} )
        print_stage_check "$stage" "$stage_check"
        if [[ "$stage_check" == "Probably correct termination." ]]; then
            echo "Continuing with next stage."
            cd ..
            return
        fi
        if [[ "${stage_check}" == *"restart from previous stage"* ]]; then
            stage_runner $stage
            return
        fi
    else
        echo "Starting calculation in stage $1."
        $namdexecution ${stage}_01.conf &> ${stage}_01.log || echo "Non-zero NAMD Exit."
        firstrun="is_done"
        stage_check=$( check_correct_termination ${stage} )
        print_stage_check "$stage" "$stage_check"
    fi
    
    while [[ "$stage_check" == *"NEEDS RESTART" ]] || [[ "$stage_check" == *"trying restart"* ]]; do
        restarter $stage
        stage_check=$( check_correct_termination $stage )
        print_stage_check "$stage" "$stage_check"
    done
    cd ..
}

replica_runner () {
    local stage=$1
    local replicas=$2
    r1=$(( $replicas - 1 ))
    if [ -f "./${stage}_01.log" ]; then
        #check if all replicas terminated as expected
        check_replica_termination ${stage} ${replicas}
        stage_check=($( cat replica_check.tmp ))
        all_good="yes"
        for check in ${stage_check[@]}; do
            if ! [[ "$stage_check" == "Probably correct termination." ]]; then
                all_good="no"
            fi
        done
        if [[ $all_good == "yes" ]]; then
            echo "Continuing with next stage."
            cd ..
            return
        fi
    else
        echo "Starting calculation in stage $1."
        mkdir $( seq 0 $r1 )
        $replicaexecution +replicas $replicas +stdout %d/${stage}_01.log ${stage}_01.conf &> ${stage}_01.log
    fi
    #TODO: the restart checks should be just as elaborate as in stage_runner. 
    check_replica_termination ${stage} ${replicas}
    stage_check=($( cat replica_check.tmp ))
    echo "Stage check for ${stage} gets: ${stage_check[@]}"
    restart="no"
    for check in ${stage_check[@]}; do
        if [[ "$stage_check" == *"NEEDS RESTART" ]] || [[ "$stage_check" == *"trying restart"* ]]; then
            restart="yes"
            break
        fi
    done
    while [[ "$restart" == "yes" ]]; do
        automatic_replica_restarter $stage
        check_replica_termination ${stage} ${replicas}
        stage_check=($( cat replica_check.tmp ))
        rm replica_check.tmp
        echo "Stage check for ${stage} gets: ${stage_check[@]}"
        restart="no"
        for check in ${stage_check[@]}; do
            if [[ "$check" == *"NEEDS RESTART" ]]; then
                restart="yes"
                break
            fi
        done
    done
    #sort into single-temperature trajectories
    for rep in $( seq -w 99 ); do
        if [ -f "0/${stage}_${rep}.log" ]; then
            #last input number is equal to runs_per_frame
            $sortreplicas %s/${stage}_${rep}.job0 $replicas ${REPLICA_runs_per_frame}
        else
            break
        fi
    done
    #find the replica that had the best configuration at the last frame
    zero_sort_history=$( find ./0/${stage}_*.sort.history )
    best_final_replica=$( awk 'END {print $2}' ${zero_sort_history} )
    #copy lowest-temperature restart file for use in the next stage
    coor=$( find ./${best_final_replica}/${1}_*.restart*.coor | tail -n 1 )
    inputrst=$( echo $coor | sed -E "s/\.coor//g" | sed -E "s/\.\///g" )
    for ftype in "coor" "vel" "xsc"; do
        cp $inputrst.$ftype ${stage}_01.restart.$ftype
    done
    cd ..
}

main "$@"
