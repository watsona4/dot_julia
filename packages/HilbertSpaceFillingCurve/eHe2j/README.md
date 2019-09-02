# HilbertSpaceFillingCurve

[![Build Status](https://travis-ci.org/jonathanBieler/HilbertSpaceFillingCurve.jl.svg?branch=master)](https://travis-ci.org/jonathanBieler/HilbertSpaceFillingCurve.jl)

[![Coverage Status](https://coveralls.io/repos/jonathanBieler/HilbertSpaceFillingCurve.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/jonathanBieler/HilbertSpaceFillingCurve.jl?branch=master)

Bindings for Doug Moore's [Fast Hilbert Curve Generation](http://www.tiac.net/~sw/2008/10/Hilbert/moore/). Windows is not supported.

![screenshot](data/figure.png)

## Usage

Convert the linear index `d` into ndims-dimensional coordinates `p` :

`p = hilbert(d::T, ndims, nbits = 32) where T <: Integer`

Convert the ndims-dimensional coordinates `p` into the linear index `d` :

`d = hilbert(p::Vector{T}, ndims, nbits = 32) where T <: Integer`

All coordinates are positive integers (zero included). The number of bits `nbits` determines the precision of the curve, and the algorithm work under the constrain:

- `ndims * nbits <= 64`

## License

License from the original code:

```
/* LICENSE
 *
 * This software is copyrighted by Rice University.  It may be freely copied,
 * modified, and redistributed, provided that the copyright notice is 
 * preserved on all copies.
 * 
 * There is no warranty or other guarantee of fitness for this software,
 * it is provided solely "as is".  Bug reports or fixes may be sent
 * to the author, who may or may not act on them as he desires.
 *
 * You may include this software in a program or other software product,
 * but must display the notice:
 *
 * Hilbert Curve implementation copyright 1998, Rice University
 *
 * in any place where the end-user would see your own copyright.
 * 
 * If you modify this software, you should include a notice giving the
 * name of the person performing the modification, the date of modification,
 * and the reason for such modification.
 */* 

```
