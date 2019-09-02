using ImageCore
using IterTools

# AbstractGray and Color3 tests should be generated seperately
function generate_test_types(number_types::AbstractArray{<:DataType}, color_types::AbstractArray{<:UnionAll})
    test_types = map(Iterators.product(number_types, color_types)) do T
        try
            T[2]{T[1]}
        catch err
            !isa(err, TypeError) && rethrow(err)
        end
    end
    test_types = filter(x->x != false, test_types)
    if isempty(filter(x->x<:Color3, test_types))
        test_types = [number_types..., test_types...]
    end
    test_types
end

_base_colorant_type(::Type{<:Number}) = Gray
_base_colorant_type(::Type{T}) where T<:Colorant = base_colorant_type(T)
"""
    test_numeric(dist, a, b, T; filename=nothing)

simply test that `dist` works for 2d image as expected, more tests go to `Distances.jl`
"""
function test_numeric(dist, a, b, T; filename=nothing)
    size(a) == size(b) || error("a and b should be the same size")
    if filename == nothing
        filename = "references/$(typeof(dist))_$(ndims(a))d"

        if eltype(a) <: Color3
            filename = filename * "_$(_base_colorant_type(T))"
        elseif eltype(a) <: Union{Number, AbstractGray}
            filename = filename * "_$(_base_colorant_type(T))"
        end
    end
    # @test_reference "$(filename)_$(eltype(a))_$(eltype(b)).txt" assess(dist, a, b)
    @test_reference "$(filename).txt" Float64(assess(dist, a, b))
end

"""
    test_cross_type(dist, a, b, type_list)

simply test if operations between `N0f8`, `Bool` and `Float32` types works as expected.
`a` and `b` should be simple enough to get rid of InexactError.
"""
function test_cross_type(dist, a, b, type_list)
    size(a) == size(b) || error("a and b should be the same size")
    rsts = [[assess(dist, Ta.(a), Tb.(b)),
             assess(dist, Tb.(a), Ta.(b))] for (Ta, Tb) in subsets(type_list, 2)]
    rsts = hcat(rsts...)
    @test all(isapprox.(rsts, rsts[1]; rtol=1e-5))
end

function test_ndarray(d, sz, T)
    x = rand(T, sz)
    y = rand(T, sz)
    @test_nowarn assess(d, x, y)

    T <: AbstractGray || return nothing
    for _ in 1:10
        x = rand(T, sz)
        y = rand(T, sz)

        @test assess(d, x, y) ≈ assess(d, channelview(x), channelview(y)) atol=1e-4
    end
end
