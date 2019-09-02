using NeRCA
using Test


# angle_between()
@test 0 == NeRCA.angle_between([1,0,0], [1,0,0])
@test π/2 ≈ NeRCA.angle_between([1,0,0], [0,1,0])
@test π/2 ≈ NeRCA.angle_between([1,0,0], [0,0,1])
@test π ≈ NeRCA.angle_between([1,0,0], [-1,0,0])

# azimuth()
@test π/2 == NeRCA.azimuth(Direction(0,1,0))
@test 0 ≈ NeRCA.azimuth(Direction(1,0,0))
@test -π/2 ≈ NeRCA.azimuth(Direction(0,-1,0))
@test π ≈ NeRCA.azimuth(Direction(-1,0,0))
