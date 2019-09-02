
################
# Bounding boxes
#################

# A bounding box is an Interval or ProductDomain of intervals that encompasses the domain.

# If the boundingbox is not a product of intervals, something has gone wrong.

boundingbox(a::SVector{1}, b::SVector{1}) = a[1]..b[1]

boundingbox(a::Number, b::Number) = a..b

boundingbox(a, b) = ProductDomain(map((ai,bi)->ClosedInterval(ai,bi), a, b)...)

boundingbox(d::AbstractInterval) = d

boundingbox(::UnitHyperBall{N,T}) where {N,T} = boundingbox(-ones(SVector{N,T}), ones(SVector{N,T}))

boundingbox(d::ProductDomain) = cartesianproduct(map(boundingbox, elements(d))...)

boundingbox(d::DerivedDomain) = boundingbox(source(d))

boundingbox(d::DifferenceDomain) = boundingbox(d.d1)

function boundingbox(d::UnionDomain)
    left = SVector(minimum(hcat(map(infimum,map(boundingbox,elements(d)))...);dims=2)...)
    right = SVector(maximum(hcat(map(supremum,map(boundingbox,elements(d)))...);dims=2)...)
    boundingbox(left,right)
end

function boundingbox(d::IntersectionDomain)
    left = SVector(maximum(hcat(map(infimum,map(boundingbox,elements(d)))...);dims=2)...)
    right = SVector(minimum(hcat(map(supremum,map(boundingbox,elements(d)))...);dims=2)...)
    boundingbox(left,right)
end

DomainSets.superdomain(d::DomainSets.MappedDomain) = DomainSets.source(d)

# Now here is a problem: how do we compute a bounding box, without extra knowledge
# of the map? We can only do this for some maps.
boundingbox(d::DomainSets.MappedDomain) = mapped_boundingbox(boundingbox(source(d)), forward_map(d))

function mapped_boundingbox(box::Interval, fmap)
    l,r = (infimum(box),supremum(box))
    ml = fmap*l
    mr = fmap*r
    boundingbox(min(ml,mr), max(ml,mr))
end

# In general, we can at least map all the corners of the bounding box of the
# underlying domain, and compute a bounding box for those points. This will be
# correct for affine maps.
function mapped_boundingbox(box::ProductDomain, fmap)
    crn = corners(infimum(box),supremum(box))
    mapped_corners = [fmap*crn[:,i] for i in 1:size(crn,2)]
    left = [minimum([mapped_corners[i][j] for i in 1:length(mapped_corners)]) for j in 1:size(crn,1)]
    right = [maximum([mapped_corners[i][j] for i in 1:length(mapped_corners)]) for j in 1:size(crn,1)]
    boundingbox(left, right)
end

# Auxiliary functions to rotate a bounding box when mapping it.
function corners(left::AbstractVector, right::AbstractVector)
    @assert length(left)==length(right)
    N=length(left)
    corners = zeros(N,2^N)
    # All possible permutations of the corners
    for i=1:2^length(left)
        for j=1:N
            corners[j,i] = ((i>>(j-1))%2==0) ? left[j] : right[j]
        end
    end
    corners
end
