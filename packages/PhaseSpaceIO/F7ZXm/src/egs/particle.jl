import Setfield

struct Latch
    _data::UInt32
end

Base.UInt32(l::Latch) = getfield(l, :_data)

"""
True if a particle crossed scoring plane multiple times.
"""
const MASK_MULTICROSS       = 0b10000000000000000000000000000000

"""
Encodes the charge of a particle -1,0,+1.
"""
const MASK_CHARGE        = 0b01100000000000000000000000000000

"""
The bit region in which a particle was created. 0 for primary particles.
"""
const MASK_CREATION      = 0b00011111000000000000000000000000 

"""
Marks the bit regions that were traversed by particle.
"""
const MASK_VISITED       = 0b00000000111111111111111111111110

"""
True if bremsstrahlung or annihilation even occurs in history.
"""
const MASK_BREMS         = 0b00000000000000000000000000000001

struct BitRegions <: AbstractVector{Bool}
    data::UInt32
end

Base.UInt32(o::BitRegions) = o.data

macro BitRegions(args...)
    pattern = zero(UInt32)
    for i in args
        pattern = setbit(pattern, true, i)
    end
    pattern
    esc(:(BitRegions($pattern)))
end

function Base.size(o::BitRegions)
    (23,)
end
function Base.getindex(o::BitRegions, index)
    @boundscheck checkbounds(o, index)
    data = UInt32(o)
    getbit(data, index)
end

function show_bitregions(io::IO, r::BitRegions)
    data = UInt32(r)
    print(io, "@BitRegions", "(")
    for i in eachindex(r)
        if r[i]
            print(io, i, ", ")
        end
    end
    print(io, ")")
end
Base.show(io::IO, ::MIME"text/plain", r::BitRegions) = show_bitregions(io, r)
Base.show(io::IO, r::BitRegions) = show_bitregions(io, r)

function Base.propertynames(latch::Latch)
    (:multicross, :charge, :creation, :visited, :brems)
end

function Base.getproperty(o::Latch, s::Symbol)
    if s == :multicross
        get_multicross(o)
    elseif s == :charge
        get_charge(o)
    elseif s == :creation
        get_creation(o)
    elseif s == :visited
        get_visited(o)
    elseif s == :brems
        get_brems(o)
    else
        @argcheck s in propertynames(o)
    end
end

function Setfield.setproperties(o::Latch, props)
    Latch(;
        multicross=get(props, :multicross, o.multicross),
        charge=get(props, :charge, o.charge),
        creation=get(props, :creation, o.creation),
        visited=get(props, :visited, o.visited),
        brems=get(props, :brems, o.brems),
    )
end

function Latch(;
        multicross::Bool=false,
        charge::Int,
        creation::Int=0, # actually bitregion 0 does not exist
        visited::BitRegions=BitRegions(zero(UInt32)),
        brems::Bool=false,
    )
    l = zero(UInt32)
    l += brems_pattern(brems)
    l += visited_pattern(visited)
    l += creation_pattern(creation)
    l += charge_pattern(charge)
    l += multicross_pattern(multicross)
    Latch(l)
end

function brems_pattern(brems::Bool)
    l = zero(UInt32)
    setbit(l, brems, 0)
end
function visited_pattern(o::BitRegions)
    o.data
end
function creation_pattern(region)
    UInt32(region) << 24
end
function charge_pattern(charge)
    if charge == 0
        UInt32(0)
    elseif charge == -1
        UInt32(1 << 30)
    elseif charge == 1
        UInt32(1 << 29)
    else
        @argcheck charge in (-1, 0, 1)
    end
end
function multicross_pattern(mc::Bool)
    l = zero(UInt32)
    setbit(l, mc, 31)
end
function get_creation(latch::Latch)
    l = UInt32(latch) & MASK_CREATION
    Int(l >> 24)
end
function get_visited(latch::Latch)
    BitRegions(UInt32(latch) & MASK_VISITED)
end
function get_brems(latch::Latch)
    Bool(UInt32(latch) & MASK_BREMS)
end
function get_multicross(latch::Latch)
    getbit(UInt32(latch), 31)
end
function get_charge(latch::Latch)
    l = UInt32(latch)
    l &= MASK_CHARGE
    if l == charge_pattern(0)
        0
    elseif l == charge_pattern(-1)
        -1
    elseif l == charge_pattern(1)
        1
    else
        msg = "Unsupported charge pattern $l"
        throw(ArgumentError(msg))
    end
end

Base.show(io::IO, latch::Latch) = kwshow(io, latch)

#### EGSParticle
struct EGSParticle{ZLAST <: Union{Nothing,Float32}}
    _latch::Latch
    _E::Float32 # sign bit new histrory
    _x::Float32
    _y::Float32
    _u::Float32
    _v::Float32
    _weight::Float32 # sign bit sign w
    _zlast::ZLAST
end

# TODO HACKY
Base.isapprox(p1::EGSParticle, p2::EGSParticle) = p1 === p2

function Base.propertynames(o::EGSParticle)
    (:latch, :new_history, :E, :x, :y, :u, :v, :w, :weight, :zlast)
end

function Setfield.setproperties(o::EGSParticle, props)
    EGSParticle(
        get(props, :latch, o.latch),
        get(props, :new_history, o.new_history),
        get(props, :E, o.E),
        get(props, :x, o.x),
        get(props, :y, o.y),
        get(props, :u, o.u),
        get(props, :v, o.v),
        get(props, :w, o.w),
        get(props, :weight, o.weight),
        get(props, :zlast, o.zlast),
    )

end

function EGSParticle(latch::Latch, new_history::Bool, E, x, y, u, v, w, weight, zlast)
    @argcheck weight >= 0
    @argcheck E >= 0
    @argcheck Float32(u^2 + v^2 + w^2) ≈ 1
    charge = latch.charge
    E_rest = rest_energy_by_charge(charge)
    E_tot = kin2total(Float32(E), E_rest)
    _E = Float32((-1)^new_history * E_tot)
    _weight = Float32(sign(w) * weight)
    EGSParticle(latch, _E, Float32(x), Float32(y), Float32(u), Float32(v), _weight, zlast)
end

function EGSParticle(;latch , new_history=true, E,x,y,u,v,w,weight=1f0,zlast=nothing)
    EGSParticle(latch, new_history, E, x, y, u, v, w, weight, zlast)
end

function kwshow(io::IO, o)
    print(io, typeof(o).name, "(")
    for pname in propertynames(o)
        pval = getproperty(o, pname)
        print(io, string(pname), "=")
        show(io, pval)
        print(io, ", ")
    end
    print(io, ")")
end

Base.show(io::IO, o::EGSParticle) = kwshow(io, o)

@inline function Base.getproperty(o::EGSParticle, s::Symbol)
    if s == :latch
        get_latch(o)
    elseif s == :E
        get_E(o)
    elseif s == :x
        get_x(o)
    elseif s == :y
        get_y(o)
    elseif s == :u
        get_u(o)
    elseif s == :v
        get_v(o)
    elseif s == :w
        get_w(o)
    elseif s == :weight
        get_weight(o)
    elseif s == :zlast
        get_zlast(o)
    elseif s == :new_history
        get_new_history(o)
    else
        throw(ErrorException("$o does not have property $s"))
    end
end
        
function kin2total(Ekin::Float32, E_rest::Float64)
    Float32(Float64(Ekin) + E_rest)
end

function total2kin(Etotal::Float32, E_rest::Float64)
    Float32(Float64(Etotal) - E_rest)
end

function rest_energy_by_charge(charge::Int)
    ifelse(charge == 0, 0., 0.511)
end

get_latch(o::EGSParticle) = getfield(o, :_latch)
function get_E(o::EGSParticle) 
    E_tot = abs(getfield(o, :_E))
    E_rest = rest_energy_by_charge(o.latch.charge)
    total2kin(E_tot, E_rest)
end

get_x(o::EGSParticle) = getfield(o, :_x)
get_y(o::EGSParticle) = getfield(o, :_y)
get_u(o::EGSParticle) = getfield(o, :_u)
get_v(o::EGSParticle) = getfield(o, :_v)

get_weight(o::EGSParticle) = abs(getfield(o, :_weight))
get_zlast(o::EGSParticle)  = getfield(o, :_zlast)
get_new_history(o::EGSParticle) = signbit(getfield(o, :_E))

function get_w(o::EGSParticle)
    u = Float64(get_u(o))
    v = Float64(get_v(o))
    sign_w = sign(getfield(o, :_weight))
    w64_square = 1 - u^2 - v^2
    w64 = if w64_square < 0
        @assert isapprox(w64_square,0,atol=100eps(Float32))
        0.
    else
        sign_w * sqrt(1 - u^2 - v^2)
    end
    Float32(w64)
end

function particle_type(p::EGSParticle)
    c = p.latch.charge
    if c == -1
        electron
    elseif c == 0
        photon
    else
        @assert c == 1
        positron
    end
end

isphoton(o::EGSParticle) = o.latch.charge == 0
iselectron(o::EGSParticle) = o.latch.charge == -1
ispositron(o::EGSParticle) = o.latch.charge == 1

