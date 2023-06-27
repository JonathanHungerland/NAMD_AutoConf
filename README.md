# NAMD_AutoConf
Script to automatically write and run configuration scripts for
Molecular Dynamics simulations using NAMD in multiple stages.
It only needs a Linux envinroment and the path to the NAMD executables
(see 00_Common_Setup/ghlrn.sh to adopt it on a different resource)
so it should work on close to any HPC.

Execution on a SLURM scheduled HPC is done via simply doing e.g.  
sbatch ../00_Common_Setup/ghlrn.sh 6rko_no_qbl.sh  

For stages that make not use of multiple replicas, a continuation
is also done automatically if a stage did not crash but also did
not reach the number of desired steps. To continue a stage do the
same command.


