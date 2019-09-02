export ParticleType
export photon, electron, positron, neutron, proton

@enum ParticleType photon=1 electron=2 positron=3 neutron=4 proton=5

for pt in instances(ParticleType)
    fname = Symbol("is", pt)
    @eval $fname(p) = p.typ == $pt
    eval(Expr(:export, fname))
end

function load(path::AbstractString, T)
    open(path) do io
        load(io, T)
    end
end

function compute_u_v_w(u, v, sign_w)
    tmp = Float64(u)^2 + Float64(v)^2
    if tmp <= 1
        w = sign_w * Float32(√(1 - tmp))
    else
        w = Float32(0)
        tmp = √(tmp)
        u = Float32(u/tmp)
        v = Float32(v/tmp)
    end
    u,v,w
end

@noinline function call_fenced(f::F, arg::A) where {F,A}
    f(arg)
end
