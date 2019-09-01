"""
    c2ibpn(date1, date2, rbpn)

Form the celestial-to-intermediate matrix for a given date given
the bias-precession-nutation matrix.  IAU 2000.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)
- `rbpn`: Celestial-to-true matrix (Note 2)

### Returned ###

- `rc2i`: Celestial-to-intermediate matrix (Note 3)

### Notes ###

1. The TT date date1+date2 is a Julian Date, apportioned in any
   convenient way between the two arguments.  For example,
   JD(TT)=2450123.7 could be expressed in any of these ways,
   among others:

   | `date1`   |     `date2` |                    |
   |:----------|:------------|:-------------------|
   | 2450123.7 |         0.0 | JD method          |
   | 2451545.0 |     -1421.3 | J2000 method       |
   | 2400000.5 |     50123.2 | MJD method         |
   | 2450123.5 |         0.2 | date & time method |

   The JD method is the most natural and convenient to use in
   cases where the loss of several decimal digits of resolution
   is acceptable.  The J2000 method is best matched to the way
   the argument is handled internally and will deliver the
   optimum resolution.  The MJD method and the date & time methods
   are both good compromises between resolution and convenience.

2. The matrix rbpn transforms vectors from GCRS to true equator (and
   CIO or equinox) of date.  Only the CIP (bottom row) is used.

3. The matrix rc2i is the first stage in the transformation from
   celestial to terrestrial coordinates:

      [TRS] = RPOM * R_3(ERA) * rc2i * [CRS]

            = RC2T * [CRS]

   where [CRS] is a vector in the Geocentric Celestial Reference
   System and [TRS] is a vector in the International Terrestrial
   Reference System (see IERS Conventions 2003), ERA is the Earth
   Rotation Angle and RPOM is the polar motion matrix.

4. Although its name does not include "00", This function is in fact
   specific to the IAU 2000 models.

### Called ###

- `eraBpn2xy`: extract CIP X,Y coordinates from NPB matrix
- `eraC2ixy`: celestial-to-intermediate matrix, given X,Y

### References ###

- "Expressions for the Celestial Intermediate Pole and Celestial
    Ephemeris Origin consistent with the IAU 2000A precession-
    nutation model", Astron.Astrophys. 400, 1145-1154 (2003)

- n.b. The celestial ephemeris origin (CEO) was renamed "celestial
    intermediate origin" (CIO) by IAU 2006 Resolution 2.

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)
"""
function c2ibpn(date1, date2, rbpn)
    rc2i = zeros((3, 3))
    ccall((:eraC2ibpn, liberfa), Cvoid,
          (Cdouble, Cdouble, Ptr{Cdouble}, Ptr{Cdouble}),
          date1, date2, rbpn, rc2i)
    rc2i
end

"""
    c2s(p)

P-vector to spherical coordinates.

### Given ###

- `p`: P-vector

### Returned ###

- `theta`: Longitude angle (radians)
- `phi`: Latitude angle (radians)

### Notes ###

1. The vector p can have any magnitude; only its direction is used.

2. If p is null, zero theta and phi are returned.

3. At either pole, zero theta is returned.
"""
function c2s(p)
    theta = Ref(0.0)
    phi = Ref(0.0)
    ccall((:eraC2s, liberfa), Cvoid,
          (Ptr{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
          p, theta, phi)
    theta[], phi[]
end

"""
    cal2jd(iy, imo, id)

Gregorian Calendar to Julian Date.

### Given ###

- `iy`, `im`, `id`: Year, month, day in Gregorian calendar (Note 1)

### Returned ###

- `djm0`: MJD zero-point: always 2400000.5
- `djm`: Modified Julian Date for 0 hrs

### Notes ###

1. The algorithm used is valid from -4800 March 1, but this
   implementation rejects dates before -4799 January 1.

2. The Julian Date is returned in two pieces, in the usual ERFA
   manner, which is designed to preserve time resolution.  The
   Julian Date is available as a single number by adding djm0 and
   djm.

3. In early eras the conversion is from the "Proleptic Gregorian
   Calendar";  no account is taken of the date(s) of adoption of
   the Gregorian Calendar, nor is the AD/BC numbering convention
   observed.

### Reference ###

- Explanatory Supplement to the Astronomical Almanac,
    P. Kenneth Seidelmann (ed), University Science Books (1992),
    Section 12.92 (p604).
"""
function cal2jd(iy, imo, id)
    r1 = Ref(0.0)
    r2 = Ref(0.0)
    i = ccall((:eraCal2jd, liberfa), Cint,
              (Cint, Cint, Cint, Ref{Cdouble}, Ref{Cdouble}),
              iy, imo, id, r1, r2)
    if i == -1
        throw(ERFAException("bad year"))
    elseif i == -2
        throw(ERFAException("bad month"))
    elseif i == -3
        throw(ERFAException("bad day"))
    end
    r1[], r2[]
end

"""
    c2tcio(rc2i, era, rpom)

Assemble the celestial to terrestrial matrix from CIO-based
components (the celestial-to-intermediate matrix, the Earth Rotation
Angle and the polar motion matrix).

### Given ###

- `rc2i`: Celestial-to-intermediate matrix
- `era`: Earth rotation angle (radians)
- `rpom`: Polar-motion matrix

### Returned ###

- `rc2t`: Celestial-to-terrestrial matrix

### Notes ###

1. This function constructs the rotation matrix that transforms
   vectors in the celestial system into vectors in the terrestrial
   system.  It does so starting from precomputed components, namely
   the matrix which rotates from celestial coordinates to the
   intermediate frame, the Earth rotation angle and the polar motion
   matrix.  One use of the present function is when generating a
   series of celestial-to-terrestrial matrices where only the Earth
   Rotation Angle changes, avoiding the considerable overhead of
   recomputing the precession-nutation more often than necessary to
   achieve given accuracy objectives.

2. The relationship between the arguments is as follows:

      [TRS] = RPOM * R_3(ERA) * rc2i * [CRS]

            = rc2t * [CRS]

   where [CRS] is a vector in the Geocentric Celestial Reference
   System and [TRS] is a vector in the International Terrestrial
   Reference System (see IERS Conventions 2003).

### Called ###

- `eraCr`: copy r-matrix
- `eraRz`: rotate around Z-axis
- `eraRxr`: product of two r-matrices

### Reference ###

- McCarthy, D. D., Petit, G. (eds.), 2004, IERS Conventions (2003),
    IERS Technical Note No. 32, BKG
"""
c2tcio

"""
    c2teqx(rc2i, era, rpom)

Assemble the celestial to terrestrial matrix from equinox-based
components (the celestial-to-true matrix, the Greenwich Apparent
Sidereal Time and the polar motion matrix).

### Given ###

- `rbpn`: Celestial-to-true matrix
- `gst`: Greenwich (apparent) Sidereal Time (radians)
- `rpom`: Polar-motion matrix

### Returned ###

- `rc2t`: Celestial-to-terrestrial matrix (Note 2)

### Notes ###

1. This function constructs the rotation matrix that transforms
   vectors in the celestial system into vectors in the terrestrial
   system.  It does so starting from precomputed components, namely
   the matrix which rotates from celestial coordinates to the
   true equator and equinox of date, the Greenwich Apparent Sidereal
   Time and the polar motion matrix.  One use of the present function
   is when generating a series of celestial-to-terrestrial matrices
   where only the Sidereal Time changes, avoiding the considerable
   overhead of recomputing the precession-nutation more often than
   necessary to achieve given accuracy objectives.

2. The relationship between the arguments is as follows:

      [TRS] = rpom * R_3(gst) * rbpn * [CRS]

            = rc2t * [CRS]

   where [CRS] is a vector in the Geocentric Celestial Reference
   System and [TRS] is a vector in the International Terrestrial
   Reference System (see IERS Conventions 2003).

### Called ###

- `eraCr`: copy r-matrix
- `eraRz`: rotate around Z-axis
- `eraRxr`: product of two r-matrices

### Reference ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)
"""
c2teqx

for name in ("c2tcio",
             "c2teqx")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(rc2i, era, rpom)
            rc2t = zeros((3, 3))
            ccall(($fc, liberfa), Cvoid,
                  (Ptr{Cdouble}, Cdouble, Ptr{Cdouble}, Ptr{Cdouble}),
                  rc2i, era, rpom, rc2t)
            rc2t
        end
    end
end

"""
    c2t00a(tta, ttb, uta, utb, xp, yp)

Form the celestial to terrestrial matrix given the date, the UT1 and
the polar motion, using the IAU 2000A nutation model.

### Given ###

- `tta`, `ttb`: TT as a 2-part Julian Date (Note 1)
- `uta`, `utb`: UT1 as a 2-part Julian Date (Note 1)
- `xp`, `yp`: Coordinates of the pole (radians, Note 2)

### Returned ###

- `rc2t`: Celestial-to-terrestrial matrix (Note 3)

### Notes ###

1. The TT and UT1 dates tta+ttb and uta+utb are Julian Dates,
   apportioned in any convenient way between the arguments uta and
   utb.  For example, JD(UT1)=2450123.7 could be expressed in any of
   these ways, among others:

           uta            utb

       2450123.7           0.0       (JD method)
       2451545.0       -1421.3       (J2000 method)
       2400000.5       50123.2       (MJD method)
       2450123.5           0.2       (date & time method)

   The JD method is the most natural and convenient to use in
   cases where the loss of several decimal digits of resolution is
   acceptable.  The J2000 and MJD methods are good compromises
   between resolution and convenience.  In the case of uta,utb, the
   date & time method is best matched to the Earth rotation angle
   algorithm used:  maximum precision is delivered when the uta
   argument is for 0hrs UT1 on the day in question and the utb
   argument lies in the range 0 to 1, or vice versa.

2. The arguments xp and yp are the coordinates (in radians) of the
   Celestial Intermediate Pole with respect to the International
   Terrestrial Reference System (see IERS Conventions 2003),
   measured along the meridians to 0 and 90 deg west respectively.

3. The matrix rc2t transforms from celestial to terrestrial
   coordinates:

      [TRS] = RPOM * R_3(ERA) * RC2I * [CRS]

            = rc2t * [CRS]

   where [CRS] is a vector in the Geocentric Celestial Reference
   System and [TRS] is a vector in the International Terrestrial
   Reference System (see IERS Conventions 2003), RC2I is the
   celestial-to-intermediate matrix, ERA is the Earth rotation
   angle and RPOM is the polar motion matrix.

4. A faster, but slightly less accurate result (about 1 mas), can
   be obtained by using instead the eraC2t00b function.

### Called ###

- `eraC2i00a`: celestial-to-intermediate matrix, IAU 2000A
- `eraEra00`: Earth rotation angle, IAU 2000
- `eraSp00`: the TIO locator s', IERS 2000
- `eraPom00`: polar motion matrix
- `eraC2tcio`: form CIO-based celestial-to-terrestrial matrix

### Reference ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)
"""
c2t00a

"""
    c2t00b(tta, ttb, uta, utb, xp, yp)

Form the celestial to terrestrial matrix given the date, the UT1 and
the polar motion, using the IAU 2000B nutation model.

### Given ###

- `tta`, `ttb`: TT as a 2-part Julian Date (Note 1)
- `uta`, `utb`: UT1 as a 2-part Julian Date (Note 1)
- `xp`, `yp`: Coordinates of the pole (radians, Note 2)

### Returned ###

- `rc2t`: Celestial-to-terrestrial matrix (Note 3)

### Notes ###

1. The TT and UT1 dates tta+ttb and uta+utb are Julian Dates,
   apportioned in any convenient way between the arguments uta and
   utb.  For example, JD(UT1)=2450123.7 could be expressed in any of
   these ways, among others:

           uta            utb

       2450123.7           0.0       (JD method)
       2451545.0       -1421.3       (J2000 method)
       2400000.5       50123.2       (MJD method)
       2450123.5           0.2       (date & time method)

   The JD method is the most natural and convenient to use in
   cases where the loss of several decimal digits of resolution is
   acceptable.  The J2000 and MJD methods are good compromises
   between resolution and convenience.  In the case of uta,utb, the
   date & time method is best matched to the Earth rotation angle
   algorithm used:  maximum precision is delivered when the uta
   argument is for 0hrs UT1 on the day in question and the utb
   argument lies in the range 0 to 1, or vice versa.

2. The arguments xp and yp are the coordinates (in radians) of the
   Celestial Intermediate Pole with respect to the International
   Terrestrial Reference System (see IERS Conventions 2003),
   measured along the meridians to 0 and 90 deg west respectively.

3. The matrix rc2t transforms from celestial to terrestrial
   coordinates:

      [TRS] = RPOM * R_3(ERA) * RC2I * [CRS]

            = rc2t * [CRS]

   where [CRS] is a vector in the Geocentric Celestial Reference
   System and [TRS] is a vector in the International Terrestrial
   Reference System (see IERS Conventions 2003), RC2I is the
   celestial-to-intermediate matrix, ERA is the Earth rotation
   angle and RPOM is the polar motion matrix.

4. The present function is faster, but slightly less accurate (about
   1 mas), than the eraC2t00a function.

### Called ###

- `eraC2i00b`: celestial-to-intermediate matrix, IAU 2000B
- `eraEra00`: Earth rotation angle, IAU 2000
- `eraPom00`: polar motion matrix
- `eraC2tcio`: form CIO-based celestial-to-terrestrial matrix

### Reference ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)
"""
c2t00b

"""
    c2t06a(tta, ttb, uta, utb, xp, yp)

Form the celestial to terrestrial matrix given the date, the UT1 and
the polar motion, using the IAU 2006 precession and IAU 2000A
nutation models.

### Given ###

- `tta`, `ttb`: TT as a 2-part Julian Date (Note 1)
- `uta`, `utb`: UT1 as a 2-part Julian Date (Note 1)
- `xp`, `yp`: Coordinates of the pole (radians, Note 2)

### Returned ###

- `rc2t`: Celestial-to-terrestrial matrix (Note 3)

### Notes ###

1. The TT and UT1 dates tta+ttb and uta+utb are Julian Dates,
   apportioned in any convenient way between the arguments uta and
   utb.  For example, JD(UT1)=2450123.7 could be expressed in any of
   these ways, among others:

           uta            utb

       2450123.7           0.0       (JD method)
       2451545.0       -1421.3       (J2000 method)
       2400000.5       50123.2       (MJD method)
       2450123.5           0.2       (date & time method)

   The JD method is the most natural and convenient to use in
   cases where the loss of several decimal digits of resolution is
   acceptable.  The J2000 and MJD methods are good compromises
   between resolution and convenience.  In the case of uta,utb, the
   date & time method is best matched to the Earth rotation angle
   algorithm used:  maximum precision is delivered when the uta
   argument is for 0hrs UT1 on the day in question and the utb
   argument lies in the range 0 to 1, or vice versa.

2. The arguments xp and yp are the coordinates (in radians) of the
   Celestial Intermediate Pole with respect to the International
   Terrestrial Reference System (see IERS Conventions 2003),
   measured along the meridians to 0 and 90 deg west respectively.

3. The matrix rc2t transforms from celestial to terrestrial
   coordinates:

      [TRS] = RPOM * R_3(ERA) * RC2I * [CRS]

            = rc2t * [CRS]

   where [CRS] is a vector in the Geocentric Celestial Reference
   System and [TRS] is a vector in the International Terrestrial
   Reference System (see IERS Conventions 2003), RC2I is the
   celestial-to-intermediate matrix, ERA is the Earth rotation
   angle and RPOM is the polar motion matrix.

### Called ###

- `eraC2i06a`: celestial-to-intermediate matrix, IAU 2006/2000A
- `eraEra00`: Earth rotation angle, IAU 2000
- `eraSp00`: the TIO locator s', IERS 2000
- `eraPom00`: polar motion matrix
- `eraC2tcio`: form CIO-based celestial-to-terrestrial matrix

### Reference ###

- McCarthy, D. D., Petit, G. (eds.), 2004, IERS Conventions (2003),
    IERS Technical Note No. 32, BKG
"""
c2t06a

for name in ("c2t00a",
             "c2t00b",
             "c2t06a")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(tta, ttb, uta, utb, xp, yp)
            rc2t = zeros((3, 3))
            ccall(($fc, liberfa), Cvoid,
                  (Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ptr{Cdouble}),
                  tta, ttb, uta, utb, xp, yp, rc2t)
            rc2t
        end
    end
end

"""
    c2tpe(tta, ttb, uta, utb, x, y, xp, yp)

Form the celestial to terrestrial matrix given the date, the UT1,
the nutation and the polar motion.  IAU 2000.

### Given ###

- `tta`, `ttb`: TT as a 2-part Julian Date (Note 1)
- `uta`, `utb`: UT1 as a 2-part Julian Date (Note 1)
- `dpsi`, `deps`: Nutation (Note 2)
- `xp`, `yp`: Coordinates of the pole (radians, Note 3)

### Returned ###

- `rc2t`: Celestial-to-terrestrial matrix (Note 4)

### Notes ###

1. The TT and UT1 dates tta+ttb and uta+utb are Julian Dates,
   apportioned in any convenient way between the arguments uta and
   utb.  For example, JD(UT1)=2450123.7 could be expressed in any of
   these ways, among others:

           uta            utb

       2450123.7           0.0       (JD method)
       2451545.0       -1421.3       (J2000 method)
       2400000.5       50123.2       (MJD method)
       2450123.5           0.2       (date & time method)

   The JD method is the most natural and convenient to use in
   cases where the loss of several decimal digits of resolution is
   acceptable.  The J2000 and MJD methods are good compromises
   between resolution and convenience.  In the case of uta,utb, the
   date & time method is best matched to the Earth rotation angle
   algorithm used:  maximum precision is delivered when the uta
   argument is for 0hrs UT1 on the day in question and the utb
   argument lies in the range 0 to 1, or vice versa.

2. The caller is responsible for providing the nutation components;
   they are in longitude and obliquity, in radians and are with
   respect to the equinox and ecliptic of date.  For high-accuracy
   applications, free core nutation should be included as well as
   any other relevant corrections to the position of the CIP.

3. The arguments xp and yp are the coordinates (in radians) of the
   Celestial Intermediate Pole with respect to the International
   Terrestrial Reference System (see IERS Conventions 2003),
   measured along the meridians to 0 and 90 deg west respectively.

4. The matrix rc2t transforms from celestial to terrestrial
   coordinates:

      [TRS] = RPOM * R_3(GST) * RBPN * [CRS]

            = rc2t * [CRS]

   where [CRS] is a vector in the Geocentric Celestial Reference
   System and [TRS] is a vector in the International Terrestrial
   Reference System (see IERS Conventions 2003), RBPN is the
   bias-precession-nutation matrix, GST is the Greenwich (apparent)
   Sidereal Time and RPOM is the polar motion matrix.

5. Although its name does not include "00", This function is in fact
   specific to the IAU 2000 models.

### Called ###

- `eraPn00`: bias/precession/nutation results, IAU 2000
- `eraGmst00`: Greenwich mean sidereal time, IAU 2000
- `eraSp00`: the TIO locator s', IERS 2000
- `eraEe00`: equation of the equinoxes, IAU 2000
- `eraPom00`: polar motion matrix
- `eraC2teqx`: form equinox-based celestial-to-terrestrial matrix

### Reference ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)
"""
c2tpe

"""
    c2txy(tta, ttb, uta, utb, x, y, xp, yp)

Form the celestial to terrestrial matrix given the date, the UT1,
the CIP coordinates and the polar motion.  IAU 2000.

### Given ###

- `tta`, `ttb`: TT as a 2-part Julian Date (Note 1)
- `uta`, `utb`: UT1 as a 2-part Julian Date (Note 1)
- `x`, `y`: Celestial Intermediate Pole (Note 2)
- `xp`, `yp`: Coordinates of the pole (radians, Note 3)

### Returned ###

- `rc2t`: Celestial-to-terrestrial matrix (Note 4)

### Notes ###

1. The TT and UT1 dates tta+ttb and uta+utb are Julian Dates,
   apportioned in any convenient way between the arguments uta and
   utb.  For example, JD(UT1)=2450123.7 could be expressed in any o
   these ways, among others:

           uta            utb

       2450123.7           0.0       (JD method)
       2451545.0       -1421.3       (J2000 method)
       2400000.5       50123.2       (MJD method)
       2450123.5           0.2       (date & time method)

   The JD method is the most natural and convenient to use in
   cases where the loss of several decimal digits of resolution is
   acceptable.  The J2000 and MJD methods are good compromises
   between resolution and convenience.  In the case of uta,utb, the
   date & time method is best matched to the Earth rotation angle
   algorithm used:  maximum precision is delivered when the uta
   argument is for 0hrs UT1 on the day in question and the utb
   argument lies in the range 0 to 1, or vice versa.

2. The Celestial Intermediate Pole coordinates are the x,y
   components of the unit vector in the Geocentric Celestial
   Reference System.

3. The arguments xp and yp are the coordinates (in radians) of the
   Celestial Intermediate Pole with respect to the International
   Terrestrial Reference System (see IERS Conventions 2003),
   measured along the meridians to 0 and 90 deg west respectively.

4. The matrix rc2t transforms from celestial to terrestrial
   coordinates:

      [TRS] = RPOM * R_3(ERA) * RC2I * [CRS]

            = rc2t * [CRS]

   where [CRS] is a vector in the Geocentric Celestial Reference
   System and [TRS] is a vector in the International Terrestrial
   Reference System (see IERS Conventions 2003), ERA is the Earth
   Rotation Angle and RPOM is the polar motion matrix.

5. Although its name does not include "00", This function is in fact
   specific to the IAU 2000 models.

### Called ###

- `eraC2ixy`: celestial-to-intermediate matrix, given X,Y
- `eraEra00`: Earth rotation angle, IAU 2000
- `eraSp00`: the TIO locator s', IERS 2000
- `eraPom00`: polar motion matrix
- `eraC2tcio`: form CIO-based celestial-to-terrestrial matrix

### Reference ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)
"""
c2txy

for name in ("c2tpe",
             "c2txy")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(tta, ttb, uta, utb, x, y, xp, yp)
            rc2t = zeros((3, 3))
            ccall(($fc, liberfa), Cvoid,
                  (Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ptr{Cdouble}),
                  tta, ttb, uta, utb, x, y, xp, yp, rc2t)
            rc2t
        end
    end
end

"""
    c2i00a(a, b)

Form the celestial-to-intermediate matrix for a given date using the
IAU 2000A precession-nutation model.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `rc2i`: Celestial-to-intermediate matrix (Note 2)

### Notes ###

1. The TT date date1+date2 is a Julian Date, apportioned in any
   convenient way between the two arguments.  For example,
   JD(TT)=2450123.7 could be expressed in any of these ways,
   among others:

   | `date1`   |     `date2` |                    |
   |:----------|:------------|:-------------------|
   | 2450123.7 |         0.0 | JD method          |
   | 2451545.0 |     -1421.3 | J2000 method       |
   | 2400000.5 |     50123.2 | MJD method         |
   | 2450123.5 |         0.2 | date & time method |

   The JD method is the most natural and convenient to use in
   cases where the loss of several decimal digits of resolution
   is acceptable.  The J2000 method is best matched to the way
   the argument is handled internally and will deliver the
   optimum resolution.  The MJD method and the date & time methods
   are both good compromises between resolution and convenience.

2. The matrix rc2i is the first stage in the transformation from
   celestial to terrestrial coordinates:

      [TRS]  =  RPOM * R_3(ERA) * rc2i * [CRS]

             =  rc2t * [CRS]

   where [CRS] is a vector in the Geocentric Celestial Reference
   System and [TRS] is a vector in the International Terrestrial
   Reference System (see IERS Conventions 2003), ERA is the Earth
   Rotation Angle and RPOM is the polar motion matrix.

3. A faster, but slightly less accurate result (about 1 mas), can be
   obtained by using instead the eraC2i00b function.

### Called ###

- `eraPnm00a`: classical NPB matrix, IAU 2000A
- `eraC2ibpn`: celestial-to-intermediate matrix, given NPB matrix

### References ###

- "Expressions for the Celestial Intermediate Pole and Celestial
    Ephemeris Origin consistent with the IAU 2000A precession-
    nutation model", Astron.Astrophys. 400, 1145-1154
    (2003)

- n.b. The celestial ephemeris origin (CEO) was renamed "celestial
    intermediate origin" (CIO) by IAU 2006 Resolution 2.

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)
"""
c2i00a

"""
    c2i00b(a, b)

Form the celestial-to-intermediate matrix for a given date using the
IAU 2000B precession-nutation model.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `rc2i`: Celestial-to-intermediate matrix (Note 2)

### Notes ###

1. The TT date date1+date2 is a Julian Date, apportioned in any
   convenient way between the two arguments.  For example,
   JD(TT)=2450123.7 could be expressed in any of these ways,
   among others:

   | `date1`   |     `date2` |                    |
   |:----------|:------------|:-------------------|
   | 2450123.7 |         0.0 | JD method          |
   | 2451545.0 |     -1421.3 | J2000 method       |
   | 2400000.5 |     50123.2 | MJD method         |
   | 2450123.5 |         0.2 | date & time method |

   The JD method is the most natural and convenient to use in
   cases where the loss of several decimal digits of resolution
   is acceptable.  The J2000 method is best matched to the way
   the argument is handled internally and will deliver the
   optimum resolution.  The MJD method and the date & time methods
   are both good compromises between resolution and convenience.

2. The matrix rc2i is the first stage in the transformation from
   celestial to terrestrial coordinates:

      [TRS]  =  RPOM * R_3(ERA) * rc2i * [CRS]

             =  rc2t * [CRS]

   where [CRS] is a vector in the Geocentric Celestial Reference
   System and [TRS] is a vector in the International Terrestrial
   Reference System (see IERS Conventions 2003), ERA is the Earth
   Rotation Angle and RPOM is the polar motion matrix.

3. The present function is faster, but slightly less accurate (about
   1 mas), than the eraC2i00a function.

### Called ###

- `eraPnm00b`: classical NPB matrix, IAU 2000B
- `eraC2ibpn`: celestial-to-intermediate matrix, given NPB matrix

### References ###

- "Expressions for the Celestial Intermediate Pole and Celestial
    Ephemeris Origin consistent with the IAU 2000A precession-
    nutation model", Astron.Astrophys. 400, 1145-1154
    (2003)

- n.b. The celestial ephemeris origin (CEO) was renamed "celestial
    intermediate origin" (CIO) by IAU 2006 Resolution 2.

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)
"""
c2i00b

"""
    c2i06a(a, b)

Form the celestial-to-intermediate matrix for a given date using the
IAU 2006 precession and IAU 2000A nutation models.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `rc2i`: Celestial-to-intermediate matrix (Note 2)

### Notes ###

1. The TT date date1+date2 is a Julian Date, apportioned in any
   convenient way between the two arguments.  For example,
   JD(TT)=2450123.7 could be expressed in any of these ways,
   among others:

   | `date1`   |     `date2` |                    |
   |:----------|:------------|:-------------------|
   | 2450123.7 |         0.0 | JD method          |
   | 2451545.0 |     -1421.3 | J2000 method       |
   | 2400000.5 |     50123.2 | MJD method         |
   | 2450123.5 |         0.2 | date & time method |

   The JD method is the most natural and convenient to use in
   cases where the loss of several decimal digits of resolution
   is acceptable.  The J2000 method is best matched to the way
   the argument is handled internally and will deliver the
   optimum resolution.  The MJD method and the date & time methods
   are both good compromises between resolution and convenience.

2. The matrix rc2i is the first stage in the transformation from
   celestial to terrestrial coordinates:

      [TRS]  =  RPOM * R_3(ERA) * rc2i * [CRS]

             =  RC2T * [CRS]

   where [CRS] is a vector in the Geocentric Celestial Reference
   System and [TRS] is a vector in the International Terrestrial
   Reference System (see IERS Conventions 2003), ERA is the Earth
   Rotation Angle and RPOM is the polar motion matrix.

### Called ###

- `eraPnm06a`: classical NPB matrix, IAU 2006/2000A
- `eraBpn2xy`: extract CIP X,Y coordinates from NPB matrix
- `eraS06`: the CIO locator s, given X,Y, IAU 2006
- `eraC2ixys`: celestial-to-intermediate matrix, given X,Y and s

### References ###

- McCarthy, D. D., Petit, G. (eds.), 2004, IERS Conventions (2003),
    IERS Technical Note No. 32, BKG
"""
c2i06a

for name in ("c2i00a",
             "c2i00b",
             "c2i06a")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(a, b)
            r = zeros((3, 3))
            ccall(($fc, liberfa), Cvoid,
                  (Cdouble, Cdouble, Ptr{Cdouble}),
                  a, b, r)
            r
        end
    end
end

"""
    c2ixy(x, y, s, t)

Form the celestial to intermediate-frame-of-date matrix for a given
date when the CIP X,Y coordinates are known.  IAU 2000.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)
- `x`, `y`: Celestial Intermediate Pole (Note 2)

### Returned ###

- `rc2i`: Celestial-to-intermediate matrix (Note 3)

### Notes ###

1. The TT date date1+date2 is a Julian Date, apportioned in any
   convenient way between the two arguments.  For example,
   JD(TT)=2450123.7 could be expressed in any of these ways,
   among others:

   | `date1`   |     `date2` |                    |
   |:----------|:------------|:-------------------|
   | 2450123.7 |         0.0 | JD method          |
   | 2451545.0 |     -1421.3 | J2000 method       |
   | 2400000.5 |     50123.2 | MJD method         |
   | 2450123.5 |         0.2 | date & time method |

   The JD method is the most natural and convenient to use in
   cases where the loss of several decimal digits of resolution
   is acceptable.  The J2000 method is best matched to the way
   the argument is handled internally and will deliver the
   optimum resolution.  The MJD method and the date & time methods
   are both good compromises between resolution and convenience.

2. The Celestial Intermediate Pole coordinates are the x,y components
   of the unit vector in the Geocentric Celestial Reference System.

3. The matrix rc2i is the first stage in the transformation from
   celestial to terrestrial coordinates:

      [TRS] = RPOM * R_3(ERA) * rc2i * [CRS]

            = RC2T * [CRS]

   where [CRS] is a vector in the Geocentric Celestial Reference
   System and [TRS] is a vector in the International Terrestrial
   Reference System (see IERS Conventions 2003), ERA is the Earth
   Rotation Angle and RPOM is the polar motion matrix.

4. Although its name does not include "00", This function is in fact
   specific to the IAU 2000 models.

### Called ###

- `eraC2ixys`: celestial-to-intermediate matrix, given X,Y and s
- `eraS00`: the CIO locator s, given X,Y, IAU 2000A

### Reference ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)
"""
function c2ixy(x, y, s, t)
    r = zeros((3, 3))
    ccall((:eraC2ixy, liberfa), Cvoid,
            (Cdouble, Cdouble, Cdouble, Cdouble, Ptr{Cdouble}),
            x, y, s, t, r)
    r
end

"""
    c2ixys(x, y, s)

Form the celestial to intermediate-frame-of-date matrix given the CIP
X,Y and the CIO locator s.

### Given ###

- `x`, `y`: Celestial Intermediate Pole (Note 1)
- `s`: The CIO locator s (Note 2)

### Returned ###

- `rc2i`: Celestial-to-intermediate matrix (Note 3)

### Notes ###

1. The Celestial Intermediate Pole coordinates are the x,y
   components of the unit vector in the Geocentric Celestial
   Reference System.

2. The CIO locator s (in radians) positions the Celestial
   Intermediate Origin on the equator of the CIP.

3. The matrix rc2i is the first stage in the transformation from
   celestial to terrestrial coordinates:

      [TRS] = RPOM * R_3(ERA) * rc2i * [CRS]

            = RC2T * [CRS]

   where [CRS] is a vector in the Geocentric Celestial Reference
   System and [TRS] is a vector in the International Terrestrial
   Reference System (see IERS Conventions 2003), ERA is the Earth
   Rotation Angle and RPOM is the polar motion matrix.

### Called ###

- `eraIr`: initialize r-matrix to identity
- `eraRz`: rotate around Z-axis
- `eraRy`: rotate around Y-axis

### Reference ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)
"""
function c2ixys(x, y, s)
    r = zeros((3, 3))
    ccall((:eraC2ixys, liberfa), Cvoid,
            (Cdouble, Cdouble, Cdouble, Ptr{Cdouble}),
            x, y, s, r)
    r
end
