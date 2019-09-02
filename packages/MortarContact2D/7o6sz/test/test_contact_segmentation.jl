# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/MortarContact2D.jl/blob/master/LICENSE

using FEMBase, MortarContact2D, Test
using MortarContact2D: create_contact_segmentation, calculate_normals

X = Dict(1 => [0.0, 0.0],
         2 => [1.0, 0.0],
         3 => [0.0, 1.0],
         4 => [1.0, 1.0])

slave = Element(Seg2, [1, 2])
master = Element(Seg2, [3, 4])
elements = [slave, master]
update!(elements, "geometry", X)
update!(slave, "displacement", 0.0 => ([0.0,0.0], [0.0,0.0]))
update!(master, "displacement", 0.0 => ([0.0,0.0], [0.0,0.0]))
update!(slave, "displacement", 1.0 => ([0.0,0.0], [0.0,0.0]))
update!(master, "displacement", 1.0 => ([2.0,0.0], [2.0,0.0]))
problem = Problem(Contact2D, "test problem", 2, "displacement")
add_slave_elements!(problem, [slave])
add_master_elements!(problem, [master])
normals = calculate_normals([slave], 0.0)
update!([slave], "normal", 0.0 => normals)
seg1 = create_contact_segmentation(problem, slave, [master], 0.0; deformed=true)
seg2 = create_contact_segmentation(problem, slave, [master], 1.0; deformed=true)
problem.properties.max_distance = 0.0
seg3 = create_contact_segmentation(problem, slave, [master], 0.0; deformed=false)
@test length(seg1) == 1
@test length(seg2) == 0
@test length(seg3) == 0

slave = Element(Seg2, [1, 2])
master = Element(Seg2, [3, 4])
elements = [slave, master]
update!(elements, "geometry", X)
problem = Problem(Contact2D, "test problem", 2, "displacement")
problem.assembly.la = zeros(8)
problem.properties.store_fields = [
    "contact area",
    "contact error",
    "weighted gap",
    "contact pressure",
    "complementarity condition",
    "active nodes",
    "inactive nodes",
    "stick nodes",
    "slip nodes"]
add_slave_elements!(problem, [slave])
add_master_elements!(problem, [master])
assemble!(problem, 0.0)

X[3] += [2.0, 0.0]
X[4] += [2.0, 0.0]
slave = Element(Seg2, [1, 2])
master = Element(Seg2, [3, 4])
elements = [slave, master]
update!(elements, "geometry", X)
problem = Problem(Contact2D, "test problem", 2, "displacement")
add_slave_elements!(problem, [slave])
add_master_elements!(problem, [master])
assemble!(problem, 0.0)

X = Dict(1 => [0.0, 0.0],
         2 => [1.0, 0.0],
         3 => [0.0, 0.0],
         4 => [1.0, 0.0])

slave = Element(Seg2, [1, 2])
master = Element(Seg2, [3, 4])
elements = [slave, master]
update!(elements, "geometry", X)
problem = Problem(Contact2D, "test problem", 2, "displacement")
add_slave_elements!(problem, [slave])
add_master_elements!(problem, [master])
assemble!(problem, 0.0)
empty!(problem.assembly)
problem.properties.iteration = 0
problem.properties.contact_state_in_first_iteration = :INACTIVE
assemble!(problem, 0.0)
