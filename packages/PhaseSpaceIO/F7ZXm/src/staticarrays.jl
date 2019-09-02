using StaticArrays: @SVector, normalize
using Setfield: setproperties
export set_position
export direction, set_direction

function direction(p)
    @SVector [p.u, p.v, p.w]
end

function Base.position(p::EGSParticle; z=nothing)
    if z === nothing
        @SVector[p.x, p.y]
    else
        @SVector[p.x, p.y, z]
    end
end

function Base.position(p::IAEAParticle)
    @SVector[p.x, p.y, p.z]
end

function set_direction(p, dir)
    u,v,w = dir
    setproperties(p, (u=u,v=v,w=w))
end

function set_position(p::IAEAParticle, pos)
    x,y,z = pos
    setproperties(p, (x=x,y=y,z=z))
end

function set_position(p::EGSParticle, pos)
    x,y = pos
    setproperties(p, (x=x,y=y))
end

function set_position_direction(p::EGSParticle, pos, dir)
    x,y = pos
    u,v,w = dir
    setproperties(p, (x=x,y=y,u=u,v=v,w=w))
end

function set_position_direction(p::IAEAParticle, pos, dir)
    x,y,z = pos
    u,v,w = dir
    setproperties(p, (x=x,y=y,z=z,u=u,v=v,w=w))
end
