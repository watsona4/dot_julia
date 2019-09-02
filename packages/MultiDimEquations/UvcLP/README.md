# MultiDimEquations

Allows to write multi-dimensional equations in Julia using an easy and compact syntax:

```
@meq nTrees!(r in reg, sp in species, dc in diameterClass[2-end], y in years) = nTrees_(r, sp, dc, y)*(1-mortRate_(r, sp, dc, y-1) - promotionRate_(r, sp, dc, y-1))) +  promotionRate_(r, sp, dc-1, y-1)
```

It is somehow similar to Algebraic modeling language (AML) like GAMS or Julia/JuMP, but outside the domain of optimisation.


[![Build Status](https://travis-ci.org/sylvaticus/MultiDimEquations.jl.svg?branch=master)](https://travis-ci.org/sylvaticus/MultiDimEquations.jl)
[![codecov.io](http://codecov.io/github/sylvaticus/MultiDimEquations.jl/coverage.svg?branch=master)](http://codecov.io/github/sylvaticus/MultiDimEquations.jl?branch=master)

[![MultiDimEquations](http://pkg.julialang.org/badges/MultiDimEquations_0.6.svg)](http://pkg.julialang.org/?pkg=MultiDimEquations&ver=0.6)
[![MultiDimEquations](http://pkg.julialang.org/badges/MultiDimEquations_0.6.svg)](http://pkg.julialang.org/?pkg=MultiDimEquations&ver=0.6)


## Installation
* `Pkg.add("MultiDimEquations")`

## Making available the package
Due to the fact that the functions to access the data are dynamically created at run time, and would not be available to you with a normal `import <package>`, you have instead to include the file in your program:

```
include("$(Pkg.dir())/MultiDimEquations/src/MultiDimEquations.jl")
```

## Definition of the variables:

Define each group of variables with their associated data source. At the moment MultiDimEquations support only DataFrame in long format, i.e. in the format parameter|dim1|dim2|...|value

```
df = wsv"""
reg	prod	var	value
us	banana	production	10
us	banana	transfCoef	0.6
us	banana	trValues	2
us	apples	production	7
us	apples	transfCoef	0.7
us	apples	trValues	5
us	juice	production	NA
us	juice	transfCoef	NA
us	juice	trValues	NA
eu	banana	production	5
eu	banana	transfCoef	0.7
eu	banana	trValues	1
eu	apples	production	8
eu	apples	transfCoef	0.8
eu	apples	trValues	4
eu	juice	production	NA
eu	juice	transfCoef	NA
eu	juice	trValues    NA
"""

variables =  vcat(unique(dropna(df[:var])),["consumption"])
defVars(variables,df;dfName="df",varNameCol="var", valueCol="value")
```

Each time you run `defVars()`, access functions are automatically created for each variable in the form of `variable_(dim1,dim2,...)` to access the data and `variable!(value,dim1,dim2,..)` to store the value.
For more info type `?defVars` once you installed and loaded the package.


# Defining the "set" (dimensions) of your data
These are simple Julia Arrays..

```
products = ["banana","apples","juice"]
primPr   = products[1:2]
secPr    = [products[3]]
reg      = ["us","eu"]
```

## Write your model using the @meq macro

The @meq macro adds a bit of convenience transforming at parse time (so, without adding run-time overheads) your equation from `par1!(d1 in DIM1, d2 in DIM2, dfix3) = par2_(d1,d2)+par3_(d1,d2)` to `[par1!(par2_(d1,d2)+par3_(d1,d2), d1,d2,dfix3) for d1 in dim1, d2 in dim2]`.

```
# equivalent to [production!(sum(trValues_(r,pp) * transfCoef_(r,pp)  for pp in primPr), r, sp) for r in reg, sp in secPr]
@meq production!(r in reg, sp in secPr)   = sum(trValues_(r,pp) * transfCoef_(r,pp)  for pp in primPr)
@meq consumption!(r in reg, pp in primPr) = production_(r,pp) - trValues_(r,pp)
@meq consumption!(r in reg, sp in secPr)  = production_(r, sp)
```

Using `defVars()` with the `@meq` macro your data is kept in a single `IndexedTable` where one column is used to keep the variable names.
An alternative (and faster) approach is to define your variables as each one being a separate `IndexedTable` (the package [LAJuliaUtils](https://github.com/sylvaticus/LAJuliaUtils.jl) has some useful functions for such approach).
You can still use @meq to provide some convenience:

@meq `par1[d1 in DIM1, d2 in DIM2, dfix3] = par2[d1,d2]+par3[d1,d2]` ==> `[par1[d1,d2,dfix3] = par2[d1,d2]+par3[d1,d2] for d1 in dim1, d2 in dim2]`.

For more info on the @meq macro type `?@meq`

## Known limitation

- This is a young package still under active development.
- While convenient, named access is definitely slower than positional access to data (i.e. it is a functional rather than performance oriented approach). Neverthless, using `IndexedTables` as backend, this package provides a reasonable fast implementation.
- Also, at this time, only `var = ...` assignments are supported.

## Acknowledgements

The development of this package was supported by the French National Research Agency through the [Laboratory of Excellence ARBRE](http://mycor.nancy.inra.fr/ARBRE/), a part of the “Investissements d'Avenir” Program (ANR 11 – LABX-0002-01).
