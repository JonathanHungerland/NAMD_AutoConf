#!/bin/bash
#
#Script to run NAMD3 with gpu on the QBL-Cluster
#Jonathan Hungerland 12.01.2022
#
#Change default SBATCH options appropriate to
#optimal performance gotten with bench_namd_cluster.sh
#margin parameter needs to be set in the *.conf
#
#SBATCH --time=4-00:00:00 
#SBATCH --nodes=1
#SBATCH --ntasks-per-node 12
#SBATCH --partition qblg.p
#SBATCH --gres=gpu:1
#SBATCH --mem=50GB
scontrol update jobid=${SLURM_JOB_ID} jobname=$1

# GPU version with CUDASOAintegrate enabled
module load hpc-env/12.2 NAMD/3.0b4-multicore-CUDA

#+devices 0 chooses the first GPU device in the list of those
#that are visible. SLURM assigns GPUs to a job by setting the
#variable CUDA_VISIBLE_DEVICES according to those GPUs the job
#may use. By using +devices 0 one uses the first of the visible
#GPUs automatically.

export NTASKS=$(( ${SLURM_NNODES} * ${SLURM_NTASKS_PER_NODE} ))
export namdexecution="namd3 +p${NTASKS}"
export namd3gpu_execution="namd3 +idlepoll +p${NTASKS} +devices 0"
#export replicaexecution="CANT DO REPLICA EXCHANGE IN NAMD3 YET"
#export sortreplicas=$( which sortreplicas )

source $1
echo "Starting NAMD run."
${MAINDIR}/02_Simulation_Setup/00_generate_setup.sh $1

