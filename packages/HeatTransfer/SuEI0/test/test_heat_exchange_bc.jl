# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/HeatTransfer.jl/blob/master/LICENSE

## Use of heat exchange boundary condition
#
# Boundary conditions needs fields `heat transfer coefficient` and
# `external temperature` defined. Boundary condition is of type
# ```math
# f = h\left(T-T_{\mathrm{u}}\right)
# ```

using FEMBase, Test, HeatTransfer, SparseArrays

# Set up initial data

X = Dict(
    1 => [0.0,0.0],
    2 => [1.0,0.0])

T = Dict(
    1 => 0.0,
    2 => 0.0)

# Create element and update fields

element = Element(Seg2, [1, 2])
update!(element, "geometry", X)
update!(element, "temperature", 0.0 => T)
update!(element, "heat transfer coefficient", 6.0)
update!(element, "external temperature", 1.0)

# Create problem, add elements to problem and assemble at time ``t=0``:

problem = Problem(PlaneHeat, "test problem", 1)
add_elements!(problem, [element])
assemble!(problem, 0.0)

# Test for stiffness matrix ``\boldsymbol{K}`` and force vector ``\boldsymbol{f}``:

K = Matrix(sparse(problem.assembly.K))
f = Vector(sparse(problem.assembly.f)[:])
@test isapprox(K, [2.0 1.0; 1.0 2.0])
@test isapprox(f, [3.0; 3.0])
