using Reproject: wcs_to_celestial_frame
@testset "wcs to celestial frame" begin
    wcs1 = WCSTransform(2;
                       ctype = ["RA---AIR", "DEC--AIR"],
                       )
    wcs2 = WCSTransform(2;
                       ctype = ["RA---AIR", "DEC--AIR"],
                       equinox = 1888.67
                       )
    wcs3 = WCSTransform(2;
                       ctype = ["RA---AIR", "DEC--AIR"],
                       equinox = 2000
                       )
    wcs4 = WCSTransform(2;
                       ctype = ["GLON--", "GLAT--"],
                       )
    wcs5 = WCSTransform(2;
                       ctype = ["TLON", "TLAT"],
                      )
    wcs6 = WCSTransform(2;
                       ctype = ["RA---AIR", "DEC--AIR"],
                       radesys = "UNK"
                      )

    @test wcs_to_celestial_frame(wcs1) == "ICRS"
    @test wcs_to_celestial_frame(wcs2) == "FK4"
    @test wcs_to_celestial_frame(wcs3) == "FK5"
    @test wcs_to_celestial_frame(wcs4) == "Gal"
    @test wcs_to_celestial_frame(wcs5) == "ITRS"
    @test wcs_to_celestial_frame(wcs6) == "UNK"
end
