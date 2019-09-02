#= Polyline encoder and decoder

This module performes an encoding and decoding for
gps coordinates into a polyline using the algorithm
detailed in:
https://developers.google.com/maps/documentation/utilities/polylinealgorithm

Example:
    julia> enc = encodePolyline([[38.5 -120.2]; [40.7 -120.95]; [43.252 -126.453]])
    "_p~iF~ps|U_ulLnnqC_mqNvxq`@"

Todo:
    * Add polyline decoding
=#

__precompile__()

module Polyline

export decodePolyline, encodePolyline

# coodrinate is a type to represents a gps data point
struct coordinate{T}
    Lat::T
    Lng::T
end

function roundCoordinate(currValue::coordinate{Float64})::coordinate{Int64}
    #= Convert the coordinate to an integer and round.

    Args:
        currValue (coordinate{Float64}): GPS data point as a real number.
    Returs:
        roundedValue (coordinate{Int64}): GPS data point as rounded integer.
    =#

    roundedValue::coordinate = coordinate{Int64}(copysign(floor(abs(currValue.Lat)), currValue.Lat),
                                                 copysign(floor(abs(currValue.Lng)), currValue.Lng))
    return roundedValue
end

function diffCoordinate(currValue::coordinate{Int64},
                        prevValue::coordinate{Int64})::coordinate{Int64}
    #= Polyline encoding only considers the difference between GPS data points
    in order to reduce memory. diffCoordinate obtains the difference between
    consecutive coordinate points.

    Args:
        currValue (coordinate{Int64}): The current GPS data point.
        prevValue (coordinate{Int64}): The previous GPS data point. The count
                                       starts from 0.
    Returns:
        coordinate{Int64}: The difference between the GPS data points.
    =#

    return coordinate{Int64}(currValue.Lat - prevValue.Lat,
                             currValue.Lng - prevValue.Lng)
end

function leftShiftCoordinate(currValue::coordinate{Int64})::coordinate{Int64}
    #= Left bitwise shift to leave space for a sign bit as the right most bit.

    Args:
        currValue(coordinate{Int64}): The difference between the last two
                                      consecutive GPS data points.
    Returns:
        coordinate{Int64}: Left bitwise shifted values.
    =#

    return coordinate{Int64}(currValue.Lat << 1,
                             currValue.Lng << 1)
end

function convertToChar(currValue::coordinate{Int64})::coordinate{Array{Char, 1}}
    #= Convert the coordinates into ascii symbols.

    Args:
        currValue(coordinate{Int64}): Integer GPS coordinates.

    Returns:
        coordinate{String}: GPS coordinates as ASCII characters.
    =#

    Lat::Int64 = currValue.Lat
    Lng::Int64 = currValue.Lng

    return coordinate{Array{Char, 1}}(encodeToChar(Lat), encodeToChar(Lng))
end

function encodeToChar(c::Int64)::Array{Char, 1}
    #= Perform the encoding of the character from a binary number to ASCII.

    Args:
        c(Int64): GPS coordinate.

    Returns:
        String: ASCII characters of the polyline.
    =#

    LatChars = Array{Char, 1}(undef, 1)

    # Invert a negative coordinate using two's complement
    if c < 0
        c = ~c
    end

    # Add a continuation bit at the LHS for non-last chunks using OR 0x20
    # (0x20 = 100000)
    while c >= 0x20
        # Get the last 5 bits (0x1f)
        # Add 63 (in order to get "better" looking polyline characters in ASCII)
        CharMod = (0x20 | (c & 0x1f)) + 63
        append!(LatChars, Char(CharMod))

        # Shift 5 bits
        c = c >> 5
    end

    # Modify the last chunk
    append!(LatChars, Char(c + 63))

    # The return string holds a beginning character at the start
    # skip it and return the rest
    return LatChars[2:end]
end

function writePolyline!(output::Array{Char, 1}, currValue::coordinate{Float64},
                        prevValue::coordinate{Float64})
    #= Convert the given coordinate points in a polyline and mutate the output.

    Args:
        output(Array{Char, 1}): Holds the resultant polyline.
        currValue(coordinate{Float64}): Current GPS data point.
        prevValue(coordinate{Float64}): Previous GPS data point.

    Returns:
        output(Array{Char, 1}): Mutate output by adding the current addition to the
                                polyline.
    =#

    # Transform GPS coordinates to Integers and round
    roundCurrValue::coordinate{Int64} = roundCoordinate(currValue)
    roundPrevValue::coordinate{Int64} = roundCoordinate(prevValue)

    # Get the difference from the previous GPS coordinated
    diffCurrValue::coordinate{Int64} = diffCoordinate(roundCurrValue, roundPrevValue)

    # Left shift the data points
    leftShift::coordinate{Int64} = leftShiftCoordinate(diffCurrValue)

    # Transform into ASCII
    charCoordinate::coordinate{Array{Char, 1}} = convertToChar(leftShift)

    # Add the characters to the polyline
    append!(output, collect(charCoordinate.Lat))
    append!(output, collect(charCoordinate.Lng))
end

function transformPolyline(value, index)
end

function decodePolyline(expr; precision=5)
end

function encodePolyline(coord::Array{Float64}, precision::Int64=5)
    #= Encodes an array of GPS coordinates to a polyline.

    Args:
        coord(Array{Float64, 1}(undef, 1)): GPS coordinates.
        precision(Int16): Exponent for rounding the GPS coordinates.
    Returns
        String: Polyline encoded GPS coordinates.
    =#

    # Compute the rounding precision
    factor::Float64 = 10. ^precision
    coord = coord .* factor

    output = Array{Char, 1}(undef, 1)

    for c in range(1, stop=size(coord)[1])
        if c == 1
            writePolyline!(output, coordinate{Float64}(coord[c, 1], coord[c, 2]),
                           coordinate{Float64}(0., 0.))
        else
            writePolyline!(output, coordinate{Float64}(coord[c, 1], coord[c, 2]),
                           coordinate{Float64}(coord[c-1, 1], coord[c-1, 2]))
        end
    end

    return join(output[2:end])
end

end # module
