"""
    parse_input_data(input_data::ImageHDU)
    parse_input_data(input_data::Tuple{AbstractArray, WCSTransform})
    parse_input_data(input_data::String, hdu_in)
    parse_input_data(input_data::FITS, hdu_in)

Parse input data and returns an Array and WCS object.

# Arguments
- `input_data`: image to reproject which can be name of a FITS file,
                an ImageHDU or a FITS file.
- `hdu_in`: used to set HDU to use when more than one HDU is present.
"""
function parse_input_data(input_data::ImageHDU)
    return read(input_data), WCS.from_header(read_header(input_data, String))[1]
end

function parse_input_data(input_data::Tuple{AbstractArray, WCSTransform})
    return input_data[1], input_data[2]
end

function parse_input_data(input_data::String, hdu_in)
    return parse_input_data(FITS(input_data), hdu_in)
end

function parse_input_data(input_data::FITS, hdu_in)
    return parse_input_data(input_data[hdu_in])
end


# TODO: extend support for passing FITSHeader when FITSHeader to WCSTransform support is possible.


"""
    parse_output_projection(output_projection::WCSTransform, shape_out)
    parse_output_projection(output_projection::ImageHDU; shape_out)
    parse_output_projection(output_projection::String, hdu_number)
    parse_output_projection(output_projection::FITS, hdu_number)

Parse output projection and returns a WCS object and shape of output.

# Arguments
- `output_projection`: WCS information about the image to be reprojected which can be
                       name of a FITS file, an ImageHDU or WCSTransform.
- `shape_out`: shape of the output image.
- `hdu_number`: specifies HDU number when file name is given as input.
"""
function parse_output_projection(output_projection::WCSTransform, shape_out)
    if length(shape_out) == 0
        throw(DomainError(shape_out, "The shape of the output image should not be an empty tuple"))
    end

    return output_projection, shape_out
end

function parse_output_projection(output_projection::ImageHDU, shape_out)
    wcs_out = WCS.from_header(read_header(output_projection, String))[1]
    if shape_out === nothing
        shape_out = size(output_projection)
    end
    if length(shape_out) == 0
        throw(DomainError(shape_out, "The shape of the output image should not be an empty tuple"))
    end
    return wcs_out, shape_out
end

function parse_output_projection(output_projection::String, hdu_number)
    parse_output_projection(FITS(output_projection), hdu_number)
end

function parse_output_projection(output_projection::FITS, hdu_number)
    wcs_out = WCS.from_header(read_header(output_projection[hdu_number], String))[1]

    if output_projection[hdu_number] isa ImageHDU
        shape_out = size(output_projection[hdu_number])
    else
        throw(ArgumentError("Given FITS file doesn't have ImageHDU"))
    end

    return wcs_out, shape_out
end
