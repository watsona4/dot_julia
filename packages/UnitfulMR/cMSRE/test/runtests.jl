using Unitful, UnitfulMR
using Test

@test 1u"Gauss" == 1e-4u"T"
@test 1u"Gauss" == 100u"μT"

