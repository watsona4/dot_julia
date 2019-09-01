module ExtensibleUnions

export addtounion!, # extensible_unions.jl
       extensiblefunction!, # extensible_functions.jl
       extensibleunion!, # extensible_unions.jl
       isextensiblefunction, # extensible_functions.jl
       isextensibleunion # extensible_unions.jl

const _registry_extensibleunion_to_genericfunctions = Dict{Any, Any}()
const _registry_extensibleunion_to_members = Dict{Any, Any}()
const _registry_genericfunctions_to_extensibleunions = Dict{Any, Any}()

include("code_transformation.jl")
include("extensible_functions.jl")
include("extensible_unions.jl")
include("init.jl")
include("reset.jl")
include("update_methods.jl")

end # module
