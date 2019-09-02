# ODEInterfaceDiffEq

[![Join the chat at https://gitter.im/JuliaDiffEq/Lobby](https://badges.gitter.im/JuliaDiffEq/Lobby.svg)](https://gitter.im/JuliaDiffEq/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Build Status](https://travis-ci.org/JuliaDiffEq/ODEInterfaceDiffEq.jl.svg?branch=master)](https://travis-ci.org/JuliaDiffEq/ODEInterfaceDiffEq.jl)
[![Coverage Status](https://coveralls.io/repos/JuliaDiffEq/ODEInterfaceDiffEq.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaDiffEq/ODEInterfaceDiffEq.jl?branch=master)
[![codecov.io](http://codecov.io/github/JuliaDiffEq/ODEInterfaceDiffEq.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaDiffEq/ODEInterfaceDiffEq.jl?branch=master)

This package contains bindings for ODEInterface.jl to allow it to be used with the
JuliaDiffEq common interface. For more information on using the solvers from this
package, see the [DifferentialEquations.jl documentation](https://juliadiffeq.github.io/DiffEqDocs.jl/latest/).

## Installation

A standard installation on MacOSX and Linux should work. On Windows, you need to install mingw32 compilers and add them to the path. [MingW32 can be found here](http://www.mingw.org/). Then add the path to your environment variables. An example path is:

```
C:\Program Files\mingw-w64\x86_64-6.1.0-posix-seh-rt_v5-rev0\mingw64\bin
```

Note that it is required that you add ODEInterface.jl as well;

```julia
]add ODEInterface
```

Otherwise you may have issues instantiating the solvers.

## Common API Usage

This library adds the common interface to ODEInterface.jl's solvers. [See the DifferentialEquations.jl documentation for details on the interface](http://docs.juliadiffeq.org/latest/index.html). Following the Lorenz example from [the ODE tutorial](http://docs.juliadiffeq.org/latest/tutorials/ode_example.html), we can solve this using `dopri5` via the following:

```julia
using ODEInterfaceDiffEq
function lorenz(du,u,p,t)
 du[1] = 10.0(u[2]-u[1])
 du[2] = u[1]*(28.0-u[3]) - u[2]
 du[3] = u[1]*u[2] - (8/3)*u[3]
end
u0 = [1.0;0.0;0.0]
tspan = (0.0,100.0)
prob = ODEProblem(lorenz,u0,tspan)
sol = solve(prob,dopri5(),abstol=1e-4)
using Plots; plot(sol,vars=(1,2,3))
```

The options available in `solve` are documented [at the common solver options page](http://docs.juliadiffeq.org/latest/basics/common_solver_opts.html). The available methods are documented [at the ODE solvers page](http://docs.juliadiffeq.org/latest/solvers/ode_solve.html#ODEInterface.jl-1).
