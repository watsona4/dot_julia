using Attrs
using Test

mutable struct Foo{Tag, T}
    x::T
end

@inline Foo{Tag}(x::T) where {Tag, T} = Foo{Tag, T}(x)

@defattrs Foo

@inline Attrs.getattr(x::Foo{Tag}, ::Attr{:tag}) where Tag = Tag

@literalattrs Attrs.getattr(x::Foo, ::Attr{:y}) = 2 * x.x

@literalattrs Attrs.getattr(x::Foo, ::Attr{:z}) = 2 * x.x + 1

@literalattrs Attrs.getattr(x::Foo{:even}, ::Attr{:z}) =
    2 * x.x + 2

@literalattrs Attrs.setattr!(x::Foo, ::Attr{:z}, y) = x.x = div(y - 1, 2)

@literalattrs Attrs.setattr!(x::Foo{:even}, ::Attr{:z}, y) =
    x.x = div(y, 2) - 1

h(x) = x.x
@literalattrs h1(x) = x.x

g(x) = x.y
@literalattrs g1(x) = x.y

k(x) = x.z
@literalattrs k1(x) = x.z

@testset "Attrs" begin

    x = Foo{:foo}(42)

    @test h(x) == 42
    @test g(x) == 84
    @test k(x) == 85
    @test h1(x) == 42
    @test g1(x) == 84
    @test k1(x) == 85

    y = Foo{:even}(42)

    @test h(y) == h(x)
    @test g(y) == g(x)
    @test k(y) == 86

    @test begin
        x2 = deepcopy(x)
        x2.x = -1
        x2.x == -1
    end

    @test begin
        x2 = deepcopy(x)
        x2.z = 85
        x2.x == 42
    end

    @test begin
        y2 = deepcopy(y)
        y2.z = 86
        y2.x == 42
    end

    @test_throws MethodError x.a
    @test_throws MethodError x.a = 42
    @test_throws MethodError x.y = 1

end
