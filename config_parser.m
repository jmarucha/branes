(* ::Package:: *)

currentDirectory=If[$InputFileName=="",NotebookDirectory[],$InputFileName//DirectoryName];
python = StartExternalSession["Python"];
ExternalEvaluate[python, "import os"]
ExternalEvaluate[python, 
 "os.chdir(" <> ToString[currentDirectory, InputForm] <> 
  ")"];
ExternalEvaluate[python,File[FileNameJoin[{currentDirectory,"config_parser.py"}]]];
config = ExternalValue[python, "config"];
DeleteObject[python];
