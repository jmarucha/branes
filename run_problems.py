#!/usr/bin/python3
import os  # os module allows to determine directories
import subprocess
from util import config, gen_header

sdpb_params = """\
--procsPerNode={processes_per_node}
--writeSolution y
--maxIterations {max_iterations}
--maxComplementarity {max_complementarity}
--dualityGapThreshold {duality_gap_threshold}
--precision {precision}""".format(**config['sdpb']).replace('\n', ' ')

sdpb = os.path.join(config['directories']['sdpb_binaries'], "sdpb")

fileNames = [name[:-3] for name in os.listdir(config['directories']['sdpb_input']) if name.endswith("_in")]
fileNames.sort()

job_template = """{header}
#-------------------- actual job: start------------
echo starting the job: `date`
echo Tasks $SLURM_NTASKS
srun {sdpb} -s {input} -o {output} {sdpb_params}
echo ending the job: `date`
#-------------------- actual job: end------------
"""

for name in fileNames:
    in_name     = name + '_in'
    out_name    = name +'_out'
    text       = job_template.format(
        header = gen_header(os.path.abspath(config['directories']['sdpb_binaries'])),
        nodes_per_job = config['sdpb']['nodes_per_job'],
        processes_per_node = config['sdpb']['processes_per_node'],
        input = os.path.abspath(os.path.join(config['directories']['sdpb_input'], in_name)),
        output = os.path.abspath(os.path.join(config['directories']['sdpb_output'],out_name)),
        sdpb_params = sdpb_params,
        sdpb = sdpb,
    )
    sbatch_name = os.path.join(config['directories']['sdpb_binaries'], 'sbatch_' + name + '.run')
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
