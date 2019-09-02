module TestIndirectImports

using Base: PkgId
using InteractiveUtils: code_llvm
using MacroTools
using Pkg
using Test
using UUIDs

using IndirectImports
using IndirectImports: IndirectFunction, IndirectPackage, isloaded, _uuidfor

macro test_thrown(ex)
    quote
        let err = nothing
            try
                $(esc(ex))
            catch err
            end
            @test err isa Exception
            err
        end
    end
end

@testset "Macros" begin
    @test isexpr((@eval @macroexpand @indirect import A), :const)
    @test isexpr(unblock((@eval @macroexpand @indirect import A: x)), :let)
    @test isexpr(unblock((@eval @macroexpand @indirect import A: x, y)), :let)

    let err = @test_thrown _uuidfor(Main, :dummy)
        @test occursin(
            "does not have associated source code file",
            sprint(showerror, err))
    end
end

function devtest(uuid, name)
    if Base.locate_package(PkgId(UUID(uuid), name)) === nothing
        Pkg.develop(PackageSpec(
            name = name,
            path = joinpath(@__DIR__, name),
        ))
    end
end

devtest("20db8cd4-68a4-11e9-2de0-29cd367489cf", "_TestIndirectImportsUpstream")
devtest("63e77324-6b0a-11e9-11e4-8be33209e5fa", "_TestIndirectImportsDownstream")
devtest("32ce5e6c-7227-11e9-3206-ad1ab32cb15a", "_TestIndirectImportsDownstream2")
using _TestIndirectImportsUpstream
using _TestIndirectImportsDownstream
using _TestIndirectImportsDownstream2

const Upstream = _TestIndirectImportsUpstream
const Downstream = _TestIndirectImportsDownstream
const Downstream_Upstream =
    _TestIndirectImportsDownstream._TestIndirectImportsUpstream

@testset "Core" begin
    @test Upstream.fun(1) == 2
    @test Upstream.fun === Downstream_Upstream.fun
    @test Val(Upstream.fun) isa Val{Upstream.fun}

    @testset for name in [:f1, :f2, :f3, :f4, :f5, :f6]
        @test getproperty(Downstream, name) === getproperty(Downstream_Upstream, name)
    end

    # A method defined in Upstream:
    @test Upstream.fun(1im) == 1 + 2im

    @test Downstream.dispatch(Downstream_Upstream.fun) === :fun
    @test Downstream.dispatch(Downstream_Upstream.fun2) === :fun2

    @test_throws(
        ErrorException("Only the top-level module can be indirectly imported."),
        IndirectPackage(Module()),
    )

    let err = @test_thrown @eval @indirect sin() = nothing
        @test occursin(
            "Function name `sin` does not refer to an indirect function.",
            sprint(showerror, err))
    end

    let err = @test_thrown @eval @indirect non_existing_function_name() = nothing
    end

    let err = @test_thrown @eval @indirect struct Spam end
        @test occursin("Cannot handle:", sprint(showerror, err))
    end

    let err = @test_thrown @eval @indirect import A=x, y
        @test occursin("Cannot handle:", sprint(showerror, err))
    end
end

@testset "Accessors" begin
    pkg = _TestIndirectImportsDownstream._TestIndirectImportsUpstream
    @test IndirectPackage(pkg.fun) === pkg
    @test nameof(pkg) === :_TestIndirectImportsUpstream
    @test nameof(pkg.fun) === :fun
    @test PkgId(Test) === PkgId(IndirectPackage(Test))
end

struct Voldemort end
Base.nameof(::Voldemort) = error("must not be named")
IndirectImports.IndirectPackage(pkg::Voldemort) = pkg

@testset "Printing" begin
    upstreamname = "_TestIndirectImportsUpstream"
    @test repr(Upstream.fun) == "$upstreamname.fun"
    @test repr(IndirectPackage(Test).fun) == "Test.fun"

    @testset "2-arg `show` MUST NOT fail" begin
        f = IndirectFunction(Voldemort(), :fun)
        @debug "repr(f) = $(repr(f))"
        @test match(r".*\bIndirectFunction\{.*Voldemort\(\), *:fun\}",
                    repr(f)) !== nothing
    end

    # A fake package that is not loaded:
    pkg = IndirectPackage(UUID("7f75c6e9-3b46-4b36-93ee-72f09c6fb1e2"),
                          :NotLoaded)
    @test !isloaded(pkg)
    @test sprint(show, pkg.fun; context=:color=>true) ==
        "\e[31mNotLoaded\e[39m.fun"  # `NotLoaded` in red

    # But `Test` is a genuine so it's loaded:
    @test isloaded(IndirectPackage(Test))
    @test sprint(show, IndirectPackage(Test).fun; context=:color=>true) ==
        "\e[32mTest\e[39m.fun"  # `Test` in green
end

onetoten(config) = Upstream.reduceop(config, 0, 1:10)

@testset "Code gen" begin
    @test onetoten(Downstream.Config1()) == 55
    @test onetoten(Downstream.Config2()) == -55
    llvm = sprint(code_llvm, onetoten, Tuple{Downstream.Config1})
    @test occursin(r"i(32|64) 55", llvm)
end

end  # module
