"""
    gc2gd(n, xyz)

Transform geocentric coordinates to geodetic using the specified
reference ellipsoid.

### Given ###

- `n`: Ellipsoid identifier (Note 1)
- `xyz`: Geocentric vector (Note 2)

### Returned ###

- `elong`: Longitude (radians, east +ve, Note 3)
- `phi`: Latitude (geodetic, radians, Note 3)
- `height`: Height above ellipsoid (geodetic, Notes 2,3)

### Notes ###

1. The identifier n is a number that specifies the choice of
   reference ellipsoid.  The following are supported:

        - `WGS84`
        - `GRS80`
        - `WGS72`

2. The geocentric vector (xyz, given) and height (height, returned)
   are in meters.

3. An error status -1 means that the identifier n is illegal.  An
   error status -2 is theoretically impossible.  In all error cases,
   all three results are set to -1e9.

4. The inverse transformation is performed in the function eraGd2gc.

### Called ###

- `eraEform`: Earth reference ellipsoids
- `eraGc2gde`: geocentric to geodetic transformation, general

"""
function gc2gd(n, xyz)
    elong = Ref(0.0)
    phi = Ref(0.0)
    height = Ref(0.0)
    i = ccall((:eraGc2gd, liberfa), Cint,
              (Cint, Ptr{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
              n, xyz, elong, phi, height)
    if i == -1
        throw(ERFAException("illegal identifier"))
    elseif i == -2
        throw(ERFAException("internal error"))
    end
    elong[], phi[], height[]
end

"""
    gc2gde(a, f, xyz)

Transform geocentric coordinates to geodetic for a reference
ellipsoid of specified form.

### Given ###

- `a`: Equatorial radius (Notes 2,4)
- `f`: Flattening (Note 3)
- `xyz`: Geocentric vector (Note 4)

### Returned ###

- `elong`: Longitude (radians, east +ve)
- `phi`: Latitude (geodetic, radians)
- `height`: Height above ellipsoid (geodetic, Note 4)

### Notes ###

1. This function is based on the GCONV2H Fortran subroutine by
   Toshio Fukushima (see reference).

2. The equatorial radius, a, can be in any units, but meters is
   the conventional choice.

3. The flattening, f, is (for the Earth) a value around 0.00335,
   i.e. around 1/298.

4. The equatorial radius, a, and the geocentric vector, xyz,
   must be given in the same units, and determine the units of
   the returned height, height.

5. If an error occurs (status < 0), elong, phi and height are
   unchanged.

6. The inverse transformation is performed in the function
   eraGd2gce.

7. The transformation for a standard ellipsoid (such as ERFA_WGS84) can
   more conveniently be performed by calling eraGc2gd, which uses a
   numerical code to identify the required A and F values.

### Reference ###

- Fukushima, T., "Transformation from Cartesian to geodetic
    coordinates accelerated by Halley's method", J.Geodesy (2006)
    79: 689-693

"""
function gc2gde(a, f, xyz)
    elong = Ref(0.0)
    phi = Ref(0.0)
    height = Ref(0.0)
    i = ccall((:eraGc2gde, liberfa), Cint,
              (Cdouble, Cdouble, Ptr{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
              a, f, xyz, elong, phi, height)
    if i == -1
        throw(ERFAException("illegal f"))
    elseif i == -2
        throw(ERFAException("internal a"))
    end
    elong[], phi[], height[]
end

"""
    gd2gc(n, elong, phi, height)

Transform geodetic coordinates to geocentric using the specified
reference ellipsoid.

### Given ###

- `n`: Ellipsoid identifier (Note 1)
- `elong`: Longitude (radians, east +ve)
- `phi`: Latitude (geodetic, radians, Note 3)
- `height`: Height above ellipsoid (geodetic, Notes 2,3)

### Returned ###

- `xyz`: Geocentric vector (Note 2)

### Notes ###

1. The identifier n is a number that specifies the choice of
   reference ellipsoid.  The following are supported:

      n    ellipsoid

      1     ERFA_WGS84
      2     ERFA_GRS80
      3     ERFA_WGS72

   The n value has no significance outside the ERFA software.  For
   convenience, symbols ERFA_WGS84 etc. are defined in erfam.h.

2. The height (height, given) and the geocentric vector (xyz,
   returned) are in meters.

3. No validation is performed on the arguments elong, phi and
   height.  An error status -1 means that the identifier n is
   illegal.  An error status -2 protects against cases that would
   lead to arithmetic exceptions.  In all error cases, xyz is set
   to zeros.

4. The inverse transformation is performed in the function eraGc2gd.

### Called ###

- `eraEform`: Earth reference ellipsoids
- `eraGd2gce`: geodetic to geocentric transformation, general
- `eraZp`: zero p-vector

"""
function gd2gc(n, elong, phi, height)
    xyz = zeros(3)
    i = ccall((:eraGd2gc, liberfa), Cint,
              (Cint, Cdouble, Cdouble, Cdouble, Ptr{Cdouble}),
              n, elong, phi, height, xyz)
    if i == -1
        throw(ERFAException("illegal identifier"))
    elseif i == -2
        throw(ERFAException("illegal case"))
    end
    xyz
end

"""
    gd2gce(a, f, elong, phi, height)

Transform geodetic coordinates to geocentric for a reference
ellipsoid of specified form.

### Given ###

- `a`: Equatorial radius (Notes 1,4)
- `f`: Flattening (Notes 2,4)
- `elong`: Longitude (radians, east +ve)
- `phi`: Latitude (geodetic, radians, Note 4)
- `height`: Height above ellipsoid (geodetic, Notes 3,4)

### Returned ###

- `xyz`: Geocentric vector (Note 3)

### Notes ###

1. The equatorial radius, a, can be in any units, but meters is
   the conventional choice.

2. The flattening, f, is (for the Earth) a value around 0.00335,
   i.e. around 1/298.

3. The equatorial radius, a, and the height, height, must be
   given in the same units, and determine the units of the
   returned geocentric vector, xyz.

4. No validation is performed on individual arguments.  The error
   status -1 protects against (unrealistic) cases that would lead
   to arithmetic exceptions.  If an error occurs, xyz is unchanged.

5. The inverse transformation is performed in the function
   eraGc2gde.

6. The transformation for a standard ellipsoid (such as ERFA_WGS84) can
   more conveniently be performed by calling eraGd2gc,  which uses a
   numerical code to identify the required a and f values.

### References ###

- Green, R.M., Spherical Astronomy, Cambridge University Press,
    (1985) Section 4.5, p96.

- Explanatory Supplement to the Astronomical Almanac,
    P. Kenneth Seidelmann (ed), University Science Books (1992),
    Section 4.22, p202.

"""
function gd2gce(a, f, elong, phi, height)
    xyz = zeros(3)
    i = ccall((:eraGd2gce, liberfa), Cint,
              (Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ptr{Cdouble}),
              a, f, elong, phi, height, xyz)
    if i == -1
        throw(ERFAException("illegal case"))
    end
    xyz
end

"""
    gst06(uta, utb, tta, ttb, rnpb)

Greenwich apparent sidereal time, IAU 2006, given the NPB matrix.

### Given ###

- `uta`, `utb`: UT1 as a 2-part Julian Date (Notes 1,2)
- `tta`, `ttb`: TT as a 2-part Julian Date (Notes 1,2)
- `rnpb`: Nutation x precession x bias matrix

### Returned ###

- Greenwich apparent sidereal time (radians)

### Notes ###

1. The UT1 and TT dates uta+utb and tta+ttb respectively, are both
   Julian Dates, apportioned in any convenient way between the
   argument pairs.  For example, JD=2450123.7 could be expressed in
   any of these ways, among others:

          Part A        Part B

       2450123.7           0.0       (JD method)
       2451545.0       -1421.3       (J2000 method)
       2400000.5       50123.2       (MJD method)
       2450123.5           0.2       (date & time method)

   The JD method is the most natural and convenient to use in
   cases where the loss of several decimal digits of resolution
   is acceptable (in the case of UT;  the TT is not at all critical
   in this respect).  The J2000 and MJD methods are good compromises
   between resolution and convenience.  For UT, the date & time
   method is best matched to the algorithm that is used by the Earth
   rotation angle function, called internally:  maximum precision is
   delivered when the uta argument is for 0hrs UT1 on the day in
   question and the utb argument lies in the range 0 to 1, or vice
   versa.

2. Both UT1 and TT are required, UT1 to predict the Earth rotation
   and TT to predict the effects of precession-nutation.  If UT1 is
   used for both purposes, errors of order 100 microarcseconds
   result.

3. Although the function uses the IAU 2006 series for s+XY/2, it is
   otherwise independent of the precession-nutation model and can in
   practice be used with any equinox-based NPB matrix.

4. The result is returned in the range 0 to 2pi.

### Called ###

- `eraBpn2xy`: extract CIP X,Y coordinates from NPB matrix
- `eraS06`: the CIO locator s, given X,Y, IAU 2006
- `eraAnp`: normalize angle into range 0 to 2pi
- `eraEra00`: Earth rotation angle, IAU 2000
- `eraEors`: equation of the origins, given NPB matrix and s

### Reference ###

- Wallace, P.T. & Capitaine, N., 2006, Astron.Astrophys. 459, 981

"""
function gst06(uta, utb, tta, ttb, rnpb)
    ccall((:eraGst06, liberfa), Cdouble,
          (Cdouble, Cdouble, Cdouble, Cdouble, Ptr{Cdouble}),
          uta, utb, tta, ttb, rnpb)
end

"""
    gmst82(dj1, dj2)

Universal Time to Greenwich mean sidereal time (IAU 1982 model).

### Given ###

- `dj1`, `dj2`: UT1 Julian Date (see note)

### Returned ###

- Greenwich mean sidereal time (radians)

### Notes ###

1. The UT1 date dj1+dj2 is a Julian Date, apportioned in any
   convenient way between the arguments dj1 and dj2.  For example,
   JD(UT1)=2450123.7 could be expressed in any of these ways,
   among others:

           dj1            dj2

       2450123.7          0          (JD method)
        2451545        -1421.3       (J2000 method)
       2400000.5       50123.2       (MJD method)
       2450123.5         0.2         (date & time method)

   The JD method is the most natural and convenient to use in
   cases where the loss of several decimal digits of resolution
   is acceptable.  The J2000 and MJD methods are good compromises
   between resolution and convenience.  The date & time method is
   best matched to the algorithm used:  maximum accuracy (or, at
   least, minimum noise) is delivered when the dj1 argument is for
   0hrs UT1 on the day in question and the dj2 argument lies in the
   range 0 to 1, or vice versa.

2. The algorithm is based on the IAU 1982 expression.  This is
   always described as giving the GMST at 0 hours UT1.  In fact, it
   gives the difference between the GMST and the UT, the steady
   4-minutes-per-day drawing-ahead of ST with respect to UT.  When
   whole days are ignored, the expression happens to equal the GMST
   at 0 hours UT1 each day.

3. In this function, the entire UT1 (the sum of the two arguments
   dj1 and dj2) is used directly as the argument for the standard
   formula, the constant term of which is adjusted by 12 hours to
   take account of the noon phasing of Julian Date.  The UT1 is then
   added, but omitting whole days to conserve accuracy.

### Called ###

- `eraAnp`: normalize angle into range 0 to 2pi

### References ###

- Transactions of the International Astronomical Union,
    XVIII B, 67 (1983).

- Aoki et al., Astron. Astrophys. 105, 359-361 (1982).

"""
gmst82

"""
    gst00b(dr, dd)

Greenwich apparent sidereal time (consistent with IAU 2000
resolutions but using the truncated nutation model IAU 2000B).

### Given ###

- `uta`, `utb`: UT1 as a 2-part Julian Date (Notes 1,2)

### Returned ###

- Greenwich apparent sidereal time (radians)

### Notes ###

1. The UT1 date uta+utb is a Julian Date, apportioned in any
   convenient way between the argument pair.  For example,
   JD=2450123.7 could be expressed in any of these ways, among
   others:

           uta            utb

       2450123.7           0.0       (JD method)
       2451545.0       -1421.3       (J2000 method)
       2400000.5       50123.2       (MJD method)
       2450123.5           0.2       (date & time method)

   The JD method is the most natural and convenient to use in cases
   where the loss of several decimal digits of resolution is
   acceptable.  The J2000 and MJD methods are good compromises
   between resolution and convenience.  For UT, the date & time
   method is best matched to the algorithm that is used by the Earth
   Rotation Angle function, called internally:  maximum precision is
   delivered when the uta argument is for 0hrs UT1 on the day in
   question and the utb argument lies in the range 0 to 1, or vice
   versa.

2. The result is compatible with the IAU 2000 resolutions, except
   that accuracy has been compromised for the sake of speed and
   convenience in two respects:

   . UT is used instead of TDB (or TT) to compute the precession
     component of GMST and the equation of the equinoxes.  This
     results in errors of order 0.1 mas at present.

   . The IAU 2000B abridged nutation model (McCarthy & Luzum, 2001)
     is used, introducing errors of up to 1 mas.

3. This GAST is compatible with the IAU 2000 resolutions and must be
   used only in conjunction with other IAU 2000 compatible
   components such as precession-nutation.

4. The result is returned in the range 0 to 2pi.

5. The algorithm is from Capitaine et al. (2003) and IERS
   Conventions 2003.

### Called ###

- `eraGmst00`: Greenwich mean sidereal time, IAU 2000
- `eraEe00b`: equation of the equinoxes, IAU 2000B
- `eraAnp`: normalize angle into range 0 to 2pi

### References ###

- Capitaine, N., Wallace, P.T. and McCarthy, D.D., "Expressions to
    implement the IAU 2000 definition of UT1", Astronomy &
    Astrophysics, 406, 1135-1149 (2003)

- McCarthy, D.D. & Luzum, B.J., "An abridged model of the
    precession-nutation of the celestial pole", Celestial Mechanics &
    Dynamical Astronomy, 85, 37-49 (2003)

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

"""
gst00b

"""
    gst94(dr, dd)

Greenwich apparent sidereal time (consistent with IAU 1982/94
resolutions).

### Given ###

- `uta`, `utb`: UT1 as a 2-part Julian Date (Notes 1,2)

### Returned ###

- Greenwich apparent sidereal time (radians)

### Notes ###

1. The UT1 date uta+utb is a Julian Date, apportioned in any
   convenient way between the argument pair.  For example,
   JD=2450123.7 could be expressed in any of these ways, among
   others:

           uta            utb

       2450123.7           0.0       (JD method)
       2451545.0       -1421.3       (J2000 method)
       2400000.5       50123.2       (MJD method)
       2450123.5           0.2       (date & time method)

   The JD method is the most natural and convenient to use in cases
   where the loss of several decimal digits of resolution is
   acceptable.  The J2000 and MJD methods are good compromises
   between resolution and convenience.  For UT, the date & time
   method is best matched to the algorithm that is used by the Earth
   Rotation Angle function, called internally:  maximum precision is
   delivered when the uta argument is for 0hrs UT1 on the day in
   question and the utb argument lies in the range 0 to 1, or vice
   versa.

2. The result is compatible with the IAU 1982 and 1994 resolutions,
   except that accuracy has been compromised for the sake of
   convenience in that UT is used instead of TDB (or TT) to compute
   the equation of the equinoxes.

3. This GAST must be used only in conjunction with contemporaneous
   IAU standards such as 1976 precession, 1980 obliquity and 1982
   nutation.  It is not compatible with the IAU 2000 resolutions.

4. The result is returned in the range 0 to 2pi.

### Called ###

- `eraGmst82`: Greenwich mean sidereal time, IAU 1982
- `eraEqeq94`: equation of the equinoxes, IAU 1994
- `eraAnp`: normalize angle into range 0 to 2pi

### References ###

- Explanatory Supplement to the Astronomical Almanac,
    P. Kenneth Seidelmann (ed), University Science Books (1992)

- IAU Resolution C7, Recommendation 3 (1994)

"""
gst94

for name in ("gmst82",
             "gst00b",
             "gst94")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval ($f)(d1, d2) = ccall(($fc, liberfa), Cdouble, (Cdouble, Cdouble), d1, d2)
end

"""
    gmst00(uta, utb, tta, ttb)

Greenwich mean sidereal time (model consistent with IAU 2000
resolutions).

### Given ###

- `uta`, `utb`: UT1 as a 2-part Julian Date (Notes 1,2)
- `tta`, `ttb`: TT as a 2-part Julian Date (Notes 1,2)

### Returned ###

- Greenwich mean sidereal time (radians)

### Notes ###

1. The UT1 and TT dates uta+utb and tta+ttb respectively, are both
   Julian Dates, apportioned in any convenient way between the
   argument pairs.  For example, JD=2450123.7 could be expressed in
   any of these ways, among others:

          Part A         Part B

       2450123.7           0.0       (JD method)
       2451545.0       -1421.3       (J2000 method)
       2400000.5       50123.2       (MJD method)
       2450123.5           0.2       (date & time method)

   The JD method is the most natural and convenient to use in
   cases where the loss of several decimal digits of resolution
   is acceptable (in the case of UT;  the TT is not at all critical
   in this respect).  The J2000 and MJD methods are good compromises
   between resolution and convenience.  For UT, the date & time
   method is best matched to the algorithm that is used by the Earth
   Rotation Angle function, called internally:  maximum precision is
   delivered when the uta argument is for 0hrs UT1 on the day in
   question and the utb argument lies in the range 0 to 1, or vice
   versa.

2. Both UT1 and TT are required, UT1 to predict the Earth rotation
   and TT to predict the effects of precession.  If UT1 is used for
   both purposes, errors of order 100 microarcseconds result.

3. This GMST is compatible with the IAU 2000 resolutions and must be
   used only in conjunction with other IAU 2000 compatible
   components such as precession-nutation and equation of the
   equinoxes.

4. The result is returned in the range 0 to 2pi.

5. The algorithm is from Capitaine et al. (2003) and IERS
   Conventions 2003.

### Called ###

- `eraEra00`: Earth rotation angle, IAU 2000
- `eraAnp`: normalize angle into range 0 to 2pi

### References ###

- Capitaine, N., Wallace, P.T. and McCarthy, D.D., "Expressions to
    implement the IAU 2000 definition of UT1", Astronomy &
    Astrophysics, 406, 1135-1149 (2003)

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

"""
gmst00

"""
    gmst06(uta, utb, tta, ttb)

Greenwich mean sidereal time (consistent with IAU 2006 precession).

### Given ###

- `uta`, `utb`: UT1 as a 2-part Julian Date (Notes 1,2)
- `tta`, `ttb`: TT as a 2-part Julian Date (Notes 1,2)

### Returned ###

- Greenwich mean sidereal time (radians)

### Notes ###

1. The UT1 and TT dates uta+utb and tta+ttb respectively, are both
   Julian Dates, apportioned in any convenient way between the
   argument pairs.  For example, JD=2450123.7 could be expressed in
   any of these ways, among others:

          Part A        Part B

       2450123.7           0.0       (JD method)
       2451545.0       -1421.3       (J2000 method)
       2400000.5       50123.2       (MJD method)
       2450123.5           0.2       (date & time method)

   The JD method is the most natural and convenient to use in
   cases where the loss of several decimal digits of resolution
   is acceptable (in the case of UT;  the TT is not at all critical
   in this respect).  The J2000 and MJD methods are good compromises
   between resolution and convenience.  For UT, the date & time
   method is best matched to the algorithm that is used by the Earth
   rotation angle function, called internally:  maximum precision is
   delivered when the uta argument is for 0hrs UT1 on the day in
   question and the utb argument lies in the range 0 to 1, or vice
   versa.

2. Both UT1 and TT are required, UT1 to predict the Earth rotation
   and TT to predict the effects of precession.  If UT1 is used for
   both purposes, errors of order 100 microarcseconds result.

3. This GMST is compatible with the IAU 2006 precession and must not
   be used with other precession models.

4. The result is returned in the range 0 to 2pi.

### Called ###

- `eraEra00`: Earth rotation angle, IAU 2000
- `eraAnp`: normalize angle into range 0 to 2pi

### Reference ###

- Capitaine, N., Wallace, P.T. & Chapront, J., 2005,
    Astron.Astrophys. 432, 355

"""
gmst06

"""
    gst00a(uta, utb, tta, ttb)

Greenwich apparent sidereal time (consistent with IAU 2000
resolutions).

### Given ###

- `uta`, `utb`: UT1 as a 2-part Julian Date (Notes 1,2)
- `tta`, `ttb`: TT as a 2-part Julian Date (Notes 1,2)

### Returned  ###

- Greenwich apparent sidereal time (radians)

### Notes ###

1. The UT1 and TT dates uta+utb and tta+ttb respectively, are both
   Julian Dates, apportioned in any convenient way between the
   argument pairs.  For example, JD=2450123.7 could be expressed in
   any of these ways, among others:

          Part A        Part B

       2450123.7           0.0       (JD method)
       2451545.0       -1421.3       (J2000 method)
       2400000.5       50123.2       (MJD method)
       2450123.5           0.2       (date & time method)

   The JD method is the most natural and convenient to use in
   cases where the loss of several decimal digits of resolution
   is acceptable (in the case of UT;  the TT is not at all critical
   in this respect).  The J2000 and MJD methods are good compromises
   between resolution and convenience.  For UT, the date & time
   method is best matched to the algorithm that is used by the Earth
   Rotation Angle function, called internally:  maximum precision is
   delivered when the uta argument is for 0hrs UT1 on the day in
   question and the utb argument lies in the range 0 to 1, or vice
   versa.

2. Both UT1 and TT are required, UT1 to predict the Earth rotation
   and TT to predict the effects of precession-nutation.  If UT1 is
   used for both purposes, errors of order 100 microarcseconds
   result.

3. This GAST is compatible with the IAU 2000 resolutions and must be
   used only in conjunction with other IAU 2000 compatible
   components such as precession-nutation.

4. The result is returned in the range 0 to 2pi.

5. The algorithm is from Capitaine et al. (2003) and IERS
   Conventions 2003.

### Called ###

- `eraGmst00`: Greenwich mean sidereal time, IAU 2000
- `eraEe00a`: equation of the equinoxes, IAU 2000A
- `eraAnp`: normalize angle into range 0 to 2pi

### References ###

- Capitaine, N., Wallace, P.T. and McCarthy, D.D., "Expressions to
    implement the IAU 2000 definition of UT1", Astronomy &
    Astrophysics, 406, 1135-1149 (2003)

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

"""
gst00a

"""
    gst06a(uta, utb, tta, ttb)

Greenwich apparent sidereal time (consistent with IAU 2000 and 2006
resolutions).

### Given ###

- `uta`, `utb`: UT1 as a 2-part Julian Date (Notes 1,2)
- `tta`, `ttb`: TT as a 2-part Julian Date (Notes 1,2)

### Returned ###

- Greenwich apparent sidereal time (radians)

### Notes ###

1. The UT1 and TT dates uta+utb and tta+ttb respectively, are both
   Julian Dates, apportioned in any convenient way between the
   argument pairs.  For example, JD=2450123.7 could be expressed in
   any of these ways, among others:

          Part A        Part B

       2450123.7           0.0       (JD method)
       2451545.0       -1421.3       (J2000 method)
       2400000.5       50123.2       (MJD method)
       2450123.5           0.2       (date & time method)

   The JD method is the most natural and convenient to use in
   cases where the loss of several decimal digits of resolution
   is acceptable (in the case of UT;  the TT is not at all critical
   in this respect).  The J2000 and MJD methods are good compromises
   between resolution and convenience.  For UT, the date & time
   method is best matched to the algorithm that is used by the Earth
   rotation angle function, called internally:  maximum precision is
   delivered when the uta argument is for 0hrs UT1 on the day in
   question and the utb argument lies in the range 0 to 1, or vice
   versa.

2. Both UT1 and TT are required, UT1 to predict the Earth rotation
   and TT to predict the effects of precession-nutation.  If UT1 is
   used for both purposes, errors of order 100 microarcseconds
   result.

3. This GAST is compatible with the IAU 2000/2006 resolutions and
   must be used only in conjunction with IAU 2006 precession and
   IAU 2000A nutation.

4. The result is returned in the range 0 to 2pi.

### Called ###

- `eraPnm06a`: classical NPB matrix, IAU 2006/2000A
- `eraGst06`: Greenwich apparent ST, IAU 2006, given NPB matrix

### Reference ###

- Wallace, P.T. & Capitaine, N., 2006, Astron.Astrophys. 459, 981

"""
gst06a

for name in ("gmst00",
             "gmst06",
             "gst00a",
             "gst06a")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval ($f)(d1, d2, t1, t2) = ccall(($fc, liberfa), Cdouble, (Cdouble, Cdouble, Cdouble, Cdouble), d1, d2, t1, t2)
end

"""
    g2icrs(dl, db)

Transformation from Galactic Coordinates to ICRS.

### Given ###

- `dl`: Galactic longitude (radians)
- `db`: Galactic latitude (radians)

### Returned ###

- `dr`: ICRS right ascension (radians)
- `dd`: ICRS declination (radians)

### Notes ###

1. The IAU 1958 system of Galactic coordinates was defined with
   respect to the now obsolete reference system FK4 B1950.0.  When
   interpreting the system in a modern context, several factors have
   to be taken into account:

   . The inclusion in FK4 positions of the E-terms of aberration.

   . The distortion of the FK4 proper motion system by differential
     Galactic rotation.

   . The use of the B1950.0 equinox rather than the now-standard
     J2000.0.

   . The frame bias between ICRS and the J2000.0 mean place system.

   The Hipparcos Catalogue (Perryman & ESA 1997) provides a rotation
   matrix that transforms directly between ICRS and Galactic
   coordinates with the above factors taken into account.  The
   matrix is derived from three angles, namely the ICRS coordinates
   of the Galactic pole and the longitude of the ascending node of
   the galactic equator on the ICRS equator.  They are given in
   degrees to five decimal places and for canonical purposes are
   regarded as exact.  In the Hipparcos Catalogue the matrix
   elements are given to 10 decimal places (about 20 microarcsec).
   In the present ERFA function the matrix elements have been
   recomputed from the canonical three angles and are given to 30
   decimal places.

2. The inverse transformation is performed by the function eraIcrs2g.

### Called ###

- `eraAnp`: normalize angle into range 0 to 2pi
- `eraAnpm`: normalize angle into range +/- pi
- `eraS2c`: spherical coordinates to unit vector
- `eraTrxp`: product of transpose of r-matrix and p-vector
- `eraC2s`: p-vector to spherical

### Reference ###

- Perryman M.A.C. & ESA, 1997, ESA SP-1200, The Hipparcos and Tycho
    catalogues.  Astrometric and photometric star catalogues
    derived from the ESA Hipparcos Space Astrometry Mission.  ESA
    Publications Division, Noordwijk, Netherlands.

"""
function g2icrs(a, b)
    r1 = Ref(0.0)
    r2 = Ref(0.0)
    ccall((:eraG2icrs, liberfa), Cvoid,
            (Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}),
            a, b, r1, r2)
    r1[], r2[]
end
