function download_dep(orig, dest, hash)
    dest_file = joinpath("data", dest)
    if isfile(dest_file)
        dest_hash = open(dest_file, "r") do f
            bytes2hex(sha256(f))
        end
        if dest_hash == hash
            return nothing
        end
    end
    mkpath("data")
    download(orig, dest_file)
    return nothing
end

@testset "reproject-core" begin
    download_dep("https://astropy.stsci.edu/data/galactic_center/gc_2mass_k.fits", "gc_2mass_k.fits",
                 "763ef344df3ac8fa80ff46f00ca1ec59946ca3f99502562d6fcfb73320b1cec3")
    download_dep("https://astropy.stsci.edu/data/galactic_center/gc_msx_e.fits", "gc_msx_e.fits",
                 "3687fb3763911825f981e74b6a9b82c0e618f7e592b1e0cb17e2c63164e28cd6")

    imgin = FITS(joinpath("data", "gc_msx_e.fits"))    # project this
    imgout = FITS(joinpath("data", "gc_2mass_k.fits")) # into this coordinate

    hdu1 = astropy.io.fits.open(joinpath("data", "gc_2mass_k.fits"))[1]
    hdu2 = astropy.io.fits.open(joinpath("data", "gc_msx_e.fits"))[1]

    @test isapprox(reproject(imgin, imgout, order = 0)[1]', rp.reproject_interp(hdu2, hdu1.header, order = 0)[1], nans = true, rtol = 1e-7)
    @test isapprox(reproject(imgout, imgin, order = 0)[1]', rp.reproject_interp(hdu1, hdu2.header, order = 0)[1], nans = true, rtol = 1e-6)
    @test isapprox(reproject(imgin, imgout, order = 1)[1]', rp.reproject_interp(hdu2, hdu1.header, order = 1)[1], nans = true, rtol = 1e-7)
    @test isapprox(reproject(imgin, imgout, order = 2)[1]', rp.reproject_interp(hdu2, hdu1.header, order = 2)[1], nans = true, rtol = 6e-2)
    @test isapprox(reproject(imgin[1], imgout[1], shape_out = (1000,1000))[1]',
            rp.reproject_interp(hdu2, astropy.wcs.WCS(hdu1.header), shape_out = (1000,1000))[1], nans = true, rtol = 1e-7)

    wcs = WCSTransform(2; ctype = ["RA---AIR", "DEC--AIR"], radesys = "UNK")
    @test_throws ArgumentError reproject(imgin, wcs, shape_out = (100,100))

    fname = tempname() * ".fits"
    f = FITS(fname, "w")
    inhdr = FITSHeader(["CTYPE1", "CTYPE2", "RADESYS", "FLTKEY", "INTKEY", "BOOLKEY", "STRKEY", "COMMENT",
                        "HISTORY"],
                       ["RA---TAN", "DEC--TAN", "UNK", 1.0, 1, true, "string value", nothing, nothing],
                       ["",
                        "",
                        "",
                        "floating point keyword",
                        "",
                        "boolean keyword",
                        "string value",
                        "this is a comment",
                        "this is a history"])

    indata = reshape(Float32[1:100;], 5, 20)
    write(f, indata; header=inhdr)
    @test_throws ArgumentError reproject(f[1], imgin, shape_out = (100,100))
    close(f)
end
