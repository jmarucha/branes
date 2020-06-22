(* ::Package:: *)

currentDirectory=If[$InputFileName=="",NotebookDirectory[],$InputFileName//DirectoryName];


currentDirectory//SetDirectory;
<<"../get_config.m"


mass=config[["physics"]][["m"]];
s0=config[["physics"]][["z0"]];
storageDirectory=config[["directories"]][["spherical_integrals"]];


workPrec=config[["mathematica"]][["working_precision"]];
goalPrec=config[["mathematica"]][["precision_goal"]];


numberGridPoints=config[["grid"]][["gridPoints"]];


Protect[m,n,j,\[Mu]1,\[Mu]2];


(* ----- objects to compute ----- *)
listToCompute="list_objects.m"//Get;
listToCompute=Table[listToCompute,{j,minSpin,maxSpin}]//Flatten//Union;
listToCompute=Cases[listToCompute,int[A__][B__][j_,\[Mu]_,\[Mu]p_]:>int[A][B][j,\[Mu],\[Mu]p]/;((j>=Abs[\[Mu]])&&(j>=Abs[\[Mu]p]))];






