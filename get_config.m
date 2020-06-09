(* ::Package:: *)

oldDirectory = Directory[]
currentDirectory=If[$InputFileName=="",NotebookDirectory[],$InputFileName//DirectoryName];
SetDirectory[currentDirectory];
config = ImportString[RunProcess[{"python3", "util.py"}, "StandardOutput"], "RawJSON"];
(*python = StartExternalSession["Python"];
ExternalEvaluate[python, "import os"]
ExternalEvaluate[python, 
 "os.chdir(" <> ToString[currentDirectory, InputForm] <> 
  ")"];
ExternalEvaluate[python,File[FileNameJoin[{currentDirectory,"util.py"}]]];
config = ExternalValue[python, "config"];
DeleteObject[python];*)
SetDirectory[oldDirectory] (* to avoid mess *)






