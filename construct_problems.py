#!/usr/bin/python3
import os  # os module allows to determine directories
import subprocess
from config_parser import config

# list is of the form [..., [valN, valMaxN, valMaxSpin], ...]
mathematica_directory = os.path.abspath(config['directories']['mathematica'])
sdpb_input = os.path.abspath(config['directories']['sdpb_input'])

job_template = """#!/bin/bash
#SBATCH --chdir {sdpb_dir}
#SBATCH --nodes 1
#SBATCH --ntasks 28
#SBATCH --cpus-per-task 1
#SBATCH --mem 128000
#SBATCH --time 06:00:00
#SBATCH --account fsl
#-------------------- actual job: start------------
echo starting the job: `date`
module load mathematica
string=$(wolframscript -code '{code}')
# select file names from the string (they are separated by |)
IFS='|' read -r -a array <<< $string
echo ${{array[0]}}
string=${{array[1]}}
IFS=', ' read -r -a array <<< $string
input1=${{array[0]}}
output1=${{input1:0:-2}}'_in'
input2=${{array[1]}}
output2=${{input2:0:-2}}'_in
./sdp2input --precision={precision} --input=$input1 --output=$output1
./sdp2input --precision={precision} --input=$input2 --output=$output2
echo ending the job: `date`
#-------------------- actual job: end------------"""

for problem in config['problem']:
    for spin in problem['spins']:
        code = 'SetDirectory["{dir}"];\
            Get["bootstrap.m"];\
            constructSDPProblem[{N}][{max_N},{max_spin}]//\
            AbsoluteTiming//Print;'.format(
                dir = mathematica_directory,
                N = problem['N'],
                max_N = problem['ansatz_size'],
                max_spin = spin,
                ) # in Wolfram Language
        sbatch_name = 'math_N={}_maxN={}_maxSpin={}.sh'.format(
            problem['N'],
            problem['ansatz_size'],
            spin,
        )
        sbatch_path = os.path.join(sdpb_input, sbatch_name)
        file = open(sbatch_path, "w") 
        file.write(job_template.format(
            sdpb_dir = sdpb_input,
            code = code,
            precision = config['sdpb']['precision']
        )) 
        file.close() 
        subprocess.call(['chmod','+x', sbatch_path])

        if config['debug']['use_debug_partition']:
            command = ['sbatch', sbatch_path, '--partition', 'debug']
        else:
            command = ['sbatch', sbatch_path]

        if not config['debug']['dry_run']:
            subprocess.call(command)
        else:
            print("MOCK RUN ",' '.join(command))