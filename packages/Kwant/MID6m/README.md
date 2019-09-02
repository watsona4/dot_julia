# Kwant.jl

Kwant.jl is an interface with the [_kwant_](https://kwant-project.org) quantum transport package, using the [PyCall](https://github.com/JuliaPy/PyCall.jl) pacakage.

The goal of this project is to faithfully emulate the native API of _kwant_.

To date, the implementation is in its very early stages, reproducing only the first few pages of the [First Steps Tutorial](https://kwant-project.org/doc/1/tutorial/first_steps). See the [tutorials folder](https://github.com/wrs28/Kwant.jl/tree/master/tutorials).

### Installation
To install from the Julia REPL, do `]add https://github.com/wrs28/Kwant.jl.git`, which will look like
````JULIA
(v1.1) pkg> add https://github.com/wrs28/Kwant.jl.git
````
or perhaps `using Pkg` and `Pkg.add("https://github.com/wrs28/Kwant.jl.git")`.

It is easiest to make a new installation of _kwant_ via the Conda.jl package (first do `]add Conda`). This can be done with
````JULIA
using Conda
Conda.add_channel("conda-forge")
Conda.add("kwant")
````
If you don't want to install a Julia-private instance of _kwant_, you can play some trickery with building PyCall to the same Python library (instructions [here](https://github.com/JuliaPy/PyCall.jl#specifying-the-python-version)), but I don't recommend it.

### Notes

To use the plotting routines that come with _kwant_, you must implicitly call `using PyPlot`. Then something like `plot(syst)` should plot the system. Dependeing on the environment and build, you may need to explicitly call `gcf()` to show the figure.

The first lines of the _kwant_ tutorial read
``` PYTHON
import kwant
syst = kwant.Builder()
a=1
lat = kwant.lattice.square(a)
t=1.0
W=10
L=30
for i in range(L):
    for j in range(W):
        # On-site Hamiltonian
        syst[lat(i, j)] = 4 * t

        # Hopping in y-direction
        if j > 0:
            syst[lat(i, j), lat(i, j - 1)] = -t

        # Hopping in x-direction
        if i > 0:
            syst[lat(i, j), lat(i - 1, j)] = -t
```

while the first lines of the Julia implementation read
``` JULIA
import Kwant
kwant = Kwant
syst = kwant.Builder()
a = 1
lat = kwant.lattice.square(a)
t = 1.0
W = 10
L = 30
for i in range(0,length=L)
    for j in range(0,length=W)
        # On-site Hamiltonian
        syst[lat(i, j)] = 4 * t

        # Hopping in y-direction
        if j > 0
            syst[lat(i,j),lat(i,j-1)] = -t
        end

        # Hopping in x-direction
        if i > 0
            syst[lat(i, j), lat(i - 1, j)] = -t
        end
    end
end
```

Note that the Python `range(W)` becomes `range(0,length=W)`. Alternate expressions for iterating can be found [here](https://docs.julialang.org/en/v1/manual/arrays/#Iteration-1).
