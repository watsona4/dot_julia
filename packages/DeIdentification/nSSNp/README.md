# DeIdentification.jl

[![DOI](https://zenodo.org/badge/145617556.svg)](https://zenodo.org/badge/latestdoi/145617556)

[![Docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://bcbi.github.io/DeIdentification.jl/latest)

[![Bors enabled](https://bors.tech/images/badge_small.svg)](https://app.bors.tech/repositories/12280)
[![Build Status](https://travis-ci.org/bcbi/DeIdentification.jl.svg?branch=master)](https://travis-ci.org/bcbi/DeIdentification.jl)
[![codecov.io](https://codecov.io/github/bcbi/DeIdentification.jl/coverage.svg?branch=master)](https://codecov.io/github/bcbi/DeIdentification.jl?branch=master)


A Julia package for de-identifying CSV data sets.

# 1. Installation
```julia
Pkg.add("DeIdentification")
```

# 2. Important Notes
There are a few subtle points that must be kept in mind when using this package. See the documentation for more details.

## Identifiers
All files must contain a primary identifier for the unit of analysis. E.g. if you are de-identifying patient data, all files must contain a patient ID.

## Config
A config YAML must be created by the user.

## Directory Structure
Logging and output directories must be defined by the user and already created before running the package
