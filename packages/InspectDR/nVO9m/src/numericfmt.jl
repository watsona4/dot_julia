#InspectDR: Numeric formatting
#-------------------------------------------------------------------------------


#==Constants
===============================================================================#
import NumericIO: UTF8_MINUS_SYMBOL, UTF8_INF_STRING
import NumericIO: UEXPONENT


#==Main types
===============================================================================#

#Convenience aliases
const NumericFormatting = NumericIO.IOFormattingReal
const ExponentFormatting = NumericIO.IOFormattingExp

abstract type RangeDisplayInfo end

#Hints on how to display numbers in a linear range:
struct LinearRangeDisplayInfo <: RangeDisplayInfo
	exp_min::Float64 #Base-10 exponent for max value
	exp_max::Float64 #Base-10 exponent for min value
	exp_step::Float64 #Base-10 exponent for step size
end
LinearRangeDisplayInfo() = LinearRangeDisplayInfo(0,0,0)

struct NoRangeDisplayInfo <: RangeDisplayInfo; end

#How to display tick labels:
struct TickLabelFormatting
	fmt::NumericFormatting
	splitexp::Bool #Only possible when !fmt.decfloating
end


mutable struct TickLabelStyle
	expdisplay::ExponentFormatting
	ndigits::NullOr{Int} #Force # of digits displayed
	decpos::NullOr{Int} #User-defined exponent for all displayed numbers
	commonexp::Bool #Use same exponent value for all displayed numbers
	showexp0::Bool
	splitexp::Bool #Only possible with Integer decpos or commonexp=true
end
TickLabelStyle(expdisplay::ExponentFormatting=UEXPONENT; ndigits=nothing,
		decpos=nothing, commonexp=true, showexp0=false, splitexp=true) =
	TickLabelStyle(expdisplay, ndigits, decpos, commonexp, showexp0, splitexp)


#==Helper functions
===============================================================================#
finiteornan(x::Float64) = isfinite(x) ? x : NaN

base10exp(v::Float64) = floor(log10(abs(v)))

#Get exponent string only:
function formatted_exp(fmt::NumericFormatting)
	s = IOBuffer()
	NumericIO.print_formatted_exp(s, fmt)
	d = s.data
	resize!(d, s.size)
	return String(d)
end


#==Other "constructors"
===============================================================================#

number_fmt(expdisplay::ExponentFormatting=UEXPONENT; ndigits=3,
		decpos=1, decfloating=true, eng=true, showexp0=false) =
	NumericIO.IOFormattingReal(expdisplay, ndigits=ndigits, decpos=decpos, decfloating=decfloating,
		showexp0=showexp0, eng=eng, minus=UTF8_MINUS_SYMBOL, inf=UTF8_INF_STRING,
	)

TickLabelFormatting(::NoRangeDisplayInfo) =
	TickLabelFormatting(number_fmt(ndigits=3, decfloating=true), false)

TickLabelFormatting(style::TickLabelStyle, rng::NoRangeDisplayInfo) =
	TickLabelFormatting(rng)

function TickLabelFormatting(style::TickLabelStyle, rng::LinearRangeDisplayInfo)
#TODO: Simplify/improve logic in this function.  Also: improve test coverage.
	decpos = style.decpos
	finite_expmin = finiteornan(rng.exp_min)
	finite_expmax = finiteornan(rng.exp_max)
	expmax = max(finite_expmin, finite_expmax)
	if !isfinite(expmax)
		expmax = rng.exp_step+1
	end

	decfloating = (nothing == decpos && !style.commonexp)
	splitexp = style.splitexp && !decfloating #Only possible when !decfloating

	ndigits = style.ndigits
	if nothing == ndigits
		ndigits = 3 #Default
		digitdelta1 = abs(expmax-rng.exp_step)
		digitdelta2 = 0
		if decpos != nothing
			digitdelta2 = decpos-rng.exp_step #In case decpos fixed much higher than data
		end
		digitdelta = max(digitdelta1, digitdelta2)
		if isfinite(digitdelta)
			ndigits = round(Int, digitdelta)+1
		end
	end

	if decfloating
		decpos = 0 #Formatting tool requires integer value
	elseif !decfloating
		decpos = expmax #Starting point for optimal decimal position.
		if !isfinite(decpos); decpos = 0; end #Algorithm requires finite decpos.
		decpos = round(Int, decpos) #Just in case
		decpos = floor(Int, decpos/3)*3

#=
		const MAXDIGITS = 5 #Before using exponential notation
		if decpos >= 0 && decpos <= MAXDIGITS && expmax <= MAXDIGITS
			decpos = 0
		elseif decpos < 0 && decpos >= MAXDIGITS && rng.exp_step >= MAXDIGITS
			decpos = 0
		end
=#
	end

	fmt = number_fmt(style.expdisplay, ndigits=ndigits,
		decpos=decpos, decfloating=decfloating, showexp0=style.showexp0
	)
	return TickLabelFormatting(fmt, splitexp)
end


#Last line
