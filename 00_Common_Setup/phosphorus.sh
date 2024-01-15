#!/bin/bash

#export NTASKS=64
path="/data/users/jonathan/NAMD_3b_multicore_CUDA"
export namdexecution="${path}/namd3 +p64 +devices 0"
export namd3gpu_execution="${path}/namd3 +p64 +ignoresharing +devices 0"
#3days/ns:
export replicaexecution="${path}/charmrun ${path}/namd3 ++local +ignoresharing +p64"

#76days/ns:
#path="/opt/NAMD_3.0b5_Linux-x86_64-netlrts-smp"
#export replicaexecution="${path}/charmrun ${path}/namd3 ++local +p64"

export sortreplicas="${path}/sortreplicas"

source $1
echo "Starting NAMD run."
${MAINDIR}/02_Simulation_Setup/00_generate_setup.sh $1
