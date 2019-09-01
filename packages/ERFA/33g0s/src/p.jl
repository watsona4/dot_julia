"""
    pmpx(rc, dc, pr, pd, px, rv, pmt, vob)

Proper motion and parallax.

### Given ###

- `rc`, `dc`: ICRS RA,Dec at catalog epoch (radians)
- `pr`: RA proper motion (radians/year; Note 1)
- `pd`: Dec proper motion (radians/year)
- `px`: Parallax (arcsec)
- `rv`: Radial velocity (km/s, +ve if receding)
- `pmt`: Proper motion time interval (SSB, Julian years)
- `pob`: SSB to observer vector (au)

### Returned ###

- `pco`: Coordinate direction (BCRS unit vector)

### Notes ###

1. The proper motion in RA is dRA/dt rather than cos(Dec)*dRA/dt.

2. The proper motion time interval is for when the starlight
   reaches the solar system barycenter.

3. To avoid the need for iteration, the Roemer effect (i.e. the
   small annual modulation of the proper motion coming from the
   changing light time) is applied approximately, using the
   direction of the star at the catalog epoch.

### References ###

- 1984 Astronomical Almanac, pp B39-B41.

- Urban, S. & Seidelmann, P. K. (eds), Explanatory Supplement to
    the Astronomical Almanac, 3rd ed., University Science Books
    (2013), Section 7.2.

### Called ###

- `eraPdp`: scalar product of two p-vectors
- `eraPn`: decompose p-vector into modulus and direction

"""
function pmpx(rc, dc, pr, pd, px, rv, pmt, vob)
    pco = zeros(3)
    ccall((:eraPmpx, liberfa), Cvoid,
          (Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ptr{Cdouble}, Ptr{Cdouble}),
          rc, dc, pr, pd, px, rv, pmt, vob, pco)
    pco
end

"""
    p06e(date1, date2)

Precession angles, IAU 2006, equinox based.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned (see Note 2) ###

- `eps0`: epsilon_0
- `psia`: psi_A
- `oma`: omega_A
- `bpa`: P_A
- `bqa`: Q_A
- `pia`: pi_A
- `bpia`: Pi_A
- `epsa`: obliquity epsilon_A
- `chia`: chi_A
- `za`: z_A
- `zetaa`: zeta_A
- `thetaa`: theta_A
- `pa`: p_A
- `gam`: F-W angle gamma_J2000
- `phi`: F-W angle phi_J2000
- `psi`: F-W angle psi_J2000

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

2. This function returns the set of equinox based angles for the
   Capitaine et al. "P03" precession theory, adopted by the IAU in
   2006.  The angles are set out in Table 1 of Hilton et al. (2006):

   eps0   epsilon_0   obliquity at J2000.0
   psia   psi_A       luni-solar precession
   oma    omega_A     inclination of equator wrt J2000.0 ecliptic
   bpa    P_A         ecliptic pole x, J2000.0 ecliptic triad
   bqa    Q_A         ecliptic pole -y, J2000.0 ecliptic triad
   pia    pi_A        angle between moving and J2000.0 ecliptics
   bpia   Pi_A        longitude of ascending node of the ecliptic
   epsa   epsilon_A   obliquity of the ecliptic
   chia   chi_A       planetary precession
   za     z_A         equatorial precession: -3rd 323 Euler angle
   zetaa  zeta_A      equatorial precession: -1st 323 Euler angle
   thetaa theta_A     equatorial precession: 2nd 323 Euler angle
   pa     p_A         general precession
   gam    gamma_J2000 J2000.0 RA difference of ecliptic poles
   phi    phi_J2000   J2000.0 codeclination of ecliptic pole
   psi    psi_J2000   longitude difference of equator poles, J2000.0

   The returned values are all radians.

3. Hilton et al. (2006) Table 1 also contains angles that depend on
   models distinct from the P03 precession theory itself, namely the
   IAU 2000A frame bias and nutation.  The quoted polynomials are
   used in other ERFA functions:

   . eraXy06  contains the polynomial parts of the X and Y series.

   . eraS06  contains the polynomial part of the s+XY/2 series.

   . eraPfw06  implements the series for the Fukushima-Williams
     angles that are with respect to the GCRS pole (i.e. the variants
     that include frame bias).

4. The IAU resolution stipulated that the choice of parameterization
   was left to the user, and so an IAU compliant precession
   implementation can be constructed using various combinations of
   the angles returned by the present function.

5. The parameterization used by ERFA is the version of the Fukushima-
   Williams angles that refers directly to the GCRS pole.  These
   angles may be calculated by calling the function eraPfw06.  ERFA
   also supports the direct computation of the CIP GCRS X,Y by
   series, available by calling eraXy06.

6. The agreement between the different parameterizations is at the
   1 microarcsecond level in the present era.

7. When constructing a precession formulation that refers to the GCRS
   pole rather than the dynamical pole, it may (depending on the
   choice of angles) be necessary to introduce the frame bias
   explicitly.

8. It is permissible to re-use the same variable in the returned
   arguments.  The quantities are stored in the stated order.

### Reference ###

- Hilton, J. et al., 2006, Celest.Mech.Dyn.Astron. 94, 351

### Called ###

- `eraObl06`: mean obliquity, IAU 2006

"""
function p06e(date1, date2)
    eps0 = Ref(0.0)
    psia = Ref(0.0)
    oma = Ref(0.0)
    bpa = Ref(0.0)
    bqa = Ref(0.0)
    pia = Ref(0.0)
    bpia = Ref(0.0)
    epsa = Ref(0.0)
    chia = Ref(0.0)
    za = Ref(0.0)
    zetaa = Ref(0.0)
    thetaa = Ref(0.0)
    pa = Ref(0.0)
    gam = Ref(0.0)
    phi = Ref(0.0)
    psi = Ref(0.0)
    ccall((:eraP06e, liberfa), Cvoid,
          (Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble},
          Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
          date1, date2, eps0, psia, oma, bpa, bqa, pia, bpia, epsa, chia, za, zetaa, thetaa, pa, gam, phi, psi)
    eps0[], psia[], oma[], bpa[], bqa[], pia[], bpia[], epsa[], chia[], za[], zetaa[], thetaa[], pa[], gam[], phi[], psi[]
end

"""
    p2s(p)

P-vector to spherical polar coordinates.

### Given ###

- `p`: P-vector

### Returned ###

- `theta`: Longitude angle (radians)
- `phi`: Latitude angle (radians)
- `r`: Radial distance

### Notes ###

1. If P is null, zero theta, phi and r are returned.

2. At either pole, zero theta is returned.

### Called ###

- `eraC2s`: p-vector to spherical
- `eraPm`: modulus of p-vector

"""
function p2s(p)
    theta = Ref(0.0)
    phi = Ref(0.0)
    r = Ref(0.0)
    ccall((:eraP2s, liberfa), Cvoid,
          (Ptr{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
          p, theta, phi, r)
    theta[], phi[], r[]
end

"""
    p2pv(p)

Extend a p-vector to a pv-vector by appending a zero velocity.

### Given ###

- `p`: P-vector

### Returned ###

- `pv`: Pv-vector

### Called ###

- `eraCp`: copy p-vector
- `eraZp`: zero p-vector

"""
function p2pv(p)
    pv = zeros((2, 3))
    ccall((:eraP2pv, liberfa), Cvoid,
          (Ptr{Cdouble}, Ptr{Cdouble}),
          p, pv)
    pv
end

"""
    pb06(date1, date2)

This function forms three Euler angles which implement general
precession from epoch J2000.0, using the IAU 2006 model.  Frame
bias (the offset between ICRS and mean J2000.0) is included.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `bzeta`: 1st rotation: radians cw around z
- `bz`: 3rd rotation: radians cw around z
- `btheta`: 2nd rotation: radians ccw around y

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

2. The traditional accumulated precession angles zeta_A, z_A,
   theta_A cannot be obtained in the usual way, namely through
   polynomial expressions, because of the frame bias.  The latter
   means that two of the angles undergo rapid changes near this
   date.  They are instead the results of decomposing the
   precession-bias matrix obtained by using the Fukushima-Williams
   method, which does not suffer from the problem.  The
   decomposition returns values which can be used in the
   conventional formulation and which include frame bias.

3. The three angles are returned in the conventional order, which
   is not the same as the order of the corresponding Euler
   rotations.  The precession-bias matrix is
   R_3(-z) x R_2(+theta) x R_3(-zeta).

4. Should zeta_A, z_A, theta_A angles be required that do not
   contain frame bias, they are available by calling the ERFA
   function eraP06e.

### Called ###

- `eraPmat06`: PB matrix, IAU 2006
- `eraRz`: rotate around Z-axis

"""
function pb06(date1, date2)
    bzeta = Ref(0.0)
    bz = Ref(0.0)
    btheta = Ref(0.0)
    ccall((:eraPb06, liberfa), Cvoid,
          (Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
          date1, date2, bzeta, bz, btheta)
    bzeta[], bz[], btheta[]
end


"""
    pfw06(date1, date2)

Precession angles, IAU 2006 (Fukushima-Williams 4-angle formulation).

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `gamb`: F-W angle gamma_bar (radians)
- `phib`: F-W angle phi_bar (radians)
- `psib`: F-W angle psi_bar (radians)
- `epsa`: F-W angle epsilon_A (radians)

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

2. Naming the following points:

         e = J2000.0 ecliptic pole,
         p = GCRS pole,
         E = mean ecliptic pole of date,
   and   P = mean pole of date,

   the four Fukushima-Williams angles are as follows:

      gamb = gamma_bar = epE
      phib = phi_bar = pE
      psib = psi_bar = pEP
      epsa = epsilon_A = EP

3. The matrix representing the combined effects of frame bias and
   precession is:

      PxB = R_1(-epsa).R_3(-psib).R_1(phib).R_3(gamb)

4. The matrix representing the combined effects of frame bias,
   precession and nutation is simply:

      NxPxB = R_1(-epsa-dE).R_3(-psib-dP).R_1(phib).R_3(gamb)

   where dP and dE are the nutation components with respect to the
   ecliptic of date.

### Reference ###

- Hilton, J. et al., 2006, Celest.Mech.Dyn.Astron. 94, 351

### Called ###

- `eraObl06`: mean obliquity, IAU 2006

"""
function pfw06(date1, date2)
    gamb = Ref(0.0)
    phib = Ref(0.0)
    psib = Ref(0.0)
    epsa = Ref(0.0)
    ccall((:eraPfw06, liberfa), Cvoid,
          (Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
          date1, date2, gamb, phib, psib, epsa)
    gamb[], phib[], psib[], epsa[]
end

"""
    plan94(date1, date2, np)

Approximate heliocentric position and velocity of a nominated major
planet:  Mercury, Venus, EMB, Mars, Jupiter, Saturn, Uranus or
Neptune (but not the Earth itself).

### Given ###

- `date1`: TDB date part A (Note 1)
- `date2`: TDB date part B (Note 1)
- `np`: Planet (1=Mercury, 2=Venus, 3=EMB, 4=Mars,
                           5=Jupiter, 6=Saturn, 7=Uranus, 8=Neptune)

### Returned (argument) ###

- Planet `p,v` (heliocentric, J2000.0, au,au/d)

### Notes ###

1. The date date1+date2 is in the TDB time scale (in practice TT can
   be used) and is a Julian Date, apportioned in any convenient way
   between the two arguments.  For example, JD(TDB)=2450123.7 could
   be expressed in any of these ways, among others:

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
   good compromises between resolution and convenience.  The limited
   accuracy of the present algorithm is such that any of the methods
   is satisfactory.

2. If an np value outside the range 1-8 is supplied, an error status
   (function value -1) is returned and the pv vector set to zeroes.

3. For np=3 the result is for the Earth-Moon Barycenter.  To obtain
   the heliocentric position and velocity of the Earth, use instead
   the ERFA function eraEpv00.

4. On successful return, the arrays `p` and `v` contain the following:

   - `p`: heliocentric position, au
   - `v`: heliocentric velocity, au/d

   The reference frame is equatorial and is with respect to the
   mean equator and equinox of epoch J2000.0.

5. The algorithm is due to J.L. Simon, P. Bretagnon, J. Chapront,
   M. Chapront-Touze, G. Francou and J. Laskar (Bureau des
   Longitudes, Paris, France).  From comparisons with JPL
   ephemeris DE102, they quote the following maximum errors
   over the interval 1800-2050:

   | Body          | L (arcsec)  | B (arcsec) | R (km) |
   |:--------------|:------------|:-----------|:-------|
   | Mercury       |  4          |  1         | 300    |
   | Venus         |  5          |  1         | 800    |
   | EMB           |  6          |  1         | 1000   |
   | Mars          | 17          |  1         | 7700   |
   | Jupiter       | 71          |  5         | 76000  |
   | Saturn        | 81          | 13         | 267000 |
   | Uranus        | 86          |  7         | 712000 |
   | Neptune       | 11          |  1         | 253000 |

   Over the interval 1000-3000, they report that the accuracy is no
   worse than 1.5 times that over 1800-2050.  Outside 1000-3000 the
   accuracy declines.

   Comparisons of the present function with the JPL DE200 ephemeris
   give the following RMS errors over the interval 1960-2025:

   | Body         | position (km)   | velocity (m/s) |
   |:-------------|:----------------|:---------------|
   |  Mercury     |      334        |      0.437     |
   |  Venus       |     1060        |      0.855     |
   |  EMB         |     2010        |      0.815     |
   |  Mars        |     7690        |      1.98      |
   |  Jupiter     |    71700        |      7.70      |
   |  Saturn      |   199000        |     19.4       |
   |  Uranus      |   564000        |     16.4       |
   |  Neptune     |   158000        |     14.4       |

   Comparisons against DE200 over the interval 1800-2100 gave the
   following maximum absolute differences.  (The results using
   DE406 were essentially the same.)

   | Body      | L (arcsec) | B (arcsec)  |  R (km) | Rdot (m/s) |
   |:----------|:-----------|:------------|:--------|:-----------|
   |  Mercury  |     7      |     1       |    500  |    0.7     |
   |  Venus    |     7      |     1       |   1100  |    0.9     |
   |  EMB      |     9      |     1       |   1300  |    1.0     |
   |  Mars     |    26      |     1       |   9000  |    2.5     |
   |  Jupiter  |    78      |     6       |  82000  |    8.2     |
   |  Saturn   |    87      |    14       | 263000  |   24.6     |
   |  Uranus   |    86      |     7       | 661000  |   27.4     |
   |  Neptune  |    11      |     2       | 248000  |   21.4     |

6. The present ERFA re-implementation of the original Simon et al.
   Fortran code differs from the original in the following respects:

     -  C instead of Fortran.

     -  The date is supplied in two parts.

     -  The result is returned only in equatorial Cartesian form;
        the ecliptic longitude, latitude and radius vector are not
        returned.

     -  The result is in the J2000.0 equatorial frame, not ecliptic.

     -  More is done in-line: there are fewer calls to subroutines.

     -  Different error/warning status values are used.

     -  A different Kepler's-equation-solver is used (avoiding
        use of double precision complex).

     -  Polynomials in t are nested to minimize rounding errors.

     -  Explicit double constants are used to avoid mixed-mode
        expressions.

   None of the above changes affects the result significantly.

7. The returned status indicates the most serious condition
   encountered during execution of the function.  Illegal np is
   considered the most serious, overriding failure to converge,
   which in turn takes precedence over the remote date warning.

### Called ###

- `eraAnp`: normalize angle into range 0 to 2pi

### Reference ###

- Simon, J.L, Bretagnon, P., Chapront, J., Chapront-Touze, M.,
    Francou, G., and Laskar, J., Astron. Astrophys. 282, 663 (1994).

"""
function plan94(date1, date2, np)
    pv = zeros((3, 2))
    i = ccall((:eraPlan94, liberfa), Cint,
              (Cdouble, Cdouble, Cint, Ptr{Cdouble}),
              date1, date2, np, pv)
    if i == -1
        throw(ERFAException("illegal np, not in range(1,8) for planet"))
    elseif i == 1
        @warn "year outside range(1000:3000)"
    elseif i == 2
        throw(ERFAException("computation failed to converge"))
    elseif i == 0
        # pass
    end
    return pv[:, 1], pv[:, 2]
end

"""
    pm(p)

Modulus of p-vector.

### Given ###

- `p`: P-vector

### Returned ###

- Modulus

"""
function pm(p)
    ccall((:eraPm, liberfa), Cdouble, (Ptr{Cdouble},), p)
end

"""
    pmsafe(ra1, dec1, pmr1, pmd1, px1, rv1, ep1a, ep1b, ep2a, ep2b)

Star proper motion:  update star catalog data for space motion, with
special handling to handle the zero parallax case.

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

1. The starting and ending TDB epochs ep1a+ep1b and ep2a+ep2b are
   Julian Dates, apportioned in any convenient way between the two
   parts (A and B).  For example, JD(TDB)=2450123.7 could be
   expressed in any of these ways, among others:

          epNa            epNb

       2450123.7           0.0       (JD method)
       2451545.0       -1421.3       (J2000 method)
       2400000.5       50123.2       (MJD method)
       2450123.5           0.2       (date & time method)

   The JD method is the most natural and convenient to use in cases
   where the loss of several decimal digits of resolution is
   acceptable.  The J2000 method is best matched to the way the
   argument is handled internally and will deliver the optimum
   resolution.  The MJD method and the date & time methods are both
   good compromises between resolution and convenience.

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

5. Straight-line motion at constant speed, in the inertial frame, is
   assumed.

6. An extremely small (or zero or negative) parallax is overridden
   to ensure that the object is at a finite but very large distance,
   but not so large that the proper motion is equivalent to a large
   but safe speed (about 0.1c using the chosen constant).  A warning
   status of 1 is added to the status if this action has been taken.

7. If the space velocity is a significant fraction of c (see the
   constant VMAX in the function eraStarpv), it is arbitrarily set
   to zero.  When this action occurs, 2 is added to the status.

8. The relativistic adjustment carried out in the eraStarpv function
   involves an iterative calculation.  If the process fails to
   converge within a set number of iterations, 4 is added to the
   status.

### Called ###

- `eraSeps`: angle between two points
- `eraStarpm`: update star catalog data for space motion

"""
function pmsafe(ra1, dec1, pmr1, pmd1, px1, rv1, ep1a, ep1b, ep2a, ep2b)
    ra2 = Ref(0.0)
    dec2 = Ref(0.0)
    pmr2 = Ref(0.0)
    pmd2 = Ref(0.0)
    px2 = Ref(0.0)
    rv2 = Ref(0.0)
    i = ccall((:eraPmsafe, liberfa), Cint,
              (Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ref{Cdouble},
              Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
              ra1, dec1, pmr1, pmd1, px1, rv1, ep1a, ep1b, ep2a, ep2b, ra2, dec2, pmr2, pmd2, px2, rv2)
    if i == -1
        throw(ERFAException("system error"))
    elseif i == 1
        @warn "distance overridden"
    elseif i == 2
        @warn "excessive velocity"
    elseif i == 4
        throw(ERFAException("solution didn't converge"))
    end
    ra2[], dec2[], pmr2[], pmd2[], px2[], rv2[]
end

"""
    pn(p)

Convert a p-vector into modulus and unit vector.

### Given ###

- `p`: P-vector

### Returned ###

- `r`: Modulus
- `u`: Unit vector

### Notes ###

1. If p is null, the result is null.  Otherwise the result is a unit
   vector.

2. It is permissible to re-use the same array for any of the
   arguments.

### Called ###

- `eraPm`: modulus of p-vector
- `eraZp`: zero p-vector
- `eraSxp`: multiply p-vector by scalar

"""
function pn(p::AbstractArray)
    r = Ref(0.0)
    u = zeros(3)
    ccall((:eraPn, liberfa), Cvoid,
          (Ptr{Cdouble}, Ref{Cdouble}, Ptr{Cdouble}),
          p, r, u)
    r[], u
end

"""
    ppsp(a, s, b)

P-vector plus scaled p-vector.

### Given ###

- `a`: First p-vector
- `s`: Scalar (multiplier for b)
- `b`: Second p-vector

### Returned ###

- `apsb`: A + s*b

### Note ###

   It is permissible for any of a, b and apsb to be the same array.

### Called ###

- `eraSxp`: multiply p-vector by scalar
- `eraPpp`: p-vector plus p-vector

"""
function ppsp(a, s, b)
    apsb = zeros(3)
    ccall((:eraPpsp, liberfa), Cvoid,
          (Ptr{Cdouble}, Cdouble, Ptr{Cdouble}, Ptr{Cdouble}),
          a, s, b, apsb)
    apsb
end

"""
    prec76(date01, date02, date11, date12)

IAU 1976 precession model.

This function forms the three Euler angles which implement general
precession between two dates, using the IAU 1976 model (as for the
FK5 catalog).

### Given ###

- `date01`, `date02`: TDB starting date (Note 1)
- `date11`, `date12`: TDB ending date (Note 1)

### Returned ###

- `zeta`: 1st rotation: radians cw around z
- `z`: 3rd rotation: radians cw around z
- `theta`: 2nd rotation: radians ccw around y

### Notes ###

1. The dates date01+date02 and date11+date12 are Julian Dates,
   apportioned in any convenient way between the arguments daten1
   and daten2.  For example, JD(TDB)=2450123.7 could be expressed in
   any of these ways, among others:

         daten1        daten2

       2450123.7           0.0       (JD method)
       2451545.0       -1421.3       (J2000 method)
       2400000.5       50123.2       (MJD method)
       2450123.5           0.2       (date & time method)

   The JD method is the most natural and convenient to use in cases
   where the loss of several decimal digits of resolution is
   acceptable.  The J2000 method is best matched to the way the
   argument is handled internally and will deliver the optimum
   optimum resolution.  The MJD method and the date & time methods
   are both good compromises between resolution and convenience.
   The two dates may be expressed using different methods, but at
   the risk of losing some resolution.

2. The accumulated precession angles zeta, z, theta are expressed
   through canonical polynomials which are valid only for a limited
   time span.  In addition, the IAU 1976 precession rate is known to
   be imperfect.  The absolute accuracy of the present formulation
   is better than 0.1 arcsec from 1960AD to 2040AD, better than
   1 arcsec from 1640AD to 2360AD, and remains below 3 arcsec for
   the whole of the period 500BC to 3000AD.  The errors exceed
   10 arcsec outside the range 1200BC to 3900AD, exceed 100 arcsec
   outside 4200BC to 5600AD and exceed 1000 arcsec outside 6800BC to
   8200AD.

3. The three angles are returned in the conventional order, which
   is not the same as the order of the corresponding Euler
   rotations.  The precession matrix is
   R_3(-z) x R_2(+theta) x R_3(-zeta).

### Reference ###

- Lieske, J.H., 1979, Astron.Astrophys. 73, 282, equations
    (6) & (7), p283.

"""
function prec76(ep01, ep02, ep11, ep12)
    zeta = Ref(0.0)
    z = Ref(0.0)
    theta = Ref(0.0)
    ccall((:eraPrec76, liberfa), Cvoid,
          (Cdouble, Cdouble, Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
          ep01, ep02, ep11, ep12, zeta, z, theta)
    zeta[], z[], theta[]
end

"""
    pv2s(pv)

Convert position/velocity from Cartesian to spherical coordinates.

### Given ###

- `pv`: Pv-vector

### Returned ###

- `theta`: Longitude angle (radians)
- `phi`: Latitude angle (radians)
- `r`: Radial distance
- `td`: Rate of change of theta
- `pd`: Rate of change of phi
- `rd`: Rate of change of r

### Notes ###

1. If the position part of pv is null, theta, phi, td and pd
   are indeterminate.  This is handled by extrapolating the
   position through unit time by using the velocity part of
   pv.  This moves the origin without changing the direction
   of the velocity component.  If the position and velocity
   components of pv are both null, zeroes are returned for all
   six results.

2. If the position is a pole, theta, td and pd are indeterminate.
   In such cases zeroes are returned for all three.

"""
function pv2s(pv)
    theta = Ref(0.0)
    phi = Ref(0.0)
    r = Ref(0.0)
    td = Ref(0.0)
    pd = Ref(0.0)
    rd = Ref(0.0)
    ccall((:eraPv2s, liberfa), Cvoid,
          (Ptr{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
          pv, theta, phi, r, td, pd, rd)
    theta[], phi[], r[], td[], pd[], rd[]
end

"""
    pv2p(pv)

Discard velocity component of a pv-vector.

### Given ###

- `pv`: Pv-vector

### Returned ###

- `p`: P-vector

### Called ###

- `eraCp`: copy p-vector

"""
function pv2p(pv)
    p = zeros(3)
    ccall((:eraPv2p, liberfa), Cvoid,
          (Ptr{Cdouble}, Ptr{Cdouble}),
          pv, p)
    p
end

"""
    pvdpv(a, b)

Inner (=scalar=dot) product of two pv-vectors.

### Given ###

- `a`: First pv-vector
- `b`: Second pv-vector

### Returned ###

- `adb`: A . b (see note)

### Note ###

   If the position and velocity components of the two pv-vectors are
   ( ap, av ) and ( bp, bv ), the result, a . b, is the pair of
   numbers ( ap . bp , ap . bv + av . bp ).  The two numbers are the
   dot-product of the two p-vectors and its derivative.

### Called ###

- `eraPdp`: scalar product of two p-vectors

"""
function pvdpv(a, b)
    adb = zeros(2)
    ccall((:eraPvdpv, liberfa), Cvoid,
          (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
          a, b, adb)
    adb
end

"""
    pvm(pv)

Modulus of pv-vector.

### Given ###

- `pv`: Pv-vector

### Returned ###

- `r`: Modulus of position component
- `s`: Modulus of velocity component

### Called ###

- `eraPm`: modulus of p-vector

"""
function pvm(pv)
    s = Ref(0.0)
    r = Ref(0.0)
    ccall((:eraPvm, liberfa), Cvoid,
          (Ptr{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
          pv, r, s)
    r[], s[]
end

"""
    pvstar(pv)

Convert star position+velocity vector to catalog coordinates.

### Given (Note 1) ###

- `pv`: pv-vector (au, au/day)

### Returned (Note 2) ###

- `ra`: Right ascension (radians)
- `dec`: Declination (radians)
- `pmr`: RA proper motion (radians/year)
- `pmd`: Dec proper motion (radians/year)
- `px`: Parallax (arcsec)
- `rv`: Radial velocity (km/s, positive = receding)

### Notes ###

1. The specified pv-vector is the coordinate direction (and its rate
   of change) for the date at which the light leaving the star
   reached the solar-system barycenter.

2. The star data returned by this function are "observables" for an
   imaginary observer at the solar-system barycenter.  Proper motion
   and radial velocity are, strictly, in terms of barycentric
   coordinate time, TCB.  For most practical applications, it is
   permissible to neglect the distinction between TCB and ordinary
   "proper" time on Earth (TT/TAI).  The result will, as a rule, be
   limited by the intrinsic accuracy of the proper-motion and
   radial-velocity data;  moreover, the supplied pv-vector is likely
   to be merely an intermediate result (for example generated by the
   function eraStarpv), so that a change of time unit will cancel
   out overall.

   In accordance with normal star-catalog conventions, the object's
   right ascension and declination are freed from the effects of
   secular aberration.  The frame, which is aligned to the catalog
   equator and equinox, is Lorentzian and centered on the SSB.

   Summarizing, the specified pv-vector is for most stars almost
   identical to the result of applying the standard geometrical
   "space motion" transformation to the catalog data.  The
   differences, which are the subject of the Stumpff paper cited
   below, are:

   (i) In stars with significant radial velocity and proper motion,
   the constantly changing light-time distorts the apparent proper
   motion.  Note that this is a classical, not a relativistic,
   effect.

   (ii) The transformation complies with special relativity.

3. Care is needed with units.  The star coordinates are in radians
   and the proper motions in radians per Julian year, but the
   parallax is in arcseconds; the radial velocity is in km/s, but
   the pv-vector result is in au and au/day.

4. The proper motions are the rate of change of the right ascension
   and declination at the catalog epoch and are in radians per Julian
   year.  The RA proper motion is in terms of coordinate angle, not
   true angle, and will thus be numerically larger at high
   declinations.

5. Straight-line motion at constant speed in the inertial frame is
   assumed.  If the speed is greater than or equal to the speed of
   light, the function aborts with an error status.

6. The inverse transformation is performed by the function eraStarpv.

### Called ###

- `eraPn`: decompose p-vector into modulus and direction
- `eraPdp`: scalar product of two p-vectors
- `eraSxp`: multiply p-vector by scalar
- `eraPmp`: p-vector minus p-vector
- `eraPm`: modulus of p-vector
- `eraPpp`: p-vector plus p-vector
- `eraPv2s`: pv-vector to spherical
- `eraAnp`: normalize angle into range 0 to 2pi

### Reference ###

- Stumpff, P., 1985, Astron.Astrophys. 144, 232-240.

"""
function pvstar(pv)
    ra = Ref(0.0)
    dec = Ref(0.0)
    pmr = Ref(0.0)
    pmd = Ref(0.0)
    px = Ref(0.0)
    rv = Ref(0.0)
    i = ccall((:eraPvstar, liberfa), Cint,
              (Ptr{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
              pv, ra, dec, pmr, pmd, px, rv)
    if i == -1
        throw(ERFAException("superluminal speed"))
    elseif i == -2
        @warn "null position vector"
        return ra[], dec[], pmr[], pmd[], px[], rv[]
    end
    ra[], dec[], pmr[], pmd[], px[], rv[]
end

"""
    pvtob(elong, phi, height, xp, yp, sp, theta)

Position and velocity of a terrestrial observing station.

### Given ###

- `elong`: Longitude (radians, east +ve, Note 1)
- `phi`: Latitude (geodetic, radians, Note 1)
- `hm`: Height above ref. ellipsoid (geodetic, m)
- `xp`, `yp`: Coordinates of the pole (radians, Note 2)
- `sp`: The TIO locator s' (radians, Note 2)
- `theta`: Earth rotation angle (radians, Note 3)

### Returned ###

- `pv`: Position/velocity vector (m, m/s, CIRS)

### Notes ###

1. The terrestrial coordinates are with respect to the ERFA_WGS84
   reference ellipsoid.

2. xp and yp are the coordinates (in radians) of the Celestial
   Intermediate Pole with respect to the International Terrestrial
   Reference System (see IERS Conventions), measured along the
   meridians 0 and 90 deg west respectively.  sp is the TIO locator
   s', in radians, which positions the Terrestrial Intermediate
   Origin on the equator.  For many applications, xp, yp and
   (especially) sp can be set to zero.

3. If theta is Greenwich apparent sidereal time instead of Earth
   rotation angle, the result is with respect to the true equator
   and equinox of date, i.e. with the x-axis at the equinox rather
   than the celestial intermediate origin.

4. The velocity units are meters per UT1 second, not per SI second.
   This is unlikely to have any practical consequences in the modern
   era.

5. No validation is performed on the arguments.  Error cases that
   could lead to arithmetic exceptions are trapped by the eraGd2gc
   function, and the result set to zeros.

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- Urban, S. & Seidelmann, P. K. (eds), Explanatory Supplement to
    the Astronomical Almanac, 3rd ed., University Science Books
    (2013), Section 7.4.3.3.

### Called ###

- `eraGd2gc`: geodetic to geocentric transformation
- `eraPom00`: polar motion matrix
- `eraTrxp`: product of transpose of r-matrix and p-vector

"""
function pvtob(elong, phi, height, xp, yp, sp, theta)
    pv = zeros((2, 3))
    ccall((:eraPvtob, liberfa), Cvoid,
          (Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ptr{Cdouble}),
          elong, phi, height, xp, yp, sp, theta, pv)
    pv
end

"""
    pvu(dt, pv)

Update a pv-vector.

### Given ###

- `dt`: Time interval
- `pv`: Pv-vector

### Returned ###

- `upv`: P updated, v unchanged

### Notes ###

1. "Update" means "refer the position component of the vector
   to a new date dt time units from the existing date".

2. The time units of dt must match those of the velocity.

3. It is permissible for pv and upv to be the same array.

### Called ###

- `eraPpsp`: p-vector plus scaled p-vector
- `eraCp`: copy p-vector

"""
function pvu(dt, pv)
    upv = zeros((2, 3))
    ccall((:eraPvu, liberfa), Cvoid,
          (Cdouble, Ptr{Cdouble}, Ptr{Cdouble}),
          dt, pv, upv)
    upv
end

"""
    pvup(dt, pv)

Update a pv-vector, discarding the velocity component.

### Given ###

- `dt`: Time interval
- `pv`: Pv-vector

### Returned ###

- `p`: P-vector

### Notes ###

1. "Update" means "refer the position component of the vector to a
   new date dt time units from the existing date".

2. The time units of dt must match those of the velocity.

"""
function pvup(dt, pv)
    p = zeros(3)
    ccall((:eraPvup, liberfa), Cvoid,
          (Cdouble, Ptr{Cdouble}, Ptr{Cdouble}),
          dt, pv, p)
    p
end

"""
    pn00(date1, date2, dpsi, deps)

Precession-nutation, IAU 2000 model:  a multi-purpose function,
supporting classical (equinox-based) use directly and CIO-based
use indirectly.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)
- `dpsi`, `deps`: Nutation (Note 2)

### Returned ###

- `epsa`: Mean obliquity (Note 3)
- `rb`: Frame bias matrix (Note 4)
- `rp`: Precession matrix (Note 5)
- `rbp`: Bias-precession matrix (Note 6)
- `rn`: Nutation matrix (Note 7)
- `rbpn`: GCRS-to-true matrix (Note 8)

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

2. The caller is responsible for providing the nutation components;
   they are in longitude and obliquity, in radians and are with
   respect to the equinox and ecliptic of date.  For high-accuracy
   applications, free core nutation should be included as well as
   any other relevant corrections to the position of the CIP.

3. The returned mean obliquity is consistent with the IAU 2000
   precession-nutation models.

4. The matrix rb transforms vectors from GCRS to J2000.0 mean
   equator and equinox by applying frame bias.

5. The matrix rp transforms vectors from J2000.0 mean equator and
   equinox to mean equator and equinox of date by applying
   precession.

6. The matrix rbp transforms vectors from GCRS to mean equator and
   equinox of date by applying frame bias then precession.  It is
   the product rp x rb.

7. The matrix rn transforms vectors from mean equator and equinox of
   date to true equator and equinox of date by applying the nutation
   (luni-solar + planetary).

8. The matrix rbpn transforms vectors from GCRS to true equator and
   equinox of date.  It is the product rn x rbp, applying frame
   bias, precession and nutation in that order.

9. It is permissible to re-use the same array in the returned
   arguments.  The arrays are filled in the order given.

### Called ###

- `eraPr00`: IAU 2000 precession adjustments
- `eraObl80`: mean obliquity, IAU 1980
- `eraBp00`: frame bias and precession matrices, IAU 2000
- `eraCr`: copy r-matrix
- `eraNumat`: form nutation matrix
- `eraRxr`: product of two r-matrices

### Reference ###

- Capitaine, N., Chapront, J., Lambert, S. and Wallace, P.,
    "Expressions for the Celestial Intermediate Pole and Celestial
    Ephemeris Origin consistent with the IAU 2000A precession-
    nutation model", Astron.Astrophys. 400, 1145-1154 (2003)

- n.b. The celestial ephemeris origin (CEO) was renamed "celestial
    intermediate origin" (CIO) by IAU 2006 Resolution 2.

"""
pn00

"""
    pn06(date1, date2, dpsi, deps)

Precession-nutation, IAU 2006 model:  a multi-purpose function,
supporting classical (equinox-based) use directly and CIO-based use
indirectly.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)
- `dpsi`, `deps`: Nutation (Note 2)

### Returned ###

- `epsa`: Mean obliquity (Note 3)
- `rb`: Frame bias matrix (Note 4)
- `rp`: Precession matrix (Note 5)
- `rbp`: Bias-precession matrix (Note 6)
- `rn`: Nutation matrix (Note 7)
- `rbpn`: GCRS-to-true matrix (Note 8)

### Notes ###

1.  The TT date date1+date2 is a Julian Date, apportioned in any
    convenient way between the two arguments.  For example,
    JD(TT)=2450123.7 could be expressed in any of these ways,
    among others:

           date1          date2

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

2.  The caller is responsible for providing the nutation components;
    they are in longitude and obliquity, in radians and are with
    respect to the equinox and ecliptic of date.  For high-accuracy
    applications, free core nutation should be included as well as
    any other relevant corrections to the position of the CIP.

3.  The returned mean obliquity is consistent with the IAU 2006
    precession.

4.  The matrix rb transforms vectors from GCRS to J2000.0 mean
    equator and equinox by applying frame bias.

5.  The matrix rp transforms vectors from J2000.0 mean equator and
    equinox to mean equator and equinox of date by applying
    precession.

6.  The matrix rbp transforms vectors from GCRS to mean equator and
    equinox of date by applying frame bias then precession.  It is
    the product rp x rb.

7.  The matrix rn transforms vectors from mean equator and equinox
    of date to true equator and equinox of date by applying the
    nutation (luni-solar + planetary).

8.  The matrix rbpn transforms vectors from GCRS to true equator and
    equinox of date.  It is the product rn x rbp, applying frame
    bias, precession and nutation in that order.

9.  The X,Y,Z coordinates of the Celestial Intermediate Pole are
    elements (3,1-3) of the GCRS-to-true matrix, i.e. rbpn[2][0-2].

10. It is permissible to re-use the same array in the returned
    arguments.  The arrays are filled in the stated order.

### Called ###

- `eraPfw06`: bias-precession F-W angles, IAU 2006
- `eraFw2m`: F-W angles to r-matrix
- `eraCr`: copy r-matrix
- `eraTr`: transpose r-matrix
- `eraRxr`: product of two r-matrices

### References ###

- Capitaine, N. & Wallace, P.T., 2006, Astron.Astrophys. 450, 855

- Wallace, P.T. & Capitaine, N., 2006, Astron.Astrophys. 459, 981

"""
pn06

for name in ("pn00",
             "pn06")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(date1, date2, dpsi, deps)
            epsa = Ref(0.0)
            rb = zeros((3, 3))
            rp = zeros((3, 3))
            rbp = zeros((3, 3))
            rn = zeros((3, 3))
            rbpn = zeros((3, 3))
            ccall(($fc, liberfa), Cvoid,
                  (Cdouble, Cdouble, Cdouble, Cdouble, Ref{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
                  date1, date2, dpsi, deps, epsa, rb, rp, rbp, rn, rbpn)
            epsa[], rb, rp, rbp, rn, rbpn
        end
    end
end

"""
    pmp(a, b)

P-vector subtraction.

### Given ###

- `a`: First p-vector
- `b`: Second p-vector

### Returned ###

- `amb`: A - b

### Note ###

   It is permissible to re-use the same array for any of the
   arguments.

"""
pmp

"""
    ppp(a, b)

P-vector addition.

### Given ###

- `a`: First p-vector
- `b`: Second p-vector

### Returned ###

- `apb`: A + b

### Note ###

   It is permissible to re-use the same array for any of the
   arguments.

"""
ppp

"""
    pxp(a, b)

p-vector outer (=vector=cross) product.

### Given ###

- `a`: First p-vector
- `b`: Second p-vector

### Returned ###

- `axb`: A x b

### Note ###

   It is permissible to re-use the same array for any of the
   arguments.

"""
pxp

for name in ("pmp",
             "ppp",
             "pxp")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(a, b)
            ab = zeros(3)
            ccall(($fc, liberfa), Cvoid,
                  (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
                  a, b, ab)
            ab
        end
    end
end

"""
    pvmpv(a, b)

Subtract one pv-vector from another.

### Given ###

- `a`: First pv-vector
- `b`: Second pv-vector

### Returned ###

- `amb`: A - b

### Note ###

   It is permissible to re-use the same array for any of the
   arguments.

### Called ###

- `eraPmp`: p-vector minus p-vector

"""
pvmpv

"""
    pvppv(a, b)

Add one pv-vector to another.

### Given ###

- `a`: First pv-vector
- `b`: Second pv-vector

### Returned ###

- `apb`: A + b

### Note ###

   It is permissible to re-use the same array for any of the
   arguments.

### Called ###

- `eraPpp`: p-vector plus p-vector

"""
pvppv

"""
    pvxpv(a, b)

Outer (=vector=cross) product of two pv-vectors.

### Given ###

- `a`: First pv-vector
- `b`: Second pv-vector

### Returned ###

- `axb`: A x b

### Notes ###

1. If the position and velocity components of the two pv-vectors are
   ( ap, av ) and ( bp, bv ), the result, a x b, is the pair of
   vectors ( ap x bp, ap x bv + av x bp ).  The two vectors are the
   cross-product of the two p-vectors and its derivative.

2. It is permissible to re-use the same array for any of the
   arguments.

### Called ###

- `eraCpv`: copy pv-vector
- `eraPxp`: vector product of two p-vectors
- `eraPpp`: p-vector plus p-vector

"""
pvxpv

for name in ("pvmpv",
             "pvppv",
             "pvxpv")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(a, b)
            ab = zeros((2, 3))
            ccall(($fc, liberfa), Cvoid,
                  (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
                  a, b, ab)
            ab
        end
    end
end

"""
    pn00a(date1, date2)

Precession-nutation, IAU 2000A model:  a multi-purpose function,
supporting classical (equinox-based) use directly and CIO-based
use indirectly.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `dpsi`, `deps`: Nutation (Note 2)
- `epsa`: Mean obliquity (Note 3)
- `rb`: Frame bias matrix (Note 4)
- `rp`: Precession matrix (Note 5)
- `rbp`: Bias-precession matrix (Note 6)
- `rn`: Nutation matrix (Note 7)
- `rbpn`: GCRS-to-true matrix (Notes 8,9)

### Notes ###

1.  The TT date date1+date2 is a Julian Date, apportioned in any
    convenient way between the two arguments.  For example,
    JD(TT)=2450123.7 could be expressed in any of these ways,
    among others:

           date1          date2

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

2.  The nutation components (luni-solar + planetary, IAU 2000A) in
    longitude and obliquity are in radians and with respect to the
    equinox and ecliptic of date.  Free core nutation is omitted;
    for the utmost accuracy, use the eraPn00  function, where the
    nutation components are caller-specified.  For faster but
    slightly less accurate results, use the eraPn00b function.

3.  The mean obliquity is consistent with the IAU 2000 precession.

4.  The matrix rb transforms vectors from GCRS to J2000.0 mean
    equator and equinox by applying frame bias.

5.  The matrix rp transforms vectors from J2000.0 mean equator and
    equinox to mean equator and equinox of date by applying
    precession.

6.  The matrix rbp transforms vectors from GCRS to mean equator and
    equinox of date by applying frame bias then precession.  It is
    the product rp x rb.

7.  The matrix rn transforms vectors from mean equator and equinox
    of date to true equator and equinox of date by applying the
    nutation (luni-solar + planetary).

8.  The matrix rbpn transforms vectors from GCRS to true equator and
    equinox of date.  It is the product rn x rbp, applying frame
    bias, precession and nutation in that order.

9.  The X,Y,Z coordinates of the IAU 2000A Celestial Intermediate
    Pole are elements (3,1-3) of the GCRS-to-true matrix,
    i.e. rbpn[2][0-2].

10. It is permissible to re-use the same array in the returned
    arguments.  The arrays are filled in the order given.

### Called ###

- `eraNut00a`: nutation, IAU 2000A
- `eraPn00`: bias/precession/nutation results, IAU 2000

### Reference ###

- Capitaine, N., Chapront, J., Lambert, S. and Wallace, P.,
    "Expressions for the Celestial Intermediate Pole and Celestial
    Ephemeris Origin consistent with the IAU 2000A precession-
    nutation model", Astron.Astrophys. 400, 1145-1154 (2003)

- n.b. The celestial ephemeris origin (CEO) was renamed "celestial
    intermediate origin" (CIO) by IAU 2006 Resolution 2.

"""
pn00a

"""
    pn00b(date1, date2)

Precession-nutation, IAU 2000B model:  a multi-purpose function,
supporting classical (equinox-based) use directly and CIO-based
use indirectly.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `dpsi`, `deps`: Nutation (Note 2)
- `epsa`: Mean obliquity (Note 3)
- `rb`: Frame bias matrix (Note 4)
- `rp`: Precession matrix (Note 5)
- `rbp`: Bias-precession matrix (Note 6)
- `rn`: Nutation matrix (Note 7)
- `rbpn`: GCRS-to-true matrix (Notes 8,9)

### Notes ###

1.  The TT date date1+date2 is a Julian Date, apportioned in any
    convenient way between the two arguments.  For example,
    JD(TT)=2450123.7 could be expressed in any of these ways,
    among others:

           date1          date2

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

2.  The nutation components (luni-solar + planetary, IAU 2000B) in
    longitude and obliquity are in radians and with respect to the
    equinox and ecliptic of date.  For more accurate results, but
    at the cost of increased computation, use the eraPn00a function.
    For the utmost accuracy, use the eraPn00  function, where the
    nutation components are caller-specified.

3.  The mean obliquity is consistent with the IAU 2000 precession.

4.  The matrix rb transforms vectors from GCRS to J2000.0 mean
    equator and equinox by applying frame bias.

5.  The matrix rp transforms vectors from J2000.0 mean equator and
    equinox to mean equator and equinox of date by applying
    precession.

6.  The matrix rbp transforms vectors from GCRS to mean equator and
    equinox of date by applying frame bias then precession.  It is
    the product rp x rb.

7.  The matrix rn transforms vectors from mean equator and equinox
    of date to true equator and equinox of date by applying the
    nutation (luni-solar + planetary).

8.  The matrix rbpn transforms vectors from GCRS to true equator and
    equinox of date.  It is the product rn x rbp, applying frame
    bias, precession and nutation in that order.

9.  The X,Y,Z coordinates of the IAU 2000B Celestial Intermediate
    Pole are elements (3,1-3) of the GCRS-to-true matrix,
    i.e. rbpn[2][0-2].

10. It is permissible to re-use the same array in the returned
    arguments.  The arrays are filled in the stated order.

### Called ###

- `eraNut00b`: nutation, IAU 2000B
- `eraPn00`: bias/precession/nutation results, IAU 2000

### Reference ###

- Capitaine, N., Chapront, J., Lambert, S. and Wallace, P.,
    "Expressions for the Celestial Intermediate Pole and Celestial
    Ephemeris Origin consistent with the IAU 2000A precession-
    nutation model", Astron.Astrophys. 400, 1145-1154 (2003).

- n.b. The celestial ephemeris origin (CEO) was renamed "celestial
    intermediate origin" (CIO) by IAU 2006 Resolution 2.

"""
pn00b

"""
    pn06a(date1, date2)

Precession-nutation, IAU 2006/2000A models:  a multi-purpose function,
supporting classical (equinox-based) use directly and CIO-based use
indirectly.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `dpsi`, `deps`: Nutation (Note 2)
- `epsa`: Mean obliquity (Note 3)
- `rb`: Frame bias matrix (Note 4)
- `rp`: Precession matrix (Note 5)
- `rbp`: Bias-precession matrix (Note 6)
- `rn`: Nutation matrix (Note 7)
- `rbpn`: GCRS-to-true matrix (Notes 8,9)

### Notes ###

1.  The TT date date1+date2 is a Julian Date, apportioned in any
    convenient way between the two arguments.  For example,
    JD(TT)=2450123.7 could be expressed in any of these ways,
    among others:

           date1          date2

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

2.  The nutation components (luni-solar + planetary, IAU 2000A) in
    longitude and obliquity are in radians and with respect to the
    equinox and ecliptic of date.  Free core nutation is omitted;
    for the utmost accuracy, use the eraPn06 function, where the
    nutation components are caller-specified.

3.  The mean obliquity is consistent with the IAU 2006 precession.

4.  The matrix rb transforms vectors from GCRS to mean J2000.0 by
    applying frame bias.

5.  The matrix rp transforms vectors from mean J2000.0 to mean of
    date by applying precession.

6.  The matrix rbp transforms vectors from GCRS to mean of date by
    applying frame bias then precession.  It is the product rp x rb.

7.  The matrix rn transforms vectors from mean of date to true of
    date by applying the nutation (luni-solar + planetary).

8.  The matrix rbpn transforms vectors from GCRS to true of date
    (CIP/equinox).  It is the product rn x rbp, applying frame bias,
    precession and nutation in that order.

9.  The X,Y,Z coordinates of the IAU 2006/2000A Celestial
    Intermediate Pole are elements (3,1-3) of the GCRS-to-true
    matrix, i.e. rbpn[2][0-2].

10. It is permissible to re-use the same array in the returned
    arguments.  The arrays are filled in the stated order.

### Called ###

- `eraNut06a`: nutation, IAU 2006/2000A
- `eraPn06`: bias/precession/nutation results, IAU 2006

### Reference ###

- Capitaine, N. & Wallace, P.T., 2006, Astron.Astrophys. 450, 855

"""
pn06a

for name in ("pn00a",
             "pn00b",
             "pn06a")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(date1, date2)
            dpsi = Ref(0.0)
            deps = Ref(0.0)
            epsa = Ref(0.0)
            rb = zeros((3, 3))
            rp = zeros((3, 3))
            rbp = zeros((3, 3))
            rn = zeros((3, 3))
            rbpn = zeros((3, 3))
            ccall(($fc, liberfa), Cvoid,
                  (Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
                  date1, date2, dpsi, deps, epsa, rb, rp, rbp, rn, rbpn)
            dpsi[], deps[], epsa[], rb, rp, rbp, rn, rbpn
        end
    end
end

"""
    pas(al, ap, bl, bp)

Position-angle from spherical coordinates.

### Given ###

- `al`: Longitude of point A (e.g. RA) in radians
- `ap`: Latitude of point A (e.g. Dec) in radians
- `bl`: Longitude of point B
- `bp`: Latitude of point B

### Returned ###

- Position angle of B with respect to A

### Notes ###

1. The result is the bearing (position angle), in radians, of point
   B with respect to point A.  It is in the range -pi to +pi.  The
   sense is such that if B is a small distance "east" of point A,
   the bearing is approximately +pi/2.

2. Zero is returned if the two points are coincident.

"""
function pas(al, ap, bl, bp)
    ccall((:eraPas, liberfa), Cdouble, (Cdouble, Cdouble, Cdouble, Cdouble), al, ap, bl, bp)
end

"""
    pap(a, b)

Position-angle from two p-vectors.

### Given ###

- `a`: Direction of reference point
- `b`: Direction of point whose PA is required

### Returned ###

- Position angle of b with respect to a (radians)

### Notes ###

1. The result is the position angle, in radians, of direction b with
   respect to direction a.  It is in the range -pi to +pi.  The
   sense is such that if b is a small distance "north" of a the
   position angle is approximately zero, and if b is a small
   distance "east" of a the position angle is approximately +pi/2.

2. The vectors a and b need not be of unit length.

3. Zero is returned if the two directions are the same or if either
   vector is null.

4. If vector a is at a pole, the result is ill-defined.

### Called ###

- `eraPn`: decompose p-vector into modulus and direction
- `eraPm`: modulus of p-vector
- `eraPxp`: vector product of two p-vectors
- `eraPmp`: p-vector minus p-vector
- `eraPdp`: scalar product of two p-vectors

"""
pap

"""
    pdp(a, b)

p-vector inner (=scalar=dot) product.

### Given ###

- `a`: First p-vector
- `b`: Second p-vector

### Returned ###

- ``a \\cdot b``

"""
pdp

for name in ("pap",
             "pdp")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(a, b)
            ccall(($fc, liberfa), Cdouble, (Ptr{Cdouble}, Ptr{Cdouble}), a, b)
        end
    end
end

"""
    pr00(date1, date2)

Precession-rate part of the IAU 2000 precession-nutation models
(part of MHB2000).

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `dpsipr`, `depspr`: Precession corrections (Notes 2,3)

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

2. The precession adjustments are expressed as "nutation
   components", corrections in longitude and obliquity with respect
   to the J2000.0 equinox and ecliptic.

3. Although the precession adjustments are stated to be with respect
   to Lieske et al. (1977), the MHB2000 model does not specify which
   set of Euler angles are to be used and how the adjustments are to
   be applied.  The most literal and straightforward procedure is to
   adopt the 4-rotation epsilon_0, psi_A, omega_A, xi_A option, and
   to add dpsipr to psi_A and depspr to both omega_A and eps_A.

4. This is an implementation of one aspect of the IAU 2000A nutation
   model, formally adopted by the IAU General Assembly in 2000,
   namely MHB2000 (Mathews et al. 2002).

### References ###

- Lieske, J.H., Lederle, T., Fricke, W. & Morando, B., "Expressions
    for the precession quantities based upon the IAU (1976) System of
    Astronomical Constants", Astron.Astrophys., 58, 1-16 (1977)

- Mathews, P.M., Herring, T.A., Buffet, B.A., "Modeling of nutation
    and precession   New nutation series for nonrigid Earth and
    insights into the Earth's interior", J.Geophys.Res., 107, B4,
    2002.  The MHB2000 code itself was obtained on 9th September 2002
    from ftp://maia.usno.navy.mil/conv2000/chapter5/IAU2000A.

- Wallace, P.T., "Software for Implementing the IAU 2000
    Resolutions", in IERS Workshop 5.1 (2002).

"""
function pr00(a, b)
    r1 = Ref(0.0)
    r2 = Ref(0.0)
    ccall((:eraPr00, liberfa), Cvoid,
            (Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}),
            a, b, r1, r2)
    r1[], r2[]
end

"""
    pmat00(date1, date2)

Precession matrix (including frame bias) from GCRS to a specified
date, IAU 2000 model.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `rbp`: Bias-precession matrix (Note 2)

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

2. The matrix operates in the sense V(date) = rbp * V(GCRS), where
   the p-vector V(GCRS) is with respect to the Geocentric Celestial
   Reference System (IAU, 2000) and the p-vector V(date) is with
   respect to the mean equatorial triad of the given date.

### Called ###

- `eraBp00`: frame bias and precession matrices, IAU 2000

### Reference ###

- IAU: Trans. International Astronomical Union, Vol. XXIVB;  Proc.
    24th General Assembly, Manchester, UK.  Resolutions B1.3, B1.6.
    (2000)

"""
pmat00

"""
    pmat06(date1, date2)

Precession matrix (including frame bias) from GCRS to a specified
date, IAU 2006 model.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `rbp`: Bias-precession matrix (Note 2)

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

2. The matrix operates in the sense V(date) = rbp * V(GCRS), where
   the p-vector V(GCRS) is with respect to the Geocentric Celestial
   Reference System (IAU, 2000) and the p-vector V(date) is with
   respect to the mean equatorial triad of the given date.

### Called ###

- `eraPfw06`: bias-precession F-W angles, IAU 2006
- `eraFw2m`: F-W angles to r-matrix

### References ###

- Capitaine, N. & Wallace, P.T., 2006, Astron.Astrophys. 450, 855

- Wallace, P.T. & Capitaine, N., 2006, Astron.Astrophys. 459, 981

"""
pmat06

"""
    pmat76(date1, date2)

Precession matrix from J2000.0 to a specified date, IAU 1976 model.

### Given ###

- `date1`, `date2`: Ending date, TT (Note 1)

### Returned ###

- `rmatp`: Precession matrix, J2000.0 -> date1+date2

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

2. The matrix operates in the sense V(date) = RMATP * V(J2000),
   where the p-vector V(J2000) is with respect to the mean
   equatorial triad of epoch J2000.0 and the p-vector V(date)
   is with respect to the mean equatorial triad of the given
   date.

3. Though the matrix method itself is rigorous, the precession
   angles are expressed through canonical polynomials which are
   valid only for a limited time span.  In addition, the IAU 1976
   precession rate is known to be imperfect.  The absolute accuracy
   of the present formulation is better than 0.1 arcsec from
   1960AD to 2040AD, better than 1 arcsec from 1640AD to 2360AD,
   and remains below 3 arcsec for the whole of the period
   500BC to 3000AD.  The errors exceed 10 arcsec outside the
   range 1200BC to 3900AD, exceed 100 arcsec outside 4200BC to
   5600AD and exceed 1000 arcsec outside 6800BC to 8200AD.

### Called ###

- `eraPrec76`: accumulated precession angles, IAU 1976
- `eraIr`: initialize r-matrix to identity
- `eraRz`: rotate around Z-axis
- `eraRy`: rotate around Y-axis
- `eraCr`: copy r-matrix

### References ###

- Lieske, J.H., 1979, Astron.Astrophys. 73, 282.
    equations (6) & (7), p283.

- Kaplan,G.H., 1981. USNO circular no. 163, pA2.

"""
pmat76

"""
    pnm00a(date1, date2)

Form the matrix of precession-nutation for a given date (including
frame bias), equinox-based, IAU 2000A model.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `rbpn`: Classical NPB matrix (Note 2)

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

2. The matrix operates in the sense V(date) = rbpn * V(GCRS), where
   the p-vector V(date) is with respect to the true equatorial triad
   of date date1+date2 and the p-vector V(GCRS) is with respect to
   the Geocentric Celestial Reference System (IAU, 2000).

3. A faster, but slightly less accurate result (about 1 mas), can be
   obtained by using instead the eraPnm00b function.

### Called ###

- `eraPn00a`: bias/precession/nutation, IAU 2000A

### Reference ###

- IAU: Trans. International Astronomical Union, Vol. XXIVB;  Proc.
    24th General Assembly, Manchester, UK.  Resolutions B1.3, B1.6.
    (2000)

"""
pnm00a

"""
    pnm00b(date1, date2)

Form the matrix of precession-nutation for a given date (including
frame bias), equinox-based, IAU 2000B model.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `rbpn`: Bias-precession-nutation matrix (Note 2)

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

2. The matrix operates in the sense V(date) = rbpn * V(GCRS), where
   the p-vector V(date) is with respect to the true equatorial triad
   of date date1+date2 and the p-vector V(GCRS) is with respect to
   the Geocentric Celestial Reference System (IAU, 2000).

3. The present function is faster, but slightly less accurate (about
   1 mas), than the eraPnm00a function.

### Called ###

- `eraPn00b`: bias/precession/nutation, IAU 2000B

### Reference ###

- IAU: Trans. International Astronomical Union, Vol. XXIVB;  Proc.
    24th General Assembly, Manchester, UK.  Resolutions B1.3, B1.6.
    (2000)

"""
pnm00b

"""
    pnm06a(date1, date2)

Form the matrix of precession-nutation for a given date (including
frame bias), IAU 2006 precession and IAU 2000A nutation models.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `rnpb`: Bias-precession-nutation matrix (Note 2)

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

2. The matrix operates in the sense V(date) = rnpb * V(GCRS), where
   the p-vector V(date) is with respect to the true equatorial triad
   of date date1+date2 and the p-vector V(GCRS) is with respect to
   the Geocentric Celestial Reference System (IAU, 2000).

### Called ###

- `eraPfw06`: bias-precession F-W angles, IAU 2006
- `eraNut06a`: nutation, IAU 2006/2000A
- `eraFw2m`: F-W angles to r-matrix

### Reference ###

- Capitaine, N. & Wallace, P.T., 2006, Astron.Astrophys. 450, 855.

"""
pnm06a

"""
    pnm80(date1, date2)

Form the matrix of precession/nutation for a given date, IAU 1976
precession model, IAU 1980 nutation model.

### Given ###

- `date1`, `date2`: TDB date (Note 1)

### Returned ###

- `rmatpn`: Combined precession/nutation matrix

### Notes ###

1. The TDB date date1+date2 is a Julian Date, apportioned in any
   convenient way between the two arguments.  For example,
   JD(TDB)=2450123.7 could be expressed in any of these ways,
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

2. The matrix operates in the sense V(date) = rmatpn * V(J2000),
   where the p-vector V(date) is with respect to the true equatorial
   triad of date date1+date2 and the p-vector V(J2000) is with
   respect to the mean equatorial triad of epoch J2000.0.

### Called ###

- `eraPmat76`: precession matrix, IAU 1976
- `eraNutm80`: nutation matrix, IAU 1980
- `eraRxr`: product of two r-matrices

### Reference ###

- Explanatory Supplement to the Astronomical Almanac,
    P. Kenneth Seidelmann (ed), University Science Books (1992),
    Section 3.3 (p145).

"""
pnm80

for name in ("pmat00",
             "pmat06",
             "pmat76",
             "pnm00a",
             "pnm00b",
             "pnm06a",
             "pnm80")
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
    pom00(xp, yp, sp)

Form the matrix of polar motion for a given date, IAU 2000.

### Given ###

- `xp`, `yp`: Coordinates of the pole (radians, Note 1)
- `sp`: The TIO locator s' (radians, Note 2)

### Returned ###

- `rpom`: Polar-motion matrix (Note 3)

### Notes ###

1. The arguments xp and yp are the coordinates (in radians) of the
   Celestial Intermediate Pole with respect to the International
   Terrestrial Reference System (see IERS Conventions 2003),
   measured along the meridians to 0 and 90 deg west respectively.

2. The argument sp is the TIO locator s', in radians, which
   positions the Terrestrial Intermediate Origin on the equator.  It
   is obtained from polar motion observations by numerical
   integration, and so is in essence unpredictable.  However, it is
   dominated by a secular drift of about 47 microarcseconds per
   century, and so can be taken into account by using s' = -47*t,
   where t is centuries since J2000.0.  The function eraSp00
   implements this approximation.

3. The matrix operates in the sense V(TRS) = rpom * V(CIP), meaning
   that it is the final rotation when computing the pointing
   direction to a celestial source.

### Called ###

- `eraIr`: initialize r-matrix to identity
- `eraRz`: rotate around Z-axis
- `eraRy`: rotate around Y-axis
- `eraRx`: rotate around X-axis

### Reference ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

"""
function pom00(x, y, s)
    r = zeros((3, 3))
    ccall((:eraPom00, liberfa), Cvoid,
            (Cdouble, Cdouble, Cdouble, Ptr{Cdouble}),
            x, y, s, r)
    r
end
