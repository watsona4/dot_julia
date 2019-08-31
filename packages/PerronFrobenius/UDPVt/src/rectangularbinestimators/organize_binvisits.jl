"""
    BinVisits

A data structure helping to organize information about bins that
get visited by the orbit.

## Fields

`first_visited_by`: Vector with the same length as there are visited bins.
`first_visited_by[i]` identifies which point of the orbit first visits the
i-th bin. If `first_visited_by[i] = 5`, then the i-th bin first got visited
by the 5th point of the orbit.

`visitors`. Vector with same length as there are visited bins.
`visitors[i]` will give a vector containing  the (column)
indices of the points visiting that bin. If `visitors[i] = [4, 12]`,
then the i-th bin was visited by points #4 and #12 of the embedding.

`visits_whichbin`: Vector with same length as there are number of points.
Each element of this vector indicate which bin the corresponding
point visits (expressed in terms of the unique bin labels).
If `visits_whichbin[i] = 5`, then the i-th point of the orbit
visits the 5th visited bin.

"""
struct BinVisits
    first_visited_by::Vector{Int}
    visitors::Vector{Vector{Int}}
    visits_whichbin::Vector{Int}
end


####################
# Pretty printing
####################
function summarise(bv::PerronFrobenius.BinVisits)
    n_pts = length(bv.first_visited_by)

end
Base.show(io::IO, bv::PerronFrobenius.BinVisits) = println(io, summarise(bv))

"""
    whichpoints_visit_whichbins(A, U) -> Vector{Int}

Given a sequence of unique elements from an array `U`, say
U = [a b c e], which are taken from the array `A`, say
A = [a b c a c b b a c e], we express the elements of the full
vector as their corresponding integer position in the array of
unique elements. The corresponding position vector will be
P = [1 2 3 1 3 2 2 1 3 4].

"""
function whichpoints_visit_whichbins(A, U)
    a = [A[:,i] for i in 1:size(A, 2)]
    u = [U[:,i] for i in 1:size(U, 2)]
    inds = Int[]
    npts = length(a)
    npts_unique = length(u)
    for j = 1:npts
        for i = 1:npts_unique
            if a[j] == u[i]
                push!(inds, i)
            end
        end
    end
    inds
end

"""
    organize_bin_labels(visited_bin_labels::Array{Float64})

Organise bin labels by identifying bins that are visited multiple times,
and finding which points fall in which bins.

`visited_bin_labels` is an array where each column cᵢ (corresponding to
the point pᵢ) represents a tuple of integers identifying the position
of that bin, relative to some minimum value, given a stepsize `ϵ`.
See `assign_bin_labels` for more information.
"""
function organize_bin_labels(visited_bin_labels::Array{Int, 2})
    slices = groupslices(visited_bin_labels, 2)
    first_visited_by = firstinds(slices)
    visitors = groupinds(slices)
    visits_whichbin = whichpoints_visit_whichbins(visited_bin_labels, unique(visited_bin_labels, dims = 2))

    BinVisits(first_visited_by, visitors, visits_whichbin)
end
