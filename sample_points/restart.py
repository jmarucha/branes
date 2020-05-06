#!/usr/bin/python
import os  # os module allows to determine directories
import subprocess
import shutil


# set description
folderName = 'session_1'
description = '\
accuracy goal for int  = 20  \n\
precision              = 150 \n\
number of grid points  = 400 \n\
sdpb precision         = 800  # binary precision \n\
'


# determine working directory
directory  = os.path.dirname(os.path.realpath(__file__))
dataDir    = os.path.join(directory, 'data')
storeDir   = os.path.join(dataDir, folderName)
	

# create the storeDir and add the description file	
os.mkdir(storeDir)
name = os.path.join(storeDir, 'description.txt')
file = open(name, "w") 
file.write(description) 
file.close() 


# clean int_data folder
intDir = os.path.join(directory, 'int_data')
shutil.rmtree(intDir)
os.mkdir(intDir)


# copy all the files in dataDir to storeDir
for name in os.listdir(dataDir):
    origin = os.path.join(dataDir, name)
    if os.path.isdir(origin)==False:
        destin = os.path.join(storeDir, name)
        shutil.move(origin, destin)





