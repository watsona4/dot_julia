#!/bin/bash

set -ex

typename="$1"
filename="src/$typename.jl"
echo "mutable struct $typename <: LCMType" > "$filename"
echo "end" >> "$filename"
echo "" >> "$filename"
echo "@lcmtypesetup($typename)" >> "$filename"

echo "export $typename" >> "src/DrakeLCMTypes.jl"
echo "include(\"$typename.jl\")" >> "src/DrakeLCMTypes.jl"

