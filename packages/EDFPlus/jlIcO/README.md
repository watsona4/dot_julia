# EDFPlus.jl

[![Build status](https://ci.appveyor.com/api/projects/status/cfw6pe03rfn9qsoo?svg=true)](https://ci.appveyor.com/project/wherrera10/edfplus.jl)
[![Build Status](https://travis-ci.org/wherrera10/EDFPlus.jl.svg?branch=master)](https://travis-ci.org/wherrera10/EDFPlus.jl)
[![Coverage Status](https://coveralls.io/repos/github/wherrera10/EDFPlus.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/wherrera10/EDFPlus.jl?branch=master&service=github)

Julia for handling BDF+ and EDF+ EEG and similar signal data files.

Heavily influenced by the C EEG library edflib.

License: 2-clause BSD.

Installation:

To install from a Julia REPL command line session:

    using Pkg
     Pkg.add(PackageSpec(url="http://github.com/wherrera10/EDFPlus.jl"))

Note that the test files include a 23 mb test file. You may need to allow extra time for that to download when installing.
