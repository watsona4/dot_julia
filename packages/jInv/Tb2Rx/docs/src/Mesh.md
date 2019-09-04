# jInv.Mesh

Discretization of differential operators is an essential ingredient of PDE parameter estimation problems.
Depending on the problem and computational resources, different mesh types are needed in practical applications.
The `Mesh` submodule of `jInv` provides different mesh geometry under the abstract type `AbstractMesh`.
Currently, the `Mesh` submodule methods and provides operators on regular and tensor meshes but is easily extensible.

## Regular Meshes


## List of types and methods
```@autodocs
Modules = [jInv.Mesh]
Order   = [:type,:function]
```
