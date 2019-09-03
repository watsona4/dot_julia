__precompile__(true)

module SortMerge

using Printf, SparseArrays

import Base.show
import Base.sortperm
import Base.zip

import Base.iterate, Base.length, Base.size, Base.getindex,
       Base.firstindex, Base.lastindex, Base.IndexStyle

export sortmerge, sortperm, nmatch, countmatch, multimatch

# --------------------------------------------------------------------
# Source structure
#
struct Source
    size::Int
    sortperm::Vector{Int}
    cmatch::SparseVector{Int,Int}
end


# --------------------------------------------------------------------
# Matched structure
#
struct Matched <: AbstractVector{Vector{Int}}
    nsrc::Int
    nrow::Int
    sources::Vector{Source}
    matched::Matrix{Int}
end

# Methods
length(mm::Matched) = mm.nsrc
size(mm::Matched) = (mm.nsrc,)
getindex(mm::Matched, inds) = mm.matched[:, inds]
firstindex(mm::Matched) = 1
lastindex(mm::Matched) = mm.nsrc
IndexStyle(::Type{Matched}) = IndexLinear()

nmatch(mm::Matched) = mm.nrow
countmatch(mm::Matched, source::Int) = mm.sources[source].cmatch
sortperm(  mm::Matched, source::Int) = mm.sources[source].sortperm

zip(mm::Matched) = zip(map(i -> mm.matched[:,i], 1:mm.nsrc)...)
#unzip(mm::Matched)  = ntuple(i -> mm.matched[:,i],  length(mm.sources))


function multimatch(mm::Matched, source::Int, multi::Int; group=false)
    @assert multi >= 1
    index = findall(countmatch(mm, source) .== multi)
    index_out = sortmerge(index, mm.matched[:,source], quiet=true)[2]
    matrix = mm.matched[index_out,:]

    out = Vector{Matched}()
    ngroups = (group  ?  length(index)  :  1)
    for igroup in 1:ngroups
        jj = (group  ?
              findall(matrix[:,source] .== index[igroup])  :
              collect(1:length(index_out)))

        sources = Vector{Source}()
        for i in 1:mm.nsrc
            push!(sources, Source(mm.sources[i].size, Vector{Int}(),
                                  sparsevec(unique(mm.matched[index_out[jj], i]),
                                            multi, length(mm.sources[i].cmatch))))
        end
        push!(out, Matched(mm.nsrc, length(jj), sources, mm.matched[index_out[jj],:]))
    end

    (group)  &&  (return out)
    return out[1]
end


function default_lt(v, i, j)
    return v[i] < v[j]
end
function default_sd(A, B, i, j)
    return sign(A[i] - B[j])
end

# sortmerge(j::NTuple{2, Matched}, A, B, args...; sd=default_sd, quiet=false) = 
#   sortmerge(A, B, args..., sort1=j[1].sortperm, sort2=j[2].sortperm, sd=sd, quiet=quiet)
function sortmerge(A, B, args...;
                   sd=default_sd,
                   quiet=false,
                   sort1=Vector{Int}(),
                   sort2=Vector{Int}(),
                   lt1=default_lt,
                   lt2=default_lt,
                   sorted=false)

    elapsed = (Base.time_ns)()
    size1 = size(A)[1]
    size2 = size(B)[1]

    elapsed_sorting = fill(0., 2)
    elapsed_sorting[1] = (Base.time_ns)()
    if length(sort1) == 0
        sort1 = collect(range(1, length=size1))
        (sorted)  ||  (sort1 = sortperm(sort1, lt=(i, j) -> (lt1(A, i, j))))
    end
    elapsed_sorting[1] = ((Base.time_ns)() - elapsed_sorting[1]) / 1.e9
    elapsed_sorting[2] = (Base.time_ns)()
    if length(sort2) == 0
        sort2 = collect(range(1, length=size2))
        (sorted)  ||  (sort2 = sortperm(sort2, lt=(i, j) -> (lt2(B, i, j))))
    end
    elapsed_sorting[2] = ((Base.time_ns)() - elapsed_sorting[2]) / 1.e9

    i2a = 1
    match1 = Array{Int}(undef, 0)
    match2 = Array{Int}(undef, 0)
    cm1 = fill(0, size1)
    cm2 = fill(0, size2)

    lastlog = -1.
    progress = false
    for i1 in 1:size1
        for i2 in i2a:size2
            if !quiet  &&  !progress  &&  (((Base.time_ns)() - elapsed) / 1.e9 > 1)
                progress = true
            end
            if !quiet  &&  progress
                completed = ceil(1000. * ((i1-1) * size2 + i2) / (size1 * size2))
                if completed > lastlog
                    @printf("Completed: %5.1f%%, matched: %d \r", completed/10., length(match1))
                    lastlog = completed
                end
            end

            j1 = sort1[i1]
            j2 = sort2[i2]
            if length(args) > 0  # This improves performances
                dd = Int(sd(A, B, j1, j2, args...))
            else
                dd = Int(sd(A, B, j1, j2))
            end

            if     dd == -1; break
            elseif dd ==  1; i2a += 1
            elseif dd ==  0
                push!(match1, j1)
                push!(match2, j2)
                cm1[j1] += 1
                cm2[j2] += 1
            end
        end
    end
    if !quiet  &&  progress
        @printf("Completed: %5.1f%%, matched: %d \n", 100., length(match1))
    end

    ii = findall(cm1 .> 0); side1 = Source(size1, sort1, sparsevec(ii, cm1[ii], length(cm1)))
    ii = findall(cm2 .> 0); side2 = Source(size2, sort2, sparsevec(ii, cm2[ii], length(cm2)))
    mm = Matched(2, length(match1), [side1, side2], [match1 match2])
    elapsed = ((Base.time_ns)() - elapsed) / 1.e9

    if !quiet
        for i in 1:length(mm.sources)
            ss = mm.sources[i]
            uu = length(unique(mm.matched[:,i]))
            @printf("Input %2d: %10d / %10d  (%6.2f%%)  -  max mult. %d | sort : %.3gs\n",
                    i, uu, ss.size, 100. * uu/float(ss.size), maximum(ss.cmatch), elapsed_sorting[i])
        end
        @printf("Output  : %10d                                         | total: %.3gs\n",
                size(mm.matched)[1], elapsed)
    end
    return mm
end

end # module
