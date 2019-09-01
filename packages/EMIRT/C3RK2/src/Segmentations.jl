module Segmentations

using ..Types
using ..Domains 
using Colors
using FixedPointNumbers

export seg2aff, singleton2boundary!, relabel_seg 
export add_seg_boundary!, seg2rgb, seg_overlay_img, seg_overlay_img!
export seg2sgm, seg2segMST, segid1N!, segid1N!_V3
export downsample

const NORMED8_HALF  = Normed{UInt8,8}(0.5)
const NORMED8_ONE   = Normed{UInt8,8}(1.0)

"""
construct affinity map from segmentation
"""
function seg2aff(seg::Array{T,3}) where T
  aff = zeros(Float32, (size(seg)..., 3))
  aff[2:end, :,:,1] = (seg[2:end, :,:] .== seg[1:end-1, :,:])
  aff[:, 2:end,:,2] = (seg[:, 2:end,:] .== seg[:, 1:end-1,:])
  aff[:,:, 2:end,3] = (seg[:,:, 2:end] .== seg[:,:, 1:end-1])
  aff
end

"""
label all the singletones as boundary
use original segmentation as mask to lable boundary
some singletons could be created by cropping margins,
this protected the marginal singletons.
"""
function singleton2boundary!( seg::Array{T,3}, ref::Array{T,3} ) where T
    Threads.@threads for i in eachindex(seg)
        seg[i] = ref[i]>0x00000000 ? seg[i] : 0x00000000
    end
end

function singleton2boundary!( seg::Array{T,3} ) where T

    # a flag array indicating whether it is segment
    flg = falses(size(seg))
    # size
    X,Y,Z = size(seg)

    # traverse the segmentation
    for z in 1:Z
        for y in 1:Y
            for x in 1:X
                if flg[x,y,z]
                    continue
                end
                if x>1 && seg[x,y,z]==seg[x-1,y,z]
                    continue
                end
                if x<X && seg[x,y,z]==seg[x+1,y,z]
                    flg[x+1,y,z] = true
                    continue
                end
                if y>1 && seg[x,y,z]==seg[x,y-1,z]
                    continue
                end
                if y<Y && seg[x,y,z]==seg[x,y+1,z]
                    flg[x,y+1,z] = true
                    continue
                end
                if z>1 && seg[x,y,z]==seg[x,y,z-1]
                    continue
                end
                if z<Z && seg[x,y,z]==seg[x,y,z+1]
                    flg[x,y,z+1] = true
                    continue
                end
                # it is a singletone
                seg[x,y,z] = T(0)
            end
        end
    end
end


# relabel the segment according to connectivity
# where N is the total number of segments
# Note that this is different from relabel1N in segerror package, which relabeles in 2D and labeled the segment ID to 1-N, where N is the total number of segments.
function relabel_seg( seg::Array{T,3} ) where T
    N = length(seg)
    X,Y,Z = size(seg)
    X = T(X);   Y = T(Y);   Z = T(Z);

    # initialize the disjoint sets
    djs = Tdjsets(N)

    # x affinity
    for x in 0x00000002:X
        for y in 0x00000001:Y
            for z in 0x00000001:Z
                if seg[x,y,z]>0 && seg[x,y,z]==seg[x-1,y,z]
                    # should union these two sets
                    vid1 = x            + (y-0x00000001)*X + (z-0x00000001)*X*Y
                    vid2 = x-0x00000001 + (y-0x00000001)*X + (z-0x00000001)*X*Y
                    # find tree root
                    r1 = find!(djs, vid1)
                    r2 = find!(djs, vid2)
                    # union two sets
                    union!(djs, r1, r2)
                end
            end
        end
    end

    # y affinity
    for x in 0x00000001:T(X)
        for y in 0x00000002:T(Y)
            for z in 0x00000001:T(Z)
                if seg[x,y,z]>0x00000000 && seg[x,y,z]==seg[x,y-0x00000001,z]
                    vid1 = x + (y-0x00000001)*X + (z-0x00000001)*X*Y
                    vid2 = x + (y-0x00000002)*X + (z-0x00000001)*X*Y
                    r1 = find!(djs, vid1)
                    r2 = find!(djs, vid2)
                    union!(djs, r1, r2)
                end
            end
        end
    end

    # z affinity
    for x in 0x00000001:T(X)
        for y in 0x00000001:T(Y)
            for z in 0x00000002:T(Z)
                if seg[x,y,z]>0x00000000 && seg[x,y,z] == seg[x,y,z-0x00000001]
                    vid1 = x + (y-0x00000001)*X + (z-0x00000001)*X*Y
                    vid2 = x + (y-0x00000001)*X + (z-0x00000002)*X*Y
                    r1 = find!(djs, vid1)
                    r2 = find!(djs, vid2)
                    union!(djs, r1, r2)
                end
            end
        end
    end

    # get current segmentation
    setallroot!( djs )
    ret = djs.sets
    ret = reshape(ret, size(seg))
    # mark all the singletons to 0 as boundary
    # singleton2boundary!(ret, seg) # this will remove the singletons created by cropping
    # should use original segmentation as a mask to remove boundary regions
    Threads.@threads for i in eachindex(seg)
        if seg[i] == 0x00000000
            ret[i] = 0x00000000
        end
    end
    return ret
end

# reassign segment ID as 1-N
function segid1N!( seg::Array{T,3} ) where T
    # dictionary of ids
    did = Dict{T, T}(T(0)=>T(0))
    sizehint!(did, div(length(seg),16))

    # number of segments
    N = 0x00000000
    v = 0x00000000
    # assign the map to a new segment
    for z in 1:size(seg, 3)
        for y in 1:size(seg, 2)
            for x in 1:size(seg, 1)
                v = seg[x,y,z]
                if !haskey(did, v)
                    # a new segment ID
                    N += 0x00000001
                    did[v] = N
                    seg[x,y,z] = N
                else
                    seg[x,y,z] = did[ v ]
                end
            end
        end
    end
    return N
end

"""
downsampling segmentation by simply sampling voxels
"""
function downsample( seg::Union{Array{UInt32,3},Array{UInt64,3}}; 
                    scale::Vector{Int} = [2,2,1])
    start = map(x->cld(x,2), scale)
    seg[start[1]:scale[1]:end, start[2]:scale[2]:end, start[3]:scale[3]:end]
end 

    
#==
"""
multiple threads version runs without stop, used all the cpu!
"""
function segid1N!_V3{T}( seg::Array{T,3} )
    # dictionary of ids
    did = Dict{T, T}(T(0)=>T(0))
    sizehint!(did, div(length(seg),32))

    # number of segments
    N = Atomic{T}(0)
    v = T(0)

    # lock of critical section
    critical = SpinLock()
    # assign the map to a new segment
    gc_enable(false)
    for z in 1:size(seg, 3)
        for y in 1:size(seg, 2)
            @threads for x in 1:size(seg, 1)
                v = seg[x,y,z]
                if !haskey(did, v)
                    # a new segment ID
                    lock(critical)
                    # atomic_add!(N, 1)
                    N += 1
                    did[v] = N
                    seg[x,y,z] = N
                    unlock(critical)
                else
                    seg[x,y,z] = did[ v ]
                end
            end
        end
    end
    gc_enable(true)
    return N
end
==#

# add boundary between contacting segments
function add_lbl_boundary!(seg::Array{T,3}, conn=8) where T
    # neighborhood definition
    @assert conn==8 || conn==4
    sx,sy,sz = size(seg)
    for z = 1:sz
        for y = 1:sy
            for x = 1:sx
                if seg[x,y,z]==T(0)
                    # ignore the existing boundary
                    continue
                end
                # flag of central pixel
                cf = false
                # x direction
                if x<sx && seg[x+1,y,z]>T(0) && seg[x,y,z]!=seg[x+1,y,z]
                    cf = true
                    seg[x+1,y,z] = T(0)
                end
                # y direction
                if y<sy && seg[x,y+1,z]>T(0) && seg[x,y,z]!=seg[x,y+1,z]
                    cf = true
                    seg[x,y+1,z] = T(0)
                end
                if x>1 && seg[x-1,y,z]>T(0) && seg[x,y,z]!=seg[x-1,y,z]
                    cf = true
                    seg[x-1,y,z] = T(0)
                end
                if y>1 && seg[x,y-1,z]>T(0) && seg[x,y,z]!=seg[x,y-1,z]
                    cf = true
                    seg[x,y-1,z] = T(0)
                end

                if conn==8
                    if x<sx && y<sy && seg[x+1,y+1,z]>T(0) && seg[x,y,z]!=seg[x+1,y+1,z]
                        cf = true
                        seg[x+1,y+1,z] = T(0)
                    end

                    if x>1 && y<sy && seg[x-1,y+1,z]>T(0) && seg[x,y,z]!=seg[x-1,y+1,z]
                        cf = true
                        seg[x-1,y+1,z] = T(0)
                    end
                    if x<sx && y>1 && seg[x+1,y-1,z]>T(0) && seg[x,y,z]!=seg[x+1,y-1,z]
                        cf = true
                        seg[x+1,y-1,z] = T(0)
                    end
                    if x>1 && y>1 && seg[x-1,y-1,z]>T(0) && seg[x,y,z]!=seg[x-1,y-1,z]
                        cf = true
                        seg[x-1,y-1,z] = T(0)
                    end
                end
                if cf
                    print("$x,$y, ")
                    seg[x,y,z] = T(0)
                end
            end
        end
    end
end


"""
transform segmentation to domains
Inputs:
seg: a segmentation or label of image volume

Outputs:
dms: domains for fast union-find algorithm defined in "domains.jl"
"""
function segmentation2domains(seg::Array{T,3}; is_merge = true) where T
    # initialize a domain as singletons
    @assert ndims(seg)==2 || ndims(seg)==3
    dms = Tdomains( length(seg) )

    # if do not merge, return directly
    if !is_merge
        return dms
    end

    # volume size
    sx,sy,sz = size(seg)
    sx = T(sx); sy = T(sy); sz = T(sz)

    # union all the voxel with same segment ID
    for z in 0x00000001:sz
        for y in 0x00000001:sy
            for x in 0x00000001:sx
                # voxel id
                vid1 = x + (y-0x00000001)*sx + (z-0x00000001)*sx*sy
                # segmentation ID
                sid1 = seg[x,y,z]

                # x affinity
                if x>0x00000001 && sid1==seg[x-0x00000001,y,z]
                    vid2 = x-0x00000001 + (y-0x00000001)*sx + (z-0x00000001)*sx*sy
                    union!(dms, vid1, vid2)
                end

                # y affinity
                if y>0x00000001 && sid1==seg[x,y-0x00000001,z]
                    vid2 = x + (y-0x00000002)*sx + (z-0x00000001)*sx*sy
                    union!(dms, vid1, vid2)
                end

                # z affinity
                if z>0x00000001 && sid1==seg[x,y,z-0x00000001]
                    vid2 = x + (y-0x00000001)*sx + (z-0x00000002)*sx*sy
                    union!(dms, vid1, vid2)
                end
            end
        end
    end
    return dms
end

"""
transform indexed segmentation image to RGB image with random color label
seg: segmentation, an indexed array

Outputs:
ret: rgb image array with a size of X x Y x Z x 3, the color dim is the last one
"""
function seg2rgb(seg::Segmentation)
    # the color dict, key is segment id, value is color
    dcol = Dict{UInt32, RGB{N0f8}}()
    # set the boundary color to be black
    dcol[0] = RGB{N0f8}(0,0,0)

    # create RGB image
    sx,sy,sz = size(seg)
    ret = Array(RGB{N0f8}, (sx,sy,sz))
    # assign random color
    for z = 1:sz
        for y = 1:sy
            for x = 1:sx
                key = seg[x,y,z]
                if !haskey(dcol, key)
                    dcol[key] = rand(RGB{N0f8})
                end
                ret[x,y,z] = dcol[key]
            end
        end
        ret[i] = dcol[key]
    end
    return ret
end

"""
overlay segmentation to gray image using Alpha compositing
https://en.wikipedia.org/wiki/Alpha_compositing
Inputs:
img: gray image array
seg: segmentation, an indexed array
alpha1: the alpha value of the image
alpha2: the alpha value of the segmentation

Outputs:
ret: composited RGBA image array
"""
function seg_overlay_img(img::Array{UInt8, 3}, seg::Array{Ts,3};
                            alpha1::Normed = NORMED8_HALF,
                            alpha2::Normed = NORMED8_HALF ) where Ts
    @assert size(img)==size(seg)
    @assert alpha1>0.0f0 && alpha1<1.0f0
    @assert alpha2>0.0f0 && alpha2<1.0f0

    # initialize the returned RGBA image
    # ret = Array{RGB{U8},3}(sx,sy,sz)
    ret = similar(img, RGB{U8})

    # colorful segmentation image
    cseg = seg2rgb(Segmentation(seg))

    # transform img to 0-1
    fimg = reinterpret(N0f8, img)
    fimg = ( fimg-minimum(fimg) ) ./ (maximum(fimg) - minimum(fimg))

    # Threads.@threads for z in 1:sz
    # # for z in 1:sz
    #     for y in 1:sy
    #         for x in 1:sx
    Threads.@threads for i in eachindex( img )
        if seg[i]==0x00000000
            ret[i] = RGB{U8}(fimg[i], fimg[i], fimg[i])
        else
            ret[i] = RGB{U8}(   (fimg[i]*alpha1 + cseg[i].r * alpha2*(NORMED8_ONE-alpha1) ) / (alpha1+alpha2*(NORMED8_ONE-alpha1)),
                                (fimg[i]*alpha1 + cseg[i].g * alpha2*(NORMED8_ONE-alpha1) ) / (alpha1+alpha2*(NORMED8_ONE-alpha1)),
                                (fimg[i]*alpha1 + cseg[i].b * alpha2*(NORMED8_ONE-alpha1) ) / (alpha1+alpha2*(NORMED8_ONE-alpha1)) )
        end
    end
    return ret
end

"""
transform segmentation to sgm by making fake mst
"""
function seg2segMST(seg::Segmentation)
    # making fake mst
    segmentPairs = zeros(UInt32, (1,2))
    segmentPairs[1] = seg[1]
    segmentPairs[2] = seg[end]
    segmentPairAffinities = Vector{Float32}( [0.001] )

    return SegMST(seg, segmentPairs, segmentPairAffinities)
end
seg2sgm = seg2segMST

end # end of module
