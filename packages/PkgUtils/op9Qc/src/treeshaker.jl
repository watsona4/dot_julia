# See @ianshmean for name

"""
Returns a list of dependencies required by a package that aren't actually used. 
"""
function trim_dependencies(s)
    named_deps = get_dependencies(s)
    test_path = joinpath(Pkg.dir(s), "test", "runtests.jl")
    @info "Snooping $test_path"

    # snoop the tests
    SnoopCompile.@snoopc "/tmp/$s.log" begin
        using ColorTypes, Pkg
        include(joinpath(dirname(dirname(pathof(ColorTypes))), "test", "runtests.jl"))
    end

    # parse the test coverage
    snoopfile = read("/tmp/$s.log")
    used_deps = filter(dep -> occursin(dep, snoopfile), named_deps)
    return setdiff(named_deps, used_deps)
end
