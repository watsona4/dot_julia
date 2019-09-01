module Evaluate

using HDF5
using ..Types
using ..AffinityMaps 
using ..Segmentations 
using ..Domains
using Distributed 

export evaluate, evaluate_by_patch

function evaluate(seg::Array, lbl::Array, is_fr::Bool=true, is_selfpair::Bool=true)
    ret = Dict{Symbol, Float32}()
    # overlap matrix reprisented by dict
    om = Dict{Tuple{UInt32,UInt32},Float32}()
    si = Dict{UInt32,Float32}()
    li = Dict{UInt32,Float32}()

    # number of voxels
    N = Float32(0)
    for iter in eachindex(lbl)
        lid = lbl[iter]
        # foreground restriction
        if is_fr && (lid == 0)
            continue
        end
        N += 1
        if haskey(li, lid)
            li[lid] += 1
        else
            li[lid] = 1
        end

        sid = seg[iter]
        if haskey(si, sid)
            si[sid] += 1
        else
            si[sid] = 1
        end

        if haskey(om, (sid,lid))
            om[(sid,lid)] += 1
        else
            om[(sid,lid)] = 1
        end
    end

    # compute the errors
    if is_selfpair
        ssum  = sum(pmap(x->x*x/2, values(si)))
        lsum  = sum(pmap(x->x*x/2, values(li)))
        TP = sum(pmap(x->x*x/2, values(om)))
        # total number of voxel pair
        Np = N*N/2

        # information theory metrics
        HS = - sum( pmap(x->x/N*Base.log(x/N), values(si)) )
        HT = - sum( pmap(x->x/N*Base.log(x/N), values(li)) )
        HST = Float32(0)
        HTS = Float32(0)
        IST = Float32(0)
        # i = UInt32(0); j = UInt32(0); v = Float32(0);
        # HST = @parallel (-) for ((i, j),v) in om
        #     v/Np * log( v/li[j] )
        # end

        # HTS = @parallel (-) for ((i, j),v) in om
        #     v/Np * log( v/si[i] )
        # end

        # IST = @parallel (+) for ((i, j),v) in om
        #     v/Np * log( v*Np / ( si[i] * li[j] ) )
        # end

        for ((i::UInt32, j::UInt32),v::Float32) in om
            # segment id pair
            pij = v / N
            HTS -= pij * Base.log( v / si[i] )
            HST -= pij * Base.log( v / li[j] )
            IST += pij * Base.log( v * N / (si[i] * li[j]) )
        end
        ret[:VI] = HS + HT - 2*IST
        ret[:VIs] = HST
        ret[:VIm] = HTS
        ret[:VIS] = - ret[:VI]
        ret[:VIFSs] = IST / HS
        ret[:VIFSm] = IST / HT
        ret[:VIFS] = 2*IST / (HT + HS)
    else
        ssum  = sum(pmap(x->x*(x-1)/2, values(si)))
        lsum  = sum(pmap(x->x*(x-1)/2, values(li)))
        TP = sum(pmap(x->x*(x-1)/2, values(om)))
        # total number of voxel pair
        Np = Float32( N*(N-1)/2 )
    end
    FP = ssum - TP
    FN = lsum - TP
    TN = Np - TP - FP - FN

    # rand error
    ret[:res] = FN / Np
    ret[:rem] = FP / Np
    ret[:re] = ret[:rem] + ret[:res]
    # rand index
    ret[:ris] = TN / Np
    ret[:rim] = TP / Np
    ret[:ri] = ret[:rim] + ret[:ris]

    # rand f score
    ret[:rfs] = TP / (TP + FN)
    ret[:rfm] = TP / (TP + FP)
    ret[:rf] = 2*TP / (2*TP + FP + FN)
    return ret
end

"""
patch-based segmentation error
`Inputs`
`seg`: segmentation, indexed array
`lbl`: ground true label, indexed array
`ptsz`: patch size

`Outputs`
`ri`: rand index
`rim`: rand index of mergers
`ris`: rand index of splitters
`rf`: rand f score
`rfm`: rand f score of mergers
`rfs`: rand f score of splitters
"""
function evaluate_by_patch(seg_in, lbl_in, ptsz=[100,100,1], step=[100,100,1])
    @assert size(seg_in)==size(lbl_in)
    # @assert Tuple(ptsz) < size(seg)

    if ndims(seg_in)==2
        sx,sy = size(seg_in)
        sz = 1
        seg = reshape(seg_in, (sx,sy,sz))
        lbl = reshape(lbl_in, (sx,sy,sz))
    else
        sx,sy,sz = size(seg_in)
        seg = seg_in
        lbl = lbl_in
    end

    # initialize the evaluate result dict
    ret = Dict{Symbol, Float32}()
    ret[:ri] = 0;   ret[:ris] = 0;   ret[:rim] = 0;
    ret[:rf] = 0;   ret[:rfs] = 0;   ret[:rfm] = 0;
    ret[:VIFS] = 0; ret[:VIFSs] = 0; ret[:VIFSm] = 0;

    # number of patches
    Np = 0
    # the patch-based errors
    pri = 0; prim = 0; pris = 0;
    prf = 0; prfm = 0; prfs = 0;
    # get patches and measure
    for z1 in 1:step[3]:sz
        for y1 in 1:step[2]:sy
            for x1 in 1:step[1]:sx
                # get patch
                z2 = z1+ptsz[3]-1
                if z2 > sz
                    z2 = sz
                    z1 = z2 - ptsz[3] + 1
                end

                y2 = y1+ptsz[2]-1
                if y2 > sy
                    y2 = sy
                    y1 = y2 - ptsz[2] + 1
                end

                x2 = x1+ptsz[1]-1
                if x2 > sx
                    x2 = sx
                    x1 = x2 - ptsz[1] + 1
                end
                # patch of seg and lbl
                pseg = seg[x1:x2,y1:y2,z1:z2]
                plbl = lbl[x1:x2,y1:y2,z1:z2]
                # compute the error
                ed = segerror(pseg, plbl)
                # increas the errors
                for k in keys(ret)
                    ret[k] += ed[k]
                end
                # increase the number of patches
                Np += 1
            end
        end
    end
    # normalize across all the patches
    for k in keys(ret)
        ret[k] /= Np
    end
    return ret
end

end # end of module
