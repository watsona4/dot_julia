"""
    refco(phpa, tc, rh, wl)

Determine the constants A and B in the atmospheric refraction model
dZ = A tan Z + B tan^3 Z.

Z is the "observed" zenith distance (i.e. affected by refraction)
and dZ is what to add to Z to give the "topocentric" (i.e. in vacuo)
zenith distance.

### Given ###

- `phpa`: Pressure at the observer (hPa = millibar)
- `tc`: Ambient temperature at the observer (deg C)
- `rh`: Relative humidity at the observer (range 0-1)
- `wl`: Wavelength (micrometers)

### Returned ###

- `refa`: tan Z coefficient (radians)
- `refb`: tan^3 Z coefficient (radians)

### Notes ###

1. The model balances speed and accuracy to give good results in
   applications where performance at low altitudes is not paramount.
   Performance is maintained across a range of conditions, and
   applies to both optical/IR and radio.

2. The model omits the effects of (i) height above sea level (apart
   from the reduced pressure itself), (ii) latitude (i.e. the
   flattening of the Earth), (iii) variations in tropospheric lapse
   rate and (iv) dispersive effects in the radio.

   The model was tested using the following range of conditions:

     lapse rates 0.0055, 0.0065, 0.0075 deg/meter
     latitudes 0, 25, 50, 75 degrees
     heights 0, 2500, 5000 meters ASL
     pressures mean for height -10% to +5% in steps of 5%
     temperatures -10 deg to +20 deg with respect to 280 deg at SL
     relative humidity 0, 0.5, 1
     wavelengths 0.4, 0.6, ... 2 micron, + radio
     zenith distances 15, 45, 75 degrees

   The accuracy with respect to raytracing through a model
   atmosphere was as follows:

                          worst         RMS

     optical/IR           62 mas       8 mas
     radio               319 mas      49 mas

   For this particular set of conditions:

     lapse rate 0.0065 K/meter
     latitude 50 degrees
     sea level
     pressure 1005 mb
     temperature 280.15 K
     humidity 80%
     wavelength 5740 Angstroms

   the results were as follows:

     ZD       raytrace     eraRefco   Saastamoinen

     10         10.27        10.27        10.27
     20         21.19        21.20        21.19
     30         33.61        33.61        33.60
     40         48.82        48.83        48.81
     45         58.16        58.18        58.16
     50         69.28        69.30        69.27
     55         82.97        82.99        82.95
     60        100.51       100.54       100.50
     65        124.23       124.26       124.20
     70        158.63       158.68       158.61
     72        177.32       177.37       177.31
     74        200.35       200.38       200.32
     76        229.45       229.43       229.42
     78        267.44       267.29       267.41
     80        319.13       318.55       319.10

    deg        arcsec       arcsec       arcsec

   The values for Saastamoinen's formula (which includes terms
   up to tan^5) are taken from Hohenkerk and Sinclair (1985).

3. A wl value in the range 0-100 selects the optical/IR case and is
   wavelength in micrometers.  Any value outside this range selects
   the radio case.

4. Outlandish input parameters are silently limited to
   mathematically safe values.  Zero pressure is permissible, and
   causes zeroes to be returned.

5. The algorithm draws on several sources, as follows:

   a) The formula for the saturation vapour pressure of water as
      a function of temperature and temperature is taken from
      Equations (A4.5-A4.7) of Gill (1982).

   b) The formula for the water vapour pressure, given the
      saturation pressure and the relative humidity, is from
      Crane (1976), Equation (2.5.5).

   c) The refractivity of air is a function of temperature,
      total pressure, water-vapour pressure and, in the case
      of optical/IR, wavelength.  The formulae for the two cases are
      developed from Hohenkerk & Sinclair (1985) and Rueger (2002).

   d) The formula for beta, the ratio of the scale height of the
      atmosphere to the geocentric distance of the observer, is
      an adaption of Equation (9) from Stone (1996).  The
      adaptations, arrived at empirically, consist of (i) a small
      adjustment to the coefficient and (ii) a humidity term for the
      radio case only.

   e) The formulae for the refraction constants as a function of
      n-1 and beta are from Green (1987), Equation (4.31).

### References ###

- Crane, R.K., Meeks, M.L. (ed), "Refraction Effects in the Neutral
    Atmosphere", Methods of Experimental Physics: Astrophysics 12B,
    Academic Press, 1976.

- Gill, Adrian E., "Atmosphere-Ocean Dynamics", Academic Press,
    1982.

- Green, R.M., "Spherical Astronomy", Cambridge University Press,
    1987.

- Hohenkerk, C.Y., & Sinclair, A.T., NAO Technical Note No. 63,
    1985.

- Rueger, J.M., "Refractive Index Formulae for Electronic Distance
    Measurement with Radio and Millimetre Waves", in Unisurv Report
    S-68, School of Surveying and Spatial Information Systems,
    University of New South Wales, Sydney, Australia, 2002.

- Stone, Ronald C., P.A.S.P. 108, 1051-1058, 1996.

"""
function refco(phpa, tk, rh, wl)
    refa = Ref(0.0)
    refb = Ref(0.0)
    ccall((:eraRefco, liberfa), Cvoid,
          (Cdouble, Cdouble, Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}),
          phpa, tk, rh, wl, refa, refb)
    refa[], refb[]
end

"""
    rm2v(r)

Express an r-matrix as an r-vector.

### Given ###

- `r`: Rotation matrix

### Returned ###

- `w`: Rotation vector (Note 1)

### Notes ###

1. A rotation matrix describes a rotation through some angle about
   some arbitrary axis called the Euler axis.  The "rotation vector"
   returned by this function has the same direction as the Euler axis,
   and its magnitude is the angle in radians.  (The magnitude and
   direction can be separated by means of the function eraPn.)

2. If r is null, so is the result.  If r is not a rotation matrix
   the result is undefined;  r must be proper (i.e. have a positive
   determinant) and real orthogonal (inverse = transpose).

3. The reference frame rotates clockwise as seen looking along
   the rotation vector from the origin.

"""
function rm2v(r)
    w = zeros(3)
    ccall((:eraRm2v, liberfa), Cvoid,
          (Ptr{Cdouble}, Ptr{Cdouble}),
          r, w)
    w
end

"""
    rv2m(w)

Form the r-matrix corresponding to a given r-vector.

### Given ###

- `w`: Rotation vector (Note 1)

### Returned ###

- `r`: Rotation matrix

### Notes ###

1. A rotation matrix describes a rotation through some angle about
   some arbitrary axis called the Euler axis.  The "rotation vector"
   supplied to This function has the same direction as the Euler
   axis, and its magnitude is the angle in radians.

2. If w is null, the unit matrix is returned.

3. The reference frame rotates clockwise as seen looking along the
   rotation vector from the origin.

"""
function rv2m(w)
    r = zeros((3, 3))
    ccall((:eraRv2m, liberfa), Cvoid,
          (Ptr{Cdouble}, Ptr{Cdouble}),
          w, r)
    r
end

"""
    rxr(a, b)

Multiply two r-matrices.

### Given ###

- `a`: First r-matrix
- `b`: Second r-matrix

### Returned ###

- `atb`: A * b

### Note ###

   It is permissible to re-use the same array for any of the
   arguments.

### Called ###

- `eraCr`: copy r-matrix

"""
function rxr(a, b)
    atb = zeros((3, 3))
    ccall((:eraRxr, liberfa),
          Cvoid,
          (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
          a, b, atb)
    atb
end

"""
    rx(phi, r)

Rotate an r-matrix about the x-axis.

### Given ###

- `phi`: Angle (radians)

### Given and returned ###

- `r`: r-matrix, rotated

### Notes ###

1. Calling this function with positive phi incorporates in the
   supplied r-matrix r an additional rotation, about the x-axis,
   anticlockwise as seen looking towards the origin from positive x.

2. The additional rotation can be represented by this matrix:

       (  1        0            0      )
       (                               )
       (  0   + cos(phi)   + sin(phi)  )
       (                               )
       (  0   - sin(phi)   + cos(phi)  )

"""
rx

"""
    ry(phi, r)

Rotate an r-matrix about the y-axis.

### Given ###

- `theta`: Angle (radians)

### Given and returned ###

- `r`: r-matrix, rotated

### Notes ###

1. Calling this function with positive theta incorporates in the
   supplied r-matrix r an additional rotation, about the y-axis,
   anticlockwise as seen looking towards the origin from positive y.

2. The additional rotation can be represented by this matrix:

       (  + cos(theta)     0      - sin(theta)  )
       (                                        )
       (       0           1           0        )
       (                                        )
       (  + sin(theta)     0      + cos(theta)  )

"""
ry

"""
    rz(phi, r)

Rotate an r-matrix about the z-axis.

### Given ###

- `psi`: Angle (radians)

### Given and returned ###

- `r`: r-matrix, rotated

### Notes ###

1. Calling this function with positive psi incorporates in the
   supplied r-matrix r an additional rotation, about the z-axis,
   anticlockwise as seen looking towards the origin from positive z.

2. The additional rotation can be represented by this matrix:

       (  + cos(psi)   + sin(psi)     0  )
       (                                 )
       (  - sin(psi)   + cos(psi)     0  )
       (                                 )
       (       0            0         1  )

"""
rz

for name in ("rx",
             "ry",
             "rz")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(a, r)
            ccall(($fc, liberfa), Cvoid,
                  (Cdouble, Ptr{Cdouble}),
                  a, r)
            r
        end
    end
end

"""
    rxpv(r, pv)

Multiply a pv-vector by an r-matrix.

### Given ###

- `r`: R-matrix
- `pv`: Pv-vector

### Returned ###

- `rpv`: R * pv

### Note ###

   It is permissible for pv and rpv to be the same array.

### Called ###

- `eraRxp`: product of r-matrix and p-vector

"""
function rxpv(r, p)
    rp = zeros((2, 3))
    ccall((:eraRxpv, liberfa), Cvoid,
            (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
            r, p, rp)
    rp
end

"""
    rxp(r, p)

Multiply a p-vector by an r-matrix.

### Given ###

- `r`: R-matrix
- `p`: P-vector

### Returned ###

- `rp`: R * p

### Note ###

   It is permissible for p and rp to be the same array.

### Called ###

- `eraCp`: copy p-vector

"""
function rxp(r, p)
    rp = zeros(3)
    ccall((:eraRxp, liberfa), Cvoid,
            (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
            r, p, rp)
    rp
end
