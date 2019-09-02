#PhysicalCommunications: Pseudo-Random Bit Sequence Generators/Checkers
#-------------------------------------------------------------------------------


#==Constants
===============================================================================#

#Integer representation of polynomial x^p1 + x^p2 + x^p3 + x^p4 + 1
_poly(p1::Int) = one(UInt64)<<(p1-1)
_poly(p1::Int, p2::Int) = _poly(p1) + _poly(p2)
_poly(p1::Int, p2::Int, p3::Int, p4::Int) = _poly(p1) + _poly(p2) + _poly(p3) + _poly(p4)

#==Maximum-length Linear-Feedback Shift Register (LFSR) polynomials/taps (XNOR form)
Ref: Alfke, Efficient Shift Registers, LFSR Counters, and Long Pseudo-Random
     Sequence Generators, Xilinx, XAPP 052, v1.1, 1996.==#
const MAXLFSR_POLYNOMIAL = [
	_poly(64,64) #1: not supported
	_poly(64,64) #2: not supported
	_poly(3,2) #3
	_poly(4,3) #4
	_poly(5,3) #5
	_poly(6,5) #6
	_poly(7,6) #7
	_poly(8,6,5,4) #8
	_poly(9,5) #9
	_poly(10,7) #10
	_poly(11,9) #11
	_poly(12,6,4,1) #12
	_poly(13,4,3,1) #13
	_poly(14,5,3,1) #14
	_poly(15,14) #15
	_poly(16,15,13,4) #16
	_poly(17,14) #17
	_poly(18,11) #18
	_poly(19,6,2,1) #19
	_poly(20,17) #20
	_poly(21,19) #21
	_poly(22,21) #22
	_poly(23,18) #23
	_poly(24,23,22,17) #24
	_poly(25,22) #25
	_poly(26,6,2,1) #26
	_poly(27,5,2,1) #27
	_poly(28,25) #28
	_poly(29,27) #29
	_poly(30,6,4,1) #30
	_poly(31,28) #31
	_poly(32,22,2,1) #32
]


#==Types
===============================================================================#
abstract type SequenceGenerator end #Defines algorithm used by sequence() to create a bit sequence
abstract type PRBSGenerator <: SequenceGenerator end #Specifically a pseudo-random bit sequence

#Define supported algorithms:
struct MaxLFSR{LEN} <: PRBSGenerator; end #Identifies a "Maximum-Length LFSR" algorithm

#Define iterator & state objects:
struct MaxLFSR_Iter{LEN,TRESULT} #LFSR "iterator" object
	seed::UInt64 #Initial state (easier to define here than creating state in parallel)
	mask::UInt64 #Store mask value since it cannot easily be statically evaluated.
	len::Int
end
mutable struct MaxLFSR_State{LEN}
	reg::UInt64 #Current state of LFSR register
	bitsrmg::Int #How many bits left to generate
end


#==Constructors
===============================================================================#
"""
    MaxLFSR(reglen::Int)

Construct an object used to identify the Maximum-length LFSR algorithm of a given shift register length, `reglen`.
"""
MaxLFSR(reglen::Int) = MaxLFSR{reglen}()


#==Helper functions:
===============================================================================#
#Find next bit & update state:
function _nextbit(state::MaxLFSR_State{LEN}, polymask::UInt64) where LEN
	msb = UInt64(1)<<(LEN-1) #Statically compiles if LEN is known

	#Mask out all "non-tap" bits:
	reg = state.reg | polymask
	bit = msb
	for j in 1:LEN
		bit = ~xor(reg, bit)
		reg <<= 1
	end
	bit = UInt64((bit & msb) > 0) #Convert resultant MSB to an integer

	state.reg = (state.reg << 1) | bit #Leaves garbage @ bits above LEN
	state.bitsrmg -= 1
	return bit
end


#Core algorithm for sequence() function (no kwargs):
function _sequence(::MaxLFSR{LEN}, seed::UInt64, len::Int, output::DataType) where LEN
	ensure(in(LEN, 3:32), ArgumentError("Invalid LFSR register length, $LEN: 3 <= length <= 32"))
	ensure(LEN < 64,
		OverflowError("Cannot build sequence for MaxLFSR{LEN} with LEN=$LEN >= 64."))
	availbits = (UInt64(1)<<LEN)-UInt64(1) #Available LFSR bits
	ensure((seed & availbits) == seed,
		OverflowError("seed=$seed does not fit in LFSR with register length of $LEN."))
	ensure(len>=0, ArgumentError("Invalid sequence length.  len must be non-negative"))

	poly = UInt64(MAXLFSR_POLYNOMIAL[LEN])
	mask = ~poly
	#==Since `1 XNOR A => A`, we can ignore all taps that are not part of the
	polynomial, simply by forcing all non-tap bits to 1 (OR-ing with `~poly`)
	Thus, we build a mask from `~poly`.
	==#

	return MaxLFSR_Iter{LEN, output}(seed, mask, len)
end


#==Iterator interface:
===============================================================================#

Base.length(iter::MaxLFSR_Iter) = iter.len
Base.eltype(iter::MaxLFSR_Iter{LEN, TRESULT}) where {LEN, TRESULT} = TRESULT
Iterators.IteratorSize(iter::MaxLFSR_Iter) = Base.HasLength()

function Iterators.iterate(iter::MaxLFSR_Iter{LEN, TRESULT}, state::MaxLFSR_State{LEN}) where {LEN, TRESULT}
	if state.bitsrmg < 1
		return nothing
	end
	bit = _nextbit(state, iter.mask)

	return (TRESULT(bit), state)
end

function Iterators.iterate(iter::MaxLFSR_Iter{LEN}) where LEN
	state = MaxLFSR_State{LEN}(iter.seed, iter.len)
	return iterate(iter, state)
end


#==High-level interface
===============================================================================#
"""
    sequence(t::SequenceGenerator; seed::Integer=11, len::Int=-1, output::DataType=Int)

Create an iterable object that defines a bit sequence of length `len`.

Inputs:
  - t: Instance defining type of algorithm used to generate bit sequence.
  - seed: Initial value of register used to build sequence.
  - len: Number of bits in sequence.
  - output: DataType used for sequence elements (typical values are `Int` or `Bool`).

Example returning the first `1000` bits of a PRBS-`31` pattern constructed with the Maximum-length LFSR algorithm seeded with an initial register value of `11`.:

    pattern = collect(sequence(MaxLFSR(31), seed=11, len=1000, output=Bool)).
"""
sequence(t::MaxLFSR; seed::Integer=11, len::Int=-1, output::DataType=Int) =
	_sequence(t, UInt64(seed), len, output)

"""
    sequence_detecterrors(t::SequenceGenerator, v::Array)

Tests validity of bit sequence using sequence generator algorithm.

NOTE: Seeded from first bits of sequence in v.
"""
function sequence_detecterrors(t::MaxLFSR{LEN}, v::Vector{T}) where {LEN, T<:Number}
	ensure(length(v) > LEN, ArgumentError("Pattern vector too short to test validity (must be at least > $LEN)"))

	if Bool == T
		#Will be valid
	else
		for i in 1:length(v)
			ensure(v[i]>=0 && v[i]<=1, ArgumentError("Sequence value not ∉ [0,1] @ index $i.)"))
		end
	end

	#Build seed register for Max LFSR algorithm:
	_errors = similar(v)
	seed = UInt64(0)
	for i in 1:LEN
		seed = (seed << 1) | UInt64(v[i])
		_errors[i] = 0
	end

	#Test for errors in remaining sequence:
	iter = _sequence(t, seed, length(v)-LEN, T)
	state = MaxLFSR_State{LEN}(iter.seed, iter.len)
	for i in (LEN+1):length(_errors)
		(b, state) = iterate(iter, state)
		_errors[i] = convert(T, b!=v[i])
	end

	return _errors
end

#Last line
