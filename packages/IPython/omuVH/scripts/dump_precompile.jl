#!/bin/bash
# -*- mode: julia -*-
#=
exec ${JULIA:-julia} --color=yes --startup-file=no \
    -e "include(popfirst!(ARGS))" "${BASH_SOURCE[0]}" \
    "$@"
=#

csv_path, output = ARGS

using SnoopCompile

data = SnoopCompile.read(csv_path)
pc = SnoopCompile.parcel(reverse!(data[2]))
SnoopCompile.write(output, pc)
