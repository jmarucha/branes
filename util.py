import toml
import os
import json
import subprocess

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

if config['cluster']['avoid_repeated_jobs']:
    current_jobs = subprocess.run(['squeue', '-h', '-o', '%j', '-u', os.getlogin()], capture_output=True, encoding="ASCII").stdout.split('\n')

def is_running(name):
    return os.path.basename(name) in current_jobs

if __name__ == "__main__":
    print(json.dumps(config))
