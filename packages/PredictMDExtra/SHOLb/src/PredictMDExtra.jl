module PredictMDExtra # Begin module PredictMDExtra

__precompile__(true)

include(joinpath("registry_url_list.jl"))
include(joinpath("package_directory.jl"))
include(joinpath("version.jl"))

include(joinpath("package_list.jl"))

include(joinpath("import_required_packages.jl"))

include(joinpath("import_all.jl"))

include(joinpath("welcome.jl"))
include(joinpath("init.jl"))

end # End module PredictMDExtra
