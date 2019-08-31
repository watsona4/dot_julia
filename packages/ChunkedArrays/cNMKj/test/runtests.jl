using ChunkedArrays
using Base.Test

tic()
u = [2 2
     2 2]

chunkRand = ChunkedArray(randn,float(u),10)

println(next(chunkRand))

chunkRand2 = ChunkedArray(randn,(3,3),100)

println(next(chunkRand2))

chunkRand3 = ChunkedArray(randn,100)

println(next(chunkRand3))

u = [2;2;2;2]
chunkRand4 = ChunkedArray(randn,float(u),10)
println(next(chunkRand4))

println("Random Generating Benchmark")
const loopSize = 1000
const buffSize = 100
const numRuns = 40

function test1()
  j=[0;0;0;0]
  for i = 1:loopSize
    j += randn(4)
  end
end

function test2()
  j=[0;0;0;0]
  chunks = 1000
  rands = randn(4,chunks)
  for k = 1:(loopSize÷chunks)
    rands[:] = randn(4,chunks)
    for i = 1:chunks
      j += rands[:,i]
    end
  end
end

function test3()
  j=[0;0;0;0]
  rands = randn(4,loopSize)
  for i = 1:loopSize
    j += rands[:,i]
  end
end

function test4()
  j=[0;0;0;0]
  chunks = 100
  rands = randn(4,chunks)
  for k = 1:(loopSize÷chunks)
    rands[:] = randn(4,chunks)
    for i = 1:chunks
      j += rands[:,i]
    end
  end
end

function test5()
  rands = randn(4,loopSize)
  j=[0;0;0;0]
  for i = 1:loopSize
    j += rands[:,i]
  end
end

const savedRands = randn(4,loopSize)
function test6()
  j=[0;0;0;0]
  for i = 1:loopSize
    j += savedRands[:,i]
  end
end

const chunkRands = ChunkedArray(randn,(4,),loopSize,parallel=false)
function test7()
  j=[0;0;0;0]
  for i = 1:loopSize
    j += next(chunkRands)
  end
end

function test8()
  rands2 = ChunkedArray(randn,(4,),buffSize,parallel=false)
  j=[0;0;0;0]
  for i = 1:loopSize
    j += next(rands2)
  end
end

function test9()
  rands3 = ChunkedArray(randn,(4,),loopSize,parallel=false)
  j=[0;0;0;0]
  for i = 1:loopSize
    j += rands3.randBuffer[i]
  end
end

function test10()
  rands4 = ChunkedArray(randn,(4,),loopSize,parallel=false)
  j=[0;0;0;0]
  for i = 1:loopSize
    j += next(rands4)
  end
end

function test11()
  rands5 = ChunkedArray(randn,(4,),buffSize,parallel=true)
  j=[0;0;0;0]
  for i = 1:loopSize
    j += next(rands5)
  end
end

t1 = @elapsed(for i=1:numRuns test1() end)/numRuns
t2 = @elapsed(for i=1:numRuns test2() end)/numRuns
t3 = @elapsed(for i=1:numRuns test3() end)/numRuns
t4 = @elapsed(for i=1:numRuns test4() end)/numRuns
t5 = @elapsed(for i=1:numRuns test5() end)/numRuns
t6 = @elapsed(for i=1:numRuns test6() end)/numRuns
t7 = @elapsed(for i=1:numRuns test7() end)/numRuns
t8 = @elapsed(for i=1:numRuns test8() end)/numRuns
t9 = @elapsed(for i=1:numRuns test9() end)/numRuns
t10= @elapsed(for i=1:numRuns test10() end)/numRuns
t11= @elapsed(for i=1:numRuns test11() end)/numRuns

println("""Test Results For Average Time:
One-by-one:                             $t1
Thousand-by-Thousand:                   $t2
Altogether:                             $t3
Hundred-by-hundred:                     $t4
Take at Beginning:                      $t5
Pre-made Rands:                         $t6
Chunked Rands Premade:                  $t7
Chunked Rands $buffSize buffer:              $t8
Chunked Rands Direct:                   $t9
Chunked Rands Max buffer:               $t10
Parallel Chunked Rands $buffSize buffer:     $t11
""")
toc()
