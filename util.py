import toml
import os
import json
import subprocess
import re

config = toml.load('config.toml')

for k, v in config['directories'].items():
    config['directories'][k] = os.path.abspath(v)

def gen_header(directory, nodes_per_job = config['sdpb']['nodes_per_job']):
    return """#!/bin/bash
#SBATCH --chdir %s
#SBATCH --nodes %s
#SBATCH --ntasks 28
#SBATCH --cpus-per-task 1
#SBATCH --mem=128000
#SBATCH --time %s
#SBATCH --account %s
#SBATCH --partition %s
""" % (
    directory,
    nodes_per_job,
    "00:30:00" if config['debug']['use_debug_partition'] else "12:00:00",
    config['cluster']['account'],
    "debug" if config['debug']['use_debug_partition'] else "parallel"
)

if __name__ != "__main__" and config['cluster']['avoid_repeated_jobs']:
    current_jobs = subprocess.run(['squeue', '-h', '-o', '%j', '-u', os.getlogin()], capture_output=True, encoding="ASCII").stdout.split('\n')

def is_running(name):
    return os.path.basename(name) in current_jobs

def should_rerun(name):
    out_full_dir = os.path.abspath(os.path.join(config['directories']['sdpb_output'],name + '_out'))
    if os.path.exists(os.path.join(out_full_dir, "out.txt")) and os.stat(os.path.join(out_full_dir, "out.txt")).st_size > 0:
        with open(os.path.join(out_full_dir, 'out.txt')) as output:
            terminate_reason = re.match('terminateReason = "(.+)";',output.readline())
            if terminate_reason == "found primal-dual optimal solution":
                print(f"Skipping, output of {name} exists, solution found")
                return False
            if terminate_reason == "maxComplementarity exceeded":
                print(f"Skipping, output of {name} exists, problem is divergent")
                return False


            if terminate_reason == "maxIterations exceeded":
                print(f"Rerunning, output of {name} exists, previous computation iterations number exceeded")
                return True
            if terminate_reason == "maxRuntime exceeded":
                print(f"Rerunning, output of {name} exists, previous run exceeded runtime")
                return True
            print(f"Rerunning, output of {name} exists, but is weird...")
            return True
    else:
        print(f"Brand new run of {name} inbound!")
        return True
            
if __name__ == "__main__":
    print(json.dumps(config))
