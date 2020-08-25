#!/usr/bin/env python3
import os  # os module allows to determine directories
import subprocess
from util import config, gen_header, is_running

# list is of the form [..., [valN, valMaxN, valMaxSpin], ...]
mathematica_directory = config['directories']['mathematica']
sdpb_input = config['directories']['sdpb_input']
sdp2input = os.path.join(config['directories']['sdpb_binaries'],
    "sdp2input",
)

job_template = """{header}
#-------------------- actual job: start------------
echo starting the job: `date`
module load mathematica
string=$(wolframscript -code '{code}')

echo ${{string}}


{sdp2input} --precision={precision} --input=lowerA1Bound_A0=1_N=3_maxN={maxN}_maxSpin={maxL}.m --output=lowerA1Bound_A0=1_N=3_maxN={maxN}_maxSpin={maxL}_in &
{sdp2input} --precision={precision} --input=upperA1Bound_A0=1_N=3_maxN={maxN}_maxSpin={maxL}.m --output=upperA1Bound_A0=1_N=3_maxN={maxN}_maxSpin={maxL}_in &
wait
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
        sbatch_name = 'construct_N={}_maxN={}_maxSpin={}.sh'.format(
            problem['N'],
            problem['ansatz_size'],
            spin,
        )
        sbatch_path = os.path.join(sdpb_input, sbatch_name)
        if config['cluster']['avoid_repeated_jobs'] and is_running(sbatch_name):
            print('Task {} already running, skipping.'.format(os.path.basename(sbatch_name)))
            continue
        file = open(sbatch_path, "w") 
        file.write(job_template.format(
            header = gen_header(sdpb_input, nodes_per_job = 1),
            sdp2input = sdp2input,
            code = code,
            precision = config['sdpb']['precision'],
            maxL = spin,
            maxN = problem['ansatz_size'],
        )) 
        file.close() 
        subprocess.call(['chmod','+x', sbatch_path])
        command = ['sbatch', sbatch_path]

        if not config['debug']['dry_run']:
            subprocess.call(command)
        else:
            print("MOCK RUN ",' '.join(command))
