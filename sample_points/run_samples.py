#!/usr/bin/python3
import os  # os module allows to determine directories
import subprocess
import sys

directory = os.path.dirname(os.path.realpath(__file__))

os.chdir("..") # very very bad practice
sys.path.append(".") # thats a very bad practice 
from util import config, gen_header # pylint: disable=import-error, no-name-in-module
os.chdir(directory) # never ever do something like that

header = gen_header(directory, nodes_per_job = 1)

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
        text = header + (text2 % code)

        file = open(sbatch_name, "w") 
        file.write(text) 
        file.close()

        subprocess.call(['chmod','+x', sbatch_name])
        command = ['sbatch', sbatch_name]

        if not config['debug']['dry_run']:
            subprocess.call(command)
        else:
            print("MOCK RUN ",' '.join(command))






