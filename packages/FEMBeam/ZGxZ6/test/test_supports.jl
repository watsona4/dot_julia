# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/FEMBeam.jl/blob/master/LICENSE

# Supporting beams

using FEMBeam
using FEMBase.Test

# Total length of beam
L = 10.0

# Number of elements in beam
nel = 2

# Create uniform 1d mesh for beam elements, first nodes:
X = Dict{Int64, Vector{Float64}}()
for (j, x) in enumerate(range(0.0, stop=L, length=nel+1))
    X[j] = [x, 0.0, 0.0]
end
nnodes = length(X)
@debug("Number of nodes: $nnodes")

# Create beam elements
beam_elements = [Element(Seg2, [j, j+1]) for j=1:nel]
@debug("Number of elements: ", length(beam_elements))
update!(beam_elements, "geometry", X)
update!(beam_elements, "youngs modulus", 210.0e6)
update!(beam_elements, "shear modulus", 84.0e6)
update!(beam_elements, "cross-section area", 20.0e-2)
update!(beam_elements, "torsional moment of inertia 1", 10.0e-5)
update!(beam_elements, "torsional moment of inertia 2", 20.0e-5)
update!(beam_elements, "polar moment of inertia", 30.0e-5)
update!(beam_elements, "normal", [0.0, 0.0, -1.0])

# Create boundary conditions: fix beam from left, add uniform load on top
# and point moment on right
p1 = Element(Poi1, [1])
p2 = Element(Poi1, [nnodes])
for i=1:3
    update!(p1, "fixed displacement $i", 0.0)
    update!(p1, "fixed rotation $i", 0.0)
end
update!(p2, "point force 1", 10.0e3)
update!(p2, "point moment 1", 10.0e3)

# Create a problem, containing beam elements
problem = Problem(Beam, "our test beam", 6)
add_elements!(problem, beam_elements)
add_elements!(problem, [p1, p2])

# Create a static analysis
step = Analysis(Static)
add_problems!(step, [problem])
ls, normu, normla = run!(step)
@test isapprox(normla, sqrt(2*10000.0^2))
