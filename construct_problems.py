#!/usr/bin/python
import os  # os module allows to determine directories
import subprocess


# list is of the form [..., [valN, valMaxN, valMaxSpin], ...]
precision = '1024' # binary precision
list = [[3,10,10], [3,10,15], [3,10,20], [3,10,25], [3,10,30]]


# determine working directory
directory   = os.path.dirname(os.path.realpath(__file__))
problemsDir = os.path.join(directory, 'problems')


text1 = "\
#!/bin/bash\n\
#SBATCH --chdir %s\n\
#SBATCH --nodes 1\n\
#SBATCH --ntasks 28\n\
#SBATCH --cpus-per-task 1\n\
#SBATCH --mem 128000\n\
#SBATCH --time 06:00:00\n\
#SBATCH --account fsl\n\n" % problemsDir


text2 = "\
#-------------------- actual job: start------------\n\
echo starting the job: `date`\n\
module load mathematica\n\
string=$(wolframscript -code '%s')\n\
# select file names from the strimg (they are separated by |)\n\
IFS='|' read -r -a array <<< $string\n\
echo ${array[0]}\n\
string=${array[1]}\n\
IFS=', ' read -r -a array <<< $string\n\
input1=${array[0]}\n\
output1=${input1:0:-2}'_in'\n\
input2=${array[1]}\n\
output2=${input2:0:-2}'_in'\n\
./sdp2input --precision=%s --input=$input1 --output=$output1 \n\
./sdp2input --precision=%s --input=$input2 --output=$output2 \n\
echo ending the job: `date`\n\
#-------------------- actual job: end------------\n"


for elem in list:
    N    = elem[0]
    maxN = elem[1]
    spin = elem[2]
    code = 'SetDirectory["%s"]; Get["bootstrap.m"]; constructSDPProblem[%d][%d,%d]//AbsoluteTiming//Print;' % (directory, N, maxN, spin)
    text = text1 + (text2 % (code, precision, precision))
    name = 'math_N=' + str(N) + '_maxN=' + str(maxN)+ '_maxSpin=' + str(spin) + '.sh'
    name = os.path.join(problemsDir, name)
    file = open(name, "w") 
    file.write(text) 
    file.close() 
    subprocess.call(['chmod','+x', name])
    command = ['sbatch', name]
    subprocess.call(command)






