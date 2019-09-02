using CoordinateTransformations

function (t::Translation)(p::IAEAParticle)
    pos = t(position(p))
    set_position(p, pos)
end
function (t::LinearMap)(p::IAEAParticle)
    pos = t(position(p))
    dir = t(direction(p))
    set_position_direction(p, pos, dir)
end
function (t::AffineMap)(p::IAEAParticle)
    pos = t(position(p))
    dir = t.linear*direction(p)
    set_position_direction(p, pos, dir)
end
