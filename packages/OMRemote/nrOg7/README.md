# OMRemote.jl

![OMRemote logo](/resources/logo/RemoteOM.png)

Julia package to remote control [OpenModelica](https://www.openmodelica.org/)
simulations based the Julia package [OMJulia](https://github.com/OpenModelica/OMJulia.jl).

This Julia package is under development. All releases up to 3.0.0 will be non-backwards compatible.

# Features

- Run simulations systematically in a work directory environment
- Create and store OpenModelica result files in MAT format
- [Evaluate results](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html?highlight=readsimulationresult) accessing the OpenModelica API through [OMJulia](https://github.com/OpenModelica/OMJulia.jl)
- Alternatively the results files can be accessed through the Python package [DyMat](https://pypi.org/project/DyMat/) which is available through [PyDyMat](https://gitlab.com/christiankral/PyDyMat.jl); **note** that [DyMat](https://pypi.org/project/DyMat/) must be installed through Pythong[3] in this case
