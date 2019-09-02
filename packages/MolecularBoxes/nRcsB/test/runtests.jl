
using MolecularBoxes

using Test
using StaticArrays

#a 3D vector for testing
const Vec = SVector{3,Float64}

const BoxV =  Box{Vec,3,(true,true,true)}

@testset "Test Box constructor" begin
    vectors  = ( Vec(3,0,0),
                 Vec(0,4,0),
                 Vec(0,0,5))
    avectors = ([3.,0.,0.],
                [0.,4.,0.],
                [0.,0.,5.])
    ppp = (true,true,true)
    pp = (true,true)
    @test Box{Vec,3,ppp}(vectors) != nothing
    box = BoxV(vectors) 
    @test_throws MethodError Box{Vec,2,ppp}(vectors)
    @test_throws ErrorException Box{Vec,3,pp}(vectors)
    @test_throws ErrorException Box{Vec,3,ppp}((
        Vec(1,1,0),
        Vec(0,2,0),
        Vec(0,0,3),
    ))

    @test BoxV(vectors) == Box(Vec(3,4,5))

end

@testset "Test getters" begin
    p = (true,false,true)
    vectors  = (
        Vec(3,0,0),
        Vec(0,4,0),
        Vec(0,0,5),
    )
    box = Box{Vec,3,p}(vectors)
    @test isperiodic(box) == p
    @test box.vectors == vectors
    @test box.lengths == convert(Vec, collect(vectors[i][i] for i in 1:3) )
end


lengths = Vec(3,4,5)
hi = lengths

box = Box(lengths, periodic=(true,true,true))
boxpfp = Box(lengths, periodic=(true,false,true))
boxppf = Box(lengths, periodic=(true,true,false))

v = Vec(-1,3,8)
v1 = Vec(0.5,1,1)
v2 = lengths+Vec(-0.5,-1,-1)

@testset "test dimensions/coordinates access functions" begin
    @test box.lengths == lengths
end

@testset "Test separation" begin
    @test separation(v1,v2,box) == Vec(1,-2,2)
    @test separation(v1,v2,boxppf) == Vec(1,-2,-3)
    @test separation(v2,v1,boxppf) == Vec(-1,-2, 3)
    #@pending separation(need,more,tests) --> Vec(x,x,x)
    # especially for boundary cases
end

@testset "Test centre-of-mass calculation" begin
    @test center_of_mass([v1,v2], box) == Vec(3,2,5)
    @test center_of_mass([v1,v2], box, weights = [2.0, 2.0]) == Vec(3,2,5)
    # could user a better test of weights
    @test_throws ErrorException center_of_mass([v1,v2], boxpfp)
end
   

