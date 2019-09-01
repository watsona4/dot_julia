__precompile__()

module ERFA

const depsfile = joinpath(dirname(dirname(@__FILE__)), "deps", "deps.jl")
if isfile(depsfile)
    include(depsfile)
else
    error("ERFA is not properly installed. Please run Pkg.build(\"ERFA\")")
end

include("erfa_common.jl")
include("deprecated.jl")

include("a.jl")
include("b.jl")
include("c.jl")
include("d.jl")
include("e.jl")
include("f.jl")
include("g.jl")
include("h.jl")
include("i.jl")
include("j.jl")
include("l.jl")
include("n.jl")
include("o.jl")
include("p.jl")
include("r.jl")
include("s.jl")
include("t.jl")
include("u.jl")
include("x.jl")

function ASTROM(pmt, eb::AbstractArray, eh::AbstractArray, em, v::AbstractArray, bm1, bpn::AbstractArray, along, phi, xpl, ypl, sphi, cphi, diurab, eral, refa, refb)
    ASTROM(pmt,
              (eb[1], eb[2], eb[3]),
              (eh[1], eh[2], eh[3]),
              em,
              (v[1], v[2], v[3]),
              bm1,
              (bpn[1], bpn[2], bpn[3], bpn[4], bpn[5], bpn[6], bpn[7], bpn[8], bpn[9]),
              along,
              phi,
              xpl,
              ypl,
              sphi,
              cphi,
              diurab,
              eral,
              refa,
              refb)
end

function LDBODY(bm, dl, pv::AbstractArray)
    LDBODY(bm, dl, (pv...,))
end

end # module
