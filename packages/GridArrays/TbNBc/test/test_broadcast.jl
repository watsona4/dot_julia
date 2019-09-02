

using DomainSets, GridArrays, Base.Broadcast, Test

@testset "broadcast" begin

    broadcast(in, PeriodicEquispacedGrid(10,-1,1) , UnitInterval()) == [i> 5 for i in 1:10]

    uniondomain = UnionDomain(0.0..0.1,0.5..1.0)
    @test broadcast(in, PeriodicEquispacedGrid(10,-1,1) , uniondomain) == [6<=i<=6 || 9<=i<=10 for i in 1:10]

    intersectdomain = IntersectionDomain(-1.0..0.1,0.0..1.0)
    @test broadcast(in, PeriodicEquispacedGrid(10,-1,1) , intersectdomain) == [i==6 for i in 1:10]

    diffdomain = DifferenceDomain(-1.0..0.1,0.0..1.0)
    @test broadcast(in, PeriodicEquispacedGrid(10,-1,1) , diffdomain) == [i<6 for i in 1:10]
end
