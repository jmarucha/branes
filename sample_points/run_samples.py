#!/usr/bin/python3
import os  # os module allows to determine directories
import subprocess
import sys

directory = os.path.dirname(os.path.realpath(__file__))

os.chdir("..") # very very bad practice
sys.path.append(".") # thats a very bad practice 
from config_parser import config # pylint: disable=import-error
os.chdir(directory) # never ever do something like that

text1 = """#!/bin/bash\n\
#SBATCH --chdir %s\n\
#SBATCH --nodes 1\n\
#SBATCH --ntasks 28\n\
#SBATCH --cpus-per-task 1\n\
#SBATCH --mem=0\n\
#SBATCH --time %s\n\
#SBATCH --account fsl
#SBATCH --partition %s
""" % (
    directory,
    "00:30:00" if config['debug']['use_debug_partition'] else "12:00:00",
    "debug" if config['debug']['use_debug_partition'] else "parallel"
)

text2 = """
#-------------------- actual job: start------------
echo starting the job: `date`
module load mathematica
wolframscript -code '%s'
echo ending the job: `date`
#-------------------- actual job: end------------\n"""


for spins in config['grid']['spins']:
    tasks = zip(
        range(spins['minL'],spins['maxL']+1, spins['partition_by']),
        range(spins['minL']+spins['partition_by']-1,spins['maxL']+1, spins['partition_by'])
    )
    for min_spin, max_spin in tasks:
        # Mathematica code
        code = 'minSpin=%s; maxSpin=%s; SetDirectory["%s"]; Get["evaluation.m"]' % (min_spin, max_spin, directory)
        sbatch_name = 'sbatch_samples_minSpin={}_maxSpin={}.sh'.format(min_spin, max_spin)
        text = text1 + (text2 % code)

        file = open(sbatch_name, "w") 
        file.write(text) 
        file.close()

        subprocess.call(['chmod','+x', sbatch_name])
        if config['debug']['use_debug_partition']:
            command = ['sbatch', sbatch_name, '--partition', 'debug']
        else:
            command = ['sbatch', sbatch_name]

        if not config['debug']['dry_run']:
            subprocess.call(command)
        else:
            print("MOCK RUN ",' '.join(command))






