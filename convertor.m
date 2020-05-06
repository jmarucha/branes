(* ::Package:: *)

(* ----- making a real matrix ----- *)
makeReal[matrix_]:=Module[{re,im,temp},
re=matrix//Re;
im=matrix//Im;
ArrayFlatten[{{re,-im},{im,re}}]
];


(* ----- merging matrices ----- *)
mergeMatrices[listMatrices_]:=Module[{f,temp},
SetAttributes[f,{Flat,Listable}];
temp=f@@listMatrices;
temp/.f->List
];


(* ----- applying function 2 levels inside the list ----- *)
(* list  =  { {a1,a2,...}, {b1,b2,...}, ... } *)
(* return = { {f[a1],f[a2],...}, {f[b1],f[b2],...}, ... }*)
applyTwoLevels[function_][list_]:=Module[{temp=list},
    Do[temp[[i,j]]=list[[i,j]]//function, {i,1,list//Length}, {j,1,list[[i]]//Length}];
    temp
]


(*(* ----- test ----- *)
exampleList={{a1,a2,a3,a4,a5},{b1,b2},{c1,c2,c3,{{m11,m12},{m21,m22}}}}
exampleList//applyTwoLevels[g]*)


(*(* ----- test ----- *)
exampleList={{{a11,a12},{a21,a22}},{{b11,b12},{b21,b22}},{{c11,c12},{c21,c22}},{{d11,d12},{d21,d22}}};
Table[exampleList[[i]]//MatrixForm,{i,1,exampleList//Length}]
exampleList//mergeMatrices//MatrixForm*)


(* ----- applying makeReal and transpose ----- *)
makeRealTranspose[expr_]:=expr//makeReal//Transpose;


convert[expr_]:=Module[{tempA,tempB,check},
(* obtain real matrix by doubling it *)
tempA=expr//applyTwoLevels[makeRealTranspose];

(* mergeMatrices *)
tempB=Table[tempA[[i]]//mergeMatrices,{i,1,tempA//Length}];

(* chech *)
check=tempB//Im//Flatten//Union;
If[Not[check==={0}],Print["Error: the matrix is complex"]];

(* construct the final output *)
Table[PositiveMatrixWithPrefactor[1, tempB[[i]]],{i,1,tempB//Length}]

]
