import toml

config = toml.load('config.toml')

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

if __name__ == "__main__":
    print(config)
