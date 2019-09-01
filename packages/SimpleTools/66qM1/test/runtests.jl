using Test
using SimpleTools

sq = Dict{Int,Int}()
for k=1:10
    sq[k] = k*k
end

rt = Dict{Int,Int}()
for k=1:10
    rt[k*k] = k
end

f = rt*sq
for k=1:10
    @test f[k] == k
end


y1 = [x^2 for x=0:.01:3]
y2 = [mod(y,1) for y in y1 ]
make_continuous!(y2,1)
@test y1==y2

@test flush_print(23,5) == "   23"
@test flush_print(23,5,false) == "23   "
