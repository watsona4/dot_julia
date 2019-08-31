# ConsoleInput.jl
[![Build Status](https://travis-ci.com/mildc055ee/ConsoleInput.jl.svg?branch=master)](https://travis-ci.com/mildc055ee/ConsoleInput.jl)
[![codecov](https://codecov.io/gh/mildc055ee/ConsoleInput.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/mildc055ee/ConsoleInput.jl)
  
minimal stdin wrapper for julia.

## APIs
This module uses original type `DlmType` defined as below.
```julia
DlmType = Union{
    AbscractChar,
    AbscractString,
    Regex
}
```
Default delimiter is `" "`.You can indicate specific delimiter like `readXXX(delimiter=",")`.
  
**Note** This packages function returns a single value when args is only one. else returns array.
### `readInt(io::IO=stdin, delimiter::DlmType=" ")`
parse inputs to Int.
```julia
readInt() #<-- 1
#--> 1

readInt() #<-- 1 2 3 4 5
#--> [1, 2, 3, 4, 5]

readInt(delimiter=',') #<--6,7,8,9,10
#--> [6, 7, 8, 9, 10]
```

### `readString(io::IO=stdin, delimiter::DlmType=" ")`
parse inputs to string.
```julia
readString() #<-- Lorem
#--> "Lorem"

readString() #<-- Lorem ipsum es
#-->["Lorem", "ipsum", "es"]
```
### `readGeneral(type, io::IO=stdin, delimiter::DlmType=" ")`
parse inputs to any types you want. First argument MUST be a type name.
```julia
readGeneral(Complex{Fload64}) #<--1.2e-3+4j -9+6.8i 0.0004 90.5im
#-->[0.0012+4.0im, -9.0+6.8im, 0.0004+0.0im, 0.0+90.5im]
```

