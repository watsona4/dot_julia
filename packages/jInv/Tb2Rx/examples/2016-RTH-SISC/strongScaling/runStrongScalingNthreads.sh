#!/bin/bash


julia -O runStrongScalingGetDataNthreads.jl --n1 256 --n2 256 --n3 128 --srcSpacing 40 --nthreads 24 --out=runStrongScalingGetData.csv --solver 4
julia -O runStrongScalingGetDataNthreads.jl --n1 256 --n2 256 --n3 128 --srcSpacing 40 --nthreads 16 --out=runStrongScalingGetData.csv --solver 4
julia -O runStrongScalingGetDataNthreads.jl --n1 256 --n2 256 --n3 128 --srcSpacing 40 --nthreads 8 --out=runStrongScalingGetData.csv --solver 4
julia -O runStrongScalingGetDataNthreads.jl --n1 256 --n2 256 --n3 128 --srcSpacing 40 --nthreads 4 --out=runStrongScalingGetData.csv --solver 4
julia -O runStrongScalingGetDataNthreads.jl --n1 256 --n2 256 --n3 128 --srcSpacing 40 --nthreads 2 --out=runStrongScalingGetData.csv --solver 4
julia -O runStrongScalingGetDataNthreads.jl --n1 256 --n2 256 --n3 128 --srcSpacing 40 --nthreads 1 --out=runStrongScalingGetData.csv --solver 4
     
julia -O -p2 runStrongScalingGetDataNthreads.jl --n1 256 --n2 256 --n3 128 --srcSpacing 40 --nthreads 12 --out=runStrongScalingGetData.csv --solver 4
julia -O -p2 runStrongScalingGetDataNthreads.jl --n1 256 --n2 256 --n3 128 --srcSpacing 40 --nthreads 8 --out=runStrongScalingGetData.csv --solver 4
julia -O -p2 runStrongScalingGetDataNthreads.jl --n1 256 --n2 256 --n3 128 --srcSpacing 40 --nthreads 4 --out=runStrongScalingGetData.csv --solver 4
julia -O -p2 runStrongScalingGetDataNthreads.jl --n1 256 --n2 256 --n3 128 --srcSpacing 40 --nthreads 2 --out=runStrongScalingGetData.csv --solver 4
julia -O -p2 runStrongScalingGetDataNthreads.jl --n1 256 --n2 256 --n3 128 --srcSpacing 40 --nthreads 1 --out=runStrongScalingGetData.csv --solver 4
     
julia -O -p4 runStrongScalingGetDataNthreads.jl --n1 256 --n2 256 --n3 128 --srcSpacing 40 --nthreads 6 --out=runStrongScalingGetData.csv --solver 4
julia -O -p4 runStrongScalingGetDataNthreads.jl --n1 256 --n2 256 --n3 128 --srcSpacing 40 --nthreads 4 --out=runStrongScalingGetData.csv --solver 4
julia -O -p4 runStrongScalingGetDataNthreads.jl --n1 256 --n2 256 --n3 128 --srcSpacing 40 --nthreads 2 --out=runStrongScalingGetData.csv --solver 4
julia -O -p4 runStrongScalingGetDataNthreads.jl --n1 256 --n2 256 --n3 128 --srcSpacing 40 --nthreads 1 --out=runStrongScalingGetData.csv --solver 4
