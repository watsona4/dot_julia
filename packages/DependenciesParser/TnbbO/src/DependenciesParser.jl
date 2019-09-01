"""
    DependenciesParser.jl

    This package provides a quick way to access dependency information
"""
module DependenciesParser
    using Base.Iterators: flatten
    using Pkg: METADATA_compatible_uuid
    using Pkg.Operations: load_package_data_raw, deps_graph, simplify_graph!, resolve
    using Pkg.TOML: parsefile
    using Pkg.Types: Context, Fixed, Requires, UUID, uuid_julia, VersionRange, VersionSpec

    """
        All package names in the General registry
    """
    const data =
        readdir.(joinpath.(homedir(), ".julia/registries/General", string.('A':'Z'))) |>
        flatten |>
        collect |>
        (x -> filter!(x -> ~any(x ∈ ["julia", ".DS_Store"]), x))
    function find_repo(name)
        dir = joinpath(homedir(), ".julia/registries/General", uppercase(name[1:1]), name)
        toml = parsefile(joinpath(dir, "Package.toml"))
        repo = replace(toml["repo"], r"\.git$" => "")
        try
            request("GET", repo)
            true
        catch
            false
        end
    end
    # Identify deleted repositories
    # using HTTP: request
    # available = Vector{Bool}(undef, length(data))
    # @time for idx ∈ eachindex(available)
    #     println(idx)
    #     available[idx] = find_repo(data[idx])
    # end
    # Based on a cache solution from above on 2019-01-25
    """
        Packages that no longer exist (repositories have been deleted)
    """
    const deleted_repo =
        ["Arduino", "ChainRecursive", "Chunks", "CombinatorialBandits", "ControlCore",
         "DotOverloading", "DynamicalBilliardsPlotting", "GLUT", "GetC", "HTSLIB",
         "KeyedTables", "LazyCall", "LazyContext", "LazyQuery", "LibGit2", "NumberedLines",
         "OpenGL", "OrthogonalPolynomials", "Parts", "React", "RecurUnroll",
         "RequirementVersions", "SDL", "SessionHacker", "Sparrow", "StringArrays",
         "TypedBools", "ValuedTuples", "ZippedArrays"]
    filter!(pkg -> pkg ∉ deleted_repo, data)
    const deps = Dict{UUID,Dict{VersionRange,Dict{String,UUID}}}()
    const compat = Dict{UUID,Dict{VersionRange,Dict{String,VersionSpec}}}()
    const uuid_to_name =
        Dict(UUID("ade2ca70-3891-5945-98fb-dc099432e06a")=>"Dates",
             UUID("7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee")=>"FileWatching",
             UUID("ea8e919c-243c-51af-8825-aaa63cd721ce")=>"SHA",
             UUID("6462fe0b-24de-5631-8697-dd941f90decc")=>"Sockets",
             UUID("8bb1440f-4735-579b-a4ab-409b98df4dab")=>"DelimitedFiles",
             UUID("9a3f8284-a2c9-5f02-9a11-845980a1fd5c")=>"Random",
             UUID("8ba89e20-285c-5b6f-9357-94700520ee1b")=>"Distributed",
             UUID("37e2e46d-f89d-539d-b4ee-838fcccc9c8e")=>"LinearAlgebra",
             UUID("a63ad114-7e13-5084-954f-fe012c677804")=>"Mmap",
             UUID("2f01184e-e22b-5df5-ae63-d93ebab69eaf")=>"SparseArrays",
             UUID("cf7118a7-6976-5b1a-9a39-7adc72f591a4")=>"UUIDs",
             UUID("56ddb016-857b-54e1-b83d-db4d58db5568")=>"Logging",
             UUID("10745b16-79ce-11e8-11f9-7d13ad32a3b2")=>"Statistics",
             UUID("8bf52ea8-c179-5cab-976a-9e18b702a9bc")=>"CRC32c",
             UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f")=>"Pkg",
             UUID("9e88b42a-f829-5b0c-bbe9-9e923198166b")=>"Serialization",
             UUID("d6f4376e-aef5-505a-96c1-9c027394607a")=>"Markdown",
             UUID("4607b0f0-06f3-5cda-b6b1-a6196a1729e9")=>"SuiteSparse",
             UUID("3fa0cd96-eef1-5676-8a61-b3b8758bbffb")=>"REPL",
             UUID("8f399da3-3557-5675-b5ff-fb832c97cbdb")=>"Libdl",
             UUID("2a0f44e3-6c83-55bd-87e4-b1978d98bd5f")=>"Base64",
             UUID("9abbd945-dff8-562f-b5e8-e1ebf5ef1b79")=>"Profile",
             UUID("b77e0a4c-d291-57a0-90e8-8db25a27a240")=>"InteractiveUtils",
             UUID("1a1011a3-84de-559e-8e89-a11a2f7dc383")=>"SharedArrays",
             UUID("de0858da-6303-5e67-8744-51eddeeeb8d7")=>"Printf",
             UUID("9fa8497b-333b-5362-9e8d-4d0656e87820")=>"Future",
             UUID("76f85450-5226-5b5a-8eaa-529ad045b433")=>"LibGit2",
             UUID("8dfed614-e22c-5e08-85e1-65c5234f0b40")=>"Test",
             UUID("4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5")=>"Unicode",
             uuid_julia=>"julia")
    const versions = Dict{UUID,Set{VersionNumber}}()
    for name ∈ data
        dir = joinpath(homedir(), ".julia/registries/General", uppercase(name[1:1]), name)
        uuid = UUID(parsefile(joinpath(dir, "Package.toml"))["uuid"])
        uuid_to_name[uuid] = name
        versions[uuid] = Set(VersionNumber.(keys(parsefile(joinpath(dir, "Versions.toml")))))
        deps[uuid] = load_package_data_raw(UUID, joinpath(dir, "Deps.toml"))
        compat[uuid] = load_package_data_raw(VersionSpec, joinpath(dir, "Compat.toml"))
    end
    """
        installable(pkg::AbstractString,
                    julia::VersionNumber = VERSION;
                    direct::Bool = false)::Tuple{Bool,Vector{String}}

        Return whether the package is installable and the dependencies for the solved version.
        If direct, only direct dependencies are returned.
    """
    function installable(pkg::AbstractString,
                         julia = VERSION::VersionNumber;
                         direct::Bool = false)
        uuid = METADATA_compatible_uuid(pkg)
        try
            graph = deps_graph(Context(),
                               uuid_to_name,
                               Requires(uuid => VersionSpec()),
                               Dict(uuid_julia => Fixed(julia)))
            simplify_graph!(graph)
            sol = get.(Ref(uuid_to_name),
                       filter(!isequal(uuid), keys(resolve(graph))),
                       nothing) |>
                  sort!
            if direct
                secondary = reduce((x,y) -> vcat(last(x), last(y)),
                                   installable.(sol)) |>
                            unique!
                sort!(filter!(dep -> dep ∉ secondary, sol))
            end
            return true, sol::Vector{String}
        catch
            return false, Vector{String}([pkg])
        end
    end
    # Code to get all installable packages
    # status = Vector{Tuple{Bool,Vector{String}}}()
    # @time for (idx, pkg) ∈ enumerate(data)
        # println(idx)
        # push!(status, installable(pkg))
    # end
    # data[first.(status)]
    # __init__() = append!(data, alldeps())
    export installable
end
