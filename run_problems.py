#!/usr/bin/python
import os  # os module allows to determine directories
import subprocess


numberNodes         = '2'    # choose the number of nodes for a single sdpb job
precision           = '1024' # binary precision
dualityGapThreshold = '1e-7'


sdpbParams = "--procsPerNode=28 --writeSolution y --maxIterations 700 \
--maxComplementarity %s --dualityGapThreshold %s --precision %s" % ('1e60', dualityGapThreshold, precision)


# determine working directory
directory   = os.path.dirname(os.path.realpath(__file__))
problemsDir = os.path.join(directory, 'problems')


# specify the *_in names to be studied
# select all the *_in files in storage directory
fileNames = []
for name in os.listdir(problemsDir):
    if name.endswith("_in"):
        fileNames.append(name)
fileNames.sort()
# select only specific files in storage directory
#filenames = [os.path.join(problemsDir, 'name1_in'), os.path.join(problemsDir, 'name2_in')]


text1 = "\
#!/bin/bash\n\
#SBATCH --chdir=%s\n\
#SBATCH --nodes=%s\n\
#SBATCH --ntasks-per-node=28\n\
#SBATCH --mem=0\n\
#SBATCH --time=12:00:00\n\
#SBATCH --account=fsl\n\n" % (problemsDir,numberNodes)


text2 = "\
#-------------------- actual job: start------------\n\
echo starting the job: `date`\n\
echo Tasks $SLURM_NTASKS\n\
srun ./sdpb -s %s -o %s " + sdpbParams + "\n\
echo ending the job: `date`\n\
#-------------------- actual job: end------------\n"
    

for mathName in fileNames:
    inName     = mathName
    outName    = mathName[0:-3] + '_out'
    text       = text1 + (text2 % (inName, outName))
    sbatchName = 'sbatch_' + mathName[0:-3] + '.run'
    sbatchName = os.path.join(problemsDir, sbatchName)
    file       = open(sbatchName, "w") 
    file.write(text) 
    file.close() 
    subprocess.call(['chmod','+x', sbatchName])


# names of files and folders in the directory
fileNames = []
for name in os.listdir(problemsDir):
    if name.endswith(".run"):
        fileNames.append(os.path.join(problemsDir,name))
fileNames.sort()


# sbatch tasks
for name in fileNames:
    command = ['sbatch', name]
    subprocess.call(command)







