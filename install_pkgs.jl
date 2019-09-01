start_pkg = "GeoStatsImages"

skip = []

rm("registries", recursive=true, force=true)

using Pkg

Pkg.add("ProgressMeter")
Pkg.add(PackageSpec(url="https://github.com/wildart/TOML.jl.git"))

home = pwd()

using ProgressMeter
using TOML

general = TOML.parsefile("$home/registries/General/Registry.toml")

packages = []
for pkg in general["packages"]
    push!(packages, pkg[2]["name"])
end

@showprogress for pkg_name in sort(packages)
    if pkg_name > start_pkg && pkg_name ∉ skip
        println("\nInstalling $pkg_name")
        try
            Pkg.add(pkg_name)
            Pkg.build(pkg_name)
        catch exc
            println(exc)
            if isa(exc, Pkg.Types.ResolverError)
                continue
            else
                rethrow
            end
        end
        run(`git add *`)
        run(`git commit -m "added package $pkg_name"`)
        run(`bash -c 'while :; do git push; if [[ $? == 0 ]]; then break; fi; done'`)
    end
end
