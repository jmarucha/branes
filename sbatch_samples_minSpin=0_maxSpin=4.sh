#!/bin/bash
#SBATCH --chdir C:\Users\marucha\Documents\branes
#SBATCH --nodes 1
#SBATCH --ntasks 28
#SBATCH --cpus-per-task 1
#SBATCH --mem=0
#SBATCH --time 12:00:00
#SBATCH --account fsl

#-------------------- actual job: start------------
echo starting the job: `date`
module load mathematica
wolframscript -code 'minSpin=0; maxSpin=4; SetDirectory["C:\Users\marucha\Documents\branes"]; Get["evaluation.m"]'
echo ending the job: `date`
#-------------------- actual job: end------------
