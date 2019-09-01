# EchoviewEcs.jl


[![Build Status](https://travis-ci.org/EchoJulia/EchoviewEcs.jl.svg?branch=master)](https://travis-ci.org/EchoJulia/EchoviewEcs.jl)

[![Coverage Status](https://coveralls.io/repos/EchoJulia/EchoviewEcs.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/EchoJulia/EchoviewEcs.jl?branch=master)

[![codecov.io](http://codecov.io/github/EchoJulia/EchoviewEcs.jl/coverage.svg?branch=master)](http://codecov.io/github/EchoJulia/EchoviewEcs.jl?branch=master)


[Julia](http://julialang.org) package for reading [Echoview calibration
supplement (.ECS) files](http://support.echoview.com/WebHelp/Files,_filesets_and_variables/About_ECS_files.htm). Scientific echosounder data requires
calibration correction, and ECS is a popular storage file format for the
correction parameters.


```
using EchoviewEcs
calibrations = load(filename)
```

`calibrations` is a `Vector` of `Dict` where `Dict` contains keys and
values being configuration parameters. SourceCal settings inherit from
FileSet settings but override such settings if specified explicitly.
