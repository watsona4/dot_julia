using HDF5
using FileIO
using Formatting

# interprete argument
srcDir = ARGS[1]
dstFile = ARGS[2]

# parameters


# read images
aff = zeros(Float32, (1600,1600,107,3))

lst_fname = readdir(srcDir)

for c in 1:3
    for z in 1:107
	info("section $z")
	#fname = joinpath(srcDir, "c$(format(c-1, width=5, zeropadding=true))_z$(format(z-1, width=5, zeropadding=true))_y20000_x17000.tiff")
        fname = joinpath(srcDir, "c$(format(c-1, width=1, zeropadding=true))_z$(format(z-1, width=5, zeropadding=true)).tiff")
        aff2d = Array{Float32,2}( load(fname).data )
        # transpose the image for tif loading
        #aff2d = permutedims(aff2d, [2,1])
        # also swap the x and y channel
        aff[:,:,z,c] = aff2d
    end
end

# correct the affinity definition
sx,sy,sz,sc = size(aff)
aff[2:sx, :, :, 1] = aff[1:sx-1, :, :, 1]
aff[:, 2:sy, :, 2] = aff[:, 1:sy-1, :, 2]
aff[:, :, 2:sz, 3] = aff[:, :, 1:sz-1, 3]

# write result
h5write(dstFile, "main", aff)
