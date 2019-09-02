# Thanks to Seth Bromberger for writing almost all of this code, and giving permission to use it
REGDIR = joinpath(DEPOT_PATH[1], "registries", "General")

version_in_range(v, s) = v in Pkg.Types.VersionSpec(s)
get_pkg_dir(s) = "$REGDIR/$(uppercase(s[1]))/$s"


# "Internal" utils and build the graph. 

"""
Get all the dependencies of a package by
reading Deps.toml.
"""
function get_dep_dict(s)
    deps = Dict{String, Vector{String}}()

    d = get_pkg_dir(s)
    vrange = ""
    !isfile("$d/Deps.toml") && return deps
    for l in readlines("$d/Deps.toml")
        if startswith(l, "[")
            vrange = strip(l, ['[',']','\"'])
            # println("l = $l, vrange = $vrange")
            deps[vrange] = Vector{String}()
        else
            pkg = split(l, " ")[1]
            if pkg != ""
                push!(deps[vrange], pkg)
            end
        end
    end
    return deps
end

"""
Get the latest version of a package by
reading Versions.toml.
"""
function get_latest_version(s)
    d = get_pkg_dir(s)
    maxver = v"0.0.0"
    !isfile("$d/Versions.toml") && return maxver
    for l in readlines("$d/Versions.toml")
        if startswith(l, "[")
            v = VersionNumber(strip(l, ['[',']','\"']))
            if v > maxver
                maxver = v
            end
        end
    end
    return maxver
end

"""
Given a package name, return a vector
of all _direct_ depedencies.
"""
function get_deps(s)
    depdict = get_dep_dict(s)
    depset = Set{String}()
    maxver = get_latest_version(s)
    for (vrange, deps) in depdict
        # println("vrange = $vrange, deps = $deps")
        if version_in_range(maxver, vrange)
            union!(depset, deps)
        end
    end
    return collect(depset)
end

function make_pkg_list(r, omit_packages)
    f = "$r/Registry.toml"
    t = Pkg.TOML.parsefile(f)["packages"]

    omitset = Set(omit_packages)
    pkglist = Set(v["name"] for (_, v) in t)
    for p in pkglist
        # println("making $p")
        depset = Set(get_deps(p))
        union!(pkglist, depset)
    end
    setdiff!(pkglist, omitset)
    return sort(collect(pkglist))
end

function build_graph(r=REGDIR; omit_packages=[])
    pkglist = make_pkg_list(r, omit_packages)
    pkgrev = Dict((k, v) for (v, k) in enumerate(pkglist))

    g = MetaDiGraph(length(pkglist))
    for p in pkglist
        v = pkgrev[p]
        set_prop!(g, v, :name, p)
        deps = get_deps(p)
        setdiff!(deps, omit_packages)
        for d in deps
            w = pkgrev[d]
            add_edge!(g, v, w)
        end
    end
    set_indexing_prop!(g, :name)
    return (g, reverse(g), pkglist, pkgrev)
end
g, rev_g, pkglist, pkgrev = build_graph()

#===
"Customer-facing" functions. 
===#

"""
See all n-th order dependents of a package. 
"""
function get_dependents(s, n = 1)
    s_index = pkgrev[s]
    new_g = egonet(rev_g, s_index, n)
    dependents = [props(new_g, dependent)[:name] for dependent in unique(vertices(new_g)[2:end])]
end

"""
See all n-th order dependencies of a package.
"""
function get_dependencies(s, n = 1)
    s_index = pkgrev[s]
    new_g = egonet(g, s_index, n)
    dependents = [props(new_g, dependent)[:name] for dependent in unique(vertices(new_g)[2:end])]
end

