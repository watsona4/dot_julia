"""
    s2c(theta, phi)

Convert spherical coordinates to Cartesian.

### Given ###

- `theta`: Longitude angle (radians)
- `phi`: Latitude angle (radians)

### Returned ###

- `c`: Direction cosines

"""
function s2c(theta, phi)
    c = zeros(3)
    ccall((:eraS2c, liberfa), Cvoid,
          (Cdouble, Cdouble, Ptr{Cdouble}),
          theta, phi, c)
    c
end

"""
    s2p(theta, phi, r)

Convert spherical polar coordinates to p-vector.

### Given ###

- `theta`: Longitude angle (radians)
- `phi`: Latitude angle (radians)
- `r`: Radial distance

### Returned ###

- `p`: Cartesian coordinates

### Called ###

- `eraS2c`: spherical coordinates to unit vector
- `eraSxp`: multiply p-vector by scalar

"""
function s2p(theta, phi, r)
    p = zeros(3)
    ccall((:eraS2p, liberfa), Cvoid,
          (Cdouble, Cdouble, Cdouble, Ptr{Cdouble}),
          theta, phi, r, p)
    p
end

"""
    s2pv(theta, phi, r, td, pd, rd)

Convert position/velocity from spherical to Cartesian coordinates.

### Given ###

- `theta`: Longitude angle (radians)
- `phi`: Latitude angle (radians)
- `r`: Radial distance
- `td`: Rate of change of theta
- `pd`: Rate of change of phi
- `rd`: Rate of change of r

### Returned ###

- `pv`: Pv-vector

"""
function s2pv(theta, phi, r, td, pd, rd)
    pv = zeros((2, 3))
    ccall((:eraS2pv, liberfa), Cvoid,
          (Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ptr{Cdouble}),
          theta, phi, r, td, pd, rd, pv)
    pv
end

"""
    s2xpv(s1, s2, pv)

Multiply a pv-vector by two scalars.

### Given ###

- `s1`: Scalar to multiply position component by
- `s2`: Scalar to multiply velocity component by
- `pv`: Pv-vector

### Returned ###

- `spv`: Pv-vector: p scaled by s1, v scaled by s2

### Note ###

   It is permissible for pv and spv to be the same array.

### Called ###

- `eraSxp`: multiply p-vector by scalar

"""
function s2xpv(s1, s2, pv)
    spv = zeros((2, 3))
    ccall((:eraS2xpv, liberfa), Cvoid,
          (Cdouble, Cdouble, Ptr{Cdouble}, Ptr{Cdouble}),
          s1, s2, pv, spv)
    spv
end

"""
    starpm(ra1, dec1, pmr1, pmd1, px1, rv1, ep1a, ep1b, ep2a, ep2b)

Star proper motion:  update star catalog data for space motion.

### Given ###

- `ra1`: Right ascension (radians), before
- `dec1`: Declination (radians), before
- `pmr1`: RA proper motion (radians/year), before
- `pmd1`: Dec proper motion (radians/year), before
- `px1`: Parallax (arcseconds), before
- `rv1`: Radial velocity (km/s, +ve = receding), before
- `ep1a`: "before" epoch, part A (Note 1)
- `ep1b`: "before" epoch, part B (Note 1)
- `ep2a`: "after" epoch, part A (Note 1)
- `ep2b`: "after" epoch, part B (Note 1)

### Returned ###

- `ra2`: Right ascension (radians), after
- `dec2`: Declination (radians), after
- `pmr2`: RA proper motion (radians/year), after
- `pmd2`: Dec proper motion (radians/year), after
- `px2`: Parallax (arcseconds), after
- `rv2`: Radial velocity (km/s, +ve = receding), after

### Notes ###

1. The starting and ending TDB dates ep1a+ep1b and ep2a+ep2b are
   Julian Dates, apportioned in any convenient way between the two
   parts (A and B).  For example, JD(TDB)=2450123.7 could be
   expressed in any of these ways, among others:

           epna          epnb

       2450123.7           0.0       (JD method)
       2451545.0       -1421.3       (J2000 method)
       2400000.5       50123.2       (MJD method)
       2450123.5           0.2       (date & time method)

   The JD method is the most natural and convenient to use in
   cases where the loss of several decimal digits of resolution
   is acceptable.  The J2000 method is best matched to the way
   the argument is handled internally and will deliver the
   optimum resolution.  The MJD method and the date & time methods
   are both good compromises between resolution and convenience.

2. In accordance with normal star-catalog conventions, the object's
   right ascension and declination are freed from the effects of
   secular aberration.  The frame, which is aligned to the catalog
   equator and equinox, is Lorentzian and centered on the SSB.

   The proper motions are the rate of change of the right ascension
   and declination at the catalog epoch and are in radians per TDB
   Julian year.

   The parallax and radial velocity are in the same frame.

3. Care is needed with units.  The star coordinates are in radians
   and the proper motions in radians per Julian year, but the
   parallax is in arcseconds.

4. The RA proper motion is in terms of coordinate angle, not true
   angle.  If the catalog uses arcseconds for both RA and Dec proper
   motions, the RA proper motion will need to be divided by cos(Dec)
   before use.

5. Straight-line motion at constant speed, in the inertial frame,
   is assumed.

6. An extremely small (or zero or negative) parallax is interpreted
   to mean that the object is on the "celestial sphere", the radius
   of which is an arbitrary (large) value (see the eraStarpv
   function for the value used).  When the distance is overridden in
   this way, the status, initially zero, has 1 added to it.

7. If the space velocity is a significant fraction of c (see the
   constant VMAX in the function eraStarpv), it is arbitrarily set
   to zero.  When this action occurs, 2 is added to the status.

8. The relativistic adjustment carried out in the eraStarpv function
   involves an iterative calculation.  If the process fails to
   converge within a set number of iterations, 4 is added to the
   status.

### Called ###

- `eraStarpv`: star catalog data to space motion pv-vector
- `eraPvu`: update a pv-vector
- `eraPdp`: scalar product of two p-vectors
- `eraPvstar`: space motion pv-vector to star catalog data

"""
function starpm(ra1, dec1, pmr1, pmd1, px1, rv1, ep1a, ep1b, ep2a, ep2b)
    ra2 = Ref(0.0)
    dec2 = Ref(0.0)
    pmr2 = Ref(0.0)
    pmd2 = Ref(0.0)
    px2 = Ref(0.0)
    rv2 = Ref(0.0)
    i = ccall((:eraStarpm, liberfa), Cint,
              (Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ref{Cdouble},
              Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
              ra1, dec1, pmr1, pmd1, px1, rv1, ep1a, ep1b, ep2a, ep2b, ra2, dec2, pmr2, pmd2, px2, rv2)
    if i == -1
        throw(ERFAException("system error"))
    elseif i == 1
        @warn "distance overridden"
        return ra2[], dec2[], pmr2[], pmd2[], px2[], rv2[]
    elseif i == 2
        @warn "excessive velocity"
        return ra2[], dec2[], pmr2[], pmd2[], px2[], rv2[]
    elseif i == 4
        throw(ERFAException("solution didn't converge"))
    end
    ra2[], dec2[], pmr2[], pmd2[], px2[], rv2[]
end

"""
    starpv(ra, dec, pmr, pmd, px, rv)

Convert star catalog coordinates to position+velocity vector.

### Given (Note 1) ###

- `ra`: Right ascension (radians)
- `dec`: Declination (radians)
- `pmr`: RA proper motion (radians/year)
- `pmd`: Dec proper motion (radians/year)
- `px`: Parallax (arcseconds)
- `rv`: Radial velocity (km/s, positive = receding)

### Returned (Note 2) ###

- `pv`: pv-vector (au, au/day)

### Notes ###

1. The star data accepted by this function are "observables" for an
   imaginary observer at the solar-system barycenter.  Proper motion
   and radial velocity are, strictly, in terms of barycentric
   coordinate time, TCB.  For most practical applications, it is
   permissible to neglect the distinction between TCB and ordinary
   "proper" time on Earth (TT/TAI).  The result will, as a rule, be
   limited by the intrinsic accuracy of the proper-motion and
   radial-velocity data;  moreover, the pv-vector is likely to be
   merely an intermediate result, so that a change of time unit
   would cancel out overall.

   In accordance with normal star-catalog conventions, the object's
   right ascension and declination are freed from the effects of
   secular aberration.  The frame, which is aligned to the catalog
   equator and equinox, is Lorentzian and centered on the SSB.

2. The resulting position and velocity pv-vector is with respect to
   the same frame and, like the catalog coordinates, is freed from
   the effects of secular aberration.  Should the "coordinate
   direction", where the object was located at the catalog epoch, be
   required, it may be obtained by calculating the magnitude of the
   position vector pv[0][0-2] dividing by the speed of light in
   au/day to give the light-time, and then multiplying the space
   velocity pv[1][0-2] by this light-time and adding the result to
   pv[0][0-2].

   Summarizing, the pv-vector returned is for most stars almost
   identical to the result of applying the standard geometrical
   "space motion" transformation.  The differences, which are the
   subject of the Stumpff paper referenced below, are:

   (i) In stars with significant radial velocity and proper motion,
   the constantly changing light-time distorts the apparent proper
   motion.  Note that this is a classical, not a relativistic,
   effect.

   (ii) The transformation complies with special relativity.

3. Care is needed with units.  The star coordinates are in radians
   and the proper motions in radians per Julian year, but the
   parallax is in arcseconds; the radial velocity is in km/s, but
   the pv-vector result is in au and au/day.

4. The RA proper motion is in terms of coordinate angle, not true
   angle.  If the catalog uses arcseconds for both RA and Dec proper
   motions, the RA proper motion will need to be divided by cos(Dec)
   before use.

5. Straight-line motion at constant speed, in the inertial frame,
   is assumed.

6. An extremely small (or zero or negative) parallax is interpreted
   to mean that the object is on the "celestial sphere", the radius
   of which is an arbitrary (large) value (see the constant PXMIN).
   When the distance is overridden in this way, the status,
   initially zero, has 1 added to it.

7. If the space velocity is a significant fraction of c (see the
   constant VMAX), it is arbitrarily set to zero.  When this action
   occurs, 2 is added to the status.

8. The relativistic adjustment involves an iterative calculation.
   If the process fails to converge within a set number (IMAX) of
   iterations, 4 is added to the status.

9. The inverse transformation is performed by the function
   eraPvstar.

### Called ###

- `eraS2pv`: spherical coordinates to pv-vector
- `eraPm`: modulus of p-vector
- `eraZp`: zero p-vector
- `eraPn`: decompose p-vector into modulus and direction
- `eraPdp`: scalar product of two p-vectors
- `eraSxp`: multiply p-vector by scalar
- `eraPmp`: p-vector minus p-vector
- `eraPpp`: p-vector plus p-vector

### Reference ###

- Stumpff, P., 1985, Astron.Astrophys. 144, 232-240.

"""
function starpv(ra, dec, pmr, pmd, px, rv)
    pv = zeros((2, 3))
    i = ccall((:eraStarpv, liberfa), Cint,
              (Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ptr{Cdouble}),
              ra, dec, pmr, pmd, px, rv, pv)
    if i == 1
        @warn "distance overridden"
        return pv
    elseif i == 2
        @warn "excessive speed "
        return pv
    elseif i == 4
        throw(ERFAException("solution didn't converge"))
    end
    pv
end

"""
    sxp(s, p)

Multiply a p-vector by a scalar.

### Given ###

- `s`: Scalar
- `p`: P-vector

### Returned ###

- `sp`: S * p

### Note ###

   It is permissible for p and sp to be the same array.

"""
function sxp(s, p)
    sp = zeros(3)
    ccall((:eraSxp, liberfa), Cvoid,
          (Cdouble, Ptr{Cdouble}, Ptr{Cdouble}),
          s, p, sp)
    sp
end

"""
    sxpv(s, pv)

Multiply a pv-vector by a scalar.

### Given ###

- `s`: Scalar
- `pv`: Pv-vector

### Returned ###

- `spv`: S * pv

### Note ###

   It is permissible for pv and spv to be the same array

### Called ###

- `eraS2xpv`: multiply pv-vector by two scalars

"""
function sxpv(s, pv)
    spv = zeros((2, 3))
    ccall((:eraSxpv, liberfa), Cvoid,
          (Cdouble, Ptr{Cdouble}, Ptr{Cdouble}),
          s, pv, spv)
    spv
end

"""
    seps(al, ap, bl, bp)

Angular separation between two sets of spherical coordinates.

### Given ###

- `al`: First longitude (radians)
- `ap`: First latitude (radians)
- `bl`: Second longitude (radians)
- `bp`: Second latitude (radians)

### Returned ###

- Angular separation (radians)

### Called ###

- `eraS2c`: spherical coordinates to unit vector
- `eraSepp`: angular separation between two p-vectors

"""
function seps(al, ap, bl, bp)
    ccall((:eraSeps, liberfa), Cdouble, (Cdouble, Cdouble, Cdouble, Cdouble), al, ap, bl, bp)
end

"""
    sepp(a, b)

Angular separation between two p-vectors.

### Given ###

- `a`: First p-vector (not necessarily unit length)
- `b`: Second p-vector (not necessarily unit length)

### Returned ###

- Angular separation (radians, always positive)

### Notes ###

1. If either vector is null, a zero result is returned.

2. The angular separation is most simply formulated in terms of
   scalar product.  However, this gives poor accuracy for angles
   near zero and pi.  The present algorithm uses both cross product
   and dot product, to deliver full accuracy whatever the size of
   the angle.

### Called ###

- `eraPxp`: vector product of two p-vectors
- `eraPm`: modulus of p-vector
- `eraPdp`: scalar product of two p-vectors

"""
function sepp(a, b)
    ccall((:eraSepp, liberfa), Cdouble, (Ptr{Cdouble}, Ptr{Cdouble}), a, b)
end

"""
    s00a(date1, date2)

The CIO locator s, positioning the Celestial Intermediate Origin on
the equator of the Celestial Intermediate Pole, using the IAU 2000A
precession-nutation model.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- The CIO locator s in radians (Note 2)

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

2. The CIO locator s is the difference between the right ascensions
   of the same point in two systems.  The two systems are the GCRS
   and the CIP,CIO, and the point is the ascending node of the
   CIP equator.  The CIO locator s remains a small fraction of
   1 arcsecond throughout 1900-2100.

3. The series used to compute s is in fact for s+XY/2, where X and Y
   are the x and y components of the CIP unit vector;  this series
   is more compact than a direct series for s would be.  The present
   function uses the full IAU 2000A nutation model when predicting
   the CIP position.  Faster results, with no significant loss of
   accuracy, can be obtained via the function eraS00b, which uses
   instead the IAU 2000B truncated model.

### Called ###

- `eraPnm00a`: classical NPB matrix, IAU 2000A
- `eraBnp2xy`: extract CIP X,Y from the BPN matrix
- `eraS00`: the CIO locator s, given X,Y, IAU 2000A

### References ###

- Capitaine, N., Chapront, J., Lambert, S. and Wallace, P.,
    "Expressions for the Celestial Intermediate Pole and Celestial
    Ephemeris Origin consistent with the IAU 2000A precession-
    nutation model", Astron.Astrophys. 400, 1145-1154 (2003)

- n.b. The celestial ephemeris origin (CEO) was renamed "celestial
    intermediate origin" (CIO) by IAU 2006 Resolution 2.

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

"""
s00a

"""
    s00b(date1, date2)

The CIO locator s, positioning the Celestial Intermediate Origin on
the equator of the Celestial Intermediate Pole, using the IAU 2000B
precession-nutation model.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- The CIO locator s in radians (Note 2)

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

2. The CIO locator s is the difference between the right ascensions
   of the same point in two systems.  The two systems are the GCRS
   and the CIP,CIO, and the point is the ascending node of the
   CIP equator.  The CIO locator s remains a small fraction of
   1 arcsecond throughout 1900-2100.

3. The series used to compute s is in fact for s+XY/2, where X and Y
   are the x and y components of the CIP unit vector;  this series
   is more compact than a direct series for s would be.  The present
   function uses the IAU 2000B truncated nutation model when
   predicting the CIP position.  The function eraS00a uses instead
   the full IAU 2000A model, but with no significant increase in
   accuracy and at some cost in speed.

### Called ###

- `eraPnm00b`: classical NPB matrix, IAU 2000B
- `eraBnp2xy`: extract CIP X,Y from the BPN matrix
- `eraS00`: the CIO locator s, given X,Y, IAU 2000A

### References ###

- Capitaine, N., Chapront, J., Lambert, S. and Wallace, P.,
    "Expressions for the Celestial Intermediate Pole and Celestial
    Ephemeris Origin consistent with the IAU 2000A precession-
    nutation model", Astron.Astrophys. 400, 1145-1154 (2003)

- n.b. The celestial ephemeris origin (CEO) was renamed "celestial
    intermediate origin" (CIO) by IAU 2006 Resolution 2.

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

"""
s00b

"""
    s06a(date1, date2)

The CIO locator s, positioning the Celestial Intermediate Origin on
the equator of the Celestial Intermediate Pole, using the IAU 2006
precession and IAU 2000A nutation models.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- The CIO locator s in radians (Note 2)

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

2. The CIO locator s is the difference between the right ascensions
   of the same point in two systems.  The two systems are the GCRS
   and the CIP,CIO, and the point is the ascending node of the
   CIP equator.  The CIO locator s remains a small fraction of
   1 arcsecond throughout 1900-2100.

3. The series used to compute s is in fact for s+XY/2, where X and Y
   are the x and y components of the CIP unit vector;  this series is
   more compact than a direct series for s would be.  The present
   function uses the full IAU 2000A nutation model when predicting
   the CIP position.

### Called ###

- `eraPnm06a`: classical NPB matrix, IAU 2006/2000A
- `eraBpn2xy`: extract CIP X,Y coordinates from NPB matrix
- `eraS06`: the CIO locator s, given X,Y, IAU 2006

### References ###

- Capitaine, N., Chapront, J., Lambert, S. and Wallace, P.,
    "Expressions for the Celestial Intermediate Pole and Celestial
    Ephemeris Origin consistent with the IAU 2000A precession-
    nutation model", Astron.Astrophys. 400, 1145-1154 (2003)

- n.b. The celestial ephemeris origin (CEO) was renamed "celestial
    intermediate origin" (CIO) by IAU 2006 Resolution 2.

- Capitaine, N. & Wallace, P.T., 2006, Astron.Astrophys. 450, 855

- McCarthy, D. D., Petit, G. (eds.), 2004, IERS Conventions (2003),
    IERS Technical Note No. 32, BKG

- Wallace, P.T. & Capitaine, N., 2006, Astron.Astrophys. 459, 981

"""
s06a

"""
    sp00(date1, date2)

The TIO locator s', positioning the Terrestrial Intermediate Origin
on the equator of the Celestial Intermediate Pole.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- The TIO locator s' in radians (Note 2)

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

2. The TIO locator s' is obtained from polar motion observations by
   numerical integration, and so is in essence unpredictable.
   However, it is dominated by a secular drift of about
   47 microarcseconds per century, which is the approximation
   evaluated by the present function.

### Reference ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

"""
sp00

for name in ("s00a",
             "s00b",
             "s06a",
             "sp00")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval ($f)(d1, d2) = ccall(($fc, liberfa), Cdouble, (Cdouble, Cdouble), d1, d2)
end

"""
    s00(date1, date2, x, y)

The CIO locator s, positioning the Celestial Intermediate Origin on
the equator of the Celestial Intermediate Pole, given the CIP's X,Y
coordinates.  Compatible with IAU 2000A precession-nutation.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)
- `x`, `y`: CIP coordinates (Note 3)

### Returned ###

- The CIO locator s in radians (Note 2)

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

2. The CIO locator s is the difference between the right ascensions
   of the same point in two systems:  the two systems are the GCRS
   and the CIP,CIO, and the point is the ascending node of the
   CIP equator.  The quantity s remains below 0.1 arcsecond
   throughout 1900-2100.

3. The series used to compute s is in fact for s+XY/2, where X and Y
   are the x and y components of the CIP unit vector;  this series
   is more compact than a direct series for s would be.  This
   function requires X,Y to be supplied by the caller, who is
   responsible for providing values that are consistent with the
   supplied date.

4. The model is consistent with the IAU 2000A precession-nutation.

### Called ###

- `eraFal03`: mean anomaly of the Moon
- `eraFalp03`: mean anomaly of the Sun
- `eraFaf03`: mean argument of the latitude of the Moon
- `eraFad03`: mean elongation of the Moon from the Sun
- `eraFaom03`: mean longitude of the Moon's ascending node
- `eraFave03`: mean longitude of Venus
- `eraFae03`: mean longitude of Earth
- `eraFapa03`: general accumulated precession in longitude

### References ###

- Capitaine, N., Chapront, J., Lambert, S. and Wallace, P.,
    "Expressions for the Celestial Intermediate Pole and Celestial
    Ephemeris Origin consistent with the IAU 2000A precession-
    nutation model", Astron.Astrophys. 400, 1145-1154 (2003)

- n.b. The celestial ephemeris origin (CEO) was renamed "celestial
    intermediate origin" (CIO) by IAU 2006 Resolution 2.

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

"""
s00

"""
    s06(date1, date2, x, y)

The CIO locator s, positioning the Celestial Intermediate Origin on
the equator of the Celestial Intermediate Pole, given the CIP's X,Y
coordinates.  Compatible with IAU 2006/2000A precession-nutation.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)
- `x`, `y`: CIP coordinates (Note 3)

### Returned ###

- The CIO locator s in radians (Note 2)

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

2. The CIO locator s is the difference between the right ascensions
   of the same point in two systems:  the two systems are the GCRS
   and the CIP,CIO, and the point is the ascending node of the
   CIP equator.  The quantity s remains below 0.1 arcsecond
   throughout 1900-2100.

3. The series used to compute s is in fact for s+XY/2, where X and Y
   are the x and y components of the CIP unit vector;  this series
   is more compact than a direct series for s would be.  This
   function requires X,Y to be supplied by the caller, who is
   responsible for providing values that are consistent with the
   supplied date.

4. The model is consistent with the "P03" precession (Capitaine et
   al. 2003), adopted by IAU 2006 Resolution 1, 2006, and the
   IAU 2000A nutation (with P03 adjustments).

### Called ###

- `eraFal03`: mean anomaly of the Moon
- `eraFalp03`: mean anomaly of the Sun
- `eraFaf03`: mean argument of the latitude of the Moon
- `eraFad03`: mean elongation of the Moon from the Sun
- `eraFaom03`: mean longitude of the Moon's ascending node
- `eraFave03`: mean longitude of Venus
- `eraFae03`: mean longitude of Earth
- `eraFapa03`: general accumulated precession in longitude

### References ###

- Capitaine, N., Wallace, P.T. & Chapront, J., 2003, Astron.
    Astrophys. 432, 355

- McCarthy, D.D., Petit, G. (eds.) 2004, IERS Conventions (2003),
    IERS Technical Note No. 32, BKG

"""
s06

for name in ("s00",
             "s06")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval ($f)(d1, d2, t1, t2) = ccall(($fc, liberfa), Cdouble, (Cdouble, Cdouble, Cdouble, Cdouble), d1, d2, t1, t2)
end
