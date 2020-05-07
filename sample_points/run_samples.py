#!/usr/bin/python
import os  # os module allows to determine directories
import subprocess


# submit a job for each entry in the list [..., [minSpin, maxSpin], ...]
spins = [[0,5], [6,10], [11,15], [16,20], [21,25], [26,30], [31,35], [36,40], [41,45], [46,50]]


# determine working directory
directory = os.path.dirname(os.path.realpath(__file__))


text1 = "\
#!/bin/bash\n\
#SBATCH --chdir %s\n\
#SBATCH --nodes 1\n\
#SBATCH --ntasks 28\n\
#SBATCH --cpus-per-task 1\n\
#SBATCH --mem=0\n\
#SBATCH --time 12:00:00\n\
#SBATCH --account fsl\n\n" % directory


text2 = "\
#-------------------- actual job: start------------\n\
echo starting the job: `date`\n\
module load mathematica\n\
wolframscript -code '%s' \n\
echo ending the job: `date`\n\
#-------------------- actual job: end------------\n"


# construct the .sh file
for element in spins:
    minSpin = element[0]
    maxSpin = element[1]
    # Mathematica code
    code = 'minSpin=%s; maxSpin=%s; SetDirectory["%s"]; Get["evaluation.m"]' % (minSpin, maxSpin, directory)
    name = 'sbatch_samples_minSpin=' + str(minSpin) + '_maxSpin=' + str(maxSpin) + '.sh'
    text = text1 + (text2 % code)
    file = open(name, "w") 
    file.write(text) 
    file.close() 
    subprocess.call(['chmod','+x', name])
    command = ['sbatch', name]
    subprocess.call(command)





