(* ::Package:: *)

currentDirectory=If[$InputFileName=="",NotebookDirectory[],$InputFileName//DirectoryName];


FileNameJoin[{currentDirectory,"config_parser.m"}]//Get;


config


(* ::Subsection:: *)
(*Amplitude*)


(* ::Subsubsection:: *)
(*Ansatz*)


(* the amplitude A(s|t,u) is denoted by f *)


\[Alpha][a_,b_,c_]:=0/;(a b c!=0)
f = Sum[\[Alpha][a,b,c]rhos[a]rhot[b]rhou[c],{a,0,maxN},{b,0,maxN-a},{c,0,maxN-a-b}];


(* imposing t-u symmetry *)
tuSymmetrize[ans_]:=ans/.\[Alpha][a_,b_,c_]:>\[Alpha][a,c,b]/;b>c;


(* t-u symmetric ansatz *)
ff=f//tuSymmetrize;


ch = (ff/.{rhot->rhou, rhou->rhot})-ff;
If[ch==0,Print["Symmetry: OK"], Print["Symmetry: ERROR"]]


listCoefficients = Table[\[Alpha][a,b,c],{a,0,maxN},{b,0,maxN-a},{c,0,maxN-a-b}]//Flatten;
listCoefficients = Select[listCoefficients, Not[NumberQ[#]]&]; (* remove zeros *)
listCoefficients = listCoefficients//tuSymmetrize//Union;(* apply t-u symmetry *)


(* ::Subsubsection:: *)
(*Further conditions on the ansatz*)


z0 = config[["physics"]][["z0"]]


(* low energy amplitude *)
lowEnergyAmplitude = 1/4 A0(-s^2+t^2+u^2)+A1 s(-s^2+2t^2+2u^2);


plugRho[expr_]:=expr/.{rhos[a_]:>((Sqrt[-z0]+I Sqrt[s])/(Sqrt[-z0]-I Sqrt[s]))^a, rhot[b_]:>((Sqrt[-z0]+I Sqrt[t])/(Sqrt[-z0]-I Sqrt[t]))^b, rhou[c_]:>((Sqrt[-z0]+I Sqrt[u])/(Sqrt[-z0]-I Sqrt[u]))^c};


expand[order_][expr_]:=Module[{temp, zeroOrderTerm, coef},
  temp = expr//plugRho;
  temp = temp/.{t->-(s/2)(1-x),u->-(s/2)(1+x)}; (* x=Cos[\[Theta]] *)
  temp = Series[temp,{s,0,order},Assumptions->s>0]//Normal;
  temp 
];


formObjects[expr_]:=Module[{temp, zeroTerm},
   (* obj[a,b,c]=x^a(Sqrt[-1+x])^b(Sqrt[-1-x])^c, where a=0,1,2,3,..; b=0,1 and c=0,1 *)
   temp = expr/.Sqrt[-1+x]->obj[0,1,0];
   temp = temp/.obj[0,1,0]Sqrt[-1-x]->obj[0,1,1];
   temp = temp/.Sqrt[-1-x]->obj[0,0,1];
   temp = temp/.x^a_. obj[0,b_,c_]:>obj[a,b,c];
   temp = temp/.x^a_.:>obj[a,0,0];
   zeroTerm = temp/.obj[__]:>0;
   temp = temp+zeroTerm(obj[0,0,0]-1)//Expand

]


obtainCoefficients[expr_]:=Module[{res, temp},
    res = expr//Expand//formObjects;
    temp = res//.A_ obj[B__]:>obj[B];
    temp = List@@temp;
    temp = temp//Union;
    Coefficient[res,temp]
]


(* extract coefficients *)
extract[order_][expr_]:=Module[{temp, zeroOrderTerm, coef},
  Clear[expan]; 
   
  (* expansion in s *)
  temp = expr//expand[order];

  (* pick coefficients in front of \[Epsilon]^(n/2) with n\[GreaterEqual]1 and then pick coefficients in front of various s^(p1/2)t^(p2/2)u^(p3/2)*)
  expan[0] = temp/.s->0;
  Do[
      coef     = Coefficient[temp,s^(n/2)];
      expan[n] = coef//obtainCoefficients//Flatten//Union;  
  ,{n,1,2order}];  
];


(* require the low energy expansion *)
ff-lowEnergyAmplitude//extract[4];


systemShort = Table[expan[i]==0//Thread,{i,0,5}]//Flatten//Factor//Union;
systemFull  = Table[expan[i]==0//Thread,{i,0,7}]//Flatten//Factor//Union;


(* solution: split in two steps in order to speed up the process *)
solutionShort = systemShort//Solve[#,listCoefficients]&//Flatten//Quiet;
systemFull    = systemFull/.solutionShort//Factor//Union;
solutionFull  = systemFull//Solve[#,listCoefficients]&//Flatten//Factor//Quiet;
solution      = (solutionShort/.solutionFull//Factor)~Join~solutionFull;


(* functions with correct low energy behaviour *)
fff=ff/.solution;


(* checks *)
check = (fff//plugRho)/.{s->\[Epsilon] s,t->\[Epsilon] t,u->\[Epsilon] u};
check = Series[check,{\[Epsilon],0,4}]//Normal;
check = Collect[check/.{u->-s-t},\[Epsilon]^_.,Factor];
check = check/.\[Epsilon]^4->0/.\[Epsilon]->1//Factor;
check = lowEnergyAmplitude-check/.{u->-s-t}//Simplify;
If[check==0,Print["Additional constraints: OK"], Print["Additional constraints: ERROR"]]


(* ::Subsubsection::Closed:: *)
(*Independent parameters*)


dependentCoefficients=Cases[solution,(A_->B_):>A];


listCoefficients = Complement[listCoefficients,dependentCoefficients]; (* remove coefficients fixed by the low enerergy *)


listCoefficients = {A0,A1}~Join~listCoefficients;


(* the number of independent coefficients *)
len = listCoefficients//Length


(* checks *)
ch0 = listCoefficients[[1;;2]]-{A0,A1}//Union; (* A0 and A1 remain free parameters *)
ch1 = fff-Coefficient[fff,listCoefficients].listCoefficients//Expand;
If[Union[{ch0,ch1}//Flatten]=={0},Print["Independent coefficients: OK"],Print["Independent coefficients: ERROR"]]


(* ::Subsubsection::Closed:: *)
(*Irreducible representations*)


permutationST[expr_]:=expr/.{rhos->rhot, rhot->rhos}


permutationSU[expr_]:=expr/.{rhos->rhou, rhou->rhos}


(*irreps: T stands for trivial, S stands for symmetric traceless and A stands for antisymmetric *)


ampT = permutationST[fff] + permutationSU[fff] + NN fff;
ampS = permutationST[fff] + permutationSU[fff];
ampA = permutationST[fff] - permutationSU[fff];


(* ::Subsection:: *)
(*Partial amplitudes*)


(* replaces products of rho variables with sines and cosines by 'int' *)
substituteFunction[expr_]:=Module[{temp},
  temp = expr//Expand;
  temp = temp/. rhot[b_] rhou[c_]:>int[0,0][b,c][j,0,0];
  temp = temp/. Cos[\[Theta]]^m_. int[0,0][b_,c_][j,0,0]:>int[m,0][b,c][j,0,0];
  temp = temp/. Sin[\[Theta]]^n_. int[m_,0][b_,c_][j,0,0]:>int[m,n][b,c][j,0,0];
 
  temp
]


(* interracting part of the partial amplitude *)
partialAmpT=1/(32\[Pi]) ampT//substituteFunction;
partialAmpS=1/(32\[Pi]) ampS//substituteFunction;
partialAmpA=1/(32\[Pi]) ampA//substituteFunction;


(* ---------- coefficients in front of unknown parameters ---------- *)


(* plug rhos *)
plugRhos[expr_]:=expr/.rhos[a_]:>rhos^a


coefsT=Coefficient[partialAmpT,listCoefficients]//plugRhos;
coefsS=Coefficient[partialAmpS,listCoefficients]//plugRhos;
coefsA=Coefficient[partialAmpA,listCoefficients]//plugRhos;


(* checks *)
ch1 = partialAmpT-coefsT.listCoefficients//plugRhos//Expand;
ch2 = partialAmpS-coefsS.listCoefficients//plugRhos//Expand;
ch3 = partialAmpA-coefsA.listCoefficients//plugRhos//Expand;
If[Union[{ch1,ch1,ch2}//Flatten]=={0},Print["Basis of functions: OK"],Print["Basis of functions: ERROR"]]


(* ::Subsection:: *)
(*Unitarity*)


unitarityT={{{1,1},{1,1}}}~Join~Table[{{0,I coefsT[[i]]},{I coefsT[[i]]//Conjugate,0}},{i,1,len}];


unitarityS={{{1,1},{1,1}}}~Join~Table[{{0,I coefsS[[i]]},{I coefsS[[i]]//Conjugate,0}},{i,1,len}];


unitarityA={{{1,1},{1,1}}}~Join~Table[{{0,I coefsA[[i]]},{I coefsA[[i]]//Conjugate,0}},{i,1,len}];


Print["Unitarity lists: constructed"];
