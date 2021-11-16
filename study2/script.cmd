#!/bin/bash
#PBS -o logfile.log
#PBS -e errorfile.err
#PBS -l walltime=40:00:00
#PBS -l select=2:ncpus=4:mpiprocs=4
tpdir=`echo $PBS_JOBID | cut -f 1 -d .`
tempdir=$HOME/scratch/job$tpdir
mkdir -p $tempdir
cd $tempdir
cp -R $PBS_O_WORKDIR/* .
module load openfoam8

ideasUnvToFoam trail16.unv						#command to convert .unv mesh to OpenFOAM mesh classes

transformPoints -scale '(0.001 0.001 0.001)'				#converting the domain to SI units of measurement

setFields								#setting the value of certain parameters in a particular region

checkMesh |tee log.CHECKMESH						#checking the mesh quality

createBaffles -dict system/createBaffles1 -overwrite | tee log.flux	#converting facezones in the domain to patches
createBaffles -dict system/createBaffles -overwrite | tee log.water
createBaffles -dict system/createBafflesDict -overwrite | tee log.copper

runApplication decomposePar						#decomposes the domain to run in parallel

mpirun -np 4 icoTempFoam_enthalphy -parallel | tee log.result		#run in parallel using mpi, number of processors, solver name

runApplication reconstructPar						#reconstructs the domain

mv ../job$tpdir $PBS_O_WORKDIR/.
