# PkgLicenses

[![Build Status](https://travis-ci.org/JuliaPackaging/PkgLicenses.jl.svg?branch=master)](https://travis-ci.org/JuliaPackaging/PkgLicenses.jl)

This is a utility package that provides an API for retrieving the text of several common
software licenses. It is used by other packages that help creating new projects (and thus
want to help the user include an appropriate LICENSE file).

# Usage

### license([lic])
List all bundled licenses. If a license label specified as a parameter then a full text of the license will be printed.
