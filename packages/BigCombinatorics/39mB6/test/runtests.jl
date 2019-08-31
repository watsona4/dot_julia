using BigCombinatorics
using Test

@test Fibonacci(10)==Fibonacci(9)+Fibonacci(8)

@test Factorial(10)==big(factorial(10))

@test FallingFactorial(10,3) == 10*9*8
@test FallingFactorial(10,10) == Factorial(10)
@test FallingFactorial(10,12) == 0

@test RisingFactorial(10,3) == 10*11*12

@test DoubleFactorial(9) == 9*7*5*3
@test DoubleFactorial(10) == 10*8*6*4*2

@test Catalan(12) == 208012

@test Derangements(1) == 0
@test Derangements(12) == 176214841

@test MultiChoose(10,1) == 10
@test MultiChoose(10,0) == 1
@test MultiChoose(10,10) == 92378

@test Multinomial(5,5,5) == div(Factorial(15), Factorial(5)^3)
@test Multinomial([6,6,6,6]) == Multinomial(6,6,6,6)

@test Bell(10)==115975
@test sum(Stirling2(10,k) for k=0:10) == Bell(10)
@test Stirling1(10,10) == 1
@test Stirling1(10,0) == 0
@test sum(Stirling1(10,k) for k=0:10) == 0

@test IntPartitions(10) == 42
@test IntPartitionsDistinct(10) == 10

@test Euler(12) == 2702765

@test PowerSum(10,3) == sum(k^3 for k=1:10)

@test BigCombinatorics.cache_clear(Fibonacci)

@test sum(Eulerian(10,k) for k=1:10) == Factorial(10)
