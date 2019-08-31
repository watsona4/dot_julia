"""
ReadableNumStyle field naming
    _integral digits_ preceed the fraction_marker (decimal point)
    _fractional digits_ follow  the fraction_marker (decimal point)
"""
struct ReadableNumStyle
    integral_digits_spanned::Int32
    fractional_digits_spanned::Int32
    between_integral_spans::Char
    between_fractional_spans::Char
    between_parts::Char
end


# default values

const IDIGS = 3%Int32                      # integral_digits_spanned
const FDIGS = 5%Int32                      # fractional_digits_spanned
const IBTWN = FRACPOINT != ',' ? ',' : '.' # between_integral_digits
const FBTWN = '_'                          # between_fractional_digits


# constructors cover likely argument orderings and omisions 

ReadableNumStyle() = ReadableNumStyle(IDIGS, FDIGS, IBTWN, FBTWN, FRACPOINT)

function ReadableNumStyle(
             idigs::I, rdigs::I=FDIGS%I, ibtwn::Char=IBTWN, rbtwn::Char=FBTWN, fracpt::Char=FRACPOINT) where {I <: Integer}
    pns = ReadableNumStyle( idigs%Int32, rdigs%Int32, ibtwn, rbtwn, fracpt )
    set_pretty_number_style!(pns)
    return pns
end    

ReadableNumStyle(
    ibtwn::Char, rbtwn::Char=FBTWN, idigs::I=IDIGS%I, rdigs::I=FDIGS%I, fracpt::Char=FRACPOINT
    ) where {I <: Integer} =
    ReadableNumStyle(idigs, rdigs, ibtwn, rbtwn, fracpt)
ReadableNumStyle(
    idigs::S, ibtwn::Char, rdigs::S=FDIGS%S, rbtwn::Char=FBTWN, fracpt::Char=FRACPOINT
    ) where {S <: Signed} =
    ReadableNumStyle( idigs%Int32, rdigs%Int32, ibtwn, rbtwn, fracpt )
ReadableNumStyle(
    ibtwn::Char, idigs::S, rbtwn::Char=FBTWN, rdigs::S=FDIGS%S, fracpt::Char=FRACPOINT
    ) where {S <: Signed} =
    ReadableNumStyle(idigs, rdigs, ibtwn, rbtwn, fracpt)

ReadableNumStyle(digs::I, btwn::Char, fracpt::Char=FRACPOINT) where {I <: Integer} =
    ReadableNumStyle( digs%Int32, digs%Int32, btwn, btwn, fracpt )
ReadableNumStyle(btwn::Char, digs::I, fracpt::Char=FRACPOINT) where {I <: Integer} =
    ReadableNumStyle( digs, btwn, fracpt )

# remember the most recent pretty number style

const PRETTY_NUMBER_STYLE_HOLDER = [ ReadableNumStyle() ]
function get_pretty_number_style()
    return PRETTY_NUMBER_STYLE_HOLDER[1]
end    
function set_pretty_number_style!(pns::ReadableNumStyle)
    PRETTY_NUMBER_STYLE_HOLDER[1] = pns
    return nothing
end    



# accept extended precision numbers and make them become readable

function readable(x::T, pns::ReadableNumStyle=get_pretty_number_style()) where {T <: Real}
    numstr = string(string(x),FRACPOINT)
    return a_readable_number(numstr, pns)
end

function readable(x::String, pns::ReadableNumStyle=get_pretty_number_style())
    numstr = string(x, FRACPOINT)
    return a_readable_number(numstr, pns)
end    
