(* ::Package:: *)

(* carefully determine the current directory and load util.m and ansatz.m *)
currentDirectory=If[$InputFileName=="",NotebookDirectory[],$InputFileName//DirectoryName];
FileNameJoin[{currentDirectory,"../get_config.m"}]//Get;
mathematicaDir = config[["directories"]][["mathematica"]];
inputDir = config[["directories"]][["sdpb_input"]];
gridDir = config[["directories"]][["spherical_integrals"]];
problemType = config[["physics"]][["problem_type"]];


Get[FileNameJoin[{mathematicaDir,"convertor.m"}]]


(* ::Subsubsection:: *)
(*Code*)


selectSpin[name_]:=StringCases[name,"spin="~~j__~~"_"~~__->j][[1]]//ToExpression


constructSDPProblem[valN_][valMaxN_, valMaxSpin_]:=Module[{setMatrices,normalization,objective,details,t1,t2,type,nameUpper,nameLower,flag},

(* add details to the file names *)
details   = "_N="<>ToString[valN]<>"_maxN="<>ToString[valMaxN]<>"_maxSpin="<>ToString[valMaxSpin];
nameUpper = "upper"<>problemType<>details<>".m";
nameLower = "lower"<>problemType<>details<>".m";

(* execute below only if one or both .m files are missing *)
SetDirectory[inputDir];
If[True ||(FileNames[{nameUpper, nameLower}]//Union)!=({nameUpper, nameLower}//Union),

(* load amplitudes *)
NN   = valN;
maxN = valMaxN;
Get[FileNameJoin[{mathematicaDir,"amplitudes.m"}]]
(* select a problem *)
If[problemType=="A1Bound_A0=1",
    unitarityTProblem     = {unitarityT[[1]]+unitarityT[[2]]}~Join~unitarityT[[3;;-1]];
    unitaritySProblem     = {unitarityS[[1]]+unitarityS[[2]]}~Join~unitarityS[[3;;-1]];
    unitarityAProblem     = {unitarityA[[1]]+unitarityA[[2]]}~Join~unitarityA[[3;;-1]]; 
    normalization         = Table[If[i==1,1,0],{i,1,len}]; 
    objective             = Table[If[i==2,1,0],{i,1,len}];
    type                  = problemType
];
If[problemType=="A0Bound_A1=1",
    unitarityTProblem     = {unitarityT[[1]]+unitarityT[[2]]}~Join~unitarityT[[3;;-1]];
    unitaritySProblem     = {unitarityS[[1]]+unitarityS[[2]]}~Join~unitarityS[[3;;-1]];
    unitarityAProblem     = {unitarityA[[1]]+unitarityA[[2]]}~Join~unitarityA[[3;;-1]]; 
    normalization         = Table[If[i==2,1,0],{i,1,len}]; 
    objective             = Table[If[i==1,1,0],{i,1,len}];
    type                  = problemType
];
If[problemType=="A0Bound_A1=-1",
    unitarityTProblem     = {unitarityT[[1]]+unitarityT[[2]]}~Join~unitarityT[[3;;-1]];
    unitaritySProblem     = {unitarityS[[1]]+unitarityS[[2]]}~Join~unitarityS[[3;;-1]];
    unitarityAProblem     = {unitarityA[[1]]+unitarityA[[2]]}~Join~unitarityA[[3;;-1]]; 
    normalization         = Table[If[i==2,-1,0],{i,1,len}]; 
    objective             = Table[If[i==1,1,0],{i,1,len}];
    type                  = problemType
];

(* input *)
AbsoluteTiming[setMatrices = constructSDPData[valN][valMaxN, valMaxSpin]][[1]]//Print["Grid processed: ", #]&;

(* export to .m format *)
Print[""];
t1=AbsoluteTiming[Export[FileNameJoin[{inputDir,nameUpper}], SDP[ objective, normalization, setMatrices]]];
Print["Upper bound constructed: ",t1[[1]]];
t2=AbsoluteTiming[Export[FileNameJoin[{inputDir,nameLower}], SDP[-objective, normalization, setMatrices]]];
Print["Lower bound constructed: ",t2[[1]]],
Print["Files already exist: ", nameUpper,", ", nameLower]
];
Write[$Output,"| "<>FileNameJoin[{inputDir,nameUpper}]<>", "<>FileNameJoin[{inputDir,nameLower}]<>" |"]

]


constructSDPData[valN_][valMaxN_, valMaxSpin_]:=Module[{count=0,names,fNum,problemMatrices,HSConstraints},

(* sample points *)
SetDirectory[gridDir];
names=Table[FileNames["spin="<>ToString[spin]<>ToString["_*"]],{spin,0,valMaxSpin}]//Flatten;

Write["stdout", "Problem type: "<>problemType<>". Parameters: N="<>ToString[valN]<>", maxN="<>ToString[valMaxN]<>", maxSpin="<>ToString[valMaxSpin]];
Write["stdout", "Total number of sample points: "<>ToString[names//Length]];

SPDBConstraint[name_] := Module[{loadedRule, spinValue},
	loadedRule = name//Get//Dispatch;
    spinValue  = name//selectSpin;
    (* unitarity T: spin\[GreaterEqual]0 and even *)
    {If[EvenQ[spinValue],unitarityTProblem/.j->spinValue//.loadedRule, 0],
     If[EvenQ[spinValue],unitaritySProblem/.j->spinValue//.loadedRule, 0],
    (* unitarity A: spin\[GreaterEqual]1 and odd *)
     If[(spinValue>=1)&&OddQ[spinValue],unitarityAProblem/.j->spinValue//.loadedRule, 0]}//Select[ArrayQ]
];
HSConstraint[name_] := Module[{loadedRule},
	If[(name//selectSpin) == 2 && config[["physics"]][["high_spin_constraints"]],
	loadedRule = name//Get//Dispatch;
	PositiveMatrixWithPrefactor[1,{{highSpinConstraint}}//.loadedRule],0]
];
HSConstraints = ParallelMap[HSConstraint,names]//Select[#=!=0&];
problemMatrices = ParallelMap[SPDBConstraint,names]//Flatten[#,1]& // convert;
HSConstraints ~ Join ~ problemMatrices
]






(* ::Subsubsection:: *)
(*Run*)


(*constructSDPProblem[3][6,2]*)








