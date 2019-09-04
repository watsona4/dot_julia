# TODO: should probably be elsewhere
module BipedControlUtil
using Random

export
    Side,
    left,
    right,
    flipsign_if_right

# Side
# From https://bitbucket.org/ihmcrobotics/ihmc-open-robotics-software/src/575d33e1ab064f4e5957096414376fc011a98bce/IHMCRoboticsToolkit/src/us/ihmc/robotics/robotSide/RobotSide.java?at=develop&fileviewer=file-view-default
@enum Side left right
flipsign_if_right(x::Number, side::Side) = ifelse(side == right, -x, x)
Random.rand(rng::AbstractRNG, ::Type{Side}) = ifelse(rand(rng, Bool), left, right)
Base.:(-)(side::Side) = ifelse(side == right, left, right)
end
