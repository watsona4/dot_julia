using GrowableArrays, EllipsisNotation

using Test


const NUM_RUNS = 100
const PROBLEM_SIZE = 1000
function test1()
  u =    [1 2 3 4
          1 3 3 4
          1 5 6 3
          5 2 3 1]

  uFull = u
  for i = 1:PROBLEM_SIZE
    uFull = hcat(uFull,u)
  end
  uFull
end

function test2()
  u =    [1 2 3 4
          1 3 3 4
          1 5 6 3
          5 2 3 1]

  uFull = u

  for i = 1:PROBLEM_SIZE
    uFull = vcat(uFull,u)
  end
  uFull
end

function test3()
  u =    [1 2 3 4
          1 3 3 4
          1 5 6 3
          5 2 3 1]

  uFull = Vector{Int}(undef, 0)
  sizehint!(uFull,PROBLEM_SIZE*16)
  append!(uFull,vec(u))

  for i = 1:PROBLEM_SIZE
    append!(uFull,vec(u))
  end
  reshape(uFull,4,4,PROBLEM_SIZE+1)
  uFull
end

function test4()
  u =    [1 2 3 4
          1 3 3 4
          1 5 6 3
          5 2 3 1]

  uFull = Vector{Array{Int}}(undef, 0)
  push!(uFull,copy(u))

  for i = 1:PROBLEM_SIZE
    push!(uFull,copy(u))
  end
  uFull
end

function test5()
  u =    [1 2 3 4
          1 3 3 4
          1 5 6 3
          5 2 3 1]

  uFull = Vector{Array{Int,2}}(undef, 0)
  push!(uFull,copy(u))

  for i = 1:PROBLEM_SIZE
    push!(uFull,copy(u))
  end
  uFull
end

function test6()
  u =    [1 2 3 4
          1 3 3 4
          1 5 6 3
          5 2 3 1]

  uFull = Vector{typeof(u)}(undef, 0)
  push!(uFull,u)

  for i = 1:PROBLEM_SIZE
    push!(uFull,copy(u))
  end
  uFull
end

function test7()
  u =    [1 2 3 4
          1 3 3 4
          1 5 6 3
          5 2 3 1]

  uFull = GrowableArray(u)
  for i = 1:PROBLEM_SIZE
    push!(uFull,u)
  end
  uFull
end

function test8()
  u =    [1 2 3 4
          1 3 3 4
          1 5 6 3
          5 2 3 1]

  uFull = GrowableArray(u)
  sizehint!(uFull,PROBLEM_SIZE)
  for i = 1:PROBLEM_SIZE
    push!(uFull,u)
  end
  uFull
end

println("Run Benchmarks")
println("Pre-Compile")
#Compile Test Functions
test1()
test2()
test3()
test4()
test5()
test6()
test7()
test8()

println("Running Benchmarks")
t1 = @elapsed for i=1:NUM_RUNS test1() end
t2 = @elapsed for i=1:NUM_RUNS test2() end
t3 = @elapsed for i=1:NUM_RUNS test3() end
t4 = @elapsed for i=1:NUM_RUNS test4() end
t5 = @elapsed for i=1:NUM_RUNS test5() end
t6 = @elapsed for i=1:NUM_RUNS test6() end
t7 = @elapsed for i=1:NUM_RUNS test7() end
t8 = @elapsed for i=1:NUM_RUNS test8() end

println("Benchmark results: $t1 $t2 $t3 $t4 $t5 $t6 $t7 $t8")
println("Note the overhead of building the type before the loop for small runs")
A = [1 2; 3 4]
B = [1 2; 4 3]
G = GrowableArray(A)
push!(G,A)
push!(G,2*A)
push!(G,3*A)
@test begin
  Garr = copy(G) #Should change it to a regular array
  typeof(Garr)<:AbstractArray{Int,3}
end

# G2 = GrowableArray(1)
# push!(G2,4)
# G2[2] = 3
# G2[4,..] = 3
# @test G[4] == 12
# @test reshape(G[4,..],2,2) == B #This acts as a standard array
u =  Float64[1 2 3 4
             1 3 3 4
             1 5 6 3
             5 2 3 1]

uFull = Vector{Array{Float64,2}}(undef, 0)
push!(uFull,u)

let u = u
for i = 1:100
  u = 1.13 .* u
  push!(uFull,u)
end
end

S = StackedArray(uFull)
K = S[1,..] + S[3,..]
Sarr = copy(S)
@test typeof(Sarr)<:AbstractArray{Float64,3}
