#!/usr/bin/python
import os  # os module allows to determine directories
import subprocess
import shutil
import glob


# set description
folderName = 'session_2'
description = '\
accuracy goal for int  = 20  \n\
precision              = 150 \n\
number of grid points  = 400 \n\
sdpb precision         = 800  # binary precision \n\
'


# determine working directory
directory  = os.path.dirname(os.path.realpath(__file__))
dataDir    = os.path.join(directory, 'problems')
storeDir   = os.path.join(dataDir, folderName)


# create the storeDir (if it doesn't exist already) and add the description file
if os.path.isdir(storeDir)==True:
    print 'The directory ' + folderName + ' already exists'
    print 'Copping files there'
else:
    os.mkdir(storeDir)
    name = os.path.join(storeDir, 'description.txt')
    file = open(name, "w") 
    file.write(description) 
    file.close() 


# construct a list of (full) files names to be kept
fixedFolder = glob.glob(os.path.join(dataDir, 'session_*'))
fixedFiles  = [os.path.join(dataDir, 'paramFile_off'), os.path.join(dataDir,'sdp2input'), os.path.join(dataDir,'sdpb')]
fixed       = fixedFolder + fixedFiles


# construct a list of all (full) files names
allFiles     = os.listdir(dataDir)
allFilesFull = []
for item in os.listdir(dataDir):
    allFilesFull.append(os.path.join(dataDir, item))


# construct a list of (full) files names to be coppied
def diff(first, second):
        second = set(second)
        return [item for item in first if item not in second]

finalList = diff(allFilesFull, fixed)


# move files
for origin in finalList:
    shutil.move(origin, storeDir)












