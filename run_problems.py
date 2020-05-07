#!/usr/bin/python3
import os  # os module allows to determine directories
import subprocess
from config_parser import config

sdpb_params = """\
--procsPerNode={processes_per_node}
--writeSolution y
--maxIterations {max_iterations}
--maxComplementarity {max_complementarity}
--dualityGapThreshold {duality_gap_threshold}
--precision {precision}""".format(**config['sdpb']).replace('\n', ' ')

fileNames = [name[:-3] for name in os.listdir(config['directories']['input']) if name.endswith("_in")]
fileNames.sort()

job_template = """#!/bin/bash
#SBATCH --chdir={sdpb_dir}
#SBATCH --nodes={nodes_per_job}
#SBATCH --ntasks-per-node={processes_per_node}
#SBATCH --mem=0
#SBATCH --time=12:00:00
#SBATCH --account=fsl
#-------------------- actual job: start------------
echo starting the job: `date`
echo Tasks $SLURM_NTASKS
srun ./sdpb -s {input} -o {output} {sdpb_params}
echo ending the job: `date`
#-------------------- actual job: end------------
"""

for name in fileNames:
    in_name     = name + '_in'
    out_name    = name +'_out'
    text       = job_template.format(
        sdpb_dir = config['directories']['sdpb'],
        nodes_per_job = config['sdpb']['nodes_per_job'],
        processes_per_node = config['sdpb']['processes_per_node'],
        input = os.path.join(config['directories']['sdpb_input'], in_name),
        output = os.path.join(config['directories']['sdpb_output'],out_name),
        sdpb_params = sdpb_params,
    )
    sbatch_name = os.path.join(config['directories']['sdpb'], 'sbatch_' + name + '.run')
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
