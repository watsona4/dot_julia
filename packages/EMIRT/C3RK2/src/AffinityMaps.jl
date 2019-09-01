module AffinityMaps
using ..Types
using ..Domains
using ..Segmentations

export aff2seg, exchangeaffxz!, aff2uniform, gaff2saff, aff2edgelist
export maskaff!, mask_margin!

function downsample(aff::AffinityMap; scale::Union{Vector, Tuple} = (2,2,1,1))
    println("downsampling affinitymap with averaging")
    outSize = map(div, size(aff), scale)
    out = similar(aff, (outSize...,)) 
    for z in 1:outSize[3]
        for y in 1:outSize[2]
            for x in 1:outSize[1]
                out[x,y,z,1:3] = mean(aff[(x-1)*scale[1]+1:x*scale[1],
                                          (y-1)*scale[2]+1:y*scale[2],
                                          (z-1)*scale[3]+1:z*scale[3],
                                          1:3])
            end
        end
    end
    return out
end            

"""
transform google affinity to seung lab affinity
"""
function gaff2saff( gaff::Array{Float32,3} )
    @assert ndims(gaff)==3
    sx,sy,sz = size(gaff)
    saff = reshape(gaff, (sx,sy,Int64(sz/3),Int64(3)));

    # transform the x y and z channel
    ret = zeros(size(saff))
    ret[2:end,:,:, 1] = saff[1:end-1,:,:, 1]
    ret[:,2:end,:, 2] = saff[:,1:end-1,:, 2]
    ret[:,:,2:end, 3] = saff[:,:,1:end-1, 3]

    return ret
end

# exchang X and Z channel of affinity
function exchangeaffxz!(aff::AffinityMap)
    println("exchange x and z of affinity map")
    taffx = deepcopy(aff[:,:,:,1])
    aff[:,:,:,1] = deepcopy(aff[:,:,:,3])
    aff[:,:,:,3] = taffx
    #aff[:,:,:,1], aff[:,:,:,3] = aff[:,:,:,3], aff[:,:,:,1]
    return aff
end

# transform affinity to segmentation
function aff2seg( aff::Array{Float32,4}; dim::Integer = 3, thd::Float32 = Float32(0.5) )
    @assert dim==2 || dim==3
    # note that should be column major affinity map
    # the znn V4 output is row major!!! should exchangeaffxz first!
    xaff = aff[:,:,:,1]
    yaff = aff[:,:,:,2]
    zaff = aff[:,:,:,3]

    # number of voxels in segmentation
    N = UInt32( length(xaff) )

    # initialize and create the disjoint sets
    djsets = Tdjsets( N )

    # union the segments by affinity edges
    X,Y,Z = size( xaff )
    X = UInt32(X);   Y = UInt32(Y);   Z = UInt32(Z);

    # x affinity
    for z in UInt32(1):UInt32(Z)
        for y in UInt32(1):UInt32(Y)
            for x in UInt32(2):UInt32(X)
                if xaff[x,y,z] > thd
                    vid1 = x            + (y-UInt32(1))*X + (z-UInt32(1))*X*Y
                    vid2 = x-UInt32(1)  + (y-UInt32(1))*X + (z-UInt32(1))*X*Y
                    rid1 = find!(djsets, vid1)
                    rid2 = find!(djsets, vid2)
                    union!(djsets, rid1, rid2)
                end
            end
        end
    end

    # y affinity
    for z in UInt32(1):UInt32(Z)
        for y in UInt32(2):UInt32(Y)
            for x in UInt32(1):UInt32(X)
                if yaff[x,y,z] > thd
                    vid1 = x + (y-UInt32(1))*X + (z-UInt32(1))*X*Y
                    vid2 = x + (y-UInt32(2))*X + (z-UInt32(1))*X*Y
                    rid1 = find!(djsets, vid1)
                    rid2 = find!(djsets, vid2)
                    union!(djsets, rid1, rid2)
                end
            end
        end
    end

    # z affinity
    if dim > 2
        # only computed in 3D case
        for z in UInt32(2):UInt32(Z)
            for y in UInt32(1):UInt32(Y)
                for x in UInt32(1):UInt32(X)
                    if zaff[x,y,z] > thd
                        vid1 = x + (y-UInt32(1))*X + (z-UInt32(1))*X*Y
                        vid2 = x + (y-UInt32(1))*X + (z-UInt32(2))*X*Y
                        rid1 = find!(djsets, vid1)
                        rid2 = find!(djsets, vid2)
                        union!(djsets, rid1, rid2)
                    end
                end
            end
        end
    end

    # get current segmentation
    setallroot!( djsets )
    # marking the singletones as boundary
    # copy the segment to avoid overwritting of djsets
    seg = deepcopy( djsets.sets )
    seg = reshape(seg, size(xaff) )
    singleton2boundary!( seg )
    return seg
end

function aff2uniform(aff, alg=QuickSort)
    print("map to uniform distribution...")
    tp = typeof(aff)
    sz = size(aff)
    N = length(aff)

    # get the indices
    print("get the permutation by sorting......")
    @time p = sortperm(aff[:], alg=alg)
    println("done :)")
    q = zeros(eltype(p), size(p))
    q[p[1:N]] = 1:N

    # generating values
    v = range(0, stop=1, length=N)
    # making new array
    v = v[q]
    v = reshape(v, sz)
    v = tp( v )
    println("done!")
    return v
end

#function aff2uniform!(aff::AffinityMap)
 #   println("transfer to uniform distribution...")
 #   for z in 1:size(aff,3)
 #       aff[:,:,z,:] = arr2uniform( aff[:,:,z,:] )
 #   end
#end

"""
transfer affinity map to edge list
"""
function aff2edgelist(aff::Array{T,4}; is_sort::Bool=true) where T
    # initialize the edge list
    elst = Array{Tuple{Float32,UInt32,UInt32},1}([])
    sizehint!(elst, div(length(aff),3))
    # get the sizes
    sx,sy,sz,sc = size(aff)
    @assert sc==3

    for z in UInt32(1):UInt32(sz)
        for y in UInt32(1):UInt32(sy)
            for x in UInt32(1):UInt32(sx)
                vid1 = x + (y-1)*sx + (z-1)*sx*sy
                # x affinity
                if x>1
                    vid2 = x-1 + (y-1)*sx + (z-1)*sx*sy
                    push!(elst, (aff[x,y,z,1], vid1, vid2))
                end
                # y affinity
                if y>1
                    vid2 = x + (y-2)*sx + (z-1)*sx*sy
                    push!(elst, (aff[x,y,z,2], vid1, vid2))
                end
                # z affinity
                if z>1
                    vid2 = x + (y-1)*sx + (z-2)*sx*sy
                    push!(elst, (aff[x,y,z,3], vid1, vid2))
                end
            end
        end
    end
    if is_sort
        @time sort!(elst, rev=true)
    end
    return elst
end

"""
    maskaff!(img::EMImage, aff::AffinityMap)

set the affinity edge value to 0 if the connecting voxel is 0 in image
"""
function maskaff!(img::EMImage, aff::AffinityMap)
    @assert size(img) == size(aff[:,:,:,1])
    # mask the affinity
    for z in 2:size(img, 3)
        for y in 1:size(img, 2)
            for x in 1:size(img, 1)
                if img[x,y,z]==0x00 || img[x,y,z-1]==0x00
                    aff[x,y,z,3] = 0.0f0
                end
            end
        end
    end

    for z in 1:size(img, 3)
        for y in 2:size(img, 2)
            for x in 1:size(img, 1)
                if img[x,y,z]==0x00 || img[x,y-1,z]==0x00
                    aff[x,y,z,2] = 0.0f0
                end
            end
        end
    end

    for z in 1:size(img, 3)
        for y in 1:size(img, 2)
            for x in 2:size(img, 1)
                if img[x,y,z]==0x00 || img[x-1,y,z]==0x00
                    aff[x,y,z,1] = 0.0f0
                end
            end
        end
    end
end

function maskaff!(mask::Array{Bool,3}, aff::AffinityMap)
    @assert size(mask) == size(aff[:,:,:,1])
    # mask the affinity
    for z in 2:size(mask, 3)
        for y in 1:size(mask, 2)
            for x in 1:size(mask, 1)
                if mask[x,y,z] || mask[x,y,z-1]
                    aff[x,y,z,3] = 0.0f0
                end
            end
        end
    end

    for z in 1:size(mask, 3)
        for y in 2:size(mask, 2)
            for x in 1:size(mask, 1)
                if mask[x,y,z] || mask[x,y-1,z]
                    aff[x,y,z,2] = 0.0f0
                end
            end
        end
    end

    for z in 1:size(mask, 3)
        for y in 1:size(mask, 2)
            for x in 2:size(mask, 1)
                if mask[x,y,z] || mask[x-1,y,z]
                    aff[x,y,z,1] = 0.0f0
                end
            end
        end
    end
end

function mask_margin!(aff::AffinityMap, maskSize::Vector)
    sx,sy,sz,sc = size(aff)
    for z in 1:sz
        for y in 1:sy
            for x in 1:sx
                if  z<=maskSize[3] || z>=sz-maskSize[3] ||
                    y<=maskSize[2] || y>=sy-maskSize[2] ||
                    x<=maskSize[1] || x>=sx-maskSize[1]
                    aff[x,y,z,:] = 0f0
                end
            end
        end
    end
end

end # end of module
