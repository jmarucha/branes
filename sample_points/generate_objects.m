(* ::Package:: *)

currentDirectory=If[$InputFileName=="",NotebookDirectory[],$InputFileName//DirectoryName];
FileNameJoin[{currentDirectory,".."}]//SetDirectory;


(* choose maxN *)
maxN=16;


<<"amplitudes.m";//AbsoluteTiming


listT=List@@(partialAmpT//.A_ int[B__][C__][D__]:>int[B][C][D])//Flatten;
listS=List@@(partialAmpS//.A_ int[B__][C__][D__]:>int[B][C][D])//Flatten;
listA=List@@(partialAmpA//.A_ int[B__][C__][D__]:>int[B][C][D])//Flatten;


listIntObjectsOriginal=listT~Join~listS~Join~listA//Union;


currentDirectory=If[$InputFileName=="",NotebookDirectory[],$InputFileName//DirectoryName];
currentDirectory//SetDirectory;
Export["list_objects.m",listIntObjectsOriginal];
