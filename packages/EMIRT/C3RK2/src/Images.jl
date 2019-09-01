module Images

using ..Types
using ..Domains
export normalize2d, normalize_serial, image2mask

"""
2D normalization.

I = (I - mean(I)) ./ std(I)

I is a 2D section.
"""
function normalize2d( img::EMImage )
    sx,sy,sz = size(img)
    ret = Array(Float32, (sx,sy,sz))
    gc_enable(false)
    Threads.@threads for z in 1:sz
        ret[:,:,z] = Array{Float32, 2}(img[:,:,z]) ./ 256f0
        ret[:,:,z] = (ret[:,:,z].-mean(ret[:,:,z])) ./ std(ret[:,:,z])
    end
    gc_enable(true)
    ret
end

function normalize2d_serial( img::EMImage )
    sx,sy,sz = size(img)
    ret = zeros(Float32, (sx,sy,sz))
    for z in 1:sz
        ret[:,:,z] = Array{Float32, 2}(img[:,:,z]) ./ 256f0
        ret[:,:,z] = (ret[:,:,z].-mean(ret[:,:,z])) ./ std(ret[:,:,z])
    end
    ret
end

"""
find mask regions.
the thresholds are inclusive.
"""
function image2mask(    img::EMImage;
                        threshold::UInt8=0x01,
                        sizeThreshold::UInt32=UInt32(400) )

    mask = (img .<= threshold )

    for z in 1:size(mask, 3)
        _sizefilter!(mask[:,:,z]; sizeThreshold=sizeThreshold)
    end
    return mask
end

function _sizefilter!(mask::BitArray{2}; sizeThreshold::UInt32=UInt32(400))
    sy, sx = size(mask)
    sy = UInt32(sy)
    sx = UInt32(sx)
    # disjoint set
    disjointSets = Tdjsets(UInt32(length(mask)))

    # y affinity
    for y in 0x00000002:sy
        for x in 0x00000001:sx
            if mask[x,y]==true && mask[x,y-0x00000001]==true
                vid1 = (y-0x00000001)*sy + x
                vid2 = (y-0x00000002)*sy + x
                union!(disjointSets, vid1, vid2)
            end
        end
    end

    # x affinity
    for y in 0x00000001:sy
        for x in 0x00000002:sx
            if mask[x,y]==true && mask[x-0x00000001,y]==true
                vid1 = (y-0x00000001)*sy + x
                vid2 = (y-0x00000001)*sy + x - 0x00000001
                union!(disjointSets, vid1, vid2)
            end
        end
    end

    # mark all the branches to root id.
    setallroot!(disjointSets)

    # remove all the small regions
    for i in eachindex(mask)
        if mask[i] && disjointSets.setsz[ i ] < sizeThreshold
            mask[i] = false
        end
    end
end

end # end of module
