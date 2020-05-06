(* ::Package:: *)

currentDirectory=If[$InputFileName=="",NotebookDirectory[],$InputFileName//DirectoryName];
storageDirectory=FileNameJoin[{currentDirectory,"data"}];


currentDirectory//SetDirectory;


mass=0;
s0=-1;


workPrec=150;
goalPrec=20;


numberGridPoints=400;


Protect[m,n,j,\[Mu]1,\[Mu]2];


(* ----- objects to compute ----- *)
listToCompute="list_objects.m"//Get;
listToCompute=Table[listToCompute,{j,minSpin,maxSpin}]//Flatten//Union;
listToCompute=Cases[listToCompute,int[A__][B__][j_,\[Mu]_,\[Mu]p_]:>int[A][B][j,\[Mu],\[Mu]p]/;((j>=Abs[\[Mu]])&&(j>=Abs[\[Mu]p]))];
