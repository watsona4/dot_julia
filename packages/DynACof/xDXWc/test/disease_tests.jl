using DynACof
using Test
using DataFrames

@testset "ALS()" begin
    df_rain= DataFrame(DOY= repeat(1:365,2), year= repeat(2018:2019,inner= 365), Rain= fill(1.0, 730))
    @test ALS(Elevation = 1000.0, df_rain= df_rain)[5] ≈ 0.002264741845695504
end;

