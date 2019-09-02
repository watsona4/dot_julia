#InspectDR: Glyph definitions
#-------------------------------------------------------------------------------

#=TODO:
   -deprecate :diagcross?
   -add :asterisk?
=#

#==Constants
===============================================================================#
const SUPPORTED_GLYPHS = Symbol[
	:+, :cross, :x, :xcross, :diagcross,
	:o, :circle,
	:*,
	:square, :diamond,
	:utriangle, :dtriangle, :ltriangle, :rtriangle,
	:uarrow, :darrow, :larrow, :rarrow, #Currently implements triangles
	:star, :star4, :star5, :star6, :star7, :star8,
	:pentagon, :hexagon, :heptagon, :octagon,
	:hline, :vline,
]


#==Main types
===============================================================================#
abstract type Glyph end

struct GlyphCircle <: Glyph
	radius::DReal
end
struct GlyphPolyline <: Glyph
	#TODO: Should we just store deltas? would be more efficient!
	x::Vector{DReal}
	y::Vector{DReal}
	closepath::Bool
end
GlyphPolyline(x, y; closepath::Bool=true, scale::DReal=1.0) =
	GlyphPolyline(x*scale, y*scale, closepath)
struct GlyphLineSegments <: Glyph
	x1::Vector{DReal}
	x2::Vector{DReal}
	y1::Vector{DReal}
	y2::Vector{DReal}
end
#NOTE: defining x1::Vector so that we can add "scale" keyword without re-definition issues.
GlyphLineSegments(x1::Vector, x2, y1, y2; scale::DReal=1.0) =
	GlyphLineSegments(x1*scale, x2*scale, y1*scale, y2*scale)


#==Helper functions
===============================================================================#
isglyph(::Glyph) = true
isglyph(s::Symbol) = (s != :none) #Not necessarily a valid glyph id

#==Generator functions
===============================================================================#
function _stargenerator(n::Int, webscale::DReal; scale::DReal=1.0)
	x = Vector{DReal}(undef, 2*n)
	y = Vector{DReal}(undef, 2*n)
	ϕ = range(0, stop=2*pi, length=2*n+1)

	for i in 1:2:length(x)
		x[i] = sin(ϕ[i])
		y[i] = cos(ϕ[i])
		x[i+1] = webscale*sin(ϕ[i+1])
		y[i+1] = webscale*cos(ϕ[i+1])
	end

	return GlyphPolyline(x, y, scale=scale)
end

function _polygongenerator(n::Int; scale::DReal=1.0)
	x = Vector{DReal}(undef, n)
	y = Vector{DReal}(undef, n)
	ϕ = range(0, stop=2*pi, length=n+1)

	for i in 1:length(x)
		x[i] = sin(ϕ[i])
		y[i] = cos(ϕ[i])
	end

	return GlyphPolyline(x, y, scale=scale)
end

function ptmap_rotate(g::GlyphPolyline, Θ::Float64)
	cosΘ = cos(Θ); sinΘ = sin(Θ) #WANTCONST
	x = similar(g.x); y = similar(g.y)
	for i in 1:length(g.x)
		xi = g.x[i]; yi = g.y[i]
		x[i] = xi*cosΘ - yi*sinΘ
		y[i] = xi*sinΘ + yi*cosΘ
	end
	return GlyphPolyline(x, y)
end

#==Predefined glyphs (implicitly defines relative sizes)
===============================================================================#
const GLYPH_CIRCLE = GlyphCircle(0.5)
const GLYPH_SQUARE = GlyphPolyline(
	[-1, 1, 1,-1], #x
	[ 1, 1,-1,-1], #y
	scale = 0.5
)
const GLYPH_DIAMOND = GlyphPolyline(
	[0, 1, 0,-1], #x
	[1, 0,-1, 0], #y
	scale = 0.6
)
const GLYPH_UTRIANGLE = GlyphPolyline(
	[ 0, 1, -1], #x
	[ 1,-1, -1], #y
	scale = 0.5
)
const GLYPH_DTRIANGLE = GlyphPolyline(
	[ 0, 1, -1], #x
	[-1, 1,  1], #y
	scale = 0.5
)
const GLYPH_LTRIANGLE = GlyphPolyline(
	[-1, 1,  1], #x
	[ 0, 1, -1], #y
	scale = 0.5
)
const GLYPH_RTRIANGLE = GlyphPolyline(
	[1, -1, -1], #x
	[0,  1, -1], #y
	scale = 0.5
)
const GLYPH_CROSS = GlyphPolyline(
	[-1, +1, +1, +4, +4, +1, +1, -1, -1, -4, -4, -1], #x
	[+4, +4, +1, +1, -1, -1, -4, -4, -1, -1, +1, +1], #y
	scale = 1/8
)
const GLYPH_LINECROSS = GlyphLineSegments(
	[-1, 0], [ 1, 0], #x1, x2
	[ 0,-1], [ 0, 1], #y1, y2
	scale = sqrt(2)/2
)
const GLYPH_XCROSS = ptmap_rotate(GLYPH_CROSS, pi/4)
const GLYPH_LINEXCROSS = GlyphLineSegments(
	[-1,-1], [ 1, 1], #x1, x2
	[ 1,-1], [-1, 1], #y1, y2
	scale = 0.5
)
const GLYPH_ASTERISK = GlyphLineSegments(
	vcat(GLYPH_LINECROSS.x1, GLYPH_LINEXCROSS.x1), vcat(GLYPH_LINECROSS.x2, GLYPH_LINEXCROSS.x2),
	vcat(GLYPH_LINECROSS.y1, GLYPH_LINEXCROSS.y1), vcat(GLYPH_LINECROSS.y2, GLYPH_LINEXCROSS.y2),
)
const GLYPH_HLINE = GlyphLineSegments(
	[-1], [ 1], #x1, x2
	[ 0], [ 0], #y1, y2
	scale = sqrt(2)/2
)
const GLYPH_VLINE = GlyphLineSegments(
	[ 0], [0], #x1, x2
	[-1], [1], #y1, y2
	scale = sqrt(2)/2
)
const GLYPH_STAR4 = _stargenerator(4, .5, scale=0.7)
const GLYPH_STAR5 = _stargenerator(5, .5, scale=0.7)
const GLYPH_STAR6 = _stargenerator(6, .5, scale=0.7)
const GLYPH_STAR7 = _stargenerator(7, .5, scale=0.7)
const GLYPH_STAR8 = _stargenerator(8, .5, scale=0.7)
const GLYPH_PENTAGON = _polygongenerator(5, scale=0.6)
const GLYPH_HEXAGON = _polygongenerator(6, scale=0.6)
const GLYPH_HEPTAGON = _polygongenerator(7, scale=0.6)
const GLYPH_OCTAGON = _polygongenerator(8, scale=0.6)


#==Scaling functions
===============================================================================#
#TODO: Could scale once for all points (more efficient)
#_scale(p::GlyphPolyline, _size::DReal) =
#	GlyphPolyline(p.x*_size, p.y*_size, p.closepath)


#==Accessors
===============================================================================#
Glyph(g::Glyph) = g #Passthrough.
function Glyph(s::Symbol)
	#TODO: use Map instead?  precompile issues?
	s == :o && return GLYPH_CIRCLE
	s == :+ && return GLYPH_LINECROSS
	s == :x && return GLYPH_LINEXCROSS
	s == :* && return GLYPH_ASTERISK

	s == :circle && return GLYPH_CIRCLE
	s == :square && return GLYPH_SQUARE
	s == :diamond && return GLYPH_DIAMOND

	s == :utriangle && return GLYPH_UTRIANGLE
	s == :dtriangle && return GLYPH_DTRIANGLE
	s == :ltriangle && return GLYPH_LTRIANGLE
	s == :rtriangle && return GLYPH_RTRIANGLE
	s == :uarrow && return GLYPH_UTRIANGLE
	s == :darrow && return GLYPH_DTRIANGLE
	s == :larrow && return GLYPH_LTRIANGLE
	s == :rarrow && return GLYPH_RTRIANGLE

	s == :cross && return GLYPH_CROSS
	s == :xcross && return GLYPH_XCROSS
	s == :diagcross && return GLYPH_XCROSS

	s == :star && return GLYPH_STAR5
	s == :star4 && return GLYPH_STAR4
	s == :star5 && return GLYPH_STAR5
	s == :star6 && return GLYPH_STAR6
	s == :star7 && return GLYPH_STAR7
	s == :star8 && return GLYPH_STAR8

	s == :pentagon && return GLYPH_PENTAGON
	s == :hexagon && return GLYPH_HEXAGON
	s == :heptagon && return GLYPH_HEPTAGON
	s == :octagon && return GLYPH_OCTAGON

	s == :hline && return GLYPH_HLINE
	s == :vline && return GLYPH_VLINE

	if isglyph(s) #Glyph requested, but not supported
		@warn("Glyph shape not supported: $s")
	end
	return nothing
end

#Last line
