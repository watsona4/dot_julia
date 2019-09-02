#!/bin/bash
# -*- mode: julia -*-
#=
exec ${JULIA:-julia} --color=yes --startup-file=no \
    -e "include(popfirst!(ARGS))" "${BASH_SOURCE[0]}" \
    "$@"
=#

csv_path, = ARGS

using SnoopCompile

SnoopCompile.@snoopc ["-i"] csv_path begin
    using IPython
    IPython.test_ipython_jl(inprocess=true)
    IPython.start_ipython()
end
