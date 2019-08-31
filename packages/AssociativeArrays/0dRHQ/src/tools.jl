module AssociativeArrayTools

using AssociativeArrays

export csv2triples, explode_sparse, LazySparse

using CSV, Images, ImageContrastAdjustment

function csv2triples(path)
    _, name = splitdir(path)
    # note: will want to try and parse integers (and floats?)
    f = CSV.File(path) # , types=collect(Iterators.repeated(Union{Missing, String}, 1000)))
    mapmany(enumerate(f)) do (i, row)
        ((row=(Id(i)), col=(prop => getproperty(row, prop)), val=1) for prop in propertynames(row))
    end
end

# triples = mapmany(enumerate(raw)) do (i, nt)
#     [(row=Id(i), col=(k => v), val=1) for (k, v) in pairs(nt)]
# end
# t = explode_sparse(triples)

export vis

function vis(A::AbstractSparseMatrix, agg_fn, imsize=300, im_or_data=:im)
    sz = size(A)
#     out_sz = (200, 200) .* if sz[1] < sz[2]
#         1, cld(sz[2], sz[1])
#     else
#         cld(sz[1], sz[2]), 1
#     end

#     out_sz = let x = imsize, y = round(Int, 1.25x)
#         sz[1] == sz[2] ? (x, x) : sz[1] < sz[2] ? (x, y) : (y, x)
#     end

    aspect = sz[2] / sz[1]
    out_sz = (imsize, imsize) # round(Int, aspect * imsize))

    agg = zeros(eltype(A), out_sz)
    counts = zeros(eltype(A), out_sz)
    step = cld.(sz, out_sz)
    @show sz out_sz step
#     @time begin
    begin
        I, J, V = findnz(A)
        for (i, j, v) in zip(I, J, V)
            @assert !iszero(v) "For performance, we do not allow stored zeros."
            i′ = fld1(i, step[1])
            j′ = fld1(j, step[2])
            counts[i′, j′] += 1
            # agg[i′, j′] += v
            agg[i′, j′] = agg_fn(agg[i′, j′], v)
        end
    end

    # hm. what to do about non-square resizing? can we somehow normalize to prevent distortion?

#     @show sz out_sz
#     @show extrema(res)
#     I = .!iszero.(out) sort of thing
    out = zeros(promote_type(Float64, eltype(A)), out_sz)
    I = findall(!iszero, agg)
    out[I] .= agg[I] # ./ prod(step) # counts[I]
#     out ./= maximum(out)
#     res = ifelse.(iszero.(out), zero(eltype(out)), (out ./ counts))
    if im_or_data == :im
        # out = log.(1 .+ out)
        # out = out ./ maximum(out)
        # out = 1 .- out
        # out = adjust_histogram(GammaCorrection(), out, 2.2)
        out = ImageContrastAdjustment.adjust_histogram(ImageContrastAdjustment.Equalization(), out ./ let m = maximum(out); iszero(m) ? 1.0 : m end, 256, minval = 0, maxval = 1)
        # pal.(out)
        Gray.(1 .- out)
    else @assert im_or_data == :data
        out
    end
end

vis(A::Assoc, args...) = vis(A.data, args...)

struct LazySparse{T, TV <: AbstractVector{T}, TI <: Integer, TVI <: AbstractVector{TI}}
    I::TVI
    J::TVI
    V::TV
    m::TI
    n::TI
end
LazySparse{T}(m::TI, n::TI) where {T, TI} = LazySparse(TI[], TI[], T[], m, n)

function Base.setindex!(a::LazySparse, v, i, j)
    push!(a.I, i)
    push!(a.J, j)
    push!(a.V, v)
    return v
end
SparseArrays.sparse(a::LazySparse) = sparse(a.I, a.J, a.V, a.m, a.n)

#=
LazySparse usage:

m = n = 2
A = LazySparse{Float64}(m, n)

for i in 1:m
  for j in 1:n
    A[i,j] = rand()
  end
end

sparse(A)

=#

#=
smooth(a, b, d, α) = (a + d*α) / (b + α)

function surprise_rows(A)
    data = AssociativeArrays.data
    observed = A
    filtered = threshold(observed, 10) # entries with at least 10 in the breed and the name
    expected = data(filtered) do a
        # note: we already computed the marginals in `threshold`.
        # the d4m schema recommends holding them always; might be a useful thing to do.
        m1 = sum(a, dims=1)
        m2 = sum(a, dims=2)
        m1 .* m2 ./ sum(a)
    end

    # todo: multi-assoc `data` function that asserts isequal named axes
    # data(filtered, expected) do o, e
    logratios = data(filtered) do o
        data(expected) do e
            log2.(smooth.(Array(o), e, 1, 50))
        end
    end
    bound = log2(1.05)

    (logratios < -bound) + (logratios > bound)
end

secondaries_surprise = surprise_rows(secondaries); # [sortperm(primary, dims=1, by=sum, rev=true), :, named=true]

function surprise_context(A, fields)
    Dict(field => (maximum_abs_sum=maximum(sum(abs, A[:, field], dims=2)),) for field in fields)
end;

secondaries_out = Dict(
    :context => surprise_context(secondaries_surprise, secondary_fields),
    :rows => let rows = rows_to_triples(secondaries_surprise)
        foreach(row -> sort!(row, by=x->x.v, rev=true), rows)
        rows
    end
)
write("secondaries_out.json", json(secondaries_out))

----------

revised:

function rest_col_data(A, a_keys, b_keys)
    < = AssociativeArrays.:<
    > = AssociativeArrays.:>

    observed = condense(A[:, a_keys]' * A[:, b_keys])
    filtered = threshold(observed, 10) # rows with at least 10 entries in its row or col
    expected = data(filtered) do a
        # note: we already computed the marginals in `threshold`.
        # the d4m schema recommends holding them always; might be a useful thing to do.
        m1 = sum(a, dims=1)
        m2 = sum(a, dims=2)
        m1 .* m2 ./ sum(a)
    end
    # todo: multi-assoc `data` function that asserts isequal named axes: data(filtered, expected) do o, e
    logratios = data(filtered) do o
        data(expected) do e
            log2.(smooth.(Array(o), e, 1, 50))
        end
    end

    bound = log2(1.05)
    out = (logratios < -bound) + (logratios > bound)
    out
#     (rns, cns, t) = trip(out)
#     (
#         maximum=maximum(x),
#         rows=[(rn=i, value=v) for (i, j, v) in t]
#     )
end
=#

function csv2assoc(csv)
    names = Vector[]
    parts = []
    dicts = []
    Js = Vector{Int}[]
    offset = 0

    cols = columns(csv)
    ncols = length(cols)
    @time for (groupname, vals) in pairs(cols)
        uvals = unique(vals)
        len = length(uvals)

        groupnames = [groupname => val for val in uvals]
        groupdict = Dict(zip(uvals, 1:len))
        J = [groupdict[val] + offset for val in vals]

        push!(names, groupnames)
        push!(dicts, groupdict)
        push!(parts, uvals)
        push!(Js, J)

        offset += len
    end
    cf = collect ∘ flatten
    @time col_axis = NamedAxis(NamedTuple{keys(cols)}(parts), NamedTuple{keys(cols)}(dicts))
    @time row_axis = NamedAxis([:row => i for i in 1:length(csv)])
    @time value = sparse(cf(1:length(csv) for _ in 1:ncols), cf(Js), 1)
    @time Assoc(value, (row_axis, col_axis))
end

end