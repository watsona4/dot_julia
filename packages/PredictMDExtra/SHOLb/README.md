# PredictMDExtra

<p>
<a
href="https://doi.org/10.5281/zenodo.1291209">
<img
src="https://zenodo.org/badge/109460252.svg"/>
</a>
</p>

<p>
<a
href="https://app.bors.tech/repositories/12271">
<img
src="https://bors.tech/images/badge_small.svg"
alt="Bors enabled">
</a>
<a
href="https://travis-ci.org/bcbi/PredictMDExtra.jl/branches">
<img
src=
"https://travis-ci.org/bcbi/PredictMDExtra.jl.svg?branch=master"
/></a>
<a
href="https://codecov.io/gh/bcbi/PredictMDExtra.jl/branch/master">
<img
src=
"https://codecov.io/gh/bcbi/PredictMDExtra.jl/branch/master/graph/badge.svg"
/></a>
</p>

PredictMDExtra is a meta-package that installs all of the Julia dependencies
of [PredictMD](https://predictmd.net) (but not PredictMD itself).

Installing PredictMDExtra does not install PredictMD. If you would like a
convenient way of installing PredictMD and all of its Julia dependencies,
see [PredictMDFull](https://github.com/bcbi/PredictMDFull.jl).



| Table of Contents |
| ----------------- |
| [Installation](#installation) |

## Installation

PredictMDExtra is registered in the Julia General registry. Therefore, to
install PredictMDExtra, simply open Julia and run the following four lines:
```julia
import Pkg
Pkg.activate("PredictMDEnvironment"; shared = true)
Pkg.add("PredictMDExtra")
import PredictMDExtra
```

That being said, PredictMDExtra is not very useful by itself. Instead, I
recommend that you install PredictMDFull, which includes both PredictMD and
PredictMDExtra. To install PredictMDFull, simply open Julia and run the
following four lines:
```julia
import Pkg
Pkg.activate("PredictMDEnvironment"; shared = true)
Pkg.add("PredictMDFull")
import PredictMDFull
```
