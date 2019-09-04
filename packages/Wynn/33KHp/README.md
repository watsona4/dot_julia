# Wynn.jl
[![Travis](https://travis-ci.com/J-Revell/Wynn.jl.svg?branch=master)](https://travis-ci.com/J-Revell/Wynn.jl)
[![Appveyor](https://ci.appveyor.com/api/projects/status/github/J-Revell/Wynn.jl?svg=true)](https://ci.appveyor.com/project/J-Revell/wynn-jl)

A package to facilitate the calculation of epsilon (<img src="/tex/7ccca27b5ccc533a2dd72dc6fa28ed84.svg?invert_in_darkmode&sanitize=true" align=middle width=6.672392099999992pt height=14.15524440000002pt/>) table structures, derived from Wynn's recursive epsilon algorithm.

Suppose we are presented with a series, <img src="/tex/e257acd1ccbe7fcb654708f1a866bfe9.svg?invert_in_darkmode&sanitize=true" align=middle width=11.027402099999989pt height=22.465723500000017pt/>, with partial sums <img src="/tex/d28140eda2d12e24b434e011b930fa23.svg?invert_in_darkmode&sanitize=true" align=middle width=14.730823799999989pt height=22.465723500000017pt/>,

<img src="/tex/305b00052b0f637b1f6b9cbbc20b6bd4.svg?invert_in_darkmode&sanitize=true" align=middle width=81.79511999999998pt height=56.32434059999998pt/>.


Wynn's epsilon algorithm computes the following recursive scheme:
<img src="/tex/018b65cf47992d70b1aef415dc34aa03.svg?invert_in_darkmode&sanitize=true" align=middle width=194.86075784999997pt height=44.36012790000002pt/>,

where

<img src="/tex/a6d06ffa0c20fa59096509295f59021c.svg?invert_in_darkmode&sanitize=true" align=middle width=59.06766524999999pt height=34.337843099999986pt/>, for <img src="/tex/cb64b662810fa2e879c6c890c2c20026.svg?invert_in_darkmode&sanitize=true" align=middle width=93.33412439999998pt height=21.68300969999999pt/>

<img src="/tex/aed0ba5a615bf67526eca4fc5bb41642.svg?invert_in_darkmode&sanitize=true" align=middle width=54.45768899999999pt height=34.337843099999986pt/>, for <img src="/tex/cb64b662810fa2e879c6c890c2c20026.svg?invert_in_darkmode&sanitize=true" align=middle width=93.33412439999998pt height=21.68300969999999pt/>

<img src="/tex/dfa1956691e72694d10703fb035b88f5.svg?invert_in_darkmode&sanitize=true" align=middle width=81.11019509999998pt height=34.337843099999986pt/>, for <img src="/tex/bfd898f3193f13c76d64173d28ac7a86.svg?invert_in_darkmode&sanitize=true" align=middle width=95.38131569999997pt height=21.68300969999999pt/>


The resulting table of <img src="/tex/f601aeaf6c36f343239c6ab5e365c738.svg?invert_in_darkmode&sanitize=true" align=middle width=21.59732354999999pt height=34.337843099999986pt/> values is known as the epsilon table.

<p align="center"><img src="/tex/6cf2c910e91ab031410942a0ddf527aa.svg?invert_in_darkmode&sanitize=true" align=middle width=168.6075039pt height=229.9926321pt/></p>

Epsilon table values with an even <img src="/tex/36b5afebdba34564d884d347484ac0c7.svg?invert_in_darkmode&sanitize=true" align=middle width=7.710416999999989pt height=21.68300969999999pt/>-th index, i.e. <img src="/tex/6c0fb9bd50b8ed35149982975f93c8cd.svg?invert_in_darkmode&sanitize=true" align=middle width=21.59732354999999pt height=34.337843099999986pt/>, are commonly used to compute rational sequence transformations and extrapolations, such as Shank's Transforms, and Pade Approximants.


# Example usage: computing the epsilon table for exp(x)
The first 5 terms of the Taylor series expansion for <img src="/tex/559b96359a4653a6c35dbf27c11f68d2.svg?invert_in_darkmode&sanitize=true" align=middle width=47.29464134999999pt height=24.65753399999998pt/> are <img src="/tex/92005f24ef508aa30b5e01a346f9154d.svg?invert_in_darkmode&sanitize=true" align=middle width=238.76678429999996pt height=26.76175259999998pt/>. The epsilon table can be generated in the manner below:

```julia
using SymPy
using Wynn
# or, if not registered with package repository
# using .Wynn

@syms x
# first 5 terms of the Taylor series expansion of exp(x)
s = [1, x, x^2/2, x^3/6, x^4/24]

etable = EpsilonTable(s).etable
```
Retrieving the epsilon table value corresponding to <img src="/tex/c82f30aacb45500b6ea0e16c83087184.svg?invert_in_darkmode&sanitize=true" align=middle width=21.59732354999999pt height=34.337843099999986pt/> is done by

```julia
etable[i, j]
```

## Further usage: computing the R[2/2] Pade Approximant of exp(x)
Suppose we wanted to approximate <img src="/tex/559b96359a4653a6c35dbf27c11f68d2.svg?invert_in_darkmode&sanitize=true" align=middle width=47.29464134999999pt height=24.65753399999998pt/> (around <img src="/tex/8436d02a042a1eec745015a5801fc1a0.svg?invert_in_darkmode&sanitize=true" align=middle width=39.53182859999999pt height=21.18721440000001pt/>) using a rational Pade Approximant <img src="/tex/8a9e0cd4c218dbb2d9e4be213d6f108e.svg?invert_in_darkmode&sanitize=true" align=middle width=49.62157199999999pt height=24.65753399999998pt/>. The pade approximant <img src="/tex/8a9e0cd4c218dbb2d9e4be213d6f108e.svg?invert_in_darkmode&sanitize=true" align=middle width=49.62157199999999pt height=24.65753399999998pt/> is known to correspond to the epsilon table value <img src="/tex/d7090fe83aa1e5aafcbd7cdaf76a596f.svg?invert_in_darkmode&sanitize=true" align=middle width=43.10908139999999pt height=34.337843099999986pt/>. Computing the R[2/2] Pade approximant is thus equivalent to <img src="/tex/6787b996d6585bee77089242315b429a.svg?invert_in_darkmode&sanitize=true" align=middle width=58.02507149999999pt height=34.337843099999986pt/>,
```julia
R = etable[0,4]
```
which yields

<img src="/tex/ed18bf83d30c6c5a437c246a3a87a143.svg?invert_in_darkmode&sanitize=true" align=middle width=183.47364255pt height=49.00309590000003pt/>

Comparing accuracy, for <img src="/tex/8614628c35cbd72f9732b246c2e4d7b8.svg?invert_in_darkmode&sanitize=true" align=middle width=39.53182859999999pt height=21.18721440000001pt/>:

<img src="/tex/abe7189da355fdabefc6dab63712e46e.svg?invert_in_darkmode&sanitize=true" align=middle width=204.31554165pt height=24.65753399999998pt/> (Native Julia function)

<img src="/tex/c71bb1b2d0f1cd5b50c54ae84b62ea49.svg?invert_in_darkmode&sanitize=true" align=middle width=198.24244109999998pt height=24.65753399999998pt/> (First 5 terms of Taylor series)

<img src="/tex/39c64d4a29b5ffc3f4c682b360fb9bc6.svg?invert_in_darkmode&sanitize=true" align=middle width=199.82352719999997pt height=24.65753399999998pt/> (Pade R[2/2] approximation)

It can be seen that as x moves away from 0, the Pade approximant is more accurate than the corresponding Taylor series.
