using DynACof
using Test


@testset "G_bulk()" begin
    @test G_bulk(Wind=3.0,ZHT=25.0,Z_top=24.0,LAI = 0.5,extwind = 0.58) ≈ 1.046699012544253
    @test G_bulk(Wind=0.1,ZHT=25.0,Z_top=24.0,LAI = 0.5,extwind = 0.58) ≈ 0.038588757824484766
end;

@testset "Gb_h()" begin
    @test Gb_h(Wind=3.0,wleaf=0.068,LAI_lay=4.0,LAI_abv=0.5,ZHT=25.0,Z_top=24.0,extwind=0.58) ≈ 0.030912386407977912
    @test Gb_h(Wind=3.0,wleaf=0.068,LAI_lay=1.0,LAI_abv=1.0,ZHT=25.0,Z_top=24.0,extwind=0.58) ≈ 0.041312162916086664
end;

@testset "GetWind()" begin
    @test GetWind(Wind=3.0,LAI_lay=4.0,LAI_abv=0.3,extwind= 0.58,Z_top = 24.0,ZHT = 25.0) ≈ 0.7297130944647338
    @test GetWind(Wind=3.0,LAI_lay= 2.0,LAI_abv=5.0,extwind= 0.58,Z_top = 24.0,ZHT = 25.0) ≈ 0.08534069619361286
end;

@testset "G_soilcan()" begin
    @test G_soilcan(Wind= 1.0, ZHT= 25.0, Z_top= 24.0,LAI= 4.5, extwind= 0.58) ≈ 1.1728894648078738
end;

@testset "G_interlay()" begin
    @test G_interlay(Wind = 3.0,ZHT = 25.0,Z_top = 2.0,LAI_top = 0.5,LAI_bot = 4.0) ≈ 0.10995838732573818
end;