# NG[![Build Status](https://travis-ci.org/hzgzh/NatureGas.jl.svg?branch=master)](https://travis-ci.org/hzgzh/Naturegas.jl)
# Nature Gas Compress Factor Calculation

## install

Pkg.add("https://github.com/hzgzh/NatureGas.git")

## usage

# Example
```
julia>ng_zfactor(6,300;CO2=0.006,N2=0.003,CH4=0.965,C2H6=0.018,C3H8=0.0045,
iC4H10=0.001,nC4H10=0.001,iC5H12=0.0005,nC5H12=0.0003,nC6H14=0.0007))
0.8953514530758864
```
