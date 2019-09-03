import Pkg

function maketempdir()::String
    tmpdir = mktempdir()
    atexit(() -> rm(tmpdir; force = true, recursive = true))
    return tmpdir
end

function allowed_intersection_predictmd_predictmdextra()::Vector{String}
    result::Vector{String} = String[
        "Distributed",
        "Pkg"
        ]
    return result
end

function main()::Nothing
    predictmdextra_dir = pwd()
    predictmdextra_toml_file_name = joinpath(predictmdextra_dir, "Project.toml")
    predictmdextra_toml = Pkg.TOML.parsefile(predictmdextra_toml_file_name)

    predictmd_toml_file_url = "https://raw.githubusercontent.com/bcbi/PredictMD.jl/master/Project.toml"
    tmpdir1 = maketempdir()
    predictmd_toml_file_name = joinpath(tmpdir1, "Project.toml")
    Base.download(predictmd_toml_file_url, predictmd_toml_file_name)
    predictmd_toml = Pkg.TOML.parsefile(predictmd_toml_file_name)
    rm(tmpdir1; force = true, recursive = true)

    predictmd_deps = sort(unique(keys(predictmd_toml["deps"])))
    predictmdextra_deps = sort(unique(keys(predictmdextra_toml["deps"])))

    intersection_predictmd_predictmdextra = intersect(predictmd_deps, predictmdextra_deps)
    @info("Actual intersection of PredictMD and PredictMDExtra", intersection_predictmd_predictmdextra, repr(intersection_predictmd_predictmdextra))
    @info("Allowed intersection of PredictMD and PredictMDExtra", allowed_intersection_predictmd_predictmdextra(), repr(allowed_intersection_predictmd_predictmdextra()))
    if !issubset(intersection_predictmd_predictmdextra, allowed_intersection_predictmd_predictmdextra())
        error("Intersection of PredictMD and PredictMDExtra contains non-allowed packages")
    end
end

main()
