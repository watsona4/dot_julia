module Mozi

include("./FESparse.jl")
include("./assembly/Enums.jl")
include("./assembly/CoordinateSystem.jl")
include("./structure/FEStructure.jl")
include("./load/LoadCase.jl")
include("./assembly/Assembly.jl")

include("./solver/Solver.jl")
include("./result/Result.jl")

using .FEStructure
using .LoadCase
using .FEAssembly
using .Solver
using .Result

using Serialization

export save,load

function save(assembly)
    open("./test_assembly.mz","w+") do f
        serialize(f,assembly)
    end
end

function load()
    assembly=nothing
    open("./test_assembly.mz") do f
        assembly=deserialize(f)
    end
    return assembly
end

export Structure,LoadCaseSet,Assembly

export add_uniaxial_metal!

export add_general_section!,add_beam_section!

export add_node!,set_nodal_mass!,set_nodal_restraint!,set_nodal_spring!

export add_beam!,set_beam_release!,set_beam_orient!

export add_quad!,set_quad_rotation!

export add_tria!,set_tria_rotation!

export add_static_case!, add_modal_case!, add_buckling_case!, add_time_history_case!

export add_nodal_force!

export add_beam_strain!, add_beam_distributed!

export set_modal_params!, set_buckling_params!,set_time_history_params!

export assemble!,clear_result!

export solve

export result_nodal_displacement,result_nodal_reaction,result_nodal_time_history

export result_beam_force,result_beam_displacement

export result_quad_force,result_quad_displacement

export result_modal_period,result_eigen_value, result_eigen_vector

end
