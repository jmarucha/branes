(* ::Package:: *)

(* carefully determine the current directory and load util.m and ansatz.m *)
currentDirectory=If[$InputFileName=="",NotebookDirectory[],$InputFileName//DirectoryName];
FileNameJoin[{currentDirectory,"../get_config.m"}]//Get

mathematicaDir = config[["directories"]][["mathematica"]]
inputDir = config[["directories"]][["sdpb_input"]]


Get[FileNameJoin[{mathematicaDir,"convertor.m"}]

(* ::Subsubsection:: *)
(*Code*)


selectSpin[name_]:=StringCases[name,"spin="~~j__~~"_"~~__->j][[1]]//ToExpression


constructSDPProblem[valN_][valMaxN_, valMaxSpin_]:=Module[{setMatrices,normalization,objective,details,t1,t2,type,nameUpper,nameLower,flag},

(* add details to the file names *)
details   = "_N="<>ToString[valN]<>"_maxN="<>ToString[valMaxN]<>"_maxSpin="<>ToString[valMaxSpin];
nameUpper = "upper"<>problemType<>details<>".m";
nameLower = "lower"<>problemType<>details<>".m";

(* execute below only if one or both .m files are missing *)
FileNameJoin[{currentDirectory,"problems"}]//SetDirectory;
If[(FileNames[{nameUpper, nameLower}]//Union)!=({nameUpper, nameLower}//Union),

(* load amplitudes *)
NN   = valN;
maxN = valMaxN;
Get[FileNameJoin[{mathematicaDir,"amplitudes.m"}]


(* select a problem *)
If[problemType=="A1Bound_A0=1",
    unitarityTProblem     = {unitarityT[[1]]+unitarityT[[2]]}~Join~unitarityT[[3;;-1]];
    unitaritySProblem     = {unitarityS[[1]]+unitarityS[[2]]}~Join~unitarityS[[3;;-1]];
    unitarityAProblem     = {unitarityA[[1]]+unitarityA[[2]]}~Join~unitarityA[[3;;-1]]; 
    normalization         = Table[If[i==1,1,0],{i,1,len}]; 
    objective             = Table[If[i==2,1,0],{i,1,len}];
    type                  = problemType
];

(* input *)
setMatrices = constructSDPData[valN][valMaxN, valMaxSpin];

(* export to .m format *)
Print[""];\
t1=AbsoluteTiming[Export[FileNameJoin[{inputDir,nameUpper}], SDP[+objective, normalization, setMatrices]]];
Print["Upper bound constructed: ",t1[[1]]];
t2=AbsoluteTiming[Export[FileNameJoin[{inputDir,nameLower}], SDP[-objective, normalization, setMatrices]]];
Print["Lower bound constructed: ",t2[[1]]],
Print["Files already exist: ", nameUpper,", ", nameLower]
];

Write[$Output,"| "<>nameUpper<>", "<>nameLower<>" |"]

]


constructSDPData[valN_][valMaxN_, valMaxSpin_]:=Module[{count=0,names,fNum,loadedRule,spinValue,setMatrices1={},setMatrices2Zero={},setMatrices2={},setMatrices3={}},

count//SetSharedVariable;
setMatrices1//SetSharedVariable;
setMatrices2//SetSharedVariable;
setMatrices3//SetSharedVariable;

(* sample points *)
FileNameJoin[{currentDirectory,"sample_points","data"}]//SetDirectory;
names=Table[FileNames["spin="<>ToString[spin]<>ToString["_*"]],{spin,0,valMaxSpin}]//Flatten;

Write["stdout", "Problem type: "<>problemType<>". Parameters: N="<>ToString[valN]<>", maxN="<>ToString[valMaxN]<>", maxSpin="<>ToString[valMaxSpin]];
Write["stdout", "Total number of sample points: "<>ToString[names//Length]];
(*Write["stdout", "Sample points considered: "];*)

(* loading sample points and substituting to unitarity constraints *)
ParallelDo[    
    loadedRule = names[[fNum]]//Get//Dispatch;
    spinValue  = names[[fNum]]//selectSpin;
    
    (* unitarity T: spin\[GreaterEqual]0 and even *)
    If[EvenQ[spinValue],AppendTo[setMatrices1,unitarityTProblem/.j->spinValue//.loadedRule];]; 
    
    (* unitarity S: spin\[GreaterEqual]0 and even *)
    If[EvenQ[spinValue],AppendTo[setMatrices2,unitaritySProblem/.j->spinValue//.loadedRule]];
      
    (* unitarity A: spin\[GreaterEqual]1 and odd *)
    If[(spinValue>=1)&&OddQ[spinValue],AppendTo[setMatrices3,unitarityAProblem/.j->spinValue//.loadedRule]];
      
(*    count++;*)
(*    WriteString["stdout", ToString[count]<>", "];*)
,{fNum,1,names//Length}];

(* combining and converting the data *)
setMatrices1~Join~setMatrices2~Join~setMatrices3//convert

]


(* ::Subsubsection:: *)
(*Run*)


(*constructSDPProblem[3][10,10]*)
