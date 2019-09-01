# Fluid-Structure Interaction

```@meta
DocTestSetup = quote
using Whirl
using Dyn3d
using Plots
end
```

```math
\def\ddt#1{\frac{\mathrm{d}#1}{\mathrm{d}t}}
```

```@setup fsi
a = 1
```

`Dyn3d` can be used to solve rigid body dynamics, to simulate fluid-structure
interaction, we use [Whirl.jl](https://github.com/ruizhi92/Whirl.jl.git) branch
`stronglycoupled2d` to solve for fluid dynamics. To make fluid and body dynamics
coupling with each other, we also need to construct a series of functions to act
as interface between them, and choose appropriate coupling schemes.

Strongly coupled method is finished, and fully coupled method is under construction.
Example of working fluid-structure interaction notebook is also provided under
/notebook.

## Strongly coupled method
Coupling scheme is refered to [Wang and Eldredge JCP](https://www.sciencedirect.com/science/article/pii/S0021999115002454), detailes
are skipped here. The main idea is to use fluid forces on body as the iterating
variable, run the body solver `Dyn3d` with proposed fluid force as external force
for the body-joint system, get updated body coordinates and velocities. Then use
these information as boundary condition for fluid solver `Whirl`, get updated
fluid force on body from Lagrange multipliers. If the proposed force and updated
force are close enough, this timestep is said to be converged. Otherwise we use
a relaxation scheme to calculate a new proposed force, iterates until it converge.

There are several things that needs to be carefully dealt with, because we are
using two packages together and variables need to be consistent from one to another.

### Scaling
For example gravity in body solver should be non-dimensionalized to $[0.0, -1.0, 0.0]$
instead of $[0.0, -9.8, 0.0]$. Scaling is done through:

mass ratio $m^* = \frac{\rho_{b}/L}{\rho_{f}} = \frac{\rho_{b}}{\rho_{f} L}$

Reynolds number $Re = \frac{\rho_{f} U_\infty L}{\mu}$

torsion stiffness $k^* = \frac{k}{\rho_{f} {U_\infty}^2 {L}^2}$

bending stiffness $c^* = \frac{c}{\rho_{f} U_\infty {L}^3}$

gravity $g^* = \frac{g L}{{U_\infty}^2}$ if uniform flow is non-zero



## Fully coupled method
Under construction

## Methods
```@autodocs
Modules = [FluidInteraction]
Order   = [:type, :function]
```

## Index

```@index
Pages = ["fluid_interaction.md"]
```
