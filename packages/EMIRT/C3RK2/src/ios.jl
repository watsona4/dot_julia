module IOs

using ..Types
using HDF5
import FileIO

#import FileIO: save

export imread, imsave, readimg, saveimg, readseg, saveseg, readaff, saveaff
export issgmfile, readsgm, savesgm, readec, saveec, readecs, saveecs, save

function imread(fname::AbstractString)
    print("reading file: $(fname) ......")
    if ishdf5(fname)
        ret =  h5read(fname, "/main")
        println("done :)")
        return ret
    else
        # handled by FileIO
        return FileIO.load(fname)
    end
end


function imsave(fname::AbstractString, vol::Array, is_overwrite=true)
    print("saving file: $(fname); ......")
    # remove existing file
    if isfile(fname) && is_overwrite
        rm(fname)
    end

    if contains(fname, ".h5") || contains(fname, ".hdf5")
        h5write(fname, "/main", vol)
    else
        # handled by FileIO
        FileIO.save(fname, vol)
    end
    println("done!")
end


"""
read raw image
"""
function readimg(fimg::AbstractString)
    if ishdf5(fimg)
        f = h5open(fimg)
        if has(f, "img")
          img = read(f["img"])
        elseif has(f, "image")
          img = read(f["image"])
        else
          img = read(f["main"])
        end
        close(f)
    else
        img = reinterpret(UInt8, load(fimg).data)
        if contains(fimg, ".tif")
            # transpose the X and Y
            perm = Vector{Int64}( 1:ndims(img) )
            perm[1:2] = [2,1]
            img = permutedims(img, perm)
        end
    end
    return img
end

"""
save raw image
"""
function save(fimg::AbstractString, img::EMImage, dname::AbstractString="image")
    if isfile(fimg)
        rm(fimg)
    end
    f = h5open(fimg, "w")
    f[dname,"chunk", (8,8,2), "shuffle", (), "deflate", 3] = img
    close(f)
end

function saveimg(fimg::AbstractString, img::EMImage, dname::AbstractString="image")
    save(fimg, img, dname)
end

"""
permute dims of x and y for tif images
"""
function permutetifdims!(arr::Array)
    # transpose the X and Y
    p = Vector{Int64}( 1:ndims(arr) )
    p[1] = 2
    p[2] = 1
    arr = permutedims(arr, p)
    arr
end

"""
read segmentation
for directory, currently only tested with VAST output
"""
function readseg(fseg::AbstractString)
    if isdir(fseg)
        error("reading from directory is not correct now.")
        files_all = readdir(fseg)
        # only collect the tif images
        files = Vector{eltype(files_all)}()
        # get full path
        for file in files_all
            if contains(file,".tif")
                push!(files, joinpath(fseg, file))
            end
        end
        @assert length(files) > 0
        # read one tif and get size
        sz = length(files)
        image2d = load(files[1])
        if contains(image2d.properties["colorspace"], "RGB")
            tmp = reinterpret(UInt8, image2d.data)
            sc,sx,sy = size(tmp)
            seg = zeros(UInt32, (sx,sy,sz))
            for z in 1:sz
                tmp = reinterpret(UInt8, load(files[z]).data)
                tmp = Array{UInt32, 3}(tmp)
                im = tmp[1,:,:] .* 256 .* 256 + tmp[2,:,:] .* 256 + tmp[3,:,:]
                seg[:,:,z] = reshape(im,(sx,sy))
            end
        else
            tmp = reinterpret(UInt32, image2d.data)
            sx,sy = size(tmp)
            seg = zeros(UInt32,(sx,sy,sz))
            for z in 1:sz
                seg[:,:,z] = reinterpret(UInt32, load(files[z]).data)
            end
        end
        seg = permutetifdims!(seg)
    elseif ishdf5(fseg)
        f = h5open(fseg)
        if has(f, "seg")
          seg = read(f["seg"])
        elseif has(f, "segmentation")
          seg = read(f["segmentation"])
        else
          @assert has(f, "main")
          seg = read(f["main"])
        end
        close(f)
    elseif contains(fseg, ".tif")
        error("reading tif is not correct now..")
        image = load(fseg)
        if contains( image.properties["colorspace"], "RGB")
            tmp = reinterpret(UInt8,image.data)
            tmp = Array{UInt32, 4}(tmp)
            sc,sx,sy,sz = size(tmp)
            seg = tmp[1,:,:,:] .* 256 .* 256 + tmp[2,:,:,:] .* 256 + tmp[3,:,:,:]
            seg = reshape(seg, (sx,sy,sz))
        else
            seg = reinterpret(UInt32, image.data)
        end
        seg = permutetifdims!(seg)
    else
        error("unsupported file format!")
    end
    return Segmentation(seg)
end

"""
"""
function save(fseg::AbstractString, seg::Segmentation, dname::AbstractString="segmentation")
    if isfile(fseg)
        rm(fseg)
    end
    f = h5open(fseg, "w")
    f[dname,"chunk", (8,8,2), "shuffle", (), "deflate", 3] = seg
    close(f)
end

function saveseg(fseg::AbstractString, seg::Segmentation, dname::AbstractString="segmentation")
    save(fseg,seg, dname)
end

"""
read affinity map
"""
function readaff(faff::AbstractString)
    f = h5open(faff)
    if has(f, "aff")
      aff = read(f["aff"])
    elseif has(f, "affinityMap")
      aff = read(f["affinityMap"])
    else
      @assert has(f, "main")
      aff = read(f["main"])
    end
    close(f)
    return AffinityMap(aff)
end

"""
save affinity map
"""
function save(faff::AbstractString, aff::AffinityMap, dname::AbstractString="affinityMap")
    if isfile(faff)
        rm(faff)
    end
    f = h5open(faff, "w")
    f[dname,"chunk", (8,8,2,3), "shuffle", (), "deflate", 3] = aff
    close(f)
end

function saveaff(faff::AbstractString, aff::AffinityMap, dname::AbstractString="affinityMap")
    save(faff, aff, dname)
end

"""
whether a file is a sgm file
if the file do not exist, reture false
"""
function issgmfile(fname::AbstractString)
    if !isfile(fname)
        return false
    else
        f = h5open(fname)
        if has(f, "segmentPairs") || has(f, "segmentPair")
            return true
        else
            return false
        end
        close(f)
    end
end

"""
read segmentation with maximum spanning tree
"""
function readsgm(fname::AbstractString)
    f = h5open(fname)
    if has(f, "seg")
      seg = read(f["seg"])
      segmentPairs = read(f["segmentPairs"])
      segmentPairAffinities = read(f["segmentPairAffinities"])
    elseif has(f, "segmentation")
      seg = read(f["segmentation"])
      segmentPairs = read(f["segmentPairs"])
      segmentPairAffinities = read(f["segmentPairAffinities"])
    else
      @assert has(f, "main")
      seg = read(f["main"])
      segmentPairs = read(f["segmentPairs"])
      segmentPairAffinities = read(f["segmentPairAffinities"])
    end
    close(f)
    return SegMST(seg, segmentPairs, segmentPairAffinities)
end

"""
save segmentation with segmentPairsrogram
"""
function save(fsgm::AbstractString, sgm::SegMST)
    f = h5open(fsgm, "w")
    f["segmentation", "chunk", (64,64,8), "shuffle", (), "deflate", 3] = sgm.segmentation
    f["segmentPairs"] = sgm.segmentPairs
    f["segmentPairAffinities"] = sgm.segmentPairAffinities
    close(f)
end
function save(fsgm::AbstractString, seg::Segmentation, segmentPairs::SegmentPairs, segmentPairAffinities::SegmentPairAffinities)
    savesgm( fsgm, SegMST(seg,segmentPairs,segmentPairAffinities) )
end

function savesgm(fsgm::AbstractString, sgm)
    save(fsgm, sgm)
end

end # end of module
