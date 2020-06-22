(* ::Package:: *)

currentDirectory=If[$InputFileName=="",NotebookDirectory[],$InputFileName//DirectoryName];


currentDirectory//SetDirectory;


(* spins should be specified *)
(*minSpin=2;
maxSpin=3;*)


<<"util.m"


storageDirectory//SetDirectory;


r1=Hash[{1,3+10^-200}]
r2=Hash[{1,3+10^-210}]
r3=Hash[{2,3+10^-200}]


(* ::Subsubsection::Closed:: *)
(*Evaluation of integrals*)


rho[s_][m_,s0_]:=(Sqrt[4m^2-s0]-Sqrt[4m^2-s])/(Sqrt[4m^2-s0]+Sqrt[4m^2-s]);


integrandrho[m_,s0_][b_,c_]:=rho[t][m,s0]^b rho[u][m,s0]^c/.{t->-((s-4m^2)/2)(1-Cos[\[Theta]]),u->-((s-4m^2)/2)(1+Cos[\[Theta]])}


integrand[mass_,s0_][m_,n_][b_,c_]:=Cos[\[Theta]]^m Sin[\[Theta]]^n integrandrho[mass,s0][b,c]/.{Sin[\[Theta]]->Sqrt[1-Cos[\[Theta]]^2]}


(* valid for integer spins j *)
wignerD[j_,\[Mu]1_,\[Mu]2_]:=Sqrt[(j+\[Mu]1)!(j-\[Mu]1)!(j+\[Mu]2)!(j-\[Mu]2)!]Sum[(-1)^(\[Mu]1-\[Mu]2+3\[Nu])/2^j ((1+Cos[\[Theta]])^(j-(\[Nu]+(\[Mu]1-\[Mu]2)/2)) (1-Cos[\[Theta]])^(\[Nu]+(\[Mu]1-\[Mu]2)/2))/(\[Nu]!(j-\[Mu]1-\[Nu])!(j+\[Mu]2-\[Nu])!(\[Nu]+\[Mu]1-\[Mu]2)!),{\[Nu],0,2j}]


(*(* check *)
wignerDStandard[j_,\[Mu]1_,\[Mu]2_]:=Sqrt[(j+\[Mu]1)!(j-\[Mu]1)!(j+\[Mu]2)!(j-\[Mu]2)!]Sum[(-1)^\[Nu](Cos[\[Theta]/2]^(2j+\[Mu]2-\[Mu]1-2\[Nu])(-Sin[\[Theta]/2])^(\[Mu]1-\[Mu]2+2\[Nu]))/(\[Nu]!(j-\[Mu]1-\[Nu])!(j+\[Mu]2-\[Nu])!(\[Nu]+\[Mu]1-\[Mu]2)!),{\[Nu],0,2j}];
spin=6;
difference=Table[wignerD[spin,\[Mu],\[Mu]p]-wignerDStandard[spin,\[Mu],\[Mu]p]//FullSimplify[#,Assumptions\[Rule](\[Theta]\[GreaterEqual]0)&&(\[Theta]\[LessEqual]\[Pi])]&,{\[Mu],-spin,spin},{\[Mu]p,-spin,spin}]//Flatten;
difference/.\[Theta]\[Rule]1/10//N[#,100]&*)


fullIntegrand[mass_,s0_][m_,n_][b_,c_][j_,\[Mu]1_,\[Mu]2_]:=integrand[mass,s0][m,n][b,c]wignerD[j,\[Mu]1,\[Mu]2]/.Cos[\[Theta]]->x//Factor


evaluate[expr_]:=NIntegrate[expr,{x,-1,+1},WorkingPrecision->workPrec,PrecisionGoal->goalPrec,AccuracyGoal->goalPrec,Method->{"GlobalAdaptive",Method->"ClenshawCurtisRule"}];


specialEvaluate[info_][expr_]:=Module[{temp, res},
    temp =  evaluate[expr]//EvaluationData;
    res  = "Result"/.temp;
    If[("Success"/.temp)==False,Print[info,res]];
    res    
]


plug[sVal_][expr_]:=expr/.int[m_,n_][b_,c_][j_,\[Mu]1_,\[Mu]2_]:>Module[{info},
    info="Info: "<>"s="<>ToString[sVal//N]<>", "<>ToString[int[m,n][b,c][j,\[Mu]1,\[Mu]2]]<>"=";
    int[m,n][b,c][j,\[Mu]1,\[Mu]2]->(fullIntegrand[mass,s0][m,n][b,c][j,\[Mu]1,\[Mu]2]/.s->sVal//specialEvaluate[info])
]


(* ::Subsubsection::Closed:: *)
(*Sample points*)


relationToCompactVariable=Solve[rho[s][mass,s0]==Exp[I \[Phi]],s]/.C[1]->0//FullSimplify//Flatten


chebyshevGrid[n_][a_,b_]:=(a+b)/2+(b-a)/2 Table[Cos[(2k-1)/(2n) \[Pi]],{k,n,1,-1}];


samplePhi=chebyshevGrid[numberGridPoints][0,\[Pi]];


samplePoints=Table[{s->N[(s/.relationToCompactVariable),workPrec],rhos->N[Exp[I \[Phi]],workPrec]},{\[Phi],samplePhi}];


(* ::Subsubsection:: *)
(*Evaluation*)


elements[spin_]:=Cases[listToCompute,int[A__][B__][j_,\[Mu]1_,\[Mu]2_]:>int[A][B][j,\[Mu]1,\[Mu]2]/;j==spin]


constructSamplePoints[spinList_]:=Module[{existingFiles,spin,tmp,res,name,point,count,fullPoint,flag},

    existingFiles = FileNames[];

    Do[
        tmp   = elements[spin];
        ParallelDo[
            point     = s/.samplePoints[[k]];
            fullPoint = {spin,point};
            fullPoint = Hash[fullPoint]//ToString;
            name      = "spin="<>ToString[spin]<>"_"<>fullPoint<>".m";
            flag      = MemberQ[existingFiles,name];
            If[flag==False,
              name = FileNameJoin[{storageDirectory,name}];
              res  = tmp//plug[point];
              res  = samplePoints[[k]]~Join~res;
              Export[name,res]
            ]
        ,{k,1,numberGridPoints}]
    ,{spin,spinList}]

]


(* ::Subsubsection:: *)
(*Run*)


spinList = Table[j,{j,minSpin,maxSpin}]


constructSamplePoints[spinList]
