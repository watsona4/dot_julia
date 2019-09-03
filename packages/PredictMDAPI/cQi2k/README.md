# PredictMDAPI

<p>
<a
href="https://doi.org/10.5281/zenodo.1291209">
<img
src="https://zenodo.org/badge/109460252.svg"/>
</a>
</p>

<p>
<a
href="https://app.bors.tech/repositories/12422">
<img
src="https://bors.tech/images/badge_small.svg"
alt="Bors enabled">
</a>
<a
href="https://travis-ci.com/bcbi/PredictMDAPI.jl/branches">
<img
src="https://travis-ci.com/bcbi/PredictMDAPI.jl.svg?branch=master"
/></a>
<a
href="https://codecov.io/gh/bcbi/PredictMDAPI.jl/branch/master">
<img
src="https://codecov.io/gh/bcbi/PredictMDAPI.jl/branch/master/graph/badge.svg"
/></a>
</p>

The PredictMDAPI package provides the abstract types, traits, and functions that define the [PredictMD](https://predictmd.net) application programming interface (API).

This is a very lightweight package. It has no dependencies. The only lines of code are:
- Abstract types, i.e. `abstract type Foo end`
- Immutable composite types with no fields, i.e. `struct Bar <: Foo end`
- Function stubs, i.e. `function hello end`
