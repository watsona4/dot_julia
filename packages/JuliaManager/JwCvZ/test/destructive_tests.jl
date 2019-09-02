"""
Tests that _may_ destroy your Julia setup!
"""
module DestructiveTests

using JuliaManager
using Test

macro test_nothrow(ex)
    esc(:($Test.@test $ex isa $Any))
end

if Sys.iswindows()
    pathsep = ";"
else
    pathsep = ":"
end

if Sys.which("jlm") === nothing
    destdir = joinpath(homedir(), ".julia", "bin")

    ENV["PATH"] = destdir * pathsep * ENV["PATH"]

    @test JuliaManager.install_cli(destdir) === nothing
    @assert Sys.which("jlm") !== nothing  # abort test
end

@show Sys.which("jlm")
@test Sys.which("jlm") !== nothing

@info "jlm --help"
@test_nothrow run(`jlm --help`)

@info "jlm create-default-sysimage"
@time @test_nothrow run(`jlm create-default-sysimage`)

if Sys.which("tox") === nothing
    run(`python3 -m pip install --user tox`)
end

jlmdir = joinpath(@__DIR__, "..", "jlm")
@info "cd $jlmdir && tox"
cd(jlmdir) do
    @time @test_nothrow run(`tox`)
end

end  # module
