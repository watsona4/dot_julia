using H5SectionsArrays
using HDF5
using Base.Test

a = rand(UInt8, 200,200,3)

# create a fake dataset
tempDir = tempname()
mkdir( tempDir )

open(joinpath(tempDir, "registry.txt"), "w") do f_registry 
    for z in 1:size(a,3)
        write(f_registry, "1,$(z)_aligned 0 100 -100 200 200 true \n")
        f = h5open(joinpath(tempDir, "1,$(z)_aligned.h5"), "w")
        f["img"] = a[:,:,z]
        f["offset"] = [100,-100]
        f["size"] = [200,200]
        close(f)
    end 
end 

@testset "test cutout" begin 
    # cutout the chunk
    ba = H5SectionsArray(tempDir)
    b = ba[101:300, -99:100, 1:3]

    @test all(a.==b)

    # clean it up
    rm(tempDir; recursive=true)

end 
