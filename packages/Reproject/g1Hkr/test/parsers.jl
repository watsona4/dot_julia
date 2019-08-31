using Reproject: parse_input_data, parse_output_projection
@testset "input parser" begin
    fname = tempname() * ".fits"
    f = FITS(fname, "w")
    inhdr = FITSHeader(["FLTKEY", "INTKEY", "BOOLKEY", "STRKEY", "COMMENT",
                        "HISTORY"],
                       [1.0, 1, true, "string value", nothing, nothing],
                       ["floating point keyword",
                        "",
                        "boolean keyword",
                        "string value",
                        "this is a comment",
                        "this is a history"])

    indata = reshape(Float32[1:100;], 5, 20)
    write(f, indata; header=inhdr)

    @testset "ImageHDU type" begin
        result = parse_input_data(f[1])
        @test result[1] isa Array
        @test result[2] isa WCSTransform
    end

    @testset "data matrix and WCSTransform tuple" begin
        wcs = WCSTransform(2;
                          cdelt = [-0.066667, 0.066667],
                          ctype = ["RA---AIR", "DEC--AIR"],
                          crpix = [-234.75, 8.3393],
                          crval = [0., -90],
                          pv    = [(2, 1, 45.0)])
        result = parse_input_data((indata, wcs))
        @test result[1] isa Array
        @test result[2] isa WCSTransform
    end

    @testset "Single HDU FITS file" begin
        result = parse_input_data(f, 1)
        @test result[1] isa Array
        @test result[2] isa WCSTransform
    end
    close(f)

    @testset "String filename input" begin
        result = parse_input_data(fname, 1)
        @test result[1] isa Array
        @test result[2] isa WCSTransform
    end

    f = FITS(fname, "w")
    write(f, indata; header=inhdr)
    write(f, indata; header=inhdr)

    @testset "Multiple HDU FITS file" begin
        result = parse_input_data(f, 2)
        @test result[1] isa Array
        @test result[2] isa WCSTransform

        close(f)
        result = parse_input_data(fname, 1)
        @test result[1] isa Array
        @test result[2] isa WCSTransform
    end
end

@testset "output parser" begin
    fname = tempname() * ".fits"
    f = FITS(fname, "w")
    inhdr = FITSHeader(["FLTKEY", "INTKEY", "BOOLKEY", "STRKEY", "COMMENT",
                        "HISTORY"],
                       [1.0, 1, true, "string value", nothing, nothing],
                       ["floating point keyword",
                        "",
                        "boolean keyword",
                        "string value",
                        "this is a comment",
                        "this is a history"])

    indata = reshape(Float32[1:100;], 5, 20)
    write(f, indata; header=inhdr)

    @testset "ImageHDU type" begin
        result = parse_output_projection(f[1], (12,12))
        @test result[1] isa WCSTransform
        @test result[2] isa Tuple
        @test_throws DomainError parse_output_projection(f[1], ())
    end
    close(f)

    @testset "String filename" begin
        result = parse_output_projection(fname, 1)
        @test result[1] isa WCSTransform
        @test result[2] isa Tuple
    end

    wcs = WCSTransform(2;
                          cdelt = [-0.066667, 0.066667],
                          ctype = ["RA---AIR", "DEC--AIR"],
                          crpix = [-234.75, 8.3393],
                          crval = [0., -90],
                          pv    = [(2, 1, 45.0)])

    @testset "WCSTransform input" begin
        result = parse_output_projection(wcs, (12,12))
        @test result[1] isa WCSTransform
        @test result[2] isa Tuple
        @test_throws DomainError parse_output_projection(wcs, ())
    end
end
