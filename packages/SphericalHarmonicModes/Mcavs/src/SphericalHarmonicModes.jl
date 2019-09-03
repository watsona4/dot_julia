module SphericalHarmonicModes

export SHModeRange,st,ts,modeindex,s_valid_range,t_valid_range,s_range,t_range,
s′s,s′_range,s′_valid_range,number_of_modes

abstract type ModeRange end
abstract type SHModeRange <: ModeRange end
abstract type ModeProduct <: ModeRange end

Base.eltype(::ModeRange) = Tuple{Int,Int}

# Throw errors if values are invalid
struct OrderError{T} <: Exception
	var :: String
	low :: T
	high :: T
end

struct tRangeError <: Exception 
	smax :: Integer
	t :: Integer
end

struct ModeMissingError{M,T} <: Exception
	s :: T
	t :: T
	m :: M
end

struct NegativeDegreeError{T<:Integer} <: Exception
	s :: T
end

Base.showerror(io::IO, e::tRangeError) = print(io," t = ", e.t,
		" does not satisfy ",-e.smax," ⩽ t ⩽ ",e.smax)

Base.showerror(io::IO, e::OrderError) = print(io,e.var,"min = ",e.low,
	" is not consistent with ",e.var,"max = ",e.high)

Base.showerror(io::IO, e::ModeMissingError{<:SHModeRange}) = 
	print(io,"Mode with (s=",e.s,",t=",e.t,")",
	" is not included in the range given by ",e.m)

Base.showerror(io::IO, e::ModeMissingError{<:ModeProduct}) = 
	print(io,"Mode with (s′=",e.s,",s=",e.t,")",
	" is not included in the range given by ",e.m)

Base.showerror(io::IO, e::NegativeDegreeError) = print(io,"s = ",e.s,
	" is not a valid mode")

check_if_non_negative() = true

function check_if_non_negative(s::Integer,args...)
	s < 0 && throw(NegativeDegreeError(s))
	check_if_non_negative(args...)
end

function check_if_st_valid(smin,smax,tmin,tmax)
	check_if_non_negative(smin,smax)
	if tmin > tmax 
		throw(OrderError("t",tmin,tmax))
	end
	if smin > smax
		throw(OrderError("s",smin,smax))
	end
	if abs(tmax) > smax
		throw(tRangeError(smax,tmax))
	end
	if abs(tmin) > smax
		throw(tRangeError(smax,tmin))
	end
end

struct st <: SHModeRange
	smin :: Int
	smax :: Int
	tmin :: Int
	tmax :: Int

	function st(smin,smax,tmin,tmax)
		check_if_st_valid(smin,smax,tmin,tmax)
		smin = max(smin,max(tmin,-tmax))
		new(smin,smax,tmin,tmax)
	end
end

struct ts <: SHModeRange
	smin :: Int
	smax :: Int
	tmin :: Int
	tmax :: Int

	function ts(smin,smax,tmin,tmax)
		check_if_st_valid(smin,smax,tmin,tmax)
		smin = max(smin,max(tmin,-tmax))
		new(smin,smax,tmin,tmax)
	end
end

struct s′s <: ModeProduct
	smin :: Int
	smax :: Int
	Δs_max :: Int
	s′min :: Int
	s′max :: Int

	function s′s(smin::Integer,smax::Integer,
		Δs_max::Integer,s′min::Integer,s′max::Integer)

		check_if_non_negative(smin,smax,Δs_max,s′min,s′max)

		# Alter the ranges if necessary
		smin = max(smin,s′min-Δs_max,0)
		s′min = max(smin-Δs_max,0,s′min)
		s′max = max(min(max(smax+Δs_max,0),s′max),s′min)
		smax = min(smax,s′max+Δs_max)

		new(smin,smax,Δs_max,s′min,s′max)
	end
end

# Constructors. Both ts and st are constructed identically, 
# so we can dispatch on the supertype
(::Type{T})(smin::Integer,smax::Integer) where {T<:SHModeRange} = T(smin,smax,-smax,smax)
(::Type{T})(s::Integer) where {T<:SHModeRange} = T(s,s)

(::Type{T})(s_range::AbstractUnitRange{<:Integer},
	t_range::AbstractUnitRange{<:Integer}) where {T<:SHModeRange} = 
	T(extrema(s_range)...,extrema(t_range)...)

(::Type{T})(s_range::AbstractUnitRange{<:Integer},t::Integer) where {T<:SHModeRange} = 
	T(extrema(s_range)...,t,t)

(::Type{T})(s::Integer,t_range::AbstractUnitRange{<:Integer}) where {T<:SHModeRange} = 
	T(s,s,extrema(t_range)...)

(::Type{T})(s_range::AbstractUnitRange{<:Integer}) where {T<:SHModeRange} = 
	T(extrema(s_range)...)

function s′s(smin::Integer,smax::Integer,Δs_max::Integer,
	s′min::Integer=max(smin-Δs_max,0))

	s′s(smin,smax,Δs_max,s′min,smax+Δs_max)
end

s′s(smin::Integer,smax::Integer,m::SHModeRange,args...) = s′s(smin,smax,m.smax,args...)

s′s( s_range::AbstractUnitRange{<:Integer},Δs_max::Integer,
	s′_range::AbstractUnitRange{<:Integer}) = 
	s′s(extrema(s_range)...,Δs_max,extrema(s′_range)...)

s′s(smin::Integer,smax::Integer,Δs_max::Integer,
	s′_range::AbstractUnitRange{<:Integer}) = 
	s′s(smin,smax,Δs_max,extrema(s′_range)...)

s′s( s_range::AbstractUnitRange{<:Integer},Δs_max::Union{Integer,<:SHModeRange},
	args...) = 
	s′s(extrema(s_range)...,Δs_max,args...)

# Get the ranges of the modes

@inline s_range(m::SHModeRange) = m.smin:m.smax
@inline t_range(m::SHModeRange) = m.tmin:m.tmax

@inline s_range(m::s′s) = m.smin:m.smax
@inline s′_range(m::s′s) = m.s′min:m.s′max

@inline function s_valid_range(m::SHModeRange,t::Integer)
	max(abs(t),m.smin):m.smax
end

@inline function t_valid_range(m::SHModeRange,s::Integer)
	max(-s,m.tmin):min(s,m.tmax)
end

@inline function s′_valid_range(m::s′s,s::Integer)
	max(s - m.Δs_max,m.s′min):min(s + m.Δs_max,m.s′max)
end

function number_of_modes(m::st)

	# We evaluate Sum[smax - Max[Abs[t], smin] + 1] piecewise in 
	# Mathematica. There are four cases to consider
	# depending on which of |t| and smin is larger

	smin,smax,tmin,tmax = m.smin,m.smax,m.tmin,m.tmax

	N = 0

	if min(tmax,-1) >= max(tmin,-smin)
		N += (1 + smax - smin)*(1 - max(-smin, tmin) + min(-1, tmax))
	end
	if min(tmax, smin) >= max(tmin, 0)
		N += (1 + smax - smin)*(1 - max(0, tmin) + min(smin, tmax))
	end
	if tmax >= max(tmin, smin + 1)
		N += div(-((1 + tmax - max(1 + smin, tmin))*(-2 - 2*smax + tmax + max(1 + smin, tmin))),2)
	end
	if min(tmax,-1,-smin - 1) >= max(tmin, -smax)
		N += div(-((-1 + max(-smax, tmin) - min(-1, -1 - smin, tmax))*(2 + 2*smax + max(-smax, tmin) + min(-1, -1 - smin, tmax))),2)
	end

	return N
end

function number_of_modes(m::ts)

	# We evaluate Sum[min(s,tmax)-max(-s,tmin)+1] piecewise in 
	# Mathematica. There are four cases to consider
	# depending on s, tmax and tmin

	smin,smax,tmin,tmax = m.smin,m.smax,m.tmin,m.tmax

	N = 0

	if min(-tmin, tmax,smax) >= smin
		N += -(-1+smin-min(smax,tmax,-tmin))*(1+smin+min(smax,tmax,-tmin))
	end
	if min(-tmin, smax) >= max(smin, max(tmax + 1, -tmax))
		N += div(-((-1 + max(smin, -tmax, 1 + tmax) - min(smax, -tmin))*(2 + 2*tmax + max(smin, -tmax, 1 + tmax) + min(smax, -tmin))),2)
	end
	if min(tmax, smax) >= max(smin, -tmin + 1, tmin)
		N += div(-((-1 + max(smin, 1 - tmin, tmin) - min(smax, tmax))*(2 - 2*tmin + max(smin, 1 - tmin, tmin) + min(smax, tmax))),2)
	end
	if smax >= max(-tmin + 1, tmax + 1,smin)
		N += (1 + tmax - tmin)*(1 + smax - max(1 + tmax, 1 - tmin,smin))
	end

	return N
end

function number_of_modes(m::s′s)

	# Number of modes is given by count(s′_valid_range(m,s) for s in s_range(m))
	smin,smax,spmin,spmax = m.smin,m.smax,m.s′min,m.s′max
	dsmax = m.Δs_max
    
    N = 0
    if spmin == max(0,smin-dsmax) && spmax == smax+dsmax
    	return number_of_modes_default_s′minmax(m)
    end

    if min(smax, spmax - dsmax) >= max(smin, spmin + dsmax)
    	
    	N += (1 + 2*dsmax)*(1 - max(smin, dsmax + spmin) + min(smax, -dsmax + spmax))

    end
    if min(smax,spmax + dsmax) >= max(smin, spmin + dsmax, spmax - dsmax + 1)
    	
    	N+= div((-1 + max(smin, 1 - dsmax + spmax, dsmax + spmin) - min(smax, dsmax + spmax))*(-2*(1 + dsmax + spmax) + max(smin, 1 - dsmax + spmax, dsmax + spmin) + min(smax, dsmax + spmax)),2)

    end
    if min(smax, spmin + dsmax - 1, spmax - dsmax) >= max(smin,spmin - dsmax)
    	
    	N+= div(-((-1 + max(smin, -dsmax + spmin) - min(smax, -dsmax + spmax, -1 + dsmax + spmin))*(2 + 2*dsmax - 2*spmin + max(smin, -dsmax + spmin) + min(smax, -dsmax + spmax, -1 + dsmax + spmin))),2)

    end
    if min(smax, spmin + dsmax - 1) >= max(smin,spmax - dsmax + 1)
    	
    	N+= (1 + spmax - spmin)*(1 - max(smin, 1 - dsmax + spmax) + min(smax, -1 + dsmax + spmin))

    end

    return N
end

Base.length(m::ModeRange) = number_of_modes(m)

# Number of modes of an s′s iterator
# Assumes s′min = max(0,smin - Δs_max) and s′max = smax + Δs_max
# Faster implementation
function number_of_modes_default_s′minmax(m::s′s)
	
	smin,smax = m.smin,m.smax
    Δs_max = m.Δs_max

	N = 0

	if smin < Δs_max
        N += -div((-1 + smin - min(smax, Δs_max -1 ))*
                    (2 + smin + 2Δs_max + min(smax, Δs_max -1 )),2)
    end

    if smax >= Δs_max
        N += (1 + smax - max(Δs_max,smin)) * (1 + 2Δs_max)
    end

	return N
end

Base.firstindex(m::ModeRange) = 1
Base.lastindex(m::ModeRange) = length(m)

# Size and axes behave similar to vectors
@inline Base.size(m::ModeRange) = (length(m),)
@inline Base.size(m::ModeRange,d::Integer) = d == 1 ? length(m) : 1

@inline Base.axes(m::ModeRange) = (Base.OneTo(length(m)),)
@inline Base.axes(m::ModeRange,d::Integer) = d == 1 ? Base.OneTo(length(m)) : Base.OneTo(1)

# Convenience function to generate the first step in the iteration
@inline first_t(m::st) = m.tmin
@inline first_s(m::st) = first(s_valid_range(m,first_t(m)))
@inline first_s(m::ts) = m.smin
@inline first_t(m::ts) = first(t_valid_range(m,first_s(m)))

@inline first_s(m::s′s) = max(m.smin,m.s′min-m.Δs_max)
@inline first_s′(m::s′s) = first(s′_valid_range(m,first_s(m)))

function Base.iterate(m::st, state=((first_s(m),first_t(m)), 1))

	(s,t), count = state

	if count > number_of_modes(m)
		return nothing
	end

	next_t = (s == m.smax) ? t+1 : t
	next_s = (s == m.smax) ? max(m.smin,abs(next_t)) : s + 1

	return (s,t), ((next_s,next_t), count + 1)
end

function Base.iterate(m::ts, state=((first_s(m),first_t(m)), 1))
	
	(s,t), count = state

	if count > number_of_modes(m)
		return nothing
	end

	next_s = (t == min(m.tmax,s)) ? s+1 : s
	next_t = (t == min(m.tmax,s)) ? max(m.tmin,-next_s) : t + 1

	return (s,t), ((next_s,next_t), count + 1)
end

function Base.iterate(m::s′s,state=((first_s′(m),first_s(m)), 1))

	(s′,s),count = state
	if count > number_of_modes(m)
		return nothing
	end

	s′_range_s = s′_valid_range(m,s)

	s′ind = searchsortedfirst(s′_range_s,s′)
	if s′ind==length(s′_range_s)
		next_s = s + 1
		next_s′ = first(s′_valid_range(m,next_s))
	else
		next_s = s
		next_s′ = s′ + 1
	end

	return (s′,s),((next_s′,next_s),count+1)
end

function _in((s,t)::Tuple{<:Integer,<:Integer},m::ts)
	(abs(t)<=s) && (m.smin <= s <= m.smax) && (m.tmin <= t <= m.tmax) &&
	(t in t_valid_range(m,s))
end

function _in((s,t)::Tuple{<:Integer,<:Integer},m::st)
	(abs(t)<=s) && (m.smin <= s <= m.smax) && (m.tmin <= t <= m.tmax) &&
	(s in s_valid_range(m,t))
end

function _in((s′,s)::Tuple{<:Integer,<:Integer},m::s′s)
	(m.smin <= s <= m.smax) && 
	(m.s′min <= s′ <= m.s′max) && 
	(s′ in s′_valid_range(m,s))
end

Base.in(T::Tuple{<:Integer,<:Integer},m::ModeRange) = _in(T,m)

Base.last(m::st) = (last(s_valid_range(m,m.tmax)),m.tmax)
Base.last(m::ts) = (m.smax,last(t_valid_range(m,m.tmax)))
Base.last(m::s′s) = (last(s′_valid_range(m,m.smax)), m.smax)

function modeindex(m::st,s::Integer,t::Integer)
	!_in((s,t),m) && throw(ModeMissingError(s,t,m))
	Nskip = 0
	
	smin,smax = m.smin,m.smax
	tmin,tmax = m.tmin,m.tmax

	# Nskip = sum(length(s_valid_range(m,ti)) fot ti=m.tmin:t-1)

	if min(t - 1, -1) >= max(tmin, -smin)
		Nskip += (1 + smax - smin)*(1 - max(-smin, tmin) + min(-1, -1 + t))
	end
	if min(t - 1, smin) >= max(tmin, 0)
		Nskip += (1 + smax - smin)*(1 - max(0, tmin) + min(smin, -1 + t))
	end
	if min(t - 1, tmax, smax) >= max(tmin, smin + 1)
		Nskip += div((-1 + max(1 + smin, tmin) - min(smax, -1 + t, tmax))*(-2*(1 + smax) + max(1 + smin, tmin) + min(smax, -1 + t, tmax)),2)
	end
	if min(t - 1, -1, -smin - 1) >= max(tmin, -smax)
		Nskip += div(-((-1 + max(-smax, tmin) - min(-1, -1 - smin, -1 + t))*(2 + 2*smax + max(-smax, tmin) + min(-1, -1 - smin, -1 + t))),2)
	end

	Nskip + searchsortedfirst(s_valid_range(m,t),s)
end

function modeindex(m::st,s::AbstractUnitRange{<:Integer},t::Integer)
	last(s) in s_valid_range(m,t) || throw(ModeMissingError(last(s),t,m))
	start = modeindex(m,first(s),t)
	start:start + length(s) - 1
end

modeindex(m::st,::Colon,t::Integer) = modeindex(m,s_valid_range(m,t),t)

function modeindex(m::ts,s::Integer,t::Integer)
	!_in((s,t),m) && throw(ModeMissingError(s,t,m))
	Nskip = 0
	
	smin,smax = m.smin,m.smax
	tmin,tmax = m.tmin,m.tmax

	# Nskip = sum(length(t_valid_range(m,si)) for si=m.smin:s-1)

	if min(-tmin, tmax, s - 1) >= smin
		Nskip += -(-1+smin-min(-1+s,tmax,-tmin))*(1+smin+min(-1+s,tmax,-tmin))
	end
	if min(-tmin, s - 1) >= max(smin, max(tmax + 1, -tmax))
		Nskip += div(-((-1 + max(smin, -tmax, 1 + tmax) - min(-1 + s, -tmin))*(2 + 2*tmax + max(smin, -tmax, 1 + tmax) + min(-1 + s, -tmin))),2)
	end
	if min(tmax, s - 1) >= max(smin, -tmin + 1, tmin)
		Nskip += div(-((-1 + max(smin, 1 - tmin, tmin) - min(-1 + s, tmax))*(2 - 2*tmin + max(smin, 1 - tmin, tmin) + min(-1 + s, tmax))),2)
	end
	if s - 1 >= max(-tmin + 1, tmax + 1, smin)
		Nskip += (1 + tmax - tmin)*(s - max(smin, 1 + tmax, 1 - tmin))
	end

	Nskip + searchsortedfirst(t_valid_range(m,s),t)
end

function modeindex(m::ts,s::Integer,t::AbstractUnitRange{<:Integer})
	last(t) in t_valid_range(m,s) || throw(ModeMissingError(s,last(t),m))
	start = modeindex(m,s,first(t))
	start:start + length(t) - 1
end

modeindex(m::ts,s::Integer,::Colon) = modeindex(m,s,t_valid_range(m,s))

function modeindex(m::s′s,s′::Integer,s::Integer)
	!_in((s′,s),m) && throw(ModeMissingError(s′,s,m))
	Nskip = 0

	smin,smax,spmin,spmax = m.smin,m.smax,m.s′min,m.s′max
	dsmax = m.Δs_max

	if min(s - 1, spmax - dsmax) >= max(smin, spmin + dsmax)
		Nskip += (1 + 2*dsmax)*(1 - max(smin, dsmax + spmin) + min(-1 + s, -dsmax + spmax))
	end
	if min(s - 1, spmax + dsmax) >= max(smin, spmin + dsmax, spmax - dsmax + 1)
		Nskip += div((-1 + max(smin, 1 - dsmax + spmax, dsmax + spmin) - min(-1 + s, dsmax + spmax))*(-2*(1 + dsmax + spmax) + max(smin, 1 - dsmax + spmax, dsmax + spmin) + min(-1 + s, dsmax + spmax)),2)
	end
	if min(s - 1, spmin + dsmax - 1, spmax - dsmax) >= max(smin, spmin - dsmax)
		Nskip += div(-((-1 + max(smin, -dsmax + spmin) - min(-1 + s, -dsmax + spmax, -1 + dsmax + spmin))*(2 + 2*dsmax - 2*spmin + max(smin, -dsmax + spmin) + min(-1 + s, -dsmax + spmax, -1 + dsmax + spmin))),2)
	end
	if min(s - 1, spmin + dsmax - 1) >= max(smin, spmax - dsmax + 1)
		Nskip += (1 + spmax - spmin)*(1 - max(smin, 1 - dsmax + spmax) + min(-1 + s, -1 + dsmax + spmin))
	end

	Nskip + searchsortedfirst(s′_valid_range(m,s),s′)
end

function modeindex(m::s′s,s′::AbstractUnitRange{<:Integer},s::Integer)
	last(s′) in s′_valid_range(m,s) || throw(ModeMissingError(last(s′),s,m))
	start = modeindex(m,first(s′),s)
	start:start + length(s′) - 1
end

modeindex(m::s′s,::Colon,s::Integer) = modeindex(m,s′_valid_range(m,s),s)

modeindex(m::ModeRange,T::Tuple{<:Any,<:Any}) = modeindex(m,T...)

# Display the iterators

function Base.show(io::IO, m::SHModeRange)
	print(io,"(s=",s_range(m),",t=",t_range(m),")")
end

function Base.show(io::IO, m::s′s)
	print(io,"(s=",s_range(m),",Δs_max=",m.Δs_max,
		",s′=",s′_range(m),")")
end

function Base.show(io::IO, ::MIME"text/plain", m::st)
	println("Spherical harmonic modes with s increasing faster than t")
	print(io,"smin = ",m.smin,", smax = ",m.smax,
		", tmin = ",m.tmin,", tmax = ",m.tmax)
end

function Base.show(io::IO, ::MIME"text/plain", m::ts)
	println("Spherical harmonic modes with t increasing faster than s")
	print(io,"smin = ",m.smin,", smax = ",m.smax,
		", tmin = ",m.tmin,", tmax = ",m.tmax)
end

function Base.show(io::IO, ::MIME"text/plain", m::s′s)
	println("Spherical harmonic modes (s′,s) where |s-Δs| ⩽ s′ ⩽ s+Δs "*
		"for 0 ⩽ Δs ⩽ Δs_max, and s′min ⩽ s′ ⩽ s′max")
	print(io,m.smin," ⩽ s ⩽ ",m.smax,", Δs_max = ",m.Δs_max,
		", and ",m.s′min," ⩽ s′ ⩽ ",m.s′max)
end

end # module
