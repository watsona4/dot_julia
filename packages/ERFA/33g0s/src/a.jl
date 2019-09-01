"""
    ab(pnat, v, s, bm1)

Apply aberration to transform natural direction into proper
direction.

### Given ###

- `pnat`: Natural direction to the source (unit vector)
- `v`: Observer barycentric velocity in units of c
- `s`: Distance between the Sun and the observer (au)
- `bm1`: ``\\sqrt{1-|v|^2}`` reciprocal of Lorenz factor

### Returned ###

- `ppr`: Proper direction to source (unit vector)

### Notes ###

1. The algorithm is based on Expr. (7.40) in the Explanatory
   Supplement (Urban & Seidelmann 2013), but with the following
   changes:

   -  Rigorous rather than approximate normalization is applied.

   -  The gravitational potential term from Expr. (7) in
      Klioner (2003) is added, taking into account only the Sun's
      contribution.  This has a maximum effect of about
      0.4 microarcsecond.

2. In almost all cases, the maximum accuracy will be limited by the
   supplied velocity.  For example, if the ERFA `eraEpv00` function is
   used, errors of up to 5 microarcseconds could occur.

### References ###

- Urban, S. & Seidelmann, P. K. (eds), Explanatory Supplement to
    the Astronomical Almanac, 3rd ed., University Science Books
    (2013).

- Klioner, Sergei A., "A practical relativistic model for micro-
    arcsecond astrometry in space", Astr. J. 125, 1580-1597 (2003).

### Called ###

- `eraPdp`: scalar product of two p-vectors

"""
function ab(pnat, v, s, bm1)
    ppr = zeros(3)
    ccall((:eraAb, liberfa), Cvoid,
          (Ptr{Cdouble}, Ptr{Cdouble}, Cdouble, Cdouble, Ptr{Cdouble}),
          pnat, v, s, bm1, ppr)
    ppr
end

"""
    apcg(date1, date2, ebpv, ehp)

For a geocentric observer, prepare star-independent astrometry
parameters for transformations between ICRS and GCRS coordinates.
The Earth ephemeris is supplied by the caller.

The parameters produced by this function are required in the
parallax, light deflection and aberration parts of the astrometric
transformation chain.

### Given ###

- `date1`: TDB as a 2-part...
- `date2`: ...Julian Date (Note 1)
- `ebpv`: Earth barycentric pos/vel (au, au/day)
- `ehp`: Earth heliocentric position (au)

### Returned ###

- `astrom`: Star-independent astrometry parameters:
    - `pmt`: PM time interval (SSB, Julian years)
    - `eb`: SSB to observer (vector, au)
    - `eh`: Sun to observer (unit vector)
    - `em`: Distance from Sun to observer (au)
    - `v`: Barycentric observer velocity (vector, c)
    - `bm1`: ``\\sqrt{1-|v|^2}`` Reciprocal of Lorenz factor
    - `bpn`: Bias-precession-nutation matrix
    - `along`: unchanged
    - `xpl`: unchanged
    - `ypl`: unchanged
    - `sphi`: unchanged
    - `cphi`: unchanged
    - `diurab`: unchanged
    - `eral`: unchanged
    - `refa`: unchanged
    - `refb`: unchanged

### Notes ###

1. The TDB date date1+date2 is a Julian Date, apportioned in any
   convenient way between the two arguments.  For example,
   JD(TDB)=2450123.7 could be expressed in any of these ways, among
   others:

   | `date1`   |     `date2` |                    |
   |:----------|:------------|:-------------------|
   | 2450123.7 |         0.0 | JD method          |
   | 2451545.0 |     -1421.3 | J2000 method       |
   | 2400000.5 |     50123.2 | MJD method         |
   | 2450123.5 |         0.2 | date & time method |

   The JD method is the most natural and convenient to use in cases
   where the loss of several decimal digits of resolution is
   acceptable.  The J2000 method is best matched to the way the
   argument is handled internally and will deliver the optimum
   resolution.  The MJD method and the date & time methods are both
   good compromises between resolution and convenience.  For most
   applications of this function the choice will not be at all
   critical.

   TT can be used instead of TDB without any significant impact on
   accuracy.

2. All the vectors are with respect to BCRS axes.

3. This is one of several functions that inserts into the astrom
   structure star-independent parameters needed for the chain of
   astrometric transformations ICRS <-> GCRS <-> CIRS <-> observed.

   The various functions support different classes of observer and
   portions of the transformation chain:

   |    Functions      |  Observer    | Transformation        |
   |:------------------|:-------------|:----------------------|
   | eraApcg eraApcg13 |  geocentric  | ICRS <-> GCRS         |
   | eraApci eraApci13 |  terrestrial | ICRS <-> CIRS         |
   | eraApco eraApco13 |  terrestrial | ICRS <-> observed     |
   | eraApcs eraApcs13 |  space       | ICRS <-> GCRS         |
   | eraAper eraAper13 |  terrestrial | update Earth rotation |
   | eraApio eraApio13 |  terrestrial | CIRS <-> observed     |

   Those with names ending in "13" use contemporary ERFA models to
   compute the various ephemerides.  The others accept ephemerides
   supplied by the caller.

   The transformation from ICRS to GCRS covers space motion,
   parallax, light deflection, and aberration.  From GCRS to CIRS
   comprises frame bias and precession-nutation.  From CIRS to
   observed takes account of Earth rotation, polar motion, diurnal
   aberration and parallax (unless subsumed into the ICRS <-> GCRS
   transformation), and atmospheric refraction.

4. The context structure astrom produced by this function is used by
   `eraAtciq` and `eraAticq`.

### Called ###

- `eraApcs`: astrometry parameters, ICRS-GCRS, space observer

"""
function apcg(date1, date2, ebpv, ehp)
    astrom = ASTROM(0.0, zeros(3), zeros(3), 0.0, zeros(3), 0.0, zeros((3, 3)), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    ccall((:eraApcg, liberfa), Cvoid,
          (Cdouble, Cdouble, Ptr{Cdouble}, Ptr{Cdouble}, Ref{ASTROM}),
          date1, date2, ebpv, ehp, astrom)
    astrom
end

"""
    apcg13(date1, date2)

For a geocentric observer, prepare star-independent astrometry
parameters for transformations between ICRS and GCRS coordinates.
The caller supplies the date, and ERFA models are used to predict
the Earth ephemeris.

The parameters produced by this function are required in the
parallax, light deflection and aberration parts of the astrometric
transformation chain.

### Given ###

- `date1`: TDB as a 2-part...
- `date2`: ...Julian Date (Note 1)

### Returned ###

- `astrom`: Star-independent astrometry parameters:
    - `pmt`: PM time interval (SSB, Julian years)
    - `eb`: SSB to observer (vector, au)
    - `eh`: Sun to observer (unit vector)
    - `em`: Distance from Sun to observer (au)
    - `v`: Barycentric observer velocity (vector, c)
    - `bm1`: ``\\sqrt{1-|v|^2}`` Reciprocal of Lorenz factor
    - `bpn`: Bias-precession-nutation matrix
    - `along`: unchanged
    - `xpl`: unchanged
    - `ypl`: unchanged
    - `sphi`: unchanged
    - `cphi`: unchanged
    - `diurab`: unchanged
    - `eral`: unchanged
    - `refa`: unchanged
    - `refb`: unchanged

### Notes ###

1. The TDB date date1+date2 is a Julian Date, apportioned in any
   convenient way between the two arguments.  For example,
   JD(TDB)=2450123.7 could be expressed in any of these ways, among
   others:

   | `date1`   |     `date2` |                    |
   |:----------|:------------|:-------------------|
   | 2450123.7 |         0.0 | JD method          |
   | 2451545.0 |     -1421.3 | J2000 method       |
   | 2400000.5 |     50123.2 | MJD method         |
   | 2450123.5 |         0.2 | date & time method |

   The JD method is the most natural and convenient to use in cases
   where the loss of several decimal digits of resolution is
   acceptable.  The J2000 method is best matched to the way the
   argument is handled internally and will deliver the optimum
   resolution.  The MJD method and the date & time methods are both
   good compromises between resolution and convenience.  For most
   applications of this function the choice will not be at all
   critical.

   TT can be used instead of TDB without any significant impact on
   accuracy.

2. All the vectors are with respect to BCRS axes.

3. In cases where the caller wishes to supply his own Earth
   ephemeris, the function eraApcg can be used instead of the present
   function.

4. This is one of several functions that inserts into the astrom
   structure star-independent parameters needed for the chain of
   astrometric transformations ICRS <-> GCRS <-> CIRS <-> observed.

   The various functions support different classes of observer and
   portions of the transformation chain:

   |    Functions      |  Observer    | Transformation        |
   |:------------------|:-------------|:----------------------|
   | eraApcg eraApcg13 |  geocentric  | ICRS <-> GCRS         |
   | eraApci eraApci13 |  terrestrial | ICRS <-> CIRS         |
   | eraApco eraApco13 |  terrestrial | ICRS <-> observed     |
   | eraApcs eraApcs13 |  space       | ICRS <-> GCRS         |
   | eraAper eraAper13 |  terrestrial | update Earth rotation |
   | eraApio eraApio13 |  terrestrial | CIRS <-> observed     |

   Those with names ending in "13" use contemporary ERFA models to
   compute the various ephemerides.  The others accept ephemerides
   supplied by the caller.

   The transformation from ICRS to GCRS covers space motion,
   parallax, light deflection, and aberration.  From GCRS to CIRS
   comprises frame bias and precession-nutation.  From CIRS to
   observed takes account of Earth rotation, polar motion, diurnal
   aberration and parallax (unless subsumed into the ICRS <-> GCRS
   transformation), and atmospheric refraction.

5. The context structure astrom produced by this function is used by
   eraAtciq* and eraAticq*.

### Called ###

- `eraEpv00`: Earth position and velocity
- `eraApcg`: astrometry parameters, ICRS-GCRS, geocenter

"""
function apcg13(date1, date2)
    astrom = ASTROM(0.0, zeros(3), zeros(3), 0.0, zeros(3), 0.0, zeros((3, 3)), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    ccall((:eraApcg13, liberfa), Cvoid,
          (Cdouble, Cdouble, Ref{ASTROM}),
          date1, date2, astrom)
    astrom
end

"""
    apci(date1, date2, ebpv, ehp, x, y, s)

For a terrestrial observer, prepare star-independent astrometry
parameters for transformations between ICRS and geocentric CIRS
coordinates.  The Earth ephemeris and CIP/CIO are supplied by the
caller.

The parameters produced by this function are required in the
parallax, light deflection, aberration, and bias-precession-nutation
parts of the astrometric transformation chain.

### Given ###

- `date1`: TDB as a 2-part...
- `date2`: ...Julian Date (Note 1)
- `ebpv`: Earth barycentric position/velocity (au, au/day)
- `ehp`: Earth heliocentric position (au)
- `x`, `y`: CIP X,Y (components of unit vector)
- `s`: The CIO locator s (radians)

### Returned ###

- `astrom`: Star-independent astrometry parameters:
    - `pmt`: PM time interval (SSB, Julian years)
    - `eb`: SSB to observer (vector, au)
    - `eh`: Sun to observer (unit vector)
    - `em`: Distance from Sun to observer (au)
    - `v`: Barycentric observer velocity (vector, c)
    - `bm1`: ``\\sqrt{1-|v|^2}`` Reciprocal of Lorenz factor
    - `bpn`: Bias-precession-nutation matrix
    - `along`: unchanged
    - `xpl`: unchanged
    - `ypl`: unchanged
    - `sphi`: unchanged
    - `cphi`: unchanged
    - `diurab`: unchanged
    - `eral`: unchanged
    - `refa`: unchanged
    - `refb`: unchanged

### Notes ###

1. The TDB date date1+date2 is a Julian Date, apportioned in any
   convenient way between the two arguments.  For example,
   JD(TDB)=2450123.7 could be expressed in any of these ways, among
   others:

   | `date1`   |     `date2` |                    |
   |:----------|:------------|:-------------------|
   | 2450123.7 |         0.0 | JD method          |
   | 2451545.0 |     -1421.3 | J2000 method       |
   | 2400000.5 |     50123.2 | MJD method         |
   | 2450123.5 |         0.2 | date & time method |

   The JD method is the most natural and convenient to use in cases
   where the loss of several decimal digits of resolution is
   acceptable.  The J2000 method is best matched to the way the
   argument is handled internally and will deliver the optimum
   resolution.  The MJD method and the date & time methods are both
   good compromises between resolution and convenience.  For most
   applications of this function the choice will not be at all
   critical.

   TT can be used instead of TDB without any significant impact on
   accuracy.

2. All the vectors are with respect to BCRS axes.

3. In cases where the caller does not wish to provide the Earth
   ephemeris and CIP/CIO, the function eraApci13 can be used instead
   of the present function.  This computes the required quantities
   using other ERFA functions.

4. This is one of several functions that inserts into the astrom
   structure star-independent parameters needed for the chain of
   astrometric transformations ICRS <-> GCRS <-> CIRS <-> observed.

   The various functions support different classes of observer and
   portions of the transformation chain:

   |    Functions      |  Observer    | Transformation        |
   |:------------------|:-------------|:----------------------|
   | eraApcg eraApcg13 |  geocentric  | ICRS <-> GCRS         |
   | eraApci eraApci13 |  terrestrial | ICRS <-> CIRS         |
   | eraApco eraApco13 |  terrestrial | ICRS <-> observed     |
   | eraApcs eraApcs13 |  space       | ICRS <-> GCRS         |
   | eraAper eraAper13 |  terrestrial | update Earth rotation |
   | eraApio eraApio13 |  terrestrial | CIRS <-> observed     |

   Those with names ending in "13" use contemporary ERFA models to
   compute the various ephemerides.  The others accept ephemerides
   supplied by the caller.

   The transformation from ICRS to GCRS covers space motion,
   parallax, light deflection, and aberration.  From GCRS to CIRS
   comprises frame bias and precession-nutation.  From CIRS to
   observed takes account of Earth rotation, polar motion, diurnal
   aberration and parallax (unless subsumed into the ICRS <-> GCRS
   transformation), and atmospheric refraction.

5. The context structure astrom produced by this function is used by
   eraAtciq* and eraAticq*.

### Called ###

- `eraApcg`: astrometry parameters, ICRS-GCRS, geocenter
- `eraC2ixys`: celestial-to-intermediate matrix, given X,Y and s

"""
function apci(date1, date2, ebpv, ehp, x, y, s)
    astrom = ASTROM(0.0, zeros(3), zeros(3), 0.0, zeros(3), 0.0, zeros((3, 3)), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    ccall((:eraApci, liberfa), Cvoid,
          (Cdouble, Cdouble, Ptr{Cdouble}, Ptr{Cdouble}, Cdouble, Cdouble, Cdouble, Ref{ASTROM}),
          date1, date2, ebpv, ehp, x, y, s, astrom)
    astrom
end

"""
    apci13(date1, date2)

For a terrestrial observer, prepare star-independent astrometry
parameters for transformations between ICRS and geocentric CIRS
coordinates.  The caller supplies the date, and ERFA models are used
to predict the Earth ephemeris and CIP/CIO.

The parameters produced by this function are required in the
parallax, light deflection, aberration, and bias-precession-nutation
parts of the astrometric transformation chain.

### Given ###

- `date1`: TDB as a 2-part...
- `date2`: ...Julian Date (Note 1)

### Returned ###

- `astrom`: Star-independent astrometry parameters:
    - `pmt`: PM time interval (SSB, Julian years)
    - `eb`: SSB to observer (vector, au)
    - `eh`: Sun to observer (unit vector)
    - `em`: Distance from Sun to observer (au)
    - `v`: Barycentric observer velocity (vector, c)
    - `bm1`: ``\\sqrt{1-|v|^2}`` Reciprocal of Lorenz factor
    - `bpn`: Bias-precession-nutation matrix
    - `along`: unchanged
    - `xpl`: unchanged
    - `ypl`: unchanged
    - `sphi`: unchanged
    - `cphi`: unchanged
    - `diurab`: unchanged
    - `eral`: unchanged
    - `refa`: unchanged
    - `refb`: unchanged
- `eo`: Equation of the origins (ERA-GST)

### Notes ###

1. The TDB date date1+date2 is a Julian Date, apportioned in any
   convenient way between the two arguments.  For example,
   JD(TDB)=2450123.7 could be expressed in any of these ways, among
   others:

   | `date1`   |     `date2` |                    |
   |:----------|:------------|:-------------------|
   | 2450123.7 |         0.0 | JD method          |
   | 2451545.0 |     -1421.3 | J2000 method       |
   | 2400000.5 |     50123.2 | MJD method         |
   | 2450123.5 |         0.2 | date & time method |

   The JD method is the most natural and convenient to use in cases
   where the loss of several decimal digits of resolution is
   acceptable.  The J2000 method is best matched to the way the
   argument is handled internally and will deliver the optimum
   resolution.  The MJD method and the date & time methods are both
   good compromises between resolution and convenience.  For most
   applications of this function the choice will not be at all
   critical.

   TT can be used instead of TDB without any significant impact on
   accuracy.

2. All the vectors are with respect to BCRS axes.

3. In cases where the caller wishes to supply his own Earth
   ephemeris and CIP/CIO, the function eraApci can be used instead
   of the present function.

4. This is one of several functions that inserts into the astrom
   structure star-independent parameters needed for the chain of
   astrometric transformations ICRS <-> GCRS <-> CIRS <-> observed.

   The various functions support different classes of observer and
   portions of the transformation chain:

   |    Functions      |  Observer    | Transformation        |
   |:------------------|:-------------|:----------------------|
   | eraApcg eraApcg13 |  geocentric  | ICRS <-> GCRS         |
   | eraApci eraApci13 |  terrestrial | ICRS <-> CIRS         |
   | eraApco eraApco13 |  terrestrial | ICRS <-> observed     |
   | eraApcs eraApcs13 |  space       | ICRS <-> GCRS         |
   | eraAper eraAper13 |  terrestrial | update Earth rotation |
   | eraApio eraApio13 |  terrestrial | CIRS <-> observed     |

   Those with names ending in "13" use contemporary ERFA models to
   compute the various ephemerides.  The others accept ephemerides
   supplied by the caller.

   The transformation from ICRS to GCRS covers space motion,
   parallax, light deflection, and aberration.  From GCRS to CIRS
   comprises frame bias and precession-nutation.  From CIRS to
   observed takes account of Earth rotation, polar motion, diurnal
   aberration and parallax (unless subsumed into the ICRS <-> GCRS
   transformation), and atmospheric refraction.

5. The context structure astrom produced by this function is used by
   eraAtciq* and eraAticq*.

### Called ###

- `eraEpv00`: Earth position and velocity
- `eraPnm06a`: classical NPB matrix, IAU 2006/2000A
- `eraBpn2xy`: extract CIP X,Y coordinates from NPB matrix
- `eraS06`: the CIO locator s, given X,Y, IAU 2006
- `eraApci`: astrometry parameters, ICRS-CIRS
- `eraEors`: equation of the origins, given NPB matrix and s

"""
function apci13(date1, date2)
    astrom = ASTROM(0.0, zeros(3), zeros(3), 0.0, zeros(3), 0.0, zeros((3, 3)), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    eo = Ref(0.0)
    ccall((:eraApci13, liberfa), Cvoid,
          (Cdouble, Cdouble, Ref{ASTROM}, Ref{Cdouble}),
          date1, date2, astrom, eo)
    astrom, eo[]
end

"""
    apco(date1, date2, ebpv, ehp, x, y, s, theta, elong, phi, hm, xp, yp, sp, refa, refb)

For a terrestrial observer, prepare star-independent astrometry
parameters for transformations between ICRS and observed
coordinates.  The caller supplies the Earth ephemeris, the Earth
rotation information and the refraction constants as well as the
site coordinates.

### Given ###

- `date1`: TDB as a 2-part...
- `date2`: ...Julian Date (Note 1)
- `ebpv`: Earth barycentric PV (au, au/day, Note 2)
- `ehp`: Earth heliocentric P (au, Note 2)
- `x`, `y`: CIP X,Y (components of unit vector)
- `s`: The CIO locator s (radians)
- `theta`: Earth rotation angle (radians)
- `elong`: Longitude (radians, east +ve, Note 3)
- `phi`: Latitude (geodetic, radians, Note 3)
- `hm`: Height above ellipsoid (m, geodetic, Note 3)
- `xp`, `yp`: Polar motion coordinates (radians, Note 4)
- `sp`: The TIO locator s' (radians, Note 4)
- `refa`: Refraction constant A (radians, Note 5)
- `refb`: Refraction constant B (radians, Note 5)

### Returned ###

- `astrom`: Star-independent astrometry parameters:
    - `pmt`: PM time interval (SSB, Julian years)
    - `eb`: SSB to observer (vector, au)
    - `eh`: Sun to observer (unit vector)
    - `em`: Distance from Sun to observer (au)
    - `v`: Barycentric observer velocity (vector, c)
    - `bm1`: ``\\sqrt{1-|v|^2}`` Reciprocal of Lorenz factor
    - `bpn`: Bias-precession-nutation matrix
    - `along`: Longitude + s' (radians)
    - `xp1`: Polar motion xp wrt local meridian (radians)
    - `yp1`: Polar motion yp wrt local meridian (radians)
    - `sphi`: Sine of geodetic latitude
    - `cphi`: Cosine of geodetic latitude
    - `diurab`: Magnitude of diurnal aberration vector
    - `eral`: "Local" Earth rotation angle (radians)
    - `refa`: Refraction constant A (radians)
    - `refb`: Refraction constant B (radians)

### Notes ###

1. The TDB date date1+date2 is a Julian Date, apportioned in any
   convenient way between the two arguments.  For example,
   JD(TDB)=2450123.7 could be expressed in any of these ways, among
   others:

   | `date1`   |     `date2` |                    |
   |:----------|:------------|:-------------------|
   | 2450123.7 |         0.0 | JD method          |
   | 2451545.0 |     -1421.3 | J2000 method       |
   | 2400000.5 |     50123.2 | MJD method         |
   | 2450123.5 |         0.2 | date & time method |

   The JD method is the most natural and convenient to use in cases
   where the loss of several decimal digits of resolution is
   acceptable.  The J2000 method is best matched to the way the
   argument is handled internally and will deliver the optimum
   resolution.  The MJD method and the date & time methods are both
   good compromises between resolution and convenience.  For most
   applications of this function the choice will not be at all
   critical.

   TT can be used instead of TDB without any significant impact on
   accuracy.

2. The vectors eb, eh, and all the astrom vectors, are with respect
   to BCRS axes.

3. The geographical coordinates are with respect to the ERFA_WGS84
   reference ellipsoid.  TAKE CARE WITH THE LONGITUDE SIGN
   CONVENTION:  the longitude required by the present function is
   right-handed, i.e. east-positive, in accordance with geographical
   convention.

4. xp and yp are the coordinates (in radians) of the Celestial
   Intermediate Pole with respect to the International Terrestrial
   Reference System (see IERS Conventions), measured along the
   meridians 0 and 90 deg west respectively.  sp is the TIO locator
   s', in radians, which positions the Terrestrial Intermediate
   Origin on the equator.  For many applications, xp, yp and
   (especially) sp can be set to zero.

   Internally, the polar motion is stored in a form rotated onto the
   local meridian.

5. The refraction constants refa and refb are for use in a
   dZ = A*tan(Z)+B*tan^3(Z) model, where Z is the observed
   (i.e. refracted) zenith distance and dZ is the amount of
   refraction.

6. It is advisable to take great care with units, as even unlikely
   values of the input parameters are accepted and processed in
   accordance with the models used.

7. In cases where the caller does not wish to provide the Earth
   Ephemeris, the Earth rotation information and refraction
   constants, the function eraApco13 can be used instead of the
   present function.  This starts from UTC and weather readings etc.
   and computes suitable values using other ERFA functions.

8. This is one of several functions that inserts into the astrom
   structure star-independent parameters needed for the chain of
   astrometric transformations ICRS <-> GCRS <-> CIRS <-> observed.

   The various functions support different classes of observer and
   portions of the transformation chain:

   |    Functions      |  Observer    | Transformation        |
   |:------------------|:-------------|:----------------------|
   | eraApcg eraApcg13 |  geocentric  | ICRS <-> GCRS         |
   | eraApci eraApci13 |  terrestrial | ICRS <-> CIRS         |
   | eraApco eraApco13 |  terrestrial | ICRS <-> observed     |
   | eraApcs eraApcs13 |  space       | ICRS <-> GCRS         |
   | eraAper eraAper13 |  terrestrial | update Earth rotation |
   | eraApio eraApio13 |  terrestrial | CIRS <-> observed     |

   Those with names ending in "13" use contemporary ERFA models to
   compute the various ephemerides.  The others accept ephemerides
   supplied by the caller.

   The transformation from ICRS to GCRS covers space motion,
   parallax, light deflection, and aberration.  From GCRS to CIRS
   comprises frame bias and precession-nutation.  From CIRS to
   observed takes account of Earth rotation, polar motion, diurnal
   aberration and parallax (unless subsumed into the ICRS <-> GCRS
   transformation), and atmospheric refraction.

9. The context structure astrom produced by this function is used by
   `eraAtioq`, `eraAtoiq`, `eraAtciq` and `eraAticq`.

### Called ###

- `eraAper`: astrometry parameters: update ERA
- `eraC2ixys`: celestial-to-intermediate matrix, given X,Y and s
- `eraPvtob`: position/velocity of terrestrial station
- `eraTrxpv`: product of transpose of r-matrix and pv-vector
- `eraApcs`: astrometry parameters, ICRS-GCRS, space observer
- `eraCr`: copy r-matrix

"""
function apco(date1, date2, ebpv, ehp, x, y, s, theta, elong, phi, hm, xp, yp, sp, refa, refb)
    astrom = ASTROM(0.0, zeros(3), zeros(3), 0.0, zeros(3), 0.0, zeros((3, 3)), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    ccall((:eraApco, liberfa), Cvoid,
          (Cdouble, Cdouble, Ptr{Cdouble}, Ptr{Cdouble}, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ref{ASTROM}),
          date1, date2, ebpv, ehp, x, y, s, theta, elong, phi, hm, xp, yp, sp, refa, refb, astrom)
    astrom
end

"""
    apco13(utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tk, rh, wl)

For a terrestrial observer, prepare star-independent astrometry
parameters for transformations between ICRS and observed
coordinates.  The caller supplies UTC, site coordinates, ambient air
conditions and observing wavelength, and ERFA models are used to
obtain the Earth ephemeris, CIP/CIO and refraction constants.

The parameters produced by this function are required in the
parallax, light deflection, aberration, and bias-precession-nutation
parts of the ICRS/CIRS transformations.

### Given ###

- `utc1`: UTC as a 2-part...
- `utc2`: ...quasi Julian Date (Notes 1,2)
- `dut1`: UT1-UTC (seconds, Note 3)
- `elong`: Longitude (radians, east +ve, Note 4)
- `phi`: Latitude (geodetic, radians, Note 4)
- `hm`: Height above ellipsoid (m, geodetic, Notes 4,6)
- `xp`, `yp`: Polar motion coordinates (radians, Note 5)
- `phpa`: Pressure at the observer (hPa = mB, Note 6)
- `tc`: Ambient temperature at the observer (deg C)
- `rh`: Relative humidity at the observer (range 0-1)
- `wl`: Wavelength (micrometers, Note 7)

### Returned ###

- `astrom`: Star-independent astrometry parameters:
    - `pmt`: PM time interval (SSB, Julian years)
    - `eb`: SSB to observer (vector, au)
    - `eh`: Sun to observer (unit vector)
    - `em`: Distance from Sun to observer (au)
    - `v`: Barycentric observer velocity (vector, c)
    - `bm1`: ``\\sqrt{1-|v|^2}`` Reciprocal of Lorenz factor
    - `bpn`: Bias-precession-nutation matrix
    - `along`: Longitude + s' (radians)
    - `xp1`: Polar motion xp wrt local meridian (radians)
    - `yp1`: Polar motion yp wrt local meridian (radians)
    - `sphi`: Sine of geodetic latitude
    - `cphi`: Cosine of geodetic latitude
    - `diurab`: Magnitude of diurnal aberration vector
    - `eral`: "Local" Earth rotation angle (radians)
    - `refa`: Refraction constant A (radians)
    - `refb`: Refraction constant B (radians)
- `eo`: Equation of the origins (ERA-GST)

### Notes ###

1.  utc1+utc2 is quasi Julian Date (see Note 2), apportioned in any
    convenient way between the two arguments, for example where utc1
    is the Julian Day Number and utc2 is the fraction of a day.

    However, JD cannot unambiguously represent UTC during a leap
    second unless special measures are taken.  The convention in the
    present function is that the JD day represents UTC days whether
    the length is 86399, 86400 or 86401 SI seconds.

    Applications should use the function eraDtf2d to convert from
    calendar date and time of day into 2-part quasi Julian Date, as
    it implements the leap-second-ambiguity convention just
    described.

2.  The warning status "dubious year" flags UTCs that predate the
    introduction of the time scale or that are too far in the
    future to be trusted.  See eraDat for further details.

3.  UT1-UTC is tabulated in IERS bulletins.  It increases by exactly
    one second at the end of each positive UTC leap second,
    introduced in order to keep UT1-UTC within +/- 0.9s.  n.b. This
    practice is under review, and in the future UT1-UTC may grow
    essentially without limit.

4.  The geographical coordinates are with respect to the ERFA_WGS84
    reference ellipsoid.  TAKE CARE WITH THE LONGITUDE SIGN:  the
    longitude required by the present function is east-positive
    (i.e. right-handed), in accordance with geographical convention.

5.  The polar motion xp,yp can be obtained from IERS bulletins.  The
    values are the coordinates (in radians) of the Celestial
    Intermediate Pole with respect to the International Terrestrial
    Reference System (see IERS Conventions 2003), measured along the
    meridians 0 and 90 deg west respectively.  For many
    applications, xp and yp can be set to zero.

    Internally, the polar motion is stored in a form rotated onto
    the local meridian.

6.  If hm, the height above the ellipsoid of the observing station
    in meters, is not known but phpa, the pressure in hPa (=mB), is
    available, an adequate estimate of hm can be obtained from the
    expression

          hm = -29.3 * tsl * log ( phpa / 1013.25 );

    where tsl is the approximate sea-level air temperature in K
    (See Astrophysical Quantities, C.W.Allen, 3rd edition, section
    52).  Similarly, if the pressure phpa is not known, it can be
    estimated from the height of the observing station, hm, as
    follows:

          phpa = 1013.25 * exp ( -hm / ( 29.3 * tsl ) );

    Note, however, that the refraction is nearly proportional to
    the pressure and that an accurate phpa value is important for
    precise work.

7.  The argument wl specifies the observing wavelength in
    micrometers.  The transition from optical to radio is assumed to
    occur at 100 micrometers (about 3000 GHz).

8.  It is advisable to take great care with units, as even unlikely
    values of the input parameters are accepted and processed in
    accordance with the models used.

9.  In cases where the caller wishes to supply his own Earth
    ephemeris, Earth rotation information and refraction constants,
    the function eraApco can be used instead of the present function.

10. This is one of several functions that inserts into the astrom
    structure star-independent parameters needed for the chain of
    astrometric transformations ICRS <-> GCRS <-> CIRS <-> observed.

    The various functions support different classes of observer and
    portions of the transformation chain:

   |    Functions      |  Observer    | Transformation        |
   |:------------------|:-------------|:----------------------|
   | eraApcg eraApcg13 |  geocentric  | ICRS <-> GCRS         |
   | eraApci eraApci13 |  terrestrial | ICRS <-> CIRS         |
   | eraApco eraApco13 |  terrestrial | ICRS <-> observed     |
   | eraApcs eraApcs13 |  space       | ICRS <-> GCRS         |
   | eraAper eraAper13 |  terrestrial | update Earth rotation |
   | eraApio eraApio13 |  terrestrial | CIRS <-> observed     |

    Those with names ending in "13" use contemporary ERFA models to
    compute the various ephemerides.  The others accept ephemerides
    supplied by the caller.

    The transformation from ICRS to GCRS covers space motion,
    parallax, light deflection, and aberration.  From GCRS to CIRS
    comprises frame bias and precession-nutation.  From CIRS to
    observed takes account of Earth rotation, polar motion, diurnal
    aberration and parallax (unless subsumed into the ICRS <-> GCRS
    transformation), and atmospheric refraction.

11. The context structure astrom produced by this function is used
    by eraAtioq, eraAtoiq, eraAtciq* and eraAticq*.

### Called ###

- `eraUtctai`: UTC to TAI
- `eraTaitt`: TAI to TT
- `eraUtcut1`: UTC to UT1
- `eraEpv00`: Earth position and velocity
- `eraPnm06a`: classical NPB matrix, IAU 2006/2000A
- `eraBpn2xy`: extract CIP X,Y coordinates from NPB matrix
- `eraS06`: the CIO locator s, given X,Y, IAU 2006
- `eraEra00`: Earth rotation angle, IAU 2000
- `eraSp00`: the TIO locator s', IERS 2000
- `eraRefco`: refraction constants for given ambient conditions
- `eraApco`: astrometry parameters, ICRS-observed
- `eraEors`: equation of the origins, given NPB matrix and s

"""
function apco13(utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tk, rh, wl)
    astrom = ASTROM(0.0, zeros(3), zeros(3), 0.0, zeros(3), 0.0, zeros((3, 3)), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    eo = Ref(0.0)
    i = ccall((:eraApco13, liberfa), Cint,
              (Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ref{ASTROM}, Ref{Cdouble}),
              utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tk, rh, wl, astrom, eo)
    if i == -1
        throw(ERFAException("unacceptable date"))
    elseif i == +1
        @warn "dubious year"
    end
    astrom, eo[]
end

"""
    apcs(date1, date2, pv, ebpv, ehp)

For an observer whose geocentric position and velocity are known,
prepare star-independent astrometry parameters for transformations
between ICRS and GCRS.  The Earth ephemeris is supplied by the
caller.

The parameters produced by this function are required in the space
motion, parallax, light deflection and aberration parts of the
astrometric transformation chain.

### Given ###

- `date1`: TDB as a 2-part...
- `date2`: ...Julian Date (Note 1)
- `pv`: Observer's geocentric pos/vel (m, m/s)
- `ebpv`: Earth barycentric PV (au, au/day)
- `ehp`: Earth heliocentric P (au)

### Returned ###

- `astrom`: Star-independent astrometry parameters:
    - `pmt`: PM time interval (SSB, Julian years)
    - `eb`: SSB to observer (vector, au)
    - `eh`: Sun to observer (unit vector)
    - `em`: Distance from Sun to observer (au)
    - `v`: Barycentric observer velocity (vector, c)
    - `bm1`: ``\\sqrt{1-|v|^2}`` Reciprocal of Lorenz factor
    - `bpn`: Bias-precession-nutation matrix
    - `along`: unchanged
    - `xpl`: unchanged
    - `ypl`: unchanged
    - `sphi`: unchanged
    - `cphi`: unchanged
    - `diurab`: unchanged
    - `eral`: unchanged
    - `refa`: unchanged
    - `refb`: unchanged

### Notes ###

1. The TDB date date1+date2 is a Julian Date, apportioned in any
   convenient way between the two arguments.  For example,
   JD(TDB)=2450123.7 could be expressed in any of these ways, among
   others:

   | `date1`   |     `date2` |                    |
   |:----------|:------------|:-------------------|
   | 2450123.7 |         0.0 | JD method          |
   | 2451545.0 |     -1421.3 | J2000 method       |
   | 2400000.5 |     50123.2 | MJD method         |
   | 2450123.5 |         0.2 | date & time method |

   The JD method is the most natural and convenient to use in cases
   where the loss of several decimal digits of resolution is
   acceptable.  The J2000 method is best matched to the way the
   argument is handled internally and will deliver the optimum
   resolution.  The MJD method and the date & time methods are both
   good compromises between resolution and convenience.  For most
   applications of this function the choice will not be at all
   critical.

   TT can be used instead of TDB without any significant impact on
   accuracy.

2. All the vectors are with respect to BCRS axes.

3. Providing separate arguments for (i) the observer's geocentric
   position and velocity and (ii) the Earth ephemeris is done for
   convenience in the geocentric, terrestrial and Earth orbit cases.
   For deep space applications it maybe more convenient to specify
   zero geocentric position and velocity and to supply the
   observer's position and velocity information directly instead of
   with respect to the Earth.  However, note the different units:
   m and m/s for the geocentric vectors, au and au/day for the
   heliocentric and barycentric vectors.

4. In cases where the caller does not wish to provide the Earth
   ephemeris, the function eraApcs13 can be used instead of the
   present function.  This computes the Earth ephemeris using the
   ERFA function eraEpv00.

5. This is one of several functions that inserts into the astrom
   structure star-independent parameters needed for the chain of
   astrometric transformations ICRS <-> GCRS <-> CIRS <-> observed.

   The various functions support different classes of observer and
   portions of the transformation chain:

   |    Functions      |  Observer    | Transformation        |
   |:------------------|:-------------|:----------------------|
   | eraApcg eraApcg13 |  geocentric  | ICRS <-> GCRS         |
   | eraApci eraApci13 |  terrestrial | ICRS <-> CIRS         |
   | eraApco eraApco13 |  terrestrial | ICRS <-> observed     |
   | eraApcs eraApcs13 |  space       | ICRS <-> GCRS         |
   | eraAper eraAper13 |  terrestrial | update Earth rotation |
   | eraApio eraApio13 |  terrestrial | CIRS <-> observed     |

   Those with names ending in "13" use contemporary ERFA models to
   compute the various ephemerides.  The others accept ephemerides
   supplied by the caller.

   The transformation from ICRS to GCRS covers space motion,
   parallax, light deflection, and aberration.  From GCRS to CIRS
   comprises frame bias and precession-nutation.  From CIRS to
   observed takes account of Earth rotation, polar motion, diurnal
   aberration and parallax (unless subsumed into the ICRS <-> GCRS
   transformation), and atmospheric refraction.

6. The context structure astrom produced by this function is used by
   eraAtciq* and eraAticq*.

### Called ###

- `eraCp`: copy p-vector
- `eraPm`: modulus of p-vector
- `eraPn`: decompose p-vector into modulus and direction
- `eraIr`: initialize r-matrix to identity

"""
function apcs(date1, date2, pv, ebpv, ehp)
    astrom = ASTROM(0.0, zeros(3), zeros(3), 0.0, zeros(3), 0.0, zeros((3, 3)), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    ccall((:eraApcs, liberfa), Cvoid,
          (Cdouble, Cdouble, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ref{ASTROM}),
          date1, date2, pv, ebpv, ehp, astrom)
    astrom
end

"""
    apcs13(date1, date2, pv)

For an observer whose geocentric position and velocity are known,
prepare star-independent astrometry parameters for transformations
between ICRS and GCRS.  The Earth ephemeris is from ERFA models.

The parameters produced by this function are required in the space
motion, parallax, light deflection and aberration parts of the
astrometric transformation chain.

### Given ###

- `date1`: TDB as a 2-part...
- `date2`: ...Julian Date (Note 1)
- `pv`: Observer's geocentric pos/vel (Note 3)

### Returned ###

- EraASTROM*   star-independent astrometry parameters:
    - `pmt`: PM time interval (SSB, Julian years)
    - `eb`: SSB to observer (vector, au)
    - `eh`: Sun to observer (unit vector)
    - `em`: Distance from Sun to observer (au)
    - `v`: Barycentric observer velocity (vector, c)
    - `bm1`: ``\\sqrt{1-|v|^2}`` Reciprocal of Lorenz factor
    - `bpn`: Bias-precession-nutation matrix
    - `along`: unchanged
    - `xpl`: unchanged
    - `ypl`: unchanged
    - `sphi`: unchanged
    - `cphi`: unchanged
    - `diurab`: unchanged
    - `eral`: unchanged
    - `refa`: unchanged
    - `refb`: unchanged

### Notes ###

1. The TDB date date1+date2 is a Julian Date, apportioned in any
   convenient way between the two arguments.  For example,
   JD(TDB)=2450123.7 could be expressed in any of these ways, among
   others:

   | `date1`   |     `date2` |                    |
   |:----------|:------------|:-------------------|
   | 2450123.7 |         0.0 | JD method          |
   | 2451545.0 |     -1421.3 | J2000 method       |
   | 2400000.5 |     50123.2 | MJD method         |
   | 2450123.5 |         0.2 | date & time method |

   The JD method is the most natural and convenient to use in cases
   where the loss of several decimal digits of resolution is
   acceptable.  The J2000 method is best matched to the way the
   argument is handled internally and will deliver the optimum
   resolution.  The MJD method and the date & time methods are both
   good compromises between resolution and convenience.  For most
   applications of this function the choice will not be at all
   critical.

   TT can be used instead of TDB without any significant impact on
   accuracy.

2. All the vectors are with respect to BCRS axes.

3. The observer's position and velocity pv are geocentric but with
   respect to BCRS axes, and in units of m and m/s.  No assumptions
   are made about proximity to the Earth, and the function can be
   used for deep space applications as well as Earth orbit and
   terrestrial.

4. In cases where the caller wishes to supply his own Earth
   ephemeris, the function eraApcs can be used instead of the present
   function.

5. This is one of several functions that inserts into the astrom
   structure star-independent parameters needed for the chain of
   astrometric transformations ICRS <-> GCRS <-> CIRS <-> observed.

   The various functions support different classes of observer and
   portions of the transformation chain:

   |    Functions      |  Observer    | Transformation        |
   |:------------------|:-------------|:----------------------|
   | eraApcg eraApcg13 |  geocentric  | ICRS <-> GCRS         |
   | eraApci eraApci13 |  terrestrial | ICRS <-> CIRS         |
   | eraApco eraApco13 |  terrestrial | ICRS <-> observed     |
   | eraApcs eraApcs13 |  space       | ICRS <-> GCRS         |
   | eraAper eraAper13 |  terrestrial | update Earth rotation |
   | eraApio eraApio13 |  terrestrial | CIRS <-> observed     |

   Those with names ending in "13" use contemporary ERFA models to
   compute the various ephemerides.  The others accept ephemerides
   supplied by the caller.

   The transformation from ICRS to GCRS covers space motion,
   parallax, light deflection, and aberration.  From GCRS to CIRS
   comprises frame bias and precession-nutation.  From CIRS to
   observed takes account of Earth rotation, polar motion, diurnal
   aberration and parallax (unless subsumed into the ICRS <-> GCRS
   transformation), and atmospheric refraction.

6. The context structure astrom produced by this function is used by
   eraAtciq* and eraAticq*.

### Called ###

- `eraEpv00`: Earth position and velocity
- `eraApcs`: astrometry parameters, ICRS-GCRS, space observer

"""
function apcs13(date1, date2, pv)
    astrom = ASTROM(0.0, zeros(3), zeros(3), 0.0, zeros(3), 0.0, zeros((3, 3)), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    ccall((:eraApcs13, liberfa), Cvoid,
          (Cdouble, Cdouble, Ptr{Cdouble}, Ref{ASTROM}),
          date1, date2, pv, astrom)
    astrom
end

"""
    aper(theta, astrom)

In the star-independent astrometry parameters, update only the
Earth rotation angle, supplied by the caller explicitly.

### Given ###

- `theta`: Earth rotation angle (radians, Note 2)
- `astrom`: Star-independent astrometry parameters:
    - `pmt`: unchanged
    - `eb`: unchanged
    - `eh`: unchanged
    - `em`: unchanged
    - `v`: unchanged
    - `bm1`: unchanged
    - `bpn`: unchanged
    - `along`: Longitude + s' (radians)
    - `xpl`: unchanged
    - `ypl`: unchanged
    - `sphi`: unchanged
    - `cphi`: unchanged
    - `diurab`: unchanged
    - `eral`: unchanged
    - `refa`: unchanged
    - `refb`: unchanged

### Returned ###

- `astrom`: Star-independent astrometry parameters:
    - `pmt`: unchanged
    - `eb`: unchanged
    - `eh`: unchanged
    - `em`: unchanged
    - `v`: unchanged
    - `bm1`: unchanged
    - `bpn`: unchanged
    - `along`: unchanged
    - `xpl`: unchanged
    - `ypl`: unchanged
    - `sphi`: unchanged
    - `cphi`: unchanged
    - `diurab`: unchanged
    - `eral`: "Local" Earth rotation angle (radians)
    - `refa`: unchanged
    - `refb`: unchanged

### Notes ###

1. This function exists to enable sidereal-tracking applications to
   avoid wasteful recomputation of the bulk of the astrometry
   parameters:  only the Earth rotation is updated.

2. For targets expressed as equinox based positions, such as
   classical geocentric apparent (RA,Dec), the supplied theta can be
   Greenwich apparent sidereal time rather than Earth rotation
   angle.

3. The function eraAper13 can be used instead of the present
   function, and starts from UT1 rather than ERA itself.

4. This is one of several functions that inserts into the astrom
   structure star-independent parameters needed for the chain of
   astrometric transformations ICRS <-> GCRS <-> CIRS <-> observed.

   The various functions support different classes of observer and
   portions of the transformation chain:

   |    Functions      |  Observer    | Transformation        |
   |:------------------|:-------------|:----------------------|
   | eraApcg eraApcg13 |  geocentric  | ICRS <-> GCRS         |
   | eraApci eraApci13 |  terrestrial | ICRS <-> CIRS         |
   | eraApco eraApco13 |  terrestrial | ICRS <-> observed     |
   | eraApcs eraApcs13 |  space       | ICRS <-> GCRS         |
   | eraAper eraAper13 |  terrestrial | update Earth rotation |
   | eraApio eraApio13 |  terrestrial | CIRS <-> observed     |

   Those with names ending in "13" use contemporary ERFA models to
   compute the various ephemerides.  The others accept ephemerides
   supplied by the caller.

   The transformation from ICRS to GCRS covers space motion,
   parallax, light deflection, and aberration.  From GCRS to CIRS
   comprises frame bias and precession-nutation.  From CIRS to
   observed takes account of Earth rotation, polar motion, diurnal
   aberration and parallax (unless subsumed into the ICRS <-> GCRS
   transformation), and atmospheric refraction.

"""
function aper(theta, astrom)
    ccall((:eraAper, liberfa), Cvoid,
          (Cdouble, Ref{ASTROM}),
          theta, astrom)
    astrom
end

"""
    aper13(ut11, ut12, astrom)

In the star-independent astrometry parameters, update only the
Earth rotation angle.  The caller provides UT1, (n.b. not UTC).

### Given ###

- `ut11`: UT1 as a 2-part...
- `ut12`: ...Julian Date (Note 1)
- `astrom`: Star-independent astrometry parameters:
    - `pmt`: unchanged
    - `eb`: unchanged
    - `eh`: unchanged
    - `em`: unchanged
    - `v`: unchanged
    - `bm1`: unchanged
    - `bpn`: unchanged
    - `along`: Longitude + s' (radians)
    - `xpl`: unchanged
    - `ypl`: unchanged
    - `sphi`: unchanged
    - `cphi`: unchanged
    - `diurab`: unchanged
    - `eral`: unchanged
    - `refa`: unchanged
    - `refb`: unchanged

### Returned ###

- `astrom`: Star-independent astrometry parameters:
    - `pmt`: unchanged
    - `eb`: unchanged
    - `eh`: unchanged
    - `em`: unchanged
    - `v`: unchanged
    - `bm1`: unchanged
    - `bpn`: unchanged
    - `along`: unchanged
    - `xpl`: unchanged
    - `ypl`: unchanged
    - `sphi`: unchanged
    - `cphi`: unchanged
    - `diurab`: unchanged
    - `eral`: "Local" Earth rotation angle (radians)
    - `refa`: unchanged
    - `refb`: unchanged

### Notes ###

1. The UT1 date (n.b. not UTC) ut11+ut12 is a Julian Date,
   apportioned in any convenient way between the arguments ut11 and
   ut12.  For example, JD(UT1)=2450123.7 could be expressed in any
   of these ways, among others:

          ut11           ut12

       2450123.7           0.0       (JD method)
       2451545.0       -1421.3       (J2000 method)
       2400000.5       50123.2       (MJD method)
       2450123.5           0.2       (date & time method)

   The JD method is the most natural and convenient to use in cases
   where the loss of several decimal digits of resolution is
   acceptable.  The J2000 and MJD methods are good compromises
   between resolution and convenience.  The date & time method is
   best matched to the algorithm used:  maximum precision is
   delivered when the ut11 argument is for 0hrs UT1 on the day in
   question and the ut12 argument lies in the range 0 to 1, or vice
   versa.

2. If the caller wishes to provide the Earth rotation angle itself,
   the function eraAper can be used instead.  One use of this
   technique is to substitute Greenwich apparent sidereal time and
   thereby to support equinox based transformations directly.

3. This is one of several functions that inserts into the astrom
   structure star-independent parameters needed for the chain of
   astrometric transformations ICRS <-> GCRS <-> CIRS <-> observed.

   The various functions support different classes of observer and
   portions of the transformation chain:

   |    Functions      |  Observer    | Transformation        |
   |:------------------|:-------------|:----------------------|
   | eraApcg eraApcg13 |  geocentric  | ICRS <-> GCRS         |
   | eraApci eraApci13 |  terrestrial | ICRS <-> CIRS         |
   | eraApco eraApco13 |  terrestrial | ICRS <-> observed     |
   | eraApcs eraApcs13 |  space       | ICRS <-> GCRS         |
   | eraAper eraAper13 |  terrestrial | update Earth rotation |
   | eraApio eraApio13 |  terrestrial | CIRS <-> observed     |

   Those with names ending in "13" use contemporary ERFA models to
   compute the various ephemerides.  The others accept ephemerides
   supplied by the caller.

   The transformation from ICRS to GCRS covers space motion,
   parallax, light deflection, and aberration.  From GCRS to CIRS
   comprises frame bias and precession-nutation.  From CIRS to
   observed takes account of Earth rotation, polar motion, diurnal
   aberration and parallax (unless subsumed into the ICRS <-> GCRS
   transformation), and atmospheric refraction.

### Called ###

- `eraAper`: astrometry parameters: update ERA
- `eraEra00`: Earth rotation angle, IAU 2000

"""
function aper13(ut11, ut12, astrom)
    ccall((:eraAper13, liberfa), Cvoid,
          (Cdouble, Cdouble, Ref{ASTROM}),
          ut11, ut12, astrom)
    astrom
end

"""
    apio(sp, theta, elong, phi, hm, xp, yp, refa, refb)

For a terrestrial observer, prepare star-independent astrometry
parameters for transformations between CIRS and observed
coordinates.  The caller supplies the Earth orientation information
and the refraction constants as well as the site coordinates.

### Given ###

- `sp`: The TIO locator s' (radians, Note 1)
- `theta`: Earth rotation angle (radians)
- `elong`: Longitude (radians, east +ve, Note 2)
- `phi`: Geodetic latitude (radians, Note 2)
- `hm`: Height above ellipsoid (m, geodetic Note 2)
- `xp`, `yp`: Polar motion coordinates (radians, Note 3)
- `refa`: Refraction constant A (radians, Note 4)
- `refb`: Refraction constant B (radians, Note 4)

### Returned ###

- `astrom`: Star-independent astrometry parameters:
    - `pmt`: unchanged
    - `eb`: unchanged
    - `eh`: unchanged
    - `em`: unchanged
    - `v`: unchanged
    - `bm1`: unchanged
    - `bpn`: unchanged
    - `along`: Longitude + s' (radians)
    - `xp1`: Polar motion xp wrt local meridian (radians)
    - `yp1`: Polar motion yp wrt local meridian (radians)
    - `sphi`: Sine of geodetic latitude
    - `cphi`: Cosine of geodetic latitude
    - `diurab`: Magnitude of diurnal aberration vector
    - `eral`: "Local" Earth rotation angle (radians)
    - `refa`: Refraction constant A (radians)
    - `refb`: Refraction constant B (radians)

### Notes ###

1. sp, the TIO locator s', is a tiny quantity needed only by the
   most precise applications.  It can either be set to zero or
   predicted using the ERFA function eraSp00.

2. The geographical coordinates are with respect to the ERFA_WGS84
   reference ellipsoid.  TAKE CARE WITH THE LONGITUDE SIGN:  the
   longitude required by the present function is east-positive
   (i.e. right-handed), in accordance with geographical convention.

3. The polar motion xp,yp can be obtained from IERS bulletins.  The
   values are the coordinates (in radians) of the Celestial
   Intermediate Pole with respect to the International Terrestrial
   Reference System (see IERS Conventions 2003), measured along the
   meridians 0 and 90 deg west respectively.  For many applications,
   xp and yp can be set to zero.

   Internally, the polar motion is stored in a form rotated onto the
   local meridian.

4. The refraction constants refa and refb are for use in a
   dZ = A*tan(Z)+B*tan^3(Z) model, where Z is the observed
   (i.e. refracted) zenith distance and dZ is the amount of
   refraction.

5. It is advisable to take great care with units, as even unlikely
   values of the input parameters are accepted and processed in
   accordance with the models used.

6. In cases where the caller does not wish to provide the Earth
   rotation information and refraction constants, the function
   eraApio13 can be used instead of the present function.  This
   starts from UTC and weather readings etc. and computes suitable
   values using other ERFA functions.

7. This is one of several functions that inserts into the astrom
   structure star-independent parameters needed for the chain of
   astrometric transformations ICRS <-> GCRS <-> CIRS <-> observed.

   The various functions support different classes of observer and
   portions of the transformation chain:

   |    Functions      |  Observer    | Transformation        |
   |:------------------|:-------------|:----------------------|
   | eraApcg eraApcg13 |  geocentric  | ICRS <-> GCRS         |
   | eraApci eraApci13 |  terrestrial | ICRS <-> CIRS         |
   | eraApco eraApco13 |  terrestrial | ICRS <-> observed     |
   | eraApcs eraApcs13 |  space       | ICRS <-> GCRS         |
   | eraAper eraAper13 |  terrestrial | update Earth rotation |
   | eraApio eraApio13 |  terrestrial | CIRS <-> observed     |

   Those with names ending in "13" use contemporary ERFA models to
   compute the various ephemerides.  The others accept ephemerides
   supplied by the caller.

   The transformation from ICRS to GCRS covers space motion,
   parallax, light deflection, and aberration.  From GCRS to CIRS
   comprises frame bias and precession-nutation.  From CIRS to
   observed takes account of Earth rotation, polar motion, diurnal
   aberration and parallax (unless subsumed into the ICRS <-> GCRS
   transformation), and atmospheric refraction.

8. The context structure astrom produced by this function is used by
   eraAtioq and eraAtoiq.

### Called ###

- `eraPvtob`: position/velocity of terrestrial station
- `eraAper`: astrometry parameters: update ERA

"""
function apio(sp, theta, elong, phi, hm, xp, yp, refa, refb)
    astrom = ASTROM(0.0, zeros(3), zeros(3), 0.0, zeros(3), 0.0, zeros((3, 3)), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    ccall((:eraApio, liberfa), Cvoid,
          (Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ref{ASTROM}),
          sp, theta, elong, phi, hm, xp, yp, refa, refb, astrom)
    astrom
end

"""
    apio13(utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tk, rh, wl)

For a terrestrial observer, prepare star-independent astrometry
parameters for transformations between CIRS and observed
coordinates.  The caller supplies UTC, site coordinates, ambient air
conditions and observing wavelength.

### Given ###

- `utc1`: UTC as a 2-part...
- `utc2`: ...quasi Julian Date (Notes 1,2)
- `dut1`: UT1-UTC (seconds)
- `elong`: Longitude (radians, east +ve, Note 3)
- `phi`: Geodetic latitude (radians, Note 3)
- `hm`: Height above ellipsoid (m, geodetic Notes 4,6)
- `xp`, `yp`: Polar motion coordinates (radians, Note 5)
- `phpa`: Pressure at the observer (hPa = mB, Note 6)
- `tc`: Ambient temperature at the observer (deg C)
- `rh`: Relative humidity at the observer (range 0-1)
- `wl`: Wavelength (micrometers, Note 7)

### Returned ###

- `astrom`: Star-independent astrometry parameters:
    - `pmt`: unchanged
    - `eb`: unchanged
    - `eh`: unchanged
    - `em`: unchanged
    - `v`: unchanged
    - `bm1`: unchanged
    - `bpn`: unchanged
    - `along`: Longitude + s' (radians)
    - `xp1`: Polar motion xp wrt local meridian (radians)
    - `yp1`: Polar motion yp wrt local meridian (radians)
    - `sphi`: Sine of geodetic latitude
    - `cphi`: Cosine of geodetic latitude
    - `diurab`: Magnitude of diurnal aberration vector
    - `eral`: "Local" Earth rotation angle (radians)
    - `refa`: Refraction constant A (radians)
    - `refb`: Refraction constant B (radians)

### Notes ###

1.  utc1+utc2 is quasi Julian Date (see Note 2), apportioned in any
    convenient way between the two arguments, for example where utc1
    is the Julian Day Number and utc2 is the fraction of a day.

    However, JD cannot unambiguously represent UTC during a leap
    second unless special measures are taken.  The convention in the
    present function is that the JD day represents UTC days whether
    the length is 86399, 86400 or 86401 SI seconds.

    Applications should use the function eraDtf2d to convert from
    calendar date and time of day into 2-part quasi Julian Date, as
    it implements the leap-second-ambiguity convention just
    described.

2.  The warning status "dubious year" flags UTCs that predate the
    introduction of the time scale or that are too far in the future
    to be trusted.  See eraDat for further details.

3.  UT1-UTC is tabulated in IERS bulletins.  It increases by exactly
    one second at the end of each positive UTC leap second,
    introduced in order to keep UT1-UTC within +/- 0.9s.  n.b. This
    practice is under review, and in the future UT1-UTC may grow
    essentially without limit.

4.  The geographical coordinates are with respect to the ERFA_WGS84
    reference ellipsoid.  TAKE CARE WITH THE LONGITUDE SIGN:  the
    longitude required by the present function is east-positive
    (i.e. right-handed), in accordance with geographical convention.

5.  The polar motion xp,yp can be obtained from IERS bulletins.  The
    values are the coordinates (in radians) of the Celestial
    Intermediate Pole with respect to the International Terrestrial
    Reference System (see IERS Conventions 2003), measured along the
    meridians 0 and 90 deg west respectively.  For many applications,
    xp and yp can be set to zero.

    Internally, the polar motion is stored in a form rotated onto
    the local meridian.

6.  If hm, the height above the ellipsoid of the observing station
    in meters, is not known but phpa, the pressure in hPa (=mB), is
    available, an adequate estimate of hm can be obtained from the
    expression

          hm = -29.3 * tsl * log ( phpa / 1013.25 );

    where tsl is the approximate sea-level air temperature in K
    (See Astrophysical Quantities, C.W.Allen, 3rd edition, section
    52).  Similarly, if the pressure phpa is not known, it can be
    estimated from the height of the observing station, hm, as
    follows:

          phpa = 1013.25 * exp ( -hm / ( 29.3 * tsl ) );

    Note, however, that the refraction is nearly proportional to the
    pressure and that an accurate phpa value is important for
    precise work.

7.  The argument wl specifies the observing wavelength in
    micrometers.  The transition from optical to radio is assumed to
    occur at 100 micrometers (about 3000 GHz).

8.  It is advisable to take great care with units, as even unlikely
    values of the input parameters are accepted and processed in
    accordance with the models used.

9.  In cases where the caller wishes to supply his own Earth
    rotation information and refraction constants, the function
    eraApc can be used instead of the present function.

10. This is one of several functions that inserts into the astrom
    structure star-independent parameters needed for the chain of
    astrometric transformations ICRS <-> GCRS <-> CIRS <-> observed.

    The various functions support different classes of observer and
    portions of the transformation chain:

   |    Functions      |  Observer    | Transformation        |
   |:------------------|:-------------|:----------------------|
   | eraApcg eraApcg13 |  geocentric  | ICRS <-> GCRS         |
   | eraApci eraApci13 |  terrestrial | ICRS <-> CIRS         |
   | eraApco eraApco13 |  terrestrial | ICRS <-> observed     |
   | eraApcs eraApcs13 |  space       | ICRS <-> GCRS         |
   | eraAper eraAper13 |  terrestrial | update Earth rotation |
   | eraApio eraApio13 |  terrestrial | CIRS <-> observed     |

    Those with names ending in "13" use contemporary ERFA models to
    compute the various ephemerides.  The others accept ephemerides
    supplied by the caller.

    The transformation from ICRS to GCRS covers space motion,
    parallax, light deflection, and aberration.  From GCRS to CIRS
    comprises frame bias and precession-nutation.  From CIRS to
    observed takes account of Earth rotation, polar motion, diurnal
    aberration and parallax (unless subsumed into the ICRS <-> GCRS
    transformation), and atmospheric refraction.

11. The context structure astrom produced by this function is used
    by eraAtioq and eraAtoiq.

### Called ###

- `eraUtctai`: UTC to TAI
- `eraTaitt`: TAI to TT
- `eraUtcut1`: UTC to UT1
- `eraSp00`: the TIO locator s', IERS 2000
- `eraEra00`: Earth rotation angle, IAU 2000
- `eraRefco`: refraction constants for given ambient conditions
- `eraApio`: astrometry parameters, CIRS-observed

"""
function apio13(utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tk, rh, wl)
    astrom = ASTROM(0.0, zeros(3), zeros(3), 0.0, zeros(3), 0.0, zeros((3, 3)), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    i = ccall((:eraApio13, liberfa), Cint,
              (Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ref{ASTROM}),
              utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tk, rh, wl, astrom)
    if i == -1
        throw(ERFAException("unacceptable date"))
    elseif i == +1
        @warn "dubious year"
    end
    astrom
end

"""
    atci13(rc, dc, pr, pd, px, rv, date1, date2)

Transform ICRS star data, epoch J2000.0, to CIRS.

### Given ###

- `rc`: ICRS right ascension at J2000.0 (radians, Note 1)
- `dc`: ICRS declination at J2000.0 (radians, Note 1)
- `pr`: RA proper motion (radians/year; Note 2)
- `pd`: Dec proper motion (radians/year)
- `px`: Parallax (arcsec)
- `rv`: Radial velocity (km/s, +ve if receding)
- `date1`: TDB as a 2-part...
- `date2`: ...Julian Date (Note 3)

### Returned ###

- `ri`, `di`: CIRS geocentric RA,Dec (radians)
- `eo`: Equation of the origins (ERA-GST, Note 5)

### Notes ###

1. Star data for an epoch other than J2000.0 (for example from the
   Hipparcos catalog, which has an epoch of J1991.25) will require a
   preliminary call to eraPmsafe before use.

2. The proper motion in RA is dRA/dt rather than cos(Dec)*dRA/dt.

3. The TDB date date1+date2 is a Julian Date, apportioned in any
   convenient way between the two arguments.  For example,
   JD(TDB)=2450123.7 could be expressed in any of these ways, among
   others:

   | `date1`   |     `date2` |                    |
   |:----------|:------------|:-------------------|
   | 2450123.7 |         0.0 | JD method          |
   | 2451545.0 |     -1421.3 | J2000 method       |
   | 2400000.5 |     50123.2 | MJD method         |
   | 2450123.5 |         0.2 | date & time method |

   The JD method is the most natural and convenient to use in cases
   where the loss of several decimal digits of resolution is
   acceptable.  The J2000 method is best matched to the way the
   argument is handled internally and will deliver the optimum
   resolution.  The MJD method and the date & time methods are both
   good compromises between resolution and convenience.  For most
   applications of this function the choice will not be at all
   critical.

   TT can be used instead of TDB without any significant impact on
   accuracy.

4. The available accuracy is better than 1 milliarcsecond, limited
   mainly by the precession-nutation model that is used, namely
   IAU 2000A/2006.  Very close to solar system bodies, additional
   errors of up to several milliarcseconds can occur because of
   unmodeled light deflection;  however, the Sun's contribution is
   taken into account, to first order.  The accuracy limitations of
   the ERFA function eraEpv00 (used to compute Earth position and
   velocity) can contribute aberration errors of up to
   5 microarcseconds.  Light deflection at the Sun's limb is
   uncertain at the 0.4 mas level.

5. Should the transformation to (equinox based) apparent place be
   required rather than (CIO based) intermediate place, subtract the
   equation of the origins from the returned right ascension:
   RA = RI - EO. (The eraAnp function can then be applied, as
   required, to keep the result in the conventional 0-2pi range.)

### Called ###

- `eraApci13`: astrometry parameters, ICRS-CIRS, 2013
- `eraAtciq`: quick ICRS to CIRS

"""
function atci13(rc, dc, pr, pd, px, rv, date1, date2)
    ri = Ref(0.0)
    di = Ref(0.0)
    eo = Ref(0.0)
    ccall((:eraAtci13, liberfa), Cvoid,
          (Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
          rc, dc, pr, pd, px, rv, date1, date2, ri, di, eo)
    ri[], di[], eo[]
end

"""
    atciq(rc, dc, pr, pd, px, rv, astrom)

Quick ICRS, epoch J2000.0, to CIRS transformation, given precomputed
star-independent astrometry parameters.

Use of this function is appropriate when efficiency is important and
where many star positions are to be transformed for one date.  The
star-independent parameters can be obtained by calling one of the
functions eraApci[13], eraApcg[13], eraApco[13] or eraApcs[13].

If the parallax and proper motions are zero the eraAtciqz function
can be used instead.

### Given ###

- `rc`, `dc`: ICRS RA,Dec at J2000.0 (radians)
- `pr`: RA proper motion (radians/year; Note 3)
- `pd`: Dec proper motion (radians/year)
- `px`: Parallax (arcsec)
- `rv`: Radial velocity (km/s, +ve if receding)
- `astrom`: Star-independent astrometry parameters:
    - `pmt`: PM time interval (SSB, Julian years)
    - `eb`: SSB to observer (vector, au)
    - `eh`: Sun to observer (unit vector)
    - `em`: Distance from Sun to observer (au)
    - `v`: Barycentric observer velocity (vector, c)
    - `bm1`: ``\\sqrt{1-|v|^2}`` Reciprocal of Lorenz factor
    - `bpn`: Bias-precession-nutation matrix
    - `along`: Longitude + s' (radians)
    - `xp1`: Polar motion xp wrt local meridian (radians)
    - `yp1`: Polar motion yp wrt local meridian (radians)
    - `sphi`: Sine of geodetic latitude
    - `cphi`: Cosine of geodetic latitude
    - `diurab`: Magnitude of diurnal aberration vector
    - `eral`: "Local" Earth rotation angle (radians)
    - `refa`: Refraction constant A (radians)
    - `refb`: Refraction constant B (radians)

### Returned ###

- `ri`, `di`: CIRS RA,Dec (radians)

### Notes ###

1. All the vectors are with respect to BCRS axes.

2. Star data for an epoch other than J2000.0 (for example from the
   Hipparcos catalog, which has an epoch of J1991.25) will require a
   preliminary call to eraPmsafe before use.

3. The proper motion in RA is dRA/dt rather than cos(Dec)*dRA/dt.

### Called ###

- `eraPmpx`: proper motion and parallax
- `eraLdsun`: light deflection by the Sun
- `eraAb`: stellar aberration
- `eraRxp`: product of r-matrix and pv-vector
- `eraC2s`: p-vector to spherical
- `eraAnp`: normalize angle into range 0 to 2pi

"""
function atciq(rc, dc, pr, pd, px, rv, astrom)
    ri = Ref(0.0)
    di = Ref(0.0)
    ccall((:eraAtciq, liberfa), Cvoid,
          (Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ref{ASTROM}, Ref{Cdouble}, Ref{Cdouble}),
          rc, dc, pr, pd, px, rv, astrom, ri, di)
    ri[], di[]
end

"""
    atciqn(rc, dc, pr, pd, px, rv, astrom, b::Vector{LDBODY})

Quick ICRS, epoch J2000.0, to CIRS transformation, given precomputed
star-independent astrometry parameters plus a list of light-
deflecting bodies.

Use of this function is appropriate when efficiency is important and
where many star positions are to be transformed for one date.  The
star-independent parameters can be obtained by calling one of the
functions eraApci[13], eraApcg[13], eraApco[13] or eraApcs[13].

If the only light-deflecting body to be taken into account is the
Sun, the eraAtciq function can be used instead.  If in addition the
parallax and proper motions are zero, the eraAtciqz function can be
used.

### Given ###

- `rc`, `dc`: ICRS RA,Dec at J2000.0 (radians)
- `pr`: RA proper motion (radians/year; Note 3)
- `pd`: Dec proper motion (radians/year)
- `px`: Parallax (arcsec)
- `rv`: Radial velocity (km/s, +ve if receding)
- EraASTROM*   star-independent astrometry parameters:
    - `pmt`: PM time interval (SSB, Julian years)
    - `eb`: SSB to observer (vector, au)
    - `eh`: Sun to observer (unit vector)
    - `em`: Distance from Sun to observer (au)
    - `v`: Barycentric observer velocity (vector, c)
    - `bm1`: ``\\sqrt{1-|v|^2}`` Reciprocal of Lorenz factor
    - `bpn`: Bias-precession-nutation matrix
    - `along`: Longitude + s' (radians)
    - `xp1`: Polar motion xp wrt local meridian (radians)
    - `yp1`: Polar motion yp wrt local meridian (radians)
    - `sphi`: Sine of geodetic latitude
    - `cphi`: Cosine of geodetic latitude
    - `diurab`: Magnitude of diurnal aberration vector
    - `eral`: "Local" Earth rotation angle (radians)
    - `refa`: Refraction constant A (radians)
    - `refb`: Refraction constant B (radians)
- `n`: Number of bodies (Note 3)
- `b::Vector{LDBODY}`: Data for each of the n bodies (Notes 3,4):
    - `bm`: Mass of the body (solar masses, Note 5)
    - `dl`: Deflection limiter (Note 6)
    - `pv`: Barycentric PV of the body (au, au/day)

### Returned ###

- `ri`, `di`: CIRS RA,Dec (radians)

### Notes ###

1. Star data for an epoch other than J2000.0 (for example from the
   Hipparcos catalog, which has an epoch of J1991.25) will require a
   preliminary call to eraPmsafe before use.

2. The proper motion in RA is dRA/dt rather than cos(Dec)*dRA/dt.

3. The struct b contains n entries, one for each body to be
   considered.  If n = 0, no gravitational light deflection will be
   applied, not even for the Sun.

4. The struct b should include an entry for the Sun as well as for
   any planet or other body to be taken into account.  The entries
   should be in the order in which the light passes the body.

5. In the entry in the b struct for body i, the mass parameter
   b[i].bm can, as required, be adjusted in order to allow for such
   effects as quadrupole field.

6. The deflection limiter parameter b[i].dl is phi^2/2, where phi is
   the angular separation (in radians) between star and body at
   which limiting is applied.  As phi shrinks below the chosen
   threshold, the deflection is artificially reduced, reaching zero
   for phi = 0.   Example values suitable for a terrestrial
   observer, together with masses, are as follows:

      body i     b[i].bm        b[i].dl

      Sun        1.0            6e-6
      Jupiter    0.00095435     3e-9
      Saturn     0.00028574     3e-10

7. For efficiency, validation of the contents of the b array is
   omitted.  The supplied masses must be greater than zero, the
   position and velocity vectors must be right, and the deflection
   limiter greater than zero.

### Called ###

- `eraPmpx`: proper motion and parallax
- `eraLdn`: light deflection by n bodies
- `eraAb`: stellar aberration
- `eraRxp`: product of r-matrix and pv-vector
- `eraC2s`: p-vector to spherical
- `eraAnp`: normalize angle into range 0 to 2pi

"""
function atciqn(rc, dc, pr, pd, px, rv, astrom, b::Vector{LDBODY})
    ri = Ref(0.0)
    di = Ref(0.0)
    n = length(b)
    ccall((:eraAtciqn, liberfa), Cvoid,
          (Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ref{ASTROM}, Cint, Ptr{LDBODY}, Ref{Cdouble}, Ref{Cdouble}),
          rc, dc, pr, pd, px, rv, astrom, n, b, ri, di)
    ri[], di[]
end

"""
    atciqz(rc, dc, astrom)

Quick ICRS to CIRS transformation, given precomputed star-
independent astrometry parameters, and assuming zero parallax and
proper motion.

Use of this function is appropriate when efficiency is important and
where many star positions are to be transformed for one date.  The
star-independent parameters can be obtained by calling one of the
functions eraApci[13], eraApcg[13], eraApco[13] or eraApcs[13].

The corresponding function for the case of non-zero parallax and
proper motion is eraAtciq.

### Given ###

- `rc`, `dc`: ICRS astrometric RA,Dec (radians)
- `astrom`: Star-independent astrometry parameters:
    - `pmt`: PM time interval (SSB, Julian years)
    - `eb`: SSB to observer (vector, au)
    - `eh`: Sun to observer (unit vector)
    - `em`: Distance from Sun to observer (au)
    - `v`: Barycentric observer velocity (vector, c)
    - `bm1`: ``\\sqrt{1-|v|^2}`` Reciprocal of Lorenz factor
    - `bpn`: Bias-precession-nutation matrix
    - `along`: Longitude + s' (radians)
    - `xp1`: Polar motion xp wrt local meridian (radians)
    - `yp1`: Polar motion yp wrt local meridian (radians)
    - `sphi`: Sine of geodetic latitude
    - `cphi`: Cosine of geodetic latitude
    - `diurab`: Magnitude of diurnal aberration vector
    - `eral`: "Local" Earth rotation angle (radians)
    - `refa`: Refraction constant A (radians)
    - `refb`: Refraction constant B (radians)

### Returned ###

- `ri`, `di`: CIRS RA,Dec (radians)

### Note ###

   All the vectors are with respect to BCRS axes.

### References ###

- Urban, S. & Seidelmann, P. K. (eds), Explanatory Supplement to
    the Astronomical Almanac, 3rd ed., University Science Books
    (2013).

- Klioner, Sergei A., "A practical relativistic model for micro-
    arcsecond astrometry in space", Astr. J. 125, 1580-1597 (2003).

### Called ###

- `eraS2c`: spherical coordinates to unit vector
- `eraLdsun`: light deflection due to Sun
- `eraAb`: stellar aberration
- `eraRxp`: product of r-matrix and p-vector
- `eraC2s`: p-vector to spherical
- `eraAnp`: normalize angle into range +/- pi

"""
function atciqz(rc, dc, astrom)
    ri = Ref(0.0)
    di = Ref(0.0)
    ccall((:eraAtciqz, liberfa), Cvoid,
          (Cdouble, Cdouble, Ref{ASTROM}, Ref{Cdouble}, Ref{Cdouble}),
          rc, dc, astrom, ri, di)
    ri[], di[]
end

"""
    atco13(rc, dc, pr, pd, px, rv, utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tk, rh, wl)

ICRS RA,Dec to observed place.  The caller supplies UTC, site
coordinates, ambient air conditions and observing wavelength.

ERFA models are used for the Earth ephemeris, bias-precession-
nutation, Earth orientation and refraction.

### Given ###

- `rc`, `dc`: ICRS right ascension at J2000.0 (radians, Note 1)
- `pr`: RA proper motion (radians/year; Note 2)
- `pd`: Dec proper motion (radians/year)
- `px`: Parallax (arcsec)
- `rv`: Radial velocity (km/s, +ve if receding)
- `utc1`: UTC as a 2-part...
- `utc2`: ...quasi Julian Date (Notes 3-4)
- `dut1`: UT1-UTC (seconds, Note 5)
- `elong`: Longitude (radians, east +ve, Note 6)
- `phi`: Latitude (geodetic, radians, Note 6)
- `hm`: Height above ellipsoid (m, geodetic, Notes 6,8)
- `xp`, `yp`: Polar motion coordinates (radians, Note 7)
- `phpa`: Pressure at the observer (hPa = mB, Note 8)
- `tc`: Ambient temperature at the observer (deg C)
- `rh`: Relative humidity at the observer (range 0-1)
- `wl`: Wavelength (micrometers, Note 9)

### Returned ###

- `aob`: Observed azimuth (radians: N=0,E=90)
- `zob`: Observed zenith distance (radians)
- `hob`: Observed hour angle (radians)
- `dob`: Observed declination (radians)
- `rob`: Observed right ascension (CIO-based, radians)
- `eo`: Equation of the origins (ERA-GST)

### Notes ###

1.  Star data for an epoch other than J2000.0 (for example from the
    Hipparcos catalog, which has an epoch of J1991.25) will require
    a preliminary call to eraPmsafe before use.

2.  The proper motion in RA is dRA/dt rather than cos(Dec)*dRA/dt.

3.  utc1+utc2 is quasi Julian Date (see Note 2), apportioned in any
    convenient way between the two arguments, for example where utc1
    is the Julian Day Number and utc2 is the fraction of a day.

    However, JD cannot unambiguously represent UTC during a leap
    second unless special measures are taken.  The convention in the
    present function is that the JD day represents UTC days whether
    the length is 86399, 86400 or 86401 SI seconds.

    Applications should use the function eraDtf2d to convert from
    calendar date and time of day into 2-part quasi Julian Date, as
    it implements the leap-second-ambiguity convention just
    described.

4.  The warning status "dubious year" flags UTCs that predate the
    introduction of the time scale or that are too far in the
    future to be trusted.  See eraDat for further details.

5.  UT1-UTC is tabulated in IERS bulletins.  It increases by exactly
    one second at the end of each positive UTC leap second,
    introduced in order to keep UT1-UTC within +/- 0.9s.  n.b. This
    practice is under review, and in the future UT1-UTC may grow
    essentially without limit.

6.  The geographical coordinates are with respect to the ERFA_WGS84
    reference ellipsoid.  TAKE CARE WITH THE LONGITUDE SIGN:  the
    longitude required by the present function is east-positive
    (i.e. right-handed), in accordance with geographical convention.

7.  The polar motion xp,yp can be obtained from IERS bulletins.  The
    values are the coordinates (in radians) of the Celestial
    Intermediate Pole with respect to the International Terrestrial
    Reference System (see IERS Conventions 2003), measured along the
    meridians 0 and 90 deg west respectively.  For many
    applications, xp and yp can be set to zero.

8.  If hm, the height above the ellipsoid of the observing station
    in meters, is not known but phpa, the pressure in hPa (=mB),
    is available, an adequate estimate of hm can be obtained from
    the expression

          hm = -29.3 * tsl * log ( phpa / 1013.25 );

    where tsl is the approximate sea-level air temperature in K
    (See Astrophysical Quantities, C.W.Allen, 3rd edition, section
    52).  Similarly, if the pressure phpa is not known, it can be
    estimated from the height of the observing station, hm, as
    follows:

          phpa = 1013.25 * exp ( -hm / ( 29.3 * tsl ) );

    Note, however, that the refraction is nearly proportional to
    the pressure and that an accurate phpa value is important for
    precise work.

9.  The argument wl specifies the observing wavelength in
    micrometers.  The transition from optical to radio is assumed to
    occur at 100 micrometers (about 3000 GHz).

10. The accuracy of the result is limited by the corrections for
    refraction, which use a simple A*tan(z) + B*tan^3(z) model.
    Providing the meteorological parameters are known accurately and
    there are no gross local effects, the predicted observed
    coordinates should be within 0.05 arcsec (optical) or 1 arcsec
    (radio) for a zenith distance of less than 70 degrees, better
    than 30 arcsec (optical or radio) at 85 degrees and better
    than 20 arcmin (optical) or 30 arcmin (radio) at the horizon.

    Without refraction, the complementary functions eraAtco13 and
    eraAtoc13 are self-consistent to better than 1 microarcsecond
    all over the celestial sphere.  With refraction included,
    consistency falls off at high zenith distances, but is still
    better than 0.05 arcsec at 85 degrees.

11. "Observed" Az,ZD means the position that would be seen by a
    perfect geodetically aligned theodolite.  (Zenith distance is
    used rather than altitude in order to reflect the fact that no
    allowance is made for depression of the horizon.)  This is
    related to the observed HA,Dec via the standard rotation, using
    the geodetic latitude (corrected for polar motion), while the
    observed HA and RA are related simply through the Earth rotation
    angle and the site longitude.  "Observed" RA,Dec or HA,Dec thus
    means the position that would be seen by a perfect equatorial
    with its polar axis aligned to the Earth's axis of rotation.

12. It is advisable to take great care with units, as even unlikely
    values of the input parameters are accepted and processed in
    accordance with the models used.

### Called ###

- `eraApco13`: astrometry parameters, ICRS-observed, 2013
- `eraAtciq`: quick ICRS to CIRS
- `eraAtioq`: quick CIRS to observed

"""
function atco13(rc, dc, pr, pd, px, rv, utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tk, rh, wl)
    aob = Ref(0.0)
    zob = Ref(0.0)
    hob = Ref(0.0)
    dob = Ref(0.0)
    rob = Ref(0.0)
    eo = Ref(0.0)
    i = ccall((:eraAtco13, liberfa), Cint,
              (Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
              rc, dc, pr, pd, px, rv, utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tk, rh, wl, aob, zob, hob, dob, rob, eo)
    if i == -1
        throw(ERFAException("unacceptable date"))
    elseif i == +1
        @warn "dubious year"
    end
    aob[], zob[], hob[], dob[], rob[], eo[]
end

"""
    atic13(ri, di, date1, date2)

Transform star RA,Dec from geocentric CIRS to ICRS astrometric.

### Given ###

- `ri`, `di`: CIRS geocentric RA,Dec (radians)
- `date1`: TDB as a 2-part...
- `date2`: ...Julian Date (Note 1)

### Returned ###

- `rc`, `dc`: ICRS astrometric RA,Dec (radians)
- `eo`: Equation of the origins (ERA-GST, Note 4)

### Notes ###

1. The TDB date date1+date2 is a Julian Date, apportioned in any
   convenient way between the two arguments.  For example,
   JD(TDB)=2450123.7 could be expressed in any of these ways, among
   others:

   | `date1`   |     `date2` |                    |
   |:----------|:------------|:-------------------|
   | 2450123.7 |         0.0 | JD method          |
   | 2451545.0 |     -1421.3 | J2000 method       |
   | 2400000.5 |     50123.2 | MJD method         |
   | 2450123.5 |         0.2 | date & time method |

   The JD method is the most natural and convenient to use in cases
   where the loss of several decimal digits of resolution is
   acceptable.  The J2000 method is best matched to the way the
   argument is handled internally and will deliver the optimum
   resolution.  The MJD method and the date & time methods are both
   good compromises between resolution and convenience.  For most
   applications of this function the choice will not be at all
   critical.

   TT can be used instead of TDB without any significant impact on
   accuracy.

2. Iterative techniques are used for the aberration and light
   deflection corrections so that the functions eraAtic13 (or
   eraAticq) and eraAtci13 (or eraAtciq) are accurate inverses;
   even at the edge of the Sun's disk the discrepancy is only about
   1 nanoarcsecond.

3. The available accuracy is better than 1 milliarcsecond, limited
   mainly by the precession-nutation model that is used, namely
   IAU 2000A/2006.  Very close to solar system bodies, additional
   errors of up to several milliarcseconds can occur because of
   unmodeled light deflection;  however, the Sun's contribution is
   taken into account, to first order.  The accuracy limitations of
   the ERFA function eraEpv00 (used to compute Earth position and
   velocity) can contribute aberration errors of up to
   5 microarcseconds.  Light deflection at the Sun's limb is
   uncertain at the 0.4 mas level.

4. Should the transformation to (equinox based) J2000.0 mean place
   be required rather than (CIO based) ICRS coordinates, subtract the
   equation of the origins from the returned right ascension:
   RA = RI - EO.  (The eraAnp function can then be applied, as
   required, to keep the result in the conventional 0-2pi range.)

### Called ###

- `eraApci13`: astrometry parameters, ICRS-CIRS, 2013
- `eraAticq`: quick CIRS to ICRS astrometric

"""
function atic13(ri, di, date1, date2)
    rc = Ref(0.0)
    dc = Ref(0.0)
    eo = Ref(0.0)
    ccall((:eraAtic13, liberfa), Cvoid,
          (Cdouble, Cdouble, Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
          ri, di, date1, date2, rc, dc, eo)
    rc[], dc[], eo[]
end

"""
    aticq(ri, di, astrom)

Quick CIRS RA,Dec to ICRS astrometric place, given the star-
independent astrometry parameters.

Use of this function is appropriate when efficiency is important and
where many star positions are all to be transformed for one date.
The star-independent astrometry parameters can be obtained by
calling one of the functions eraApci[13], eraApcg[13], eraApco[13]
or eraApcs[13].

### Given ###

- `ri`, `di`: CIRS RA,Dec (radians)
- `astrom`: Star-independent astrometry parameters:
    - `pmt`: PM time interval (SSB, Julian years)
    - `eb`: SSB to observer (vector, au)
    - `eh`: Sun to observer (unit vector)
    - `em`: Distance from Sun to observer (au)
    - `v`: Barycentric observer velocity (vector, c)
    - `bm1`: ``\\sqrt{1-|v|^2}`` Reciprocal of Lorenz factor
    - `bpn`: Bias-precession-nutation matrix
    - `along`: Longitude + s' (radians)
    - `xp1`: Polar motion xp wrt local meridian (radians)
    - `yp1`: Polar motion yp wrt local meridian (radians)
    - `sphi`: Sine of geodetic latitude
    - `cphi`: Cosine of geodetic latitude
    - `diurab`: Magnitude of diurnal aberration vector
    - `eral`: "Local" Earth rotation angle (radians)
    - `refa`: Refraction constant A (radians)
    - `refb`: Refraction constant B (radians)

### Returned ###

- `rc`, `dc`: ICRS astrometric RA,Dec (radians)

### Notes ###

1. Only the Sun is taken into account in the light deflection
   correction.

2. Iterative techniques are used for the aberration and light
   deflection corrections so that the functions eraAtic13 (or
   eraAticq) and eraAtci13 (or eraAtciq) are accurate inverses;
   even at the edge of the Sun's disk the discrepancy is only about
   1 nanoarcsecond.

### Called ###

- `eraS2c`: spherical coordinates to unit vector
- `eraTrxp`: product of transpose of r-matrix and p-vector
- `eraZp`: zero p-vector
- `eraAb`: stellar aberration
- `eraLdsun`: light deflection by the Sun
- `eraC2s`: p-vector to spherical
- `eraAnp`: normalize angle into range +/- pi

"""
function aticq(ri, di, astrom)
    rc = Ref(0.0)
    dc = Ref(0.0)
    ccall((:eraAticq, liberfa), Cvoid,
          (Cdouble, Cdouble, Ref{ASTROM}, Ref{Cdouble}, Ref{Cdouble}),
          ri, di, astrom, rc, dc)
    rc[], dc[]
end

"""
    aticqn(ri, di, astrom, b::Array{LDBODY})

Quick CIRS to ICRS astrometric place transformation, given the star-
independent astrometry parameters plus a list of light-deflecting
bodies.

Use of this function is appropriate when efficiency is important and
where many star positions are all to be transformed for one date.
The star-independent astrometry parameters can be obtained by
calling one of the functions eraApci[13], eraApcg[13], eraApco[13]
or eraApcs[13].

### Given ###

- `ri`, `di`: CIRS RA,Dec (radians)
- `astrom`: Star-independent astrometry parameters:
    - `pmt`: PM time interval (SSB, Julian years)
    - `eb`: SSB to observer (vector, au)
    - `eh`: Sun to observer (unit vector)
    - `em`: Distance from Sun to observer (au)
    - `v`: Barycentric observer velocity (vector, c)
    - `bm1`: ``\\sqrt{1-|v|^2}`` Reciprocal of Lorenz factor
    - `bpn`: Bias-precession-nutation matrix
    - `along`: Longitude + s' (radians)
    - `xp1`: Polar motion xp wrt local meridian (radians)
    - `yp1`: Polar motion yp wrt local meridian (radians)
    - `sphi`: Sine of geodetic latitude
    - `cphi`: Cosine of geodetic latitude
    - `diurab`: Magnitude of diurnal aberration vector
    - `eral`: "Local" Earth rotation angle (radians)
    - `refa`: Refraction constant A (radians)
    - `refb`: Refraction constant B (radians)
- `n`: Number of bodies (Note 3)
- `b::Vector{LDBODY}`: Data for each of the n bodies (Notes 3,4):
    - `bm`: Mass of the body (solar masses, Note 5)
    - `dl`: Deflection limiter (Note 6)
    - `pv`: Barycentric PV of the body (au, au/day)

### Returned ###

- `rc`, `dc`: ICRS astrometric RA,Dec (radians)

### Notes ###

1. Iterative techniques are used for the aberration and light
   deflection corrections so that the functions eraAticqn and
   eraAtciqn are accurate inverses; even at the edge of the Sun's
   disk the discrepancy is only about 1 nanoarcsecond.

2. If the only light-deflecting body to be taken into account is the
   Sun, the eraAticq function can be used instead.

3. The struct b contains n entries, one for each body to be
   considered.  If n = 0, no gravitational light deflection will be
   applied, not even for the Sun.

4. The struct b should include an entry for the Sun as well as for
   any planet or other body to be taken into account.  The entries
   should be in the order in which the light passes the body.

5. In the entry in the b struct for body i, the mass parameter
   b[i].bm can, as required, be adjusted in order to allow for such
   effects as quadrupole field.

6. The deflection limiter parameter b[i].dl is phi^2/2, where phi is
   the angular separation (in radians) between star and body at
   which limiting is applied.  As phi shrinks below the chosen
   threshold, the deflection is artificially reduced, reaching zero
   for phi = 0.   Example values suitable for a terrestrial
   observer, together with masses, are as follows:

      body i     b[i].bm        b[i].dl

      Sun        1.0            6e-6
      Jupiter    0.00095435     3e-9
      Saturn     0.00028574     3e-10

7. For efficiency, validation of the contents of the b array is
   omitted.  The supplied masses must be greater than zero, the
   position and velocity vectors must be right, and the deflection
   limiter greater than zero.

### Called ###

- `eraS2c`: spherical coordinates to unit vector
- `eraTrxp`: product of transpose of r-matrix and p-vector
- `eraZp`: zero p-vector
- `eraAb`: stellar aberration
- `eraLdn`: light deflection by n bodies
- `eraC2s`: p-vector to spherical
- `eraAnp`: normalize angle into range +/- pi

"""
function aticqn(ri, di, astrom, b::Array{LDBODY})
    rc = Ref(0.0)
    dc = Ref(0.0)
    n = length(b)
    ccall((:eraAticqn, liberfa), Cvoid,
          (Cdouble, Cdouble, Ref{ASTROM}, Cint, Ptr{LDBODY}, Ref{Cdouble}, Ref{Cdouble}),
          ri, di, astrom, n, b, rc, dc)
    rc[], dc[]
end

"""
    atio13(ri, di, utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tk, rh, wl)

CIRS RA,Dec to observed place.  The caller supplies UTC, site
coordinates, ambient air conditions and observing wavelength.

### Given ###

- `ri`: CIRS right ascension (CIO-based, radians)
- `di`: CIRS declination (radians)
- `utc1`: UTC as a 2-part...
- `utc2`: ...quasi Julian Date (Notes 1,2)
- `dut1`: UT1-UTC (seconds, Note 3)
- `elong`: Longitude (radians, east +ve, Note 4)
- `phi`: Geodetic latitude (radians, Note 4)
- `hm`: Height above ellipsoid (m, geodetic Notes 4,6)
- `xp`, `yp`: Polar motion coordinates (radians, Note 5)
- `phpa`: Pressure at the observer (hPa = mB, Note 6)
- `tc`: Ambient temperature at the observer (deg C)
- `rh`: Relative humidity at the observer (range 0-1)
- `wl`: Wavelength (micrometers, Note 7)

### Returned ###

- `aob`: Observed azimuth (radians: N=0,E=90)
- `zob`: Observed zenith distance (radians)
- `hob`: Observed hour angle (radians)
- `dob`: Observed declination (radians)
- `rob`: Observed right ascension (CIO-based, radians)

### Notes ###

1.  utc1+utc2 is quasi Julian Date (see Note 2), apportioned in any
    convenient way between the two arguments, for example where utc1
    is the Julian Day Number and utc2 is the fraction of a day.

    However, JD cannot unambiguously represent UTC during a leap
    second unless special measures are taken.  The convention in the
    present function is that the JD day represents UTC days whether
    the length is 86399, 86400 or 86401 SI seconds.

    Applications should use the function eraDtf2d to convert from
    calendar date and time of day into 2-part quasi Julian Date, as
    it implements the leap-second-ambiguity convention just
    described.

2.  The warning status "dubious year" flags UTCs that predate the
    introduction of the time scale or that are too far in the
    future to be trusted.  See eraDat for further details.

3.  UT1-UTC is tabulated in IERS bulletins.  It increases by exactly
    one second at the end of each positive UTC leap second,
    introduced in order to keep UT1-UTC within +/- 0.9s.  n.b. This
    practice is under review, and in the future UT1-UTC may grow
    essentially without limit.

4.  The geographical coordinates are with respect to the ERFA_WGS84
    reference ellipsoid.  TAKE CARE WITH THE LONGITUDE SIGN:  the
    longitude required by the present function is east-positive
    (i.e. right-handed), in accordance with geographical convention.

5.  The polar motion xp,yp can be obtained from IERS bulletins.  The
    values are the coordinates (in radians) of the Celestial
    Intermediate Pole with respect to the International Terrestrial
    Reference System (see IERS Conventions 2003), measured along the
    meridians 0 and 90 deg west respectively.  For many
    applications, xp and yp can be set to zero.

6.  If hm, the height above the ellipsoid of the observing station
    in meters, is not known but phpa, the pressure in hPa (=mB), is
    available, an adequate estimate of hm can be obtained from the
    expression

          hm = -29.3 * tsl * log ( phpa / 1013.25 );

    where tsl is the approximate sea-level air temperature in K
    (See Astrophysical Quantities, C.W.Allen, 3rd edition, section
    52).  Similarly, if the pressure phpa is not known, it can be
    estimated from the height of the observing station, hm, as
    follows:

          phpa = 1013.25 * exp ( -hm / ( 29.3 * tsl ) );

    Note, however, that the refraction is nearly proportional to
    the pressure and that an accurate phpa value is important for
    precise work.

7.  The argument wl specifies the observing wavelength in
    micrometers.  The transition from optical to radio is assumed to
    occur at 100 micrometers (about 3000 GHz).

8.  "Observed" Az,ZD means the position that would be seen by a
    perfect geodetically aligned theodolite.  (Zenith distance is
    used rather than altitude in order to reflect the fact that no
    allowance is made for depression of the horizon.)  This is
    related to the observed HA,Dec via the standard rotation, using
    the geodetic latitude (corrected for polar motion), while the
    observed HA and RA are related simply through the Earth rotation
    angle and the site longitude.  "Observed" RA,Dec or HA,Dec thus
    means the position that would be seen by a perfect equatorial
    with its polar axis aligned to the Earth's axis of rotation.

9.  The accuracy of the result is limited by the corrections for
    refraction, which use a simple A*tan(z) + B*tan^3(z) model.
    Providing the meteorological parameters are known accurately and
    there are no gross local effects, the predicted astrometric
    coordinates should be within 0.05 arcsec (optical) or 1 arcsec
    (radio) for a zenith distance of less than 70 degrees, better
    than 30 arcsec (optical or radio) at 85 degrees and better
    than 20 arcmin (optical) or 30 arcmin (radio) at the horizon.

10. The complementary functions eraAtio13 and eraAtoi13 are self-
    consistent to better than 1 microarcsecond all over the
    celestial sphere.

11. It is advisable to take great care with units, as even unlikely
    values of the input parameters are accepted and processed in
    accordance with the models used.

### Called ###

- `eraApio13`: astrometry parameters, CIRS-observed, 2013
- `eraAtioq`: quick CIRS to observed

"""
function atio13(ri, di, utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tk, rh, wl)
    aob = Ref(0.0)
    zob = Ref(0.0)
    hob = Ref(0.0)
    dob = Ref(0.0)
    rob = Ref(0.0)
    i = ccall((:eraAtio13, liberfa), Cint,
              (Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
              ri, di, utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tk, rh, wl, aob, zob, hob, dob, rob)
    if i == -1
        throw(ERFAException("unacceptable date"))
    elseif i == +1
        @warn "dubious year"
    end
    aob[], zob[], hob[], dob[], rob[]
end

"""
    atioq(ri, di, astrom)

Quick CIRS to observed place transformation.

Use of this function is appropriate when efficiency is important and
where many star positions are all to be transformed for one date.
The star-independent astrometry parameters can be obtained by
calling eraApio[13] or eraApco[13].

### Given ###

- `ri`: CIRS right ascension
- `di`: CIRS declination
- `astrom`: Star-independent astrometry parameters:
    - `pmt`: PM time interval (SSB, Julian years)
    - `eb`: SSB to observer (vector, au)
    - `eh`: Sun to observer (unit vector)
    - `em`: Distance from Sun to observer (au)
    - `v`: Barycentric observer velocity (vector, c)
    - `bm1`: ``\\sqrt{1-|v|^2}`` Reciprocal of Lorenz factor
    - `bpn`: Bias-precession-nutation matrix
    - `along`: Longitude + s' (radians)
    - `xp1`: Polar motion xp wrt local meridian (radians)
    - `yp1`: Polar motion yp wrt local meridian (radians)
    - `sphi`: Sine of geodetic latitude
    - `cphi`: Cosine of geodetic latitude
    - `diurab`: Magnitude of diurnal aberration vector
    - `eral`: "Local" Earth rotation angle (radians)
    - `refa`: Refraction constant A (radians)
    - `refb`: Refraction constant B (radians)

### Returned ###

- `aob`: Observed azimuth (radians: N=0,E=90)
- `zob`: Observed zenith distance (radians)
- `hob`: Observed hour angle (radians)
- `dob`: Observed declination (radians)
- `rob`: Observed right ascension (CIO-based, radians)

### Notes ###

1. This function returns zenith distance rather than altitude in
   order to reflect the fact that no allowance is made for
   depression of the horizon.

2. The accuracy of the result is limited by the corrections for
   refraction, which use a simple A*tan(z) + B*tan^3(z) model.
   Providing the meteorological parameters are known accurately and
   there are no gross local effects, the predicted observed
   coordinates should be within 0.05 arcsec (optical) or 1 arcsec
   (radio) for a zenith distance of less than 70 degrees, better
   than 30 arcsec (optical or radio) at 85 degrees and better
   than 20 arcmin (optical) or 30 arcmin (radio) at the horizon.

   Without refraction, the complementary functions eraAtioq and
   eraAtoiq are self-consistent to better than 1 microarcsecond all
   over the celestial sphere.  With refraction included, consistency
   falls off at high zenith distances, but is still better than
   0.05 arcsec at 85 degrees.

3. It is advisable to take great care with units, as even unlikely
   values of the input parameters are accepted and processed in
   accordance with the models used.

4. The CIRS RA,Dec is obtained from a star catalog mean place by
   allowing for space motion, parallax, the Sun's gravitational lens
   effect, annual aberration and precession-nutation.  For star
   positions in the ICRS, these effects can be applied by means of
   the eraAtci13 (etc.) functions.  Starting from classical "mean
   place" systems, additional transformations will be needed first.

5. "Observed" Az,El means the position that would be seen by a
   perfect geodetically aligned theodolite.  This is obtained from
   the CIRS RA,Dec by allowing for Earth orientation and diurnal
   aberration, rotating from equator to horizon coordinates, and
   then adjusting for refraction.  The HA,Dec is obtained by
   rotating back into equatorial coordinates, and is the position
   that would be seen by a perfect equatorial with its polar axis
   aligned to the Earth's axis of rotation.  Finally, the RA is
   obtained by subtracting the HA from the local ERA.

6. The star-independent CIRS-to-observed-place parameters in ASTROM
   may be computed with eraApio[13] or eraApco[13].  If nothing has
   changed significantly except the time, eraAper[13] may be used to
   perform the requisite adjustment to the astrom structure.

### Called ###

- `eraS2c`: spherical coordinates to unit vector
- `eraC2s`: p-vector to spherical
- `eraAnp`: normalize angle into range 0 to 2pi

"""
function atioq(ri, di, astrom)
    aob = Ref(0.0)
    zob = Ref(0.0)
    hob = Ref(0.0)
    dob = Ref(0.0)
    rob = Ref(0.0)
    ccall((:eraAtioq, liberfa), Cvoid,
          (Cdouble, Cdouble, Ref{ASTROM}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
          ri, di, astrom, aob, zob, hob, dob, rob)
    aob[], zob[], hob[], dob[], rob[]
end

"""
    atoc13(typeofcoordinates, ob1, ob2, utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tk, rh, wl)

Observed place at a groundbased site to to ICRS astrometric RA,Dec.
The caller supplies UTC, site coordinates, ambient air conditions
and observing wavelength.

### Given ###

- `type`: Type of coordinates - "R", "H" or "A" (Notes 1,2)
- `ob1`: Observed Az, HA or RA (radians; Az is N=0,E=90)
- `ob2`: Observed ZD or Dec (radians)
- `utc1`: UTC as a 2-part...
- `utc2`: ...quasi Julian Date (Notes 3,4)
- `dut1`: UT1-UTC (seconds, Note 5)
- `elong`: Longitude (radians, east +ve, Note 6)
- `phi`: Geodetic latitude (radians, Note 6)
- `hm`: Height above ellipsoid (m, geodetic Notes 6,8)
- `xp`, `yp`: Polar motion coordinates (radians, Note 7)
- `phpa`: Pressure at the observer (hPa = mB, Note 8)
- `tc`: Ambient temperature at the observer (deg C)
- `rh`: Relative humidity at the observer (range 0-1)
- `wl`: Wavelength (micrometers, Note 9)

### Returned ###

- `rc`, `dc`: ICRS astrometric RA,Dec (radians)

### Notes ###

1.  "Observed" Az,ZD means the position that would be seen by a
    perfect geodetically aligned theodolite.  (Zenith distance is
    used rather than altitude in order to reflect the fact that no
    allowance is made for depression of the horizon.)  This is
    related to the observed HA,Dec via the standard rotation, using
    the geodetic latitude (corrected for polar motion), while the
    observed HA and RA are related simply through the Earth rotation
    angle and the site longitude.  "Observed" RA,Dec or HA,Dec thus
    means the position that would be seen by a perfect equatorial
    with its polar axis aligned to the Earth's axis of rotation.

2.  Only the first character of the type argument is significant.
    "R" or "r" indicates that ob1 and ob2 are the observed right
    ascension and declination;  "H" or "h" indicates that they are
    hour angle (west +ve) and declination;  anything else ("A" or
    "a" is recommended) indicates that ob1 and ob2 are azimuth
    (north zero, east 90 deg) and zenith distance.

3.  utc1+utc2 is quasi Julian Date (see Note 2), apportioned in any
    convenient way between the two arguments, for example where utc1
    is the Julian Day Number and utc2 is the fraction of a day.

    However, JD cannot unambiguously represent UTC during a leap
    second unless special measures are taken.  The convention in the
    present function is that the JD day represents UTC days whether
    the length is 86399, 86400 or 86401 SI seconds.

    Applications should use the function eraDtf2d to convert from
    calendar date and time of day into 2-part quasi Julian Date, as
    it implements the leap-second-ambiguity convention just
    described.

4.  The warning status "dubious year" flags UTCs that predate the
    introduction of the time scale or that are too far in the
    future to be trusted.  See eraDat for further details.

5.  UT1-UTC is tabulated in IERS bulletins.  It increases by exactly
    one second at the end of each positive UTC leap second,
    introduced in order to keep UT1-UTC within +/- 0.9s.  n.b. This
    practice is under review, and in the future UT1-UTC may grow
    essentially without limit.

6.  The geographical coordinates are with respect to the ERFA_WGS84
    reference ellipsoid.  TAKE CARE WITH THE LONGITUDE SIGN:  the
    longitude required by the present function is east-positive
    (i.e. right-handed), in accordance with geographical convention.

7.  The polar motion xp,yp can be obtained from IERS bulletins.  The
    values are the coordinates (in radians) of the Celestial
    Intermediate Pole with respect to the International Terrestrial
    Reference System (see IERS Conventions 2003), measured along the
    meridians 0 and 90 deg west respectively.  For many
    applications, xp and yp can be set to zero.

8.  If hm, the height above the ellipsoid of the observing station
    in meters, is not known but phpa, the pressure in hPa (=mB), is
    available, an adequate estimate of hm can be obtained from the
    expression

          hm = -29.3 * tsl * log ( phpa / 1013.25 );

    where tsl is the approximate sea-level air temperature in K
    (See Astrophysical Quantities, C.W.Allen, 3rd edition, section
    52).  Similarly, if the pressure phpa is not known, it can be
    estimated from the height of the observing station, hm, as
    follows:

          phpa = 1013.25 * exp ( -hm / ( 29.3 * tsl ) );

    Note, however, that the refraction is nearly proportional to
    the pressure and that an accurate phpa value is important for
    precise work.

9.  The argument wl specifies the observing wavelength in
    micrometers.  The transition from optical to radio is assumed to
    occur at 100 micrometers (about 3000 GHz).

10. The accuracy of the result is limited by the corrections for
    refraction, which use a simple A*tan(z) + B*tan^3(z) model.
    Providing the meteorological parameters are known accurately and
    there are no gross local effects, the predicted astrometric
    coordinates should be within 0.05 arcsec (optical) or 1 arcsec
    (radio) for a zenith distance of less than 70 degrees, better
    than 30 arcsec (optical or radio) at 85 degrees and better
    than 20 arcmin (optical) or 30 arcmin (radio) at the horizon.

    Without refraction, the complementary functions eraAtco13 and
    eraAtoc13 are self-consistent to better than 1 microarcsecond
    all over the celestial sphere.  With refraction included,
    consistency falls off at high zenith distances, but is still
    better than 0.05 arcsec at 85 degrees.

11. It is advisable to take great care with units, as even unlikely
    values of the input parameters are accepted and processed in
    accordance with the models used.

### Called ###

- `eraApco13`: astrometry parameters, ICRS-observed
- `eraAtoiq`: quick observed to CIRS
- `eraAticq`: quick CIRS to ICRS

"""
function atoc13(typeofcoordinates, ob1, ob2, utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tk, rh, wl)
    rc = Ref(0.0)
    dc = Ref(0.0)
    if !(typeofcoordinates in ("R", "r", "H", "h", "A", "a"))
        typeofcoordinates = "A"
    end
    i = ccall((:eraAtoc13, liberfa), Cint,
              (Cstring, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}),
              typeofcoordinates, ob1, ob2, utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tk, rh, wl, rc, dc)
    if i == -1
        throw(ERFAException("unacceptable date"))
    elseif i == +1
        @warn "dubious year"
    end
    rc[], dc[]
end

"""
    atoi13(typeofcoordinates, ob1, ob2, utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tk, rh, wl)

Observed place to CIRS.  The caller supplies UTC, site coordinates,
ambient air conditions and observing wavelength.

### Given ###

- `type`: Type of coordinates - "R", "H" or "A" (Notes 1,2)
- `ob1`: Observed Az, HA or RA (radians; Az is N=0,E=90)
- `ob2`: Observed ZD or Dec (radians)
- `utc1`: UTC as a 2-part...
- `utc2`: ...quasi Julian Date (Notes 3,4)
- `dut1`: UT1-UTC (seconds, Note 5)
- `elong`: Longitude (radians, east +ve, Note 6)
- `phi`: Geodetic latitude (radians, Note 6)
- `hm`: Height above the ellipsoid (meters, Notes 6,8)
- `xp`, `yp`: Polar motion coordinates (radians, Note 7)
- `phpa`: Pressure at the observer (hPa = mB, Note 8)
- `tc`: Ambient temperature at the observer (deg C)
- `rh`: Relative humidity at the observer (range 0-1)
- `wl`: Wavelength (micrometers, Note 9)

### Returned ###

- `ri`: CIRS right ascension (CIO-based, radians)
- `di`: CIRS declination (radians)

### Notes ###

1.  "Observed" Az,ZD means the position that would be seen by a
    perfect geodetically aligned theodolite.  (Zenith distance is
    used rather than altitude in order to reflect the fact that no
    allowance is made for depression of the horizon.)  This is
    related to the observed HA,Dec via the standard rotation, using
    the geodetic latitude (corrected for polar motion), while the
    observed HA and RA are related simply through the Earth rotation
    angle and the site longitude.  "Observed" RA,Dec or HA,Dec thus
    means the position that would be seen by a perfect equatorial
    with its polar axis aligned to the Earth's axis of rotation.

2.  Only the first character of the type argument is significant.
    "R" or "r" indicates that ob1 and ob2 are the observed right
    ascension and declination;  "H" or "h" indicates that they are
    hour angle (west +ve) and declination;  anything else ("A" or
    "a" is recommended) indicates that ob1 and ob2 are azimuth
    (north zero, east 90 deg) and zenith distance.

3.  utc1+utc2 is quasi Julian Date (see Note 2), apportioned in any
    convenient way between the two arguments, for example where utc1
    is the Julian Day Number and utc2 is the fraction of a day.

    However, JD cannot unambiguously represent UTC during a leap
    second unless special measures are taken.  The convention in the
    present function is that the JD day represents UTC days whether
    the length is 86399, 86400 or 86401 SI seconds.

    Applications should use the function eraDtf2d to convert from
    calendar date and time of day into 2-part quasi Julian Date, as
    it implements the leap-second-ambiguity convention just
    described.

4.  The warning status "dubious year" flags UTCs that predate the
    introduction of the time scale or that are too far in the
    future to be trusted.  See eraDat for further details.

5.  UT1-UTC is tabulated in IERS bulletins.  It increases by exactly
    one second at the end of each positive UTC leap second,
    introduced in order to keep UT1-UTC within +/- 0.9s.  n.b. This
    practice is under review, and in the future UT1-UTC may grow
    essentially without limit.

6.  The geographical coordinates are with respect to the ERFA_WGS84
    reference ellipsoid.  TAKE CARE WITH THE LONGITUDE SIGN:  the
    longitude required by the present function is east-positive
    (i.e. right-handed), in accordance with geographical convention.

7.  The polar motion xp,yp can be obtained from IERS bulletins.  The
    values are the coordinates (in radians) of the Celestial
    Intermediate Pole with respect to the International Terrestrial
    Reference System (see IERS Conventions 2003), measured along the
    meridians 0 and 90 deg west respectively.  For many
    applications, xp and yp can be set to zero.

8.  If hm, the height above the ellipsoid of the observing station
    in meters, is not known but phpa, the pressure in hPa (=mB), is
    available, an adequate estimate of hm can be obtained from the
    expression

          hm = -29.3 * tsl * log ( phpa / 1013.25 );

    where tsl is the approximate sea-level air temperature in K
    (See Astrophysical Quantities, C.W.Allen, 3rd edition, section
    52).  Similarly, if the pressure phpa is not known, it can be
    estimated from the height of the observing station, hm, as
    follows:

          phpa = 1013.25 * exp ( -hm / ( 29.3 * tsl ) );

    Note, however, that the refraction is nearly proportional to
    the pressure and that an accurate phpa value is important for
    precise work.

9.  The argument wl specifies the observing wavelength in
    micrometers.  The transition from optical to radio is assumed to
    occur at 100 micrometers (about 3000 GHz).

10. The accuracy of the result is limited by the corrections for
    refraction, which use a simple A*tan(z) + B*tan^3(z) model.
    Providing the meteorological parameters are known accurately and
    there are no gross local effects, the predicted astrometric
    coordinates should be within 0.05 arcsec (optical) or 1 arcsec
    (radio) for a zenith distance of less than 70 degrees, better
    than 30 arcsec (optical or radio) at 85 degrees and better
    than 20 arcmin (optical) or 30 arcmin (radio) at the horizon.

    Without refraction, the complementary functions eraAtio13 and
    eraAtoi13 are self-consistent to better than 1 microarcsecond
    all over the celestial sphere.  With refraction included,
    consistency falls off at high zenith distances, but is still
    better than 0.05 arcsec at 85 degrees.

12. It is advisable to take great care with units, as even unlikely
    values of the input parameters are accepted and processed in
    accordance with the models used.

### Called ###

- `eraApio13`: astrometry parameters, CIRS-observed, 2013
- `eraAtoiq`: quick observed to CIRS

"""
function atoi13(typeofcoordinates, ob1, ob2, utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tk, rh, wl)
    ri = Ref(0.0)
    di = Ref(0.0)
    i = ccall((:eraAtoi13, liberfa), Cint,
              (Cstring, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}),
              typeofcoordinates, ob1, ob2, utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tk, rh, wl, ri, di)
    if i == -1
        throw(ERFAException("unacceptable date"))
    elseif i == +1
        @warn "dubious year"
    end
    ri[], di[]
end

"""
    atoiq(typeofcoordinates, ob1, ob2, astrom)

Quick observed place to CIRS, given the star-independent astrometry
parameters.

Use of this function is appropriate when efficiency is important and
where many star positions are all to be transformed for one date.
The star-independent astrometry parameters can be obtained by
calling eraApio[13] or eraApco[13].

### Given ###

- `type`: Type of coordinates: "R", "H" or "A" (Note 1)
- `ob1`: Observed Az, HA or RA (radians; Az is N=0,E=90)
- `ob2`: Observed ZD or Dec (radians)
- `astrom`: Star-independent astrometry parameters:
    - `pmt`: PM time interval (SSB, Julian years)
    - `eb`: SSB to observer (vector, au)
    - `eh`: Sun to observer (unit vector)
    - `em`: Distance from Sun to observer (au)
    - `v`: Barycentric observer velocity (vector, c)
    - `bm1`: ``\\sqrt{1-|v|^2}`` Reciprocal of Lorenz factor
    - `bpn`: Bias-precession-nutation matrix
    - `along`: Longitude + s' (radians)
    - `xp1`: Polar motion xp wrt local meridian (radians)
    - `yp1`: Polar motion yp wrt local meridian (radians)
    - `sphi`: Sine of geodetic latitude
    - `cphi`: Cosine of geodetic latitude
    - `diurab`: Magnitude of diurnal aberration vector
    - `eral`: "Local" Earth rotation angle (radians)
    - `refa`: Refraction constant A (radians)
    - `refb`: Refraction constant B (radians)

### Returned ###

- `ri`: CIRS right ascension (CIO-based, radians)
- `di`: CIRS declination (radians)

### Notes ###

1. "Observed" Az,El means the position that would be seen by a
   perfect geodetically aligned theodolite.  This is related to
   the observed HA,Dec via the standard rotation, using the geodetic
   latitude (corrected for polar motion), while the observed HA and
   RA are related simply through the Earth rotation angle and the
   site longitude.  "Observed" RA,Dec or HA,Dec thus means the
   position that would be seen by a perfect equatorial with its
   polar axis aligned to the Earth's axis of rotation.  By removing
   from the observed place the effects of atmospheric refraction and
   diurnal aberration, the CIRS RA,Dec is obtained.

2. Only the first character of the type argument is significant.
   "R" or "r" indicates that ob1 and ob2 are the observed right
   ascension and declination;  "H" or "h" indicates that they are
   hour angle (west +ve) and declination;  anything else ("A" or
   "a" is recommended) indicates that ob1 and ob2 are azimuth (north
   zero, east 90 deg) and zenith distance.  (Zenith distance is used
   rather than altitude in order to reflect the fact that no
   allowance is made for depression of the horizon.)

3. The accuracy of the result is limited by the corrections for
   refraction, which use a simple A*tan(z) + B*tan^3(z) model.
   Providing the meteorological parameters are known accurately and
   there are no gross local effects, the predicted observed
   coordinates should be within 0.05 arcsec (optical) or 1 arcsec
   (radio) for a zenith distance of less than 70 degrees, better
   than 30 arcsec (optical or radio) at 85 degrees and better than
   20 arcmin (optical) or 30 arcmin (radio) at the horizon.

   Without refraction, the complementary functions eraAtioq and
   eraAtoiq are self-consistent to better than 1 microarcsecond all
   over the celestial sphere.  With refraction included, consistency
   falls off at high zenith distances, but is still better than
   0.05 arcsec at 85 degrees.

4. It is advisable to take great care with units, as even unlikely
   values of the input parameters are accepted and processed in
   accordance with the models used.

### Called ###

- `eraS2c`: spherical coordinates to unit vector
- `eraC2s`: p-vector to spherical
- `eraAnp`: normalize angle into range 0 to 2pi

"""
function atoiq(typeofcoordinates, ob1, ob2, astrom)
    ri = Ref(0.0)
    di = Ref(0.0)
    ccall((:eraAtoiq, liberfa),
          Cvoid, (Cstring, Cdouble, Cdouble, Ref{ASTROM}, Ref{Cdouble}, Ref{Cdouble}),
          typeofcoordinates, ob1, ob2, astrom, ri, di)
    ri[], di[]
end

"""
    anp(a)

Normalize angle into the range 0 <= a < 2pi.

### Given ###

- `a`: Angle (radians)

### Returned ###

- Angle in range 0-2pi

"""
anp

"""
    anpm(a)

Normalize angle into the range -pi <= a < +pi.

### Given ###

- `a`: Angle (radians)

### Returned ###

- Angle in range +/-pi

"""
anpm

for name in ("anp",
             "anpm")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(a)
            ccall(($fc, liberfa), Cdouble, (Cdouble,), a)
        end
    end
end

"""
    a2af(ndp, a)

Decompose radians into degrees, arcminutes, arcseconds, fraction.

### Given ###

- `ndp`: Resolution (Note 1)
- `angle`: Angle in radians

### Returned ###

- `sign`: '+' or '-'
- `idmsf`: Degrees, arcminutes, arcseconds, fraction

### Called ###

- `eraD2tf`: decompose days to hms

### Notes ###

1. The argument ndp is interpreted as follows:

   ndp         resolution
    :      ...0000 00 00
   -7         1000 00 00
   -6          100 00 00
   -5           10 00 00
   -4            1 00 00
   -3            0 10 00
   -2            0 01 00
   -1            0 00 10
    0            0 00 01
    1            0 00 00.1
    2            0 00 00.01
    3            0 00 00.001
    :            0 00 00.000...

2. The largest positive useful value for ndp is determined by the
   size of angle, the format of doubles on the target platform, and
   the risk of overflowing idmsf[3].  On a typical platform, for
   angle up to 2pi, the available floating-point precision might
   correspond to ndp=12.  However, the practical limit is typically
   ndp=9, set by the capacity of a 32-bit int, or ndp=4 if int is
   only 16 bits.

3. The absolute value of angle may exceed 2pi.  In cases where it
   does not, it is up to the caller to test for and handle the
   case where angle is very nearly 2pi and rounds up to 360 degrees,
   by testing for idmsf[0]=360 and setting idmsf[0-3] to zero.

"""
a2af

"""
    a2tf(ndp, a)

Decompose radians into hours, minutes, seconds, fraction.

### Given ###

- `ndp`: Resolution (Note 1)
- `angle`: Angle in radians

### Returned ###

- `sign`: '+' or '-'
- `ihmsf`: Hours, minutes, seconds, fraction

### Called ###

- `eraD2tf`: decompose days to hms

### Notes ###

1. The argument ndp is interpreted as follows:

   ndp         resolution
    :      ...0000 00 00
   -7         1000 00 00
   -6          100 00 00
   -5           10 00 00
   -4            1 00 00
   -3            0 10 00
   -2            0 01 00
   -1            0 00 10
    0            0 00 01
    1            0 00 00.1
    2            0 00 00.01
    3            0 00 00.001
    :            0 00 00.000...

2. The largest positive useful value for ndp is determined by the
   size of angle, the format of doubles on the target platform, and
   the risk of overflowing ihmsf[3].  On a typical platform, for
   angle up to 2pi, the available floating-point precision might
   correspond to ndp=12.  However, the practical limit is typically
   ndp=9, set by the capacity of a 32-bit int, or ndp=4 if int is
   only 16 bits.

3. The absolute value of angle may exceed 2pi.  In cases where it
   does not, it is up to the caller to test for and handle the
   case where angle is very nearly 2pi and rounds up to 24 hours,
   by testing for ihmsf[0]=24 and setting ihmsf[0-3] to zero.

"""
a2tf

for name in ("a2af",
             "a2tf")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(ndp, a)
            s = Ref{Cchar}('+')
            i = zeros(Cint, 4)
            ccall(($fc, liberfa), Cvoid,
                  (Cint, Cdouble, Ptr{Cchar}, Ptr{Cint}),
                  ndp, a, s, i)
            Char(s[]), i[1], i[2], i[3], i[4]
        end
    end
end

"""
    af2a(s, ideg, iamin, asec)

Convert degrees, arcminutes, arcseconds to radians.

### Given ###

- `s`: Sign:  '-' = negative, otherwise positive
- `ideg`: Degrees
- `iamin`: Arcminutes
- `asec`: Arcseconds

### Returned ###

- `rad`: Angle in radians

### Notes ###

1.  The result is computed even if any of the range checks fail.

2.  Negative ideg, iamin and/or asec produce a warning status, but
    the absolute value is used in the conversion.

3.  If there are multiple errors, the status value reflects only the
    first, the smallest taking precedence.

"""
function af2a(s, ideg, iamin, asec)
    rad = Ref(0.0)
    i = ccall((:eraAf2a, liberfa), Cint,
                (Cchar, Cint, Cint, Cdouble, Ref{Cdouble}),
                s, ideg, iamin, asec, rad)
    if i == 1
        throw(ERFAException("ideg outside range 0-359"))
    elseif i == 2
        throw(ERFAException("iamin outside range 0-59"))
    elseif i == 3
        throw(ERFAException("asec outside range 0-59.999..."))
    end
    rad[]
end
