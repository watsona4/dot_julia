# PkgUtils

[![Build Status](https://travis-ci.org/arnavs/PkgUtils.jl.svg?branch=master)](https://travis-ci.org/arnavs/PkgUtils.jl)

Some small utilities to help Julia package authors. Thanks to @sbromberger and @ianshmean and @harryscholes and others for providing code, inspiration, etc. 

## Dependencies and Dependents

* `get_dependents("MyPackage", n = 1)` returns n-th order dependents of `MyPackage` (in the `General` registry.)

* `get_dependencies("SomePackage", n = 1)` returns n-th order dependencies of `SomePackage`.

