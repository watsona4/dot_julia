"""
    eform(n::Ellipsoid)

Earth reference ellipsoids.

### Given ###

- `n`: Ellipsoid identifier (Note 1)

### Returned ###

- `a`: Equatorial radius (meters, Note 2)
- `f`: Flattening (Note 2)

### Notes ###

1. The identifier n is a number that specifies the choice of
   reference ellipsoid.  The following are supported:

        - `WGS84`
        - `GRS80`
        - `WGS72`

2. The ellipsoid parameters are returned in the form of equatorial
   radius in meters (a) and flattening (f).  The latter is a number
   around 0.00335, i.e. around 1/298.

3. For the case where an unsupported n value is supplied, zero a and
   f are returned, as well as error status.

### References ###

- Department of Defense World Geodetic System 1984, National
    Imagery and Mapping Agency Technical Report 8350.2, Third
    Edition, p3-2.

- Moritz, H., Bull. Geodesique 66-2, 187 (1992).

- The Department of Defense World Geodetic System 1972, World
    Geodetic System Committee, May 1974.

- Explanatory Supplement to the Astronomical Almanac,
    P. Kenneth Seidelmann (ed), University Science Books (1992),
    p220.

"""
function eform(n::Ellipsoid)
    a = Ref(0.0)
    f = Ref(0.0)
    i = ccall((:eraEform, liberfa), Cint,
              (Cint, Ref{Cdouble}, Ref{Cdouble}),
              n, a, f)
    if i == -1
        throw(ERFAException("illegal identifier"))
    end
    a[], f[]
end

"""
    eors(rnpb, s)

Equation of the origins, given the classical NPB matrix and the
quantity s.

### Given ###

- `rnpb`: Classical nutation x precession x bias matrix
- `s`: The quantity s (the CIO locator)

### Returned ###

- The equation of the origins in radians.

### Notes ###

1.  The equation of the origins is the distance between the true
    equinox and the celestial intermediate origin and, equivalently,
    the difference between Earth rotation angle and Greenwich
    apparent sidereal time (ERA-GST).  It comprises the precession
    (since J2000.0) in right ascension plus the equation of the
    equinoxes (including the small correction terms).

2.  The algorithm is from Wallace & Capitaine (2006).

### References ###

- Capitaine, N. & Wallace, P.T., 2006, Astron.Astrophys. 450, 855

- Wallace, P. & Capitaine, N., 2006, Astron.Astrophys. 459, 981

"""
function eors(rnpb, s)
    ccall((:eraEors, liberfa), Cdouble,
          (Ptr{Cdouble}, Cdouble),
          rnpb, s)
end

"""
    epv00(date1, date2)

Earth position and velocity, heliocentric and barycentric, with
respect to the Barycentric Celestial Reference System.

### Given ###

- `date1`, `date2`: TDB date (Note 1)

### Returned ###

- `pvh`: Heliocentric Earth position/velocity
- `pvb`: Barycentric Earth position/velocity

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
   good compromises between resolution and convenience.  However,
   the accuracy of the result is more likely to be limited by the
   algorithm itself than the way the date has been expressed.

   n.b. TT can be used instead of TDB in most applications.

2. On return, the arrays pvh and pvb contain the following:

      pvh[0][0]  x       }
      pvh[0][1]  y       } heliocentric position, au
      pvh[0][2]  z       }

      pvh[1][0]  xdot    }
      pvh[1][1]  ydot    } heliocentric velocity, au/d
      pvh[1][2]  zdot    }

      pvb[0][0]  x       }
      pvb[0][1]  y       } barycentric position, au
      pvb[0][2]  z       }

      pvb[1][0]  xdot    }
      pvb[1][1]  ydot    } barycentric velocity, au/d
      pvb[1][2]  zdot    }

   The vectors are with respect to the Barycentric Celestial
   Reference System.  The time unit is one day in TDB.

3. The function is a SIMPLIFIED SOLUTION from the planetary theory
   VSOP2000 (X. Moisson, P. Bretagnon, 2001, Celes. Mechanics &
   Dyn. Astron., 80, 3/4, 205-213) and is an adaptation of original
   Fortran code supplied by P. Bretagnon (private comm., 2000).

4. Comparisons over the time span 1900-2100 with this simplified
   solution and the JPL DE405 ephemeris give the following results:

                              RMS    max
         Heliocentric:
            position error    3.7   11.2   km
            velocity error    1.4    5.0   mm/s

         Barycentric:
            position error    4.6   13.4   km
            velocity error    1.4    4.9   mm/s

   Comparisons with the JPL DE406 ephemeris show that by 1800 and
   2200 the position errors are approximately double their 1900-2100
   size.  By 1500 and 2500 the deterioration is a factor of 10 and
   by 1000 and 3000 a factor of 60.  The velocity accuracy falls off
   at about half that rate.

5. It is permissible to use the same array for pvh and pvb, which
   will receive the barycentric values.

"""
function epv00(date1, date2)
    pvh = zeros((2, 3))
    pvb = zeros((2, 3))
    i = ccall((:eraEpv00, liberfa),
              Cint,
              (Cdouble, Cdouble, Ptr{Cdouble}, Ptr{Cdouble}),
              date1, date2, pvh, pvb)
    if i == 1
        @warn "date outside the range 1900-2100 AD"
    end
    pvh, pvb
end

"""
    eceq06(date1, date2, dl, db)

Transformation from ecliptic coordinates (mean equinox and ecliptic
of date) to ICRS RA,Dec, using the IAU 2006 precession model.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian date (Note 1)
- `dl`, `db`: Ecliptic longitude and latitude (radians)

### Returned ###

- `dr`, `dd`: ICRS right ascension and declination (radians)

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

2. No assumptions are made about whether the coordinates represent
   starlight and embody astrometric effects such as parallax or
   aberration.

3. The transformation is approximately that from ecliptic longitude
   and latitude (mean equinox and ecliptic of date) to mean J2000.0
   right ascension and declination, with only frame bias (always
   less than 25 mas) to disturb this classical picture.

### Called ###

- `eraS2c`: spherical coordinates to unit vector
- `eraEcm06`: J2000.0 to ecliptic rotation matrix, IAU 2006
- `eraTrxp`: product of transpose of r-matrix and p-vector
- `eraC2s`: unit vector to spherical coordinates
- `eraAnp`: normalize angle into range 0 to 2pi
- `eraAnpm`: normalize angle into range +/- pi

"""
eceq06

"""
    eqec06(date1, date2, dr, dd)

Transformation from ICRS equatorial coordinates to ecliptic
coordinates (mean equinox and ecliptic of date) using IAU 2006
precession model.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian date (Note 1)
- `dr`, `dd`: ICRS right ascension and declination (radians)

### Returned ###

- `dl`, `db`: Ecliptic longitude and latitude (radians)

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

2. No assumptions are made about whether the coordinates represent
   starlight and embody astrometric effects such as parallax or
   aberration.

3. The transformation is approximately that from mean J2000.0 right
   ascension and declination to ecliptic longitude and latitude
   (mean equinox and ecliptic of date), with only frame bias (always
   less than 25 mas) to disturb this classical picture.

### Called ###

- `eraS2c`: spherical coordinates to unit vector
- `eraEcm06`: J2000.0 to ecliptic rotation matrix, IAU 2006
- `eraRxp`: product of r-matrix and p-vector
- `eraC2s`: unit vector to spherical coordinates
- `eraAnp`: normalize angle into range 0 to 2pi
- `eraAnpm`: normalize angle into range +/- pi

"""
eqec06

for name in ("eceq06",
             "eqec06")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(date1, date2, d1, d2)
            r1 = [0.0]
            r2 = [0.0]
            ccall(($fc, liberfa), Cvoid,
                  (Cdouble, Cdouble, Cdouble, Cdouble, Ptr{Cdouble}, Ptr{Cdouble}),
                  date1, date2, d1, d2, r1, r2)
            r1[1], r2[1]
        end
    end
end

"""
    epb2jd(epj)

Besselian Epoch to Julian Date.

### Given ###

- `epb`: Besselian Epoch (e.g. 1957.3)

### Returned ###

- `djm0`: MJD zero-point: always 2400000.5
- `djm`: Modified Julian Date

### Note ###

   The Julian Date is returned in two pieces, in the usual ERFA
   manner, which is designed to preserve time resolution.  The
   Julian Date is available as a single number by adding djm0 and
   djm.

### Reference ###

- Lieske, J.H., 1979, Astron.Astrophys. 73, 282.

"""
epb2jd

"""
    epj2jd(epj)

Julian Epoch to Julian Date.

### Given ###

- `epj`: Julian Epoch (e.g. 1996.8)

### Returned ###

- `djm0`: MJD zero-point: always 2400000.5
- `djm`: Modified Julian Date

### Note ###

   The Julian Date is returned in two pieces, in the usual ERFA
   manner, which is designed to preserve time resolution.  The
   Julian Date is available as a single number by adding djm0 and
   djm.

### Reference ###

- Lieske, J.H., 1979, Astron.Astrophys. 73, 282.

"""
epj2jd

for name in ("epb2jd",
             "epj2jd")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(d)
            r1 = Ref(0.0)
            r2 = Ref(0.0)
            ccall(($fc, liberfa), Cvoid,
                  (Cdouble, Ref{Cdouble}, Ref{Cdouble}),
                  d, r1, r2)
            r1[], r2[]
        end
    end
end

"""
    ee00a(dj1, dj2)

Equation of the equinoxes, compatible with IAU 2000 resolutions.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- Equation of the equinoxes (Note 2)

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

2. The result, which is in radians, operates in the following sense:

      Greenwich apparent ST = GMST + equation of the equinoxes

3. The result is compatible with the IAU 2000 resolutions.  For
   further details, see IERS Conventions 2003 and Capitaine et al.
   (2002).

### Called ###

- `eraPr00`: IAU 2000 precession adjustments
- `eraObl80`: mean obliquity, IAU 1980
- `eraNut00a`: nutation, IAU 2000A
- `eraEe00`: equation of the equinoxes, IAU 2000

### References ###

- Capitaine, N., Wallace, P.T. and McCarthy, D.D., "Expressions to
    implement the IAU 2000 definition of UT1", Astronomy &
    Astrophysics, 406, 1135-1149 (2003).

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004).

"""
ee00a

"""
    ee00b(dj1, dj2)

Equation of the equinoxes, compatible with IAU 2000 resolutions but
using the truncated nutation model IAU 2000B.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- Equation of the equinoxes (Note 2)

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

2. The result, which is in radians, operates in the following sense:

      Greenwich apparent ST = GMST + equation of the equinoxes

3. The result is compatible with the IAU 2000 resolutions except
   that accuracy has been compromised for the sake of speed.  For
   further details, see McCarthy & Luzum (2001), IERS Conventions
   2003 and Capitaine et al. (2003).

### Called ###

- `eraPr00`: IAU 2000 precession adjustments
- `eraObl80`: mean obliquity, IAU 1980
- `eraNut00b`: nutation, IAU 2000B
- `eraEe00`: equation of the equinoxes, IAU 2000

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
ee00b

"""
    ee06a(dj1, dj2)

Equation of the equinoxes, compatible with IAU 2000 resolutions and
IAU 2006/2000A precession-nutation.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- Equation of the equinoxes (Note 2)

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

2. The result, which is in radians, operates in the following sense:

      Greenwich apparent ST = GMST + equation of the equinoxes

### Called ###

- `eraAnpm`: normalize angle into range +/- pi
- `eraGst06a`: Greenwich apparent sidereal time, IAU 2006/2000A
- `eraGmst06`: Greenwich mean sidereal time, IAU 2006

### Reference ###

- McCarthy, D. D., Petit, G. (eds.), 2004, IERS Conventions (2003),
    IERS Technical Note No. 32, BKG

"""
ee06a

"""
    eect00(date1, date2)

Equation of the equinoxes complementary terms, consistent with
IAU 2000 resolutions.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- Complementary terms (Note 2)

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

2. The "complementary terms" are part of the equation of the
   equinoxes (EE), classically the difference between apparent and
   mean Sidereal Time:

      GAST = GMST + EE

   with:

      EE = dpsi * cos(eps)

   where dpsi is the nutation in longitude and eps is the obliquity
   of date.  However, if the rotation of the Earth were constant in
   an inertial frame the classical formulation would lead to
   apparent irregularities in the UT1 timescale traceable to side-
   effects of precession-nutation.  In order to eliminate these
   effects from UT1, "complementary terms" were introduced in 1994
   (IAU, 1994) and took effect from 1997 (Capitaine and Gontier,
   1993):

      GAST = GMST + CT + EE

   By convention, the complementary terms are included as part of
   the equation of the equinoxes rather than as part of the mean
   Sidereal Time.  This slightly compromises the "geometrical"
   interpretation of mean sidereal time but is otherwise
   inconsequential.

   The present function computes CT in the above expression,
   compatible with IAU 2000 resolutions (Capitaine et al., 2002, and
   IERS Conventions 2003).

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

- Capitaine, N. & Gontier, A.-M., Astron. Astrophys., 275,
    645-650 (1993)

- Capitaine, N., Wallace, P.T. and McCarthy, D.D., "Expressions to
    implement the IAU 2000 definition of UT1", Astronomy &
    Astrophysics, 406, 1135-1149 (2003)

- IAU Resolution C7, Recommendation 3 (1994)

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

"""
eect00

"""
    eo06a(date1, date2)

Equation of the origins, IAU 2006 precession and IAU 2000A nutation.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- Equation of the origins in radians

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

2. The equation of the origins is the distance between the true
   equinox and the celestial intermediate origin and, equivalently,
   the difference between Earth rotation angle and Greenwich
   apparent sidereal time (ERA-GST).  It comprises the precession
   (since J2000.0) in right ascension plus the equation of the
   equinoxes (including the small correction terms).

### Called ###

- `eraPnm06a`: classical NPB matrix, IAU 2006/2000A
- `eraBpn2xy`: extract CIP X,Y coordinates from NPB matrix
- `eraS06`: the CIO locator s, given X,Y, IAU 2006
- `eraEors`: equation of the origins, given NPB matrix and s

### References ###

- Capitaine, N. & Wallace, P.T., 2006, Astron.Astrophys. 450, 855

- Wallace, P.T. & Capitaine, N., 2006, Astron.Astrophys. 459, 981

"""
eo06a

"""
    epb(dj1, dj2)

Julian Date to Besselian Epoch.

### Given ###

- `dj1`, `dj2`: Julian Date (see note)

### Returned ###

- Besselian Epoch.

### Note ###

   The Julian Date is supplied in two pieces, in the usual ERFA
   manner, which is designed to preserve time resolution.  The
   Julian Date is available as a single number by adding dj1 and
   dj2.  The maximum resolution is achieved if dj1 is 2451545.0
   (J2000.0).

### Reference ###

- Lieske, J.H., 1979. Astron.Astrophys., 73, 282.

"""
epb

"""
    epj(dj1, dj2)

Julian Date to Julian Epoch.

### Given ###

- `dj1`, `dj2`: Julian Date (see note)

### Returned ###

- Julian Epoch

### Note ###

   The Julian Date is supplied in two pieces, in the usual ERFA
   manner, which is designed to preserve time resolution.  The
   Julian Date is available as a single number by adding dj1 and
   dj2.  The maximum resolution is achieved if dj1 is 2451545.0
   (J2000.0).

### Reference ###

- Lieske, J.H., 1979, Astron.Astrophys. 73, 282.

"""
epj

"""
    eqeq94(date1, date2)

Equation of the equinoxes, IAU 1994 model.

### Given ###

- `date1`, `date2`: TDB date (Note 1)

### Returned ###

- Equation of the equinoxes (Note 2)

### Notes ###

1. The date date1+date2 is a Julian Date, apportioned in any
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

2. The result, which is in radians, operates in the following sense:

      Greenwich apparent ST = GMST + equation of the equinoxes

### Called ###

- `eraAnpm`: normalize angle into range +/- pi
- `eraNut80`: nutation, IAU 1980
- `eraObl80`: mean obliquity, IAU 1980

### References ###

- IAU Resolution C7, Recommendation 3 (1994).

- Capitaine, N. & Gontier, A.-M., 1993, Astron. Astrophys., 275,
    645-650.

"""
eqeq94

"""
    era00(dj1, dj2)

Earth rotation angle (IAU 2000 model).

### Given ###

- `dj1`, `dj2`: UT1 as a 2-part Julian Date (see note)

### Returned ###

- Earth rotation angle (radians), range 0-2pi

### Notes ###

1. The UT1 date dj1+dj2 is a Julian Date, apportioned in any
   convenient way between the arguments dj1 and dj2.  For example,
   JD(UT1)=2450123.7 could be expressed in any of these ways,
   among others:

           dj1            dj2

       2450123.7           0.0       (JD method)
       2451545.0       -1421.3       (J2000 method)
       2400000.5       50123.2       (MJD method)
       2450123.5           0.2       (date & time method)

   The JD method is the most natural and convenient to use in
   cases where the loss of several decimal digits of resolution
   is acceptable.  The J2000 and MJD methods are good compromises
   between resolution and convenience.  The date & time method is
   best matched to the algorithm used:  maximum precision is
   delivered when the dj1 argument is for 0hrs UT1 on the day in
   question and the dj2 argument lies in the range 0 to 1, or vice
   versa.

2. The algorithm is adapted from Expression 22 of Capitaine et al.
   2000.  The time argument has been expressed in days directly,
   and, to retain precision, integer contributions have been
   eliminated.  The same formulation is given in IERS Conventions
   (2003), Chap. 5, Eq. 14.

### Called ###

- `eraAnp`: normalize angle into range 0 to 2pi

### References ###

- Capitaine N., Guinot B. and McCarthy D.D, 2000, Astron.
    Astrophys., 355, 398-405.

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

"""
era00

for name in ("ee00a",
             "ee00b",
             "ee06a",
             "eect00",
             "eo06a",
             "epb",
             "epj",
             "eqeq94",
             "era00")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval ($f)(d1, d2) = ccall(($fc, liberfa), Cdouble, (Cdouble, Cdouble), d1, d2)
end

"""
    ee00(date1, date2, epsa, dpsi)

The equation of the equinoxes, compatible with IAU 2000 resolutions,
given the nutation in longitude and the mean obliquity.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)
- `epsa`: Mean obliquity (Note 2)
- `dpsi`: Nutation in longitude (Note 3)

### Returned ###

- Equation of the equinoxes (Note 4)

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

2. The obliquity, in radians, is mean of date.

3. The result, which is in radians, operates in the following sense:

      Greenwich apparent ST = GMST + equation of the equinoxes

4. The result is compatible with the IAU 2000 resolutions.  For
   further details, see IERS Conventions 2003 and Capitaine et al.
   (2002).

### Called ###

- `eraEect00`: equation of the equinoxes complementary terms

### References ###

- Capitaine, N., Wallace, P.T. and McCarthy, D.D., "Expressions to
    implement the IAU 2000 definition of UT1", Astronomy &
    Astrophysics, 406, 1135-1149 (2003)

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

"""
ee00(date1, date2, epsa, dpsi) = ccall((:eraEe00, liberfa), Cdouble, (Cdouble, Cdouble, Cdouble, Cdouble), date1, date2, epsa, dpsi)

"""
    ecm06(date1, date2)

ICRS equatorial to ecliptic rotation matrix, IAU 2006.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian date (Note 1)

### Returned ###

- `rm`: ICRS to ecliptic rotation matrix

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

1. The matrix is in the sense

      E_ep = rm x P_ICRS,

   where P_ICRS is a vector with respect to ICRS right ascension
   and declination axes and E_ep is the same vector with respect to
   the (inertial) ecliptic and equinox of date.

2. P_ICRS is a free vector, merely a direction, typically of unit
   magnitude, and not bound to any particular spatial origin, such
   as the Earth, Sun or SSB.  No assumptions are made about whether
   it represents starlight and embodies astrometric effects such as
   parallax or aberration.  The transformation is approximately that
   between mean J2000.0 right ascension and declination and ecliptic
   longitude and latitude, with only frame bias (always less than
   25 mas) to disturb this classical picture.

### Called ###

- `eraObl06`: mean obliquity, IAU 2006
- `eraPmat06`: PB matrix, IAU 2006
- `eraIr`: initialize r-matrix to identity
- `eraRx`: rotate around X-axis
- `eraRxr`: product of two r-matrices

"""
function ecm06(date1, date2)
    r = zeros((3, 3))
    ccall((:eraEcm06, liberfa), Cvoid,
            (Cdouble, Cdouble, Ptr{Cdouble}),
            date1, date2, r)
    r
end
