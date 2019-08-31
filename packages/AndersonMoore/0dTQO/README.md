# AMA - Anderson Moore Algorithm

*Release verison*:

*Build status*:

[![Build Status](https://travis-ci.org/es335mathwiz/AndersonMoore.jl.svg?branch=develop)](https://travis-ci.org/es335mathwiz/AndersonMoore.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/github/es335mathwiz/AndersonMoore.jl?branch=develop&svg=true)](https://ci.appveyor.com/project/gtunell/andersonmoore-jl/branch/develop)
[![Coverage Status](https://coveralls.io/repos/github/es335mathwiz/AMA.jl/badge.svg?branch=develop)](https://coveralls.io/github/es335mathwiz/AMA.jl?branch=develop)
[![codecov.io](https://codecov.io/github/es335mathwiz/AndersonMoore.jl/coverage.svg?branch=develop)](https://codecov.io/github/es335mathwiz/AndersonMoore.jl?branch=develop)

## Installion

To install AMA, use the package manager by typing:

```julia
Pkg.add("AndersonMoore")
```

## Usage

This algorithm solves linear rational expectations models. There is a fast and slightly faster method to execute the algorithm which is outlined below. AndersonMooreAlg calls a julia language implementation and callSparseAim executes a C/Fortran implementation. Lastly, gensysToAMA is a function for users who are accustomed to gensys style inputs and outputs but wish to use AMA. It can be shown that AMA is faster than gensys. To begin,

Load the module:

```julia
using AndersonMoore
```

Declare the linear models to solve such as:

```julia
h = [0.  0.  0.  0.  -1.1  0.  0.  0.  1.  1.  0.  0.;
     0.  -0.4  0.  0.  0.  1.  -1.  0.  0.  0.  0.  0.;
     0.  0.  0.  0.  0.  0.  1.  0.  0.  0.  0.  0.;
     0.  0.  0.  -1.  0.  0.  0.  1.  0.  0.  0.  0.]::Array{Float64,2}
```

Set number of equations:

```julia
neq = 4
```

Set number of lags and leads:

```julia
nlags = 1
nleads = 1
```

Set a tolerance to calculate numeric shift and reduced form:

```julia
condn = 0.0000000001
```

Finally, give an inclusive upper bound for modulus of roots allowed in reduced form:

```julia
upperbnd = 1 + condn
```

#### To execute the algorithm with julia: 

```julia
(b, rts, ia, nexact, nnumeric, lgroots, AMAcode) =
     AndersonMooreAlg(h, neq, nlag, nlead, condn, upperbnd)
```
*Note* - the above returns the tuple (b, rts, ia, nexact, nnumeric, lgroots, AMAcode)
<ul>
  <li>	b         -  Reduced form coefficient matrix.<br />                      </li>
  <li>	rts       -  Roots returned by eig.<br />                                </li>
  <li>	ia        -  Dimension of companion matrix.<br />                        </li>
  <li>	nexact    -  Number of exact shift rights.<br />                         </li>
  <li>	nnumeric  -  Number of numeric shift rights.<br />                       </li>
  <li>	lgroots   -  Number of roots greater in modulus than upper bound.<br />  </li>
  <li>  AMAcode   -  Return code.<br />                                          </li>
</ul>

#### To execute the algorithm with C/Fortran:

```julia
(h, b, q, AMAcode) = 
     callSparseAim(h, nleads, nlags)
```

*Note* - the above returns the tuple (h, b, q, AMAcode)<br />
<ul>
  <li>  h         -  The original h matrix after computations.<br />  </li>
  <li>	b         -  Reduced form coefficient matrix.<br />           </li>
  <li>  q         -  Asymptotic constraints.<br />                    </li>
  <li>	AMAcode   -  Return code.                                     </li>
</ul>

#### For those accustomed to gensys:

```julia
(G1, CC, impact, fmat, fwt, ywt, gev, eu) = 
     gensysToAMA(g0, g1, cc, psi, pi, div, varargin = "" ) 
```

To run AMA, subsitute the gensys style inputs into the above command but substitute "ama" for the argument varargin.
     

## More

For more information and an indepth analysis of the algorithm, please read the [full paper](https://www.federalreserve.gov/pubs/feds/2010/201013/201013pap.pdf) written by [Gary S. Anderson](https://github.com/es335mathwiz).

The authors would appreciate acknowledgement by citation of any of the following papers:

Anderson, G. and Moore, G. "A Linear Algebraic Procedure For Solving Linear Perfect Foresight Models." Economics Letters, 17, 1985.

Anderson, G. "Solving Linear Rational Expectations Models: A Horse Race." Computational Economics, 2008, vol. 31, issue 2, pp. 95-113

Anderson, G. "A Reliable and Computationally Efficient Algorithm for Imposing the Saddle Point Property in Dynamic Models." Journal of Economic Dynamics and Control, 2010, vol 34, issue 3, pp. 472-489.


Developer: [Gregory Tunell](https://github.com/gtunell) e-mail available at <gregtunell@gmail.com>.
