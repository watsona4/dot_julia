"""
    wcs_to_celestial_frame(wcs::WCSTransform)

Returns the reference frame of a WCSTransform.
The reference frame supported in Julia are FK5, ICRS and Galactic.
"""
function wcs_to_celestial_frame(wcs::WCSTransform)
    radesys = wcs.radesys

    xcoord = wcs.ctype[1][1:4]
    ycoord = wcs.ctype[2][1:4]

    if radesys == ""
        if xcoord == "GLON" && ycoord == "GLAT"
            radesys = "Gal"
        elseif xcoord == "TLON" && ycoord == "TLAT"
            radesys = "ITRS"
        end
    end

    return radesys
end

"""
    pad_edges(array_in::Matrix{T}) where {T}

Pads a given array and creates a border with edge elements.
"""
function pad_edges(array_in::Matrix{T}) where {T}
    image = Matrix{T}(undef, size(array_in)[1] + 2, size(array_in)[2] + 2)
    image[2:end-1,2:end-1] = array_in
    image[2:end-1,1] = array_in[:,1]
    image[2:end-1,end] = array_in[:,end]
    image[1,:] = image[2,:]
    image[end,:] = image[end-1,:]
    return image
end
