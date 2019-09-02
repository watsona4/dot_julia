#MDDatasets: Register dataset operations
#-------------------------------------------------------------------------------

#==NOTE
DataF1 cannot represent matrices.  Element-by-element operations will therefore
be the default.  There is not need to use the "." operator versions.
==#

#==NOTE:
	:cummax, :cummin, :cumprod, :cumsum, maxabs, are high-level functions... not sure
	if these should be ported, or new names/uses should be found
==#


#==Support basic math operations
===============================================================================#

#Unary operators
const _operators1 = Symbol[:-, :+, :!]

for op in _operators1; @eval begin #CODEGEN--------------------------------------

#op Index:
Base.$op(i::Index) = Index($op(i.v))

#op DataF1:
Base.$op(d::DataF1) = DataF1(d.x, ($op).(d.y))

#Everything else:
Base.$op(d::DataMD) = broadcastMD(CAST_BASEOP1, Base.$op, d)

end; end #CODEGEN---------------------------------------------------------------

const _operators2 = Symbol[:-, :+, :/, :*, :^, :>, :<, :>=, :<=, :!=, :(==)]

for op in _operators2; @eval begin #CODEGEN--------------------------------------

#Index op Index:
Base.$op(i1::Index, i2::Index) = Index(($op).(i1.v, i2.v))

#DataF1 op DataF1:
Base.$op(d1::DataF1, d2::DataF1) = apply(Base.$op, d1, d2)

#DataF1 op Number:
Base.$op(d::DataF1, n::Number) = DataF1(d.x, ($op).(d.y, n))

#Number op DataF1:
Base.$op(n::Number, d::DataF1) = DataF1(d.x, ($op).(n, d.y))

#Everything else:
Base.$op(d1::DataMD, d2::DataMD) = broadcastMD(CAST_BASEOP2, Base.$op, d1, d2)
Base.$op(d1::Number, d2::DataMD) = broadcastMD(CAST_BASEOP2, Base.$op, d1, d2)
Base.$op(d1::DataMD, d2::Number) = broadcastMD(CAST_BASEOP2, Base.$op, d1, d2)

end; end #CODEGEN---------------------------------------------------------------


#==Support for 1-argument Base.functions
===============================================================================#

#==TODO:
Check out statistical stuff

isempty, isfinite, isinf, isinteger, isnan, isposdef, isreal

fft, etc

Mapping ??
map, mapreduce, mapreducedim, mapslices

#Number converters
#Bool(): map(Bool, x)
round
...

#other
#eachindex
rand
==#

#1-argument Base.functions:
const _basefn1 = [:(Base.$fn) for fn in [
	:abs, :abs2, :angle,
	:imag, :real, :exponent,
	:exp, :exp2, :exp10, :expm1,
	:log, :log10, :log1p, :log2,
	:ceil, :floor,
	:asin, :asind, :asinh, :acos, :acosd, :acosh,
	:atan, :atand, :atanh, :acot, :acotd, :acoth,
	:asec, :asecd, :asech, :acsc, :acscd, :acsch,
	:sin, :sind, :sinh, :cos, :cosd, :cosh,
	:tan, :tand, :tanh, :cot, :cotd, :coth,
	:sec, :secd, :sech, :csc, :cscd, :csch,
	:sinpi, :cospi,
	:sinc, :cosc, #cosc: d(sinc)/dx
	:deg2rad, :rad2deg,
	:clamp,
]]

#Custom functions of 1 argument that operate on base types:
const _custbasefn1 = [
	:sanitize,
]

for fn in vcat(_basefn1,_custbasefn1); @eval begin #CODEGEN---------------------

#fn(DataF1)
$fn(d::DataF1, args...; kwargs...) = DataF1(d.x, ($fn).(d.y, args...; kwargs...))

#Everything else:
$fn(d::DataMD, args...; kwargs...) = broadcastMD(CAST_BASEOP1, $fn, d, args...; kwargs...)

end; end #CODEGEN---------------------------------------------------------------

#zeros & one function... must use "fill" on functions:
const _onezerofn1 = [:(Base.$fn) for fn in [
	:zeros, :ones
]]

#Define old-ish "ones"/"zeros" syntax to simplify definition of ones/zeros:
Base.ones(::MDCUST, a) = fill(Base.one(eltype(a)), size(a))
Base.zeros(::MDCUST, a) = fill(Base.zero(eltype(a)), size(a))

for fn  in vcat(_onezerofn1); @eval begin #CODEGEN---------------------

#fn(DataF1)
$fn(d::DataF1) = DataF1(d.x, $fn(MDCUST(), d.y))

#Everything else:
$fn(d::DataMD) = broadcastMD(CAST_BASEOP2, $fn, MDCUST(), d)

end; end #CODEGEN---------------------------------------------------------------


#==Support for 2-argument Base.functions
===============================================================================#

const _basefn2 = [:(Base.$fn) for fn in [
	:max, :min,
	:atan, :hypot,
]]

for fn in _basefn2; @eval begin #CODEGEN----------------------------------------

#fn(DataF1, DataF1):
$fn(d1::DataF1, d2::DataF1) = apply($fn, d1, d2)

#Everything else:
$fn(d1::DataMD, d2::DataMD) = broadcastMD(CAST_BASEOP2, $fn, d1, d2)
$fn(d1::Number, d2::DataMD) = broadcastMD(CAST_BASEOP2, $fn, d1, d2)
$fn(d1::DataMD, d2::Number) = broadcastMD(CAST_BASEOP2, $fn, d1, d2)

end; end #CODEGEN---------------------------------------------------------------


#==Support reducing/collpasing Base.functions:
===============================================================================#
const _baseredfn1 = [:(Base.$fn) for fn in [
	:maximum, :minimum,
	:prod, :sum,
]]

for fn in _baseredfn1; @eval begin #CODEGEN-------------------------------------

#fn(DataF1):
$fn(d::DataF1) = ($fn)(d.y)

#Everything else:
$fn(d::DataMD) = broadcastMD(CAST_BASEOPRED1, $fn, d)

end; end #CODEGEN---------------------------------------------------------------


#==Support reducing/collpasing Statistics.functions:
===============================================================================#
const _statredfn1 = [:(Statistics.$fn) for fn in [
	:mean, :median, :middle,
	:std, :var,
]]

for fn in _statredfn1; @eval begin #CODEGEN-------------------------------------

#fn(DataF1):
$fn(d::DataF1) = ($fn)(d.y)

#Everything else:
$fn(d::DataMD) = broadcastMD(CAST_BASEOPRED1, ($fn), d)

end; end #CODEGEN---------------------------------------------------------------


#==Support 1-argument functions of DataF1
===============================================================================#
const _custfn1 = [
	:clip, :xval, :sample,
	:delta, :xshift, :xscale,
	:deriv, :iinteg,
	:xcross, :measperiod, :measfreq, :measduty,
	:measck2q, :measrise, :measfall,
]

for fn in _custfn1; @eval begin #CODEGEN---------------------------------------

$fn(d::DataMD, args...; kwargs...) = broadcastMD(CAST_MD1, $fn, d, args...; kwargs...)

end; end #CODEGEN---------------------------------------------------------------

#Support reducing/collpasing funcitons of DataF1
#-------------------------------------------------------------------------------
const _custredfn1 = [
	:xcross1, :integ, :xmin, :xmax, :value,
]

for fn in _custredfn1; @eval begin #CODEGEN-------------------------------------

$fn(d::DataMD, args...; kwargs...) = broadcastMD(CAST_MDRED1, $fn, d, args...; kwargs...)

end; end #CODEGEN---------------------------------------------------------------


#==Support 2-argument functions of DataF1
===============================================================================#
const _custfn2 = [
	:yvsx,
	:measdelay,
	:measck2q,
]

for fn in _custfn2; @eval begin #CODEGEN----------------------------------------

$fn(d1::DataMD, d2::DataMD, args...; kwargs...) =
	broadcastMD(CAST_MD2, $fn, d1, d2, args...; kwargs...)

end; end #CODEGEN---------------------------------------------------------------

#==Special cases
===============================================================================#
#2nd argument does not have to be DataMD:
#-------------------------------------------------------------------------------
ycross(d1::DataMD, d2, args...; kwargs...) =
	broadcastMD(CastType(DataF1, 1, Number, 2), ycross, d1, d2, args...; kwargs...)
ycross1(d1::DataMD, d2, args...; kwargs...) =
	broadcastMD(CastTypeRed(DataF1, 1, Number, 2), ycross1, d1, d2, args...; kwargs...)

#First argument is ::DS{}
#-------------------------------------------------------------------------------
measdelay(ds::DS, d1::DataMD, d2::DataMD, args...; kwargs...) =
	broadcastMD(CastType(DataF1, 2, DataF1, 3), measdelay, ds, d1, d2, args...; kwargs...)
xcross(ds::DS, d::DataMD, args...; kwargs...) =
	broadcastMD(CastType(DataF1, 2), xcross, ds, d, args...; kwargs...)
xcross1(ds::DS, d::DataMD, args...; kwargs...) =
	broadcastMD(CastTypeRed(DataF1, 2), xcross1, ds, d, args...; kwargs...)

#Last line
