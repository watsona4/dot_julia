using ExtensibleUnions
using Test

# Most of the code in this file is taken from:
# 1. https://github.com/NHDaly/DeepcopyModules.jl (license: MIT)
# 2. https://github.com/perrutquist/CodeTransformation.jl (license: MIT)

@test ExtensibleUnions.getmodule(typeof(sin)) === Base
@test ExtensibleUnions.getmodule(sin) === Base

let
    # Test example from docstring to ExtensibleUnions.addmethod!
    g(x) = x + 13
    ci = code_lowered(g)[1]
    function f end
    ExtensibleUnions.addmethod!(f, (Any,), ci)
    @test f(1) === 14

    # Alternative syntax
    function f2 end
    @test ExtensibleUnions.makesig(f2, (Any,)) === Tuple{typeof(f2), Any}
    ExtensibleUnions.addmethod!(Tuple{typeof(f2), Any}, ci)
    @test f2(1) === 14

end

let
    # Test example from docstring to codetransform!
    g(x) = x + 13
    function e end
    ExtensibleUnions.codetransform!(g => e) do ci
        for ex in ci.code
            if ex isa Expr
                map!(x -> x === 13 ? 7 : x, ex.args, ex.args)
            end
        end
        ci
    end
    @test e(1) === 8
    @test g(1) === 14
end

let
    a = Vector{T} where T
    b = ExtensibleUnions.typevars(a)
    @test b isa Tuple
    @test length(b) == 1
    @test b[1] isa TypeVar
    @test b[1].name == :T
    @test b[1].lb === Union{}
    @test b[1].ub === Any
end
