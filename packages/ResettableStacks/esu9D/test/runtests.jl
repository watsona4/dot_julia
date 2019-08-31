using ResettableStacks
using Test
using Random

S = ResettableStack{}(Tuple{Float64,Float64,Float64})

push!(S,(0.5,0.4,0.3))
push!(S,(0.5,0.4,0.4))
reset!(S)
push!(S,(0.5,0.4,0.3))
@test S.data[1] == (0.5,0.4,0.3)

S = ResettableStack{}(Float64)
for i=1:10
  push!(S,i)
end
@test pop!(S) == 10

### Iterator tests
s = ResettableStacks.ResettableStack{}(Float64)
Random.seed!(100)
for i in 1:6
  push!(s,rand())
end
for (i,c) in enumerate(s)
  @test i==1 ? c == 0.6456910432314067 : true
  @test i==2 ? c == 0.9675998379215747 : true
  @test i==3 ? c == 0.06719317094984745 : true
  @test i==4 ? c == 0.6609109399808133 : true
  @test i==5 ? c == 0.19031281518127185 : true
  @test i==6 ? c == 0.2601250914736861 : true
end
reset!(s)
push!(s,rand())
for c in s
  @test c==0.5459681993995775
end
