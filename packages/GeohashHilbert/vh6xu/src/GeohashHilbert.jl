module GeohashHilbert

export encode, decode, decode_exactly, rectangle, neighbours

"Using Base.ImmutableDict in place of Dict for `ORDERING` and
`HILBERT_RECURSION` seems to provide a ~2x performance gain. Strangely,
there's not a simple constructor taking a Dict to an ImmutableDict. So,
this function recursively converts `Dict`s to `ImmutableDict`s."
function dict_to_idict(dict::T where T <: Dict)
    ks = keys(dict)
    dict_vt = valtype(dict)
    if dict_vt <: Dict
        new_vt = Base.ImmutableDict{keytype(dict_vt), valtype(dict_vt)}
    else
        new_vt = dict_vt
    end
    idict = Base.ImmutableDict{keytype(dict), new_vt}()
    for k in ks
        idict = Base.ImmutableDict(idict, k => dict_to_idict(dict[k]))
    end
    return idict
end
function dict_to_idict(notdict)
    return notdict
end

# define the ordering of each orientation of a hilbert curve
# note that there are multiple possible global orientations of the Hilbert curve
# corresponding to rotations and reflections
# we use an orientation with global shape Π starting in the lower left
@enum HilbertOrientation UUp ULeft UDown URight # U ] Π [
@enum Quadrant LowerLeft LowerRight UpperLeft UpperRight
const ORDERING = dict_to_idict(Dict(
    UUp => Dict(UpperRight => 1, LowerRight => 2, LowerLeft => 3, UpperLeft => 4),
    ULeft => Dict(LowerLeft => 1, LowerRight => 2, UpperRight => 3, UpperLeft => 4),
    UDown => Dict(LowerLeft => 1, UpperLeft => 2, UpperRight => 3, LowerRight => 4),
    URight => Dict(UpperRight => 1, UpperLeft => 2, LowerLeft => 3, LowerRight => 4)
))
# define the recursive nature of the Hilbert curve
const HILBERT_RECURSION = dict_to_idict(Dict(
    UUp => Dict(UpperRight => URight, LowerRight => UUp, LowerLeft => UUp, UpperLeft => ULeft),
    ULeft => Dict(LowerLeft => UDown, LowerRight => ULeft, UpperRight => ULeft, UpperLeft => UUp),
    UDown => Dict(LowerLeft => ULeft, UpperLeft => UDown, UpperRight => UDown, LowerRight => URight),
    URight => Dict(UpperRight => UUp, UpperLeft => URight, LowerLeft => URight, LowerRight => UDown)
))
# e.g. in a UDown oriented curve, the lower left quadrant is a ULeft oriented curve


# the 64 digits we use for 6 bits_per_char encodings
const BASE64_CHARS = "0123456789@ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"
const BASE64_MAP = Dict(BASE64_CHARS[i] => i - 1 for i in 1:length(BASE64_CHARS))

"Encode an integer using 6 bits per character; return a string of the specified number of
characters. `nchar` must be large enough to encode `x`: ``x < 64^nchar``."
function base64_encode_int(x, nchar, charlist = BASE64_CHARS)
    chars = fill('0', nchar)
    for i in nchar : -1 : 1
        x, rem = divrem(x, 64)
        chars[i] = charlist[rem + 1]
    end
    return String(chars)
end

"Decode a base 64 encoded string back into an integer. This function will error if
any of the characters in the passed string are not in `BASE64_CHARS`."
function base64_decode_string(s, charmap = BASE64_MAP)
    # walk the string from right to left, i.e. least to most significant digit
    # note: this will throw an exception on non-ASCII strings! But, avoiding
    # something like eachindex avoids allocation.
    cursum = 0
    mult = 1
    for i in length(s) : -1 : 1
        cursum += mult * charmap[s[i]]
        mult *= 64
    end
    return cursum
end

"Convert an integer to a string of specified (minimumn) length and bits per character
encoding. For 2 and 4 bits per character, this is equivalent to converting to a string at
base `2^bits_per_char`. For 6 bits per character, a different method is required since
Julia's built in `string` doesn't support base 64 encoding."
function int_to_str(x::Int, nchar, bits_per_char = 2)
    bits_per_char == 2 && return string(x; base = 4, pad = nchar)
    bits_per_char == 4 && return string(x; base = 16, pad = nchar)
    bits_per_char == 6 && return base64_encode_int(x, nchar)
    error("bits_per_char must be in [2,4,6]")
end

"Parse a string encoded via `int_to_str` into an integer. The `bits_per_char` used to
encode the string must be specified."
function str_to_int(s::AbstractString, bits_per_char = 2)
    bits_per_char == 2 && return parse(Int, s, base = 4)
    bits_per_char == 4 && return parse(Int, s, base = 16)
    bits_per_char == 6 && return base64_decode_string(s)
    error("bits_per_char must be in [2,4,6]")
end

"""
    encode(lon, lat, precision, bits_per_char = 2)

Encode a longitude-latitude pair as a geohash string. The length of the resulting geohash
is `precision`, so higher `precision` gives a finer grained encoding. Return the geohash
string.

# Arguments
- `lon::Real`: longitude in degrees of point to encode. Must be in [-180,180].
- `lat::Real`: latitude in degrees of point to encode. Must be in [-90,90].
- `precision::Integer`: precision of returned geohash. Must be positive.
- `bits_per_char ∈ [2,4,6]`: how many bits of information each character encodes.

!!! note
    To avoid overflow in machine arithmetic, `precision * bits_per_char` must be <= 62.
    This still allows meter-level granularity. If your use case requires sub-meter
    granularity, you may wish to reconsider using longitude-latitude coordinates.
"""
function encode(lon, lat, precision::Integer, bits_per_char = 2)
    -90 <= lat <= 90 || throw(DomainError(lat, "`lat` must be between ± 90"))
    -180 <= lon <= 180 || throw(DomainError(lon, "`lon` must be between ± 180"))
    precision > 0 || throw(DomainError(precision, "`precision` must be greater than 0."))
    # Limits of 64 bit signed integer arithmetic mean we have to limit precision to avoid
    # overflow. We could mitigate this by a bit by using unsigned integers and completely
    # at significant performance cost by using BigInt.
    if precision * bits_per_char > 62
        throw(DomainError(
            (precision, bits_per_char),
            "`precision * bits_per_char` must be <= 62."
        ))
    end

    encode_bits = precision * bits_per_char
    n = 2^(encode_bits ÷ 2)
    x, y = lonlat_to_xy(lon, lat, n)
    curve_spot = xy_to_int(x, y, n)
    return int_to_str(curve_spot, precision, bits_per_char)
end

"""
Convert lon-lat coordinates to a (rounded) `x,y` integer point in the
`n` by `n` grid covering lon-lat space. Returned `x,y` are in [1...n].
"""
function lonlat_to_xy(lon, lat, n)
    # awkward 1+floor rounding to keep xy mapping for lon-lat exactly on
    # cell boundaries consistent with python package GeohashHilbert
    x = min(n, 1 + floor(Int, (lon + 180) / 360 * n))
    y = min(n, 1 + floor(Int, (lat + 90) / 180 * n))
    return x, y
end

"""
Convert `x,y` coordinates in the `n` by `n` grid covering lon-lat space
to longitude-latitude coordinates. The coordinates returned correspond to the
center of the `(x,y)`-th grid rectangle.
"""
function xy_to_lonlat(x, y, n)
    lon_grid_size = 360 / n
    lon = -180 + lon_grid_size * (x - .5)
    lat_grid_size = 180 / n
    lat = -90 + lat_grid_size * (y - .5)
    return lon, lat
end

"""
Convert coordinates `(x,y)` to an integer representing steps along the Hilbert curve filling
a `n` by `n` grid. `n` must be a power of 2 and `x,y` should be integers in `[1...n]`. The
returned integer will be between 0 (no steps along the curve, i.e. the lower-left grid cell)
and n^2 - 1 (the last square along the Hilbert curve, namely the lower-right grid cell)
inclusive.
"""
function xy_to_int(x::Int, y::Int, n::Int)
    1 <= x <= n || throw(DomainError((x, y, n), "x must be in [1,n]"))
    1 <= y <= n || throw(DomainError((x, y, n), "y must be in [1,n]"))

    cur_orientation = UDown
    cur_quadrant_size = n ÷ 2
    # steps is steps along the curve, starting with the lower left most point
    # being 0 steps along the curve
    # it might be more natural to use 1-based Julian-style indexing, but given
    # the goal of matching the Python package as closely as possible, this 0-based
    # ends up simplifying the overall code.
    steps = 0

    while cur_quadrant_size > 0
        quadrant = get_quadrant(x, y, cur_quadrant_size)
        n_previous_quadrants = ORDERING[cur_orientation][quadrant] - 1
        # steps to get to this quadrant
        steps += n_previous_quadrants * cur_quadrant_size^2
        # now iterate within the quadrant
        if x > cur_quadrant_size
            x -= cur_quadrant_size
        end
        if y > cur_quadrant_size
            y -= cur_quadrant_size
        end
        cur_orientation = HILBERT_RECURSION[cur_orientation][quadrant]
        cur_quadrant_size ÷= 2
    end

    return steps
end

"""
Convert an integer `t` to `x,y` coordinates in `[1...n]` by `[1...n]` with `(1,1)`
representing the lower left. `t` represents steps from the first (lower left) square of the
grid, so legal values of `t` are in [0,n^2).
"""
function int_to_xy(t::Int, n::Int)
    if !(0 <= t < n^2)
        throw(DomainError((t,n), "t passed to int_to_xy must be in [0, n^2 - 1]."))
    end

    cur_orientation = UDown
    cur_quadrant_size = n ÷ 2
    x = 1
    y = 1

    while cur_quadrant_size > 0
        pts_per_quadrant = cur_quadrant_size^2
        quadrant_index = 1
        # >= check because t is steps from the first xy square
        # so if eg t is exactly pts_per_quadrant, then the xy to return is
        # the first point of the second quadrant, not the last point of
        # the first quadrant.
        while t >= pts_per_quadrant
            quadrant_index += 1
            t -= pts_per_quadrant
        end
        quadrant = find_quadrant(quadrant_index, cur_orientation)
        if quadrant == UpperLeft || quadrant == UpperRight
            y += cur_quadrant_size
        end
        if quadrant == LowerRight || quadrant == UpperRight
            x += cur_quadrant_size
        end
        cur_orientation = HILBERT_RECURSION[cur_orientation][quadrant]
        cur_quadrant_size ÷= 2
    end

    return x, y
end

# for a given quadrant index (1-4) and orientation,
# find the quadrant (eg UpperLeft) of the corresponding index
# there's probably a small absolute but large relative efficiency gain
# to be had by making a REVERSE_ORDERING dict or using a different data structure
function find_quadrant(quad_index, orientation::HilbertOrientation)::Quadrant
    if !(1 <= quad_index <= 4)
        throw(DomainError(quad_index, "quad_index must be in [1,2,3,4]"))
    end
    for quad in instances(Quadrant)
        if ORDERING[orientation][quad] == quad_index
            return quad
        end
    end
    error("Couldn't find position of quad index $(quad_index) for orientation $(orientation)")
end

@inline function get_quadrant(x, y, quad_size)
    x <= quad_size && y <= quad_size && return LowerLeft
    x > quad_size && y <= quad_size && return LowerRight
    x <= quad_size && y > quad_size && return UpperLeft
    return UpperRight
end

"""
    decode(geohash, bits_per_char = 2)

Given a `geohash` string at a specified `bits_per_char`, return the coordinates of the
corresponding geohash cell's center as a tuple `(lon, lat)`.

See also: [`decode_exactly`](@ref)
"""
function decode(geohash, bits_per_char = 2)
    precision = length(geohash)
    curve_spot = str_to_int(geohash, bits_per_char)
    n = 2^(precision * bits_per_char ÷ 2)
    x, y = int_to_xy(curve_spot, n)
    return xy_to_lonlat(x, y, n)
end

"""
    decode_exactly(geohash, bits_per_char)

Given a `geohash` string at a specified `bits_per_char`, return the coordinates of the
corresponding geohash cell's center and the error margins as a tuple
`(lon, lat, lon_err, lat_err)`. That is, each point in the corresponding cell has
longitude within `lon` ± `lon_err` and likewise for latitude.

See also: [`rectangle`](@ref)
"""
function decode_exactly(geohash, bits_per_char = 2)
    precision = length(geohash)
    lon, lat = decode(geohash, bits_per_char)
    lon_rect_size, lat_rect_size = cell_size_deg(precision, bits_per_char)
    return lon, lat, lon_rect_size / 2, lat_rect_size / 2
end

"Compute the size in longitude/latitude degrees of geohash rectangles
for a given precision level and bits per character (default 2). Return
a tuple `(lon_size, lat_size)`"
function cell_size_deg(precision, bits_per_char = 2)
    n = 2^(precision * bits_per_char ÷ 2)
    return 360 / n, 180 / n
end

"""
    neighbours(geohash, bits_per_char = 2)

Compute the geohashes of the cells neighboring the specified geohash cell. Return a
dictionary keyed by "north", "north-east", "east", etc. and with values the geohash string
of the corresponding adjacent cell at the same precision and bits per character. Note that
cells near the poles will have only five neighbors.
"""
function neighbours(geohash, bits_per_char = 2)
    lon, lat, lon_err, lat_err = decode_exactly(geohash, bits_per_char)
    prec = length(geohash)

    north = lat + 2 * lat_err
    south = lat - 2 * lat_err
    east = lon + 2 * lon_err
    west = lon - 2 * lon_err

    # wrap around the lon = +/- 180 line
    east > 180 && (east -= 360)
    west < -180 && (west += 360)

    neigh_dict = Dict{String, String}(
        "east" => encode(east, lat, prec, bits_per_char),
        "west" => encode(west, lat, prec, bits_per_char)
    )

    if north <= 90 # input cell isn't already at the north pole
        neigh_dict = merge(neigh_dict, Dict{String, String}(
            "north-east" => encode(east, north, prec, bits_per_char),
            "north" => encode(lon, north, prec, bits_per_char),
            "north-west" => encode(west, north, prec, bits_per_char)
        ))
    end

    if south >= -90 # input cell isn't already at the south pole
        neigh_dict = merge(neigh_dict, Dict{String, String}(
            "south-west" => encode(west, south, prec, bits_per_char),
            "south" => encode(lon, south, prec, bits_per_char),
            "south-east" => encode(east, south, prec, bits_per_char)
        ))
    end

    return neigh_dict

end

"""
    rectangle(geohash, bits_per_char = 2)

Return a GeoJSON Dict that encodes as a Feature the rectangle associated with a given
`geohash`.
"""
function rectangle(geohash, bits_per_char = 2)

    lon, lat, lon_err, lat_err = decode_exactly(geohash, bits_per_char)

    return Dict{Any, Any}(
        "type" => "Feature",
        "properties" => Dict{Any, Any}(
            "code" => geohash,
            "lon" => lon,
            "lat" => lat,
            "lon_err" => lon_err,
            "lat_err" => lat_err,
            "bits_per_char" => bits_per_char,
        ),
        "bbox" => (
            lon - lon_err,  # bottom left
            lat - lat_err,
            lon + lon_err,  # top right
            lat + lat_err,
        ),
        "geometry" => Dict{Any, Any}(
            "type" => "Polygon",
            "coordinates" => [[
                (lon - lon_err, lat - lat_err),
                (lon + lon_err, lat - lat_err),
                (lon + lon_err, lat + lat_err),
                (lon - lon_err, lat + lat_err),
                (lon - lon_err, lat - lat_err),
            ]],
        ),
    )
end

end # module
