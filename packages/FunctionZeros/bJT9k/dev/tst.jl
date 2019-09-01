using FunctionZeros
using BenchmarkTools
import SpecialFunctions

@btime besselj_zero(3,10)
@btime besselj_zero(3,10)

const z = besselj_zero(3,10)
zer = SpecialFunctions.besselj(3,z)
