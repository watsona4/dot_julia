# PyCallJLD.jl

[![Build Status](https://travis-ci.org/JuliaPy/PyCallJLD.jl.svg?branch=master)](https://travis-ci.org/JuliaPy/PyCallJLD.jl)

[![Coverage Status](https://coveralls.io/repos/JuliaPy/PyCallJLD.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaPy/PyCallJLD.jl?branch=master)

[![codecov.io](http://codecov.io/github/JuliaPy/PyCallJLD.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaPy/PyCallJLD.jl?branch=master)

PyCallJLD enables saving and loading [PyCall's `PyObject`s](https://github.com/JuliaPy/PyCall.jl) using [JLD.jl](https://github.com/JuliaIO/JLD.jl/). Example:

```julia
using PyCall, JLD, PyCallJLD

@pyimport sklearn.linear_model as lm

# Create some Python objects
m1 = lm.LinearRegression()
m2 = lm.ARDRegression()

# Save them to models.jld
JLD.save("models.jld", "mods", [m1, m2])

# Load them back
models = JLD.load("models.jld", "mods")
```

The objects are serialized using [`cPickle.dumps`](https://docs.python.org/2/library/pickle.html#pickle.dumps)

See [PyCall](https://github.com/JuliaPy/PyCall.jl)'s and
[JLD](https://github.com/JuliaIO/JLD.jl/)'s documentation for details.