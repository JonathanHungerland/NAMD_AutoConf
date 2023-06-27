#!/bin/bash
#SBATCH --time=12:00:00
#SBATCH --partition=standard96
#SBATCH --nodes=2
#SBATCH --tasks-per-node=96
#SBATCH --account=nip00058
scontrol update jobid=${SLURM_JOB_ID} jobname=$1
module purge
module load HLRNenv
module load vmd
export SLURM_CPU_BIND=none
module load impi
module load namd/2.13

export NTASKS=$(( ${SLURM_NNODES} * ${SLURM_NTASKS_PER_NODE} ))
export namdexecution="mpirun namd2"
export replicaexecution="mpirun namd2"
export sortreplicas=$( which sortreplicas )

source $1
echo "Starting NAMD run."
${MAINDIR}/02_Simulation_Setup/00_generate_setup.sh $1
