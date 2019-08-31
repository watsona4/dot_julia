# Readables.jl    [ do not use #master, pending revision ]
### Make extended precision numbers readable.

| Copyright © 2018 by Jeffrey Sarnoff.  | This work is made available under The MIT License. |
|:--------------------------------------|:------------------------------------------------:|


-----

[![Build Status](https://travis-ci.org/JeffreySarnoff/TimesDates.jl.svg?branch=master)](https://travis-ci.org/JeffreySarnoff/Readables.jl)
 
----


## Use

```julia
using Readables

setprecision(BigFloat, 160)

macro twoways(val)
    :(println(string("\n\t", $val, "\n\t", readablestring($val))))
end
```
```julia
val = (pi/2)^9; @twoways(val)

	58.22089713563711
	58.22089_71356_3711

val = (BigFloat(pi)/2)^9; @twoways(val)

        58.220897135637132161151176564921201882554800340637
        58.22089,71356,37132,16115,11765,64921,20188,25548,00340,637

setprecision(BigFloat, 192)

val = (BigFloat(pi))^115; ival = trunc(BigInt, val); @twoways(ival)

	1486741142588149449007460570055579083524909316281177999404
	1,486,741,142,588,149,449,007,460,570,055,579,083,524,909,316,281,177,999,404

```

## Customize

```julia
config = Readable()
config = setintgroup(config, 6)
config = setintsep(config, '⚬')

ival = trunc(BigInt, (BigFloat(pi))^64);

readable(config, ival)
"65704006:445717084572:022626334540"
```

## Configure

We assume a `Real` value has an integer componant and a fractional componant (either may be zero).

`intgroup, fracgroup` is the number of digits used to form digit subsequences in the integer and fractional parts

`intsep, fracsep` is the `Char` used to separate groups in the integer and fractional parts

### exported configurables

- decpoint, setdecpoint
- intsep, fracsep, setintsep, setfracsep
- intgroup, fracgroup, setintgroup, setfracgroup


----
