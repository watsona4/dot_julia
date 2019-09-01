"""
    fk5hip()

FK5 to Hipparcos rotation and spin.

### Returned ###

- `r5h`: R-matrix: FK5 rotation wrt Hipparcos (Note 2)
- `s5h`: R-vector: FK5 spin wrt Hipparcos (Note 3)

### Notes ###

1. This function models the FK5 to Hipparcos transformation as a
   pure rotation and spin;  zonal errors in the FK5 catalogue are
   not taken into account.

2. The r-matrix r5h operates in the sense:

         P_Hipparcos = r5h x P_FK5

   where P_FK5 is a p-vector in the FK5 frame, and P_Hipparcos is
   the equivalent Hipparcos p-vector.

3. The r-vector s5h represents the time derivative of the FK5 to
   Hipparcos rotation.  The units are radians per year (Julian,
   TDB).

### Called ###

- `eraRv2m`: r-vector to r-matrix

### Reference ###

- F.Mignard & M.Froeschle, Astron. Astrophys. 354, 732-739 (2000).

"""
function fk5hip()
    r5h = zeros((3, 3))
    s5h = zeros(3)
    ccall((:eraFk5hip, liberfa), Cvoid,
          (Ptr{Cdouble}, Ptr{Cdouble}),
          r5h, s5h)
    r5h, s5h
end

"""
    fk5hz(r5, d5, date1, date2)

Transform an FK5 (J2000.0) star position into the system of the
Hipparcos catalogue, assuming zero Hipparcos proper motion.

### Given ###

- `r5`: FK5 RA (radians), equinox J2000.0, at date
- `d5`: FK5 Dec (radians), equinox J2000.0, at date
- `date1`, `date2`: TDB date (Notes 1,2)

### Returned ###

- `rh`: Hipparcos RA (radians)
- `dh`: Hipparcos Dec (radians)

### Notes ###

1. This function converts a star position from the FK5 system to
   the Hipparcos system, in such a way that the Hipparcos proper
   motion is zero.  Because such a star has, in general, a non-zero
   proper motion in the FK5 system, the function requires the date
   at which the position in the FK5 system was determined.

2. The TT date date1+date2 is a Julian Date, apportioned in any
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

3. The FK5 to Hipparcos transformation is modeled as a pure
   rotation and spin;  zonal errors in the FK5 catalogue are not
   taken into account.

4. The position returned by this function is in the Hipparcos
   reference system but at date date1+date2.

5. See also eraFk52h, eraH2fk5, eraHfk5z.

### Called ###

- `eraS2c`: spherical coordinates to unit vector
- `eraFk5hip`: FK5 to Hipparcos rotation and spin
- `eraSxp`: multiply p-vector by scalar
- `eraRv2m`: r-vector to r-matrix
- `eraTrxp`: product of transpose of r-matrix and p-vector
- `eraPxp`: vector product of two p-vectors
- `eraC2s`: p-vector to spherical
- `eraAnp`: normalize angle into range 0 to 2pi

### Reference ###

- F.Mignard & M.Froeschle, 2000, Astron.Astrophys. 354, 732-739.

"""
function fk5hz(r5, d5, date1, date2)
    rh = Ref(0.0)
    dh = Ref(0.0)
    ccall((:eraFk5hz, liberfa), Cvoid,
          (Cdouble, Cdouble, Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}),
          r5, d5, date1, date2, rh, dh)
    rh[], dh[]
end

"""
    fw2xy(gamb, phib, psi, eps)

CIP X,Y given Fukushima-Williams bias-precession-nutation angles.

### Given ###

- `gamb`: F-W angle gamma_bar (radians)
- `phib`: F-W angle phi_bar (radians)
- `psi`: F-W angle psi (radians)
- `eps`: F-W angle epsilon (radians)

### Returned ###

- `x`, `y`: CIP unit vector X,Y

### Notes ###

1. Naming the following points:

         e = J2000.0 ecliptic pole,
         p = GCRS pole
         E = ecliptic pole of date,
   and   P = CIP,

   the four Fukushima-Williams angles are as follows:

      gamb = gamma = epE
      phib = phi = pE
      psi = psi = pEP
      eps = epsilon = EP

2. The matrix representing the combined effects of frame bias,
   precession and nutation is:

      NxPxB = R_1(-epsA).R_3(-psi).R_1(phib).R_3(gamb)

   The returned values x,y are elements [2][0] and [2][1] of the
   matrix.  Near J2000.0, they are essentially angles in radians.

### Called ###

- `eraFw2m`: F-W angles to r-matrix
- `eraBpn2xy`: extract CIP X,Y coordinates from NPB matrix

### Reference ###

- Hilton, J. et al., 2006, Celest.Mech.Dyn.Astron. 94, 351

"""
function fw2xy(gamb, phib, psi, eps)
    x = Ref(0.0)
    y = Ref(0.0)
    ccall((:eraFw2xy, liberfa), Cvoid,
          (Cdouble, Cdouble, Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}),
          gamb, phib, psi, eps, x, y)
    x[], y[]
end

"""
    fad03(t)

Fundamental argument, IERS Conventions (2003):

mean elongation of the Moon from the Sun.

### Given ###

- `t`: TDB, Julian centuries since J2000.0 (Note 1)

### Returned ###

- `D`, radians (Note 2)

### Notes ###

1. Though t is strictly TDB, it is usually more convenient to use
   TT, which makes no significant difference.

2. The expression used is as adopted in IERS Conventions (2003) and
   is from Simon et al. (1994).

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- Simon, J.-L., Bretagnon, P., Chapront, J., Chapront-Touze, M.,
    Francou, G., Laskar, J. 1994, Astron.Astrophys. 282, 663-683

"""
fad03

"""
    fae03(t)

Fundamental argument, IERS Conventions (2003): Mean longitude of Earth.

### Given ###

- `t`: TDB, Julian centuries since J2000.0 (Note 1)

### Returned ###

- Mean longitude of Earth, radians (Note 2)

### Notes ###

1. Though t is strictly TDB, it is usually more convenient to use
   TT, which makes no significant difference.

2. The expression used is as adopted in IERS Conventions (2003) and
   comes from Souchay et al. (1999) after Simon et al. (1994).

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- Simon, J.-L., Bretagnon, P., Chapront, J., Chapront-Touze, M.,
    Francou, G., Laskar, J. 1994, Astron.Astrophys. 282, 663-683

- Souchay, J., Loysel, B., Kinoshita, H., Folgueira, M. 1999,
    Astron.Astrophys.Supp.Ser. 135, 111

"""
fae03

"""
    faf03(t)

Fundamental argument, IERS Conventions (2003): Mean longitude of the Moon minus
mean longitude of the ascending node.

### Given ###

- `t`: TDB, Julian centuries since J2000.0 (Note 1)

### Returned ###

- `F`, radians (Note 2)

### Notes ###

1. Though t is strictly TDB, it is usually more convenient to use
   TT, which makes no significant difference.

2. The expression used is as adopted in IERS Conventions (2003) and
   is from Simon et al. (1994).

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- Simon, J.-L., Bretagnon, P., Chapront, J., Chapront-Touze, M.,
    Francou, G., Laskar, J. 1994, Astron.Astrophys. 282, 663-683

"""
faf03

"""
    faju03(t)

Fundamental argument, IERS Conventions (2003): Mean longitude of Jupiter.

### Given ###

- `t`: TDB, Julian centuries since J2000.0 (Note 1)

### Returned ###

- Mean longitude of Jupiter, radians (Note 2)

### Notes ###

1. Though t is strictly TDB, it is usually more convenient to use
   TT, which makes no significant difference.

2. The expression used is as adopted in IERS Conventions (2003) and
   comes from Souchay et al. (1999) after Simon et al. (1994).

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- Simon, J.-L., Bretagnon, P., Chapront, J., Chapront-Touze, M.,
    Francou, G., Laskar, J. 1994, Astron.Astrophys. 282, 663-683

- Souchay, J., Loysel, B., Kinoshita, H., Folgueira, M. 1999,
    Astron.Astrophys.Supp.Ser. 135, 111

"""
faju03

"""
    fal03(t)

Fundamental argument, IERS Conventions (2003):

mean anomaly of the Moon.

### Given ###

- `t`: TDB, Julian centuries since J2000.0 (Note 1)

### Returned ###

- `l`, radians (Note 2)

### Notes ###

1. Though t is strictly TDB, it is usually more convenient to use
   TT, which makes no significant difference.

2. The expression used is as adopted in IERS Conventions (2003) and
   is from Simon et al. (1994).

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- Simon, J.-L., Bretagnon, P., Chapront, J., Chapront-Touze, M.,
    Francou, G., Laskar, J. 1994, Astron.Astrophys. 282, 663-683

"""
fal03

"""
    falp03(t)

Fundamental argument, IERS Conventions (2003):

mean anomaly of the Sun.

### Given ###

- `t`: TDB, Julian centuries since J2000.0 (Note 1)

### Returned ###

- `l'`, radians (Note 2)

### Notes ###

1. Though t is strictly TDB, it is usually more convenient to use
   TT, which makes no significant difference.

2. The expression used is as adopted in IERS Conventions (2003) and
   is from Simon et al. (1994).

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- Simon, J.-L., Bretagnon, P., Chapront, J., Chapront-Touze, M.,
    Francou, G., Laskar, J. 1994, Astron.Astrophys. 282, 663-683

"""
falp03

"""
    fama03(t)

Fundamental argument, IERS Conventions (2003): Mean longitude of Mars.

### Given ###

- `t`: TDB, Julian centuries since J2000.0 (Note 1)

### Returned ###

- Mean longitude of Mars, radians (Note 2)

### Notes ###

1. Though t is strictly TDB, it is usually more convenient to use
   TT, which makes no significant difference.

2. The expression used is as adopted in IERS Conventions (2003) and
   comes from Souchay et al. (1999) after Simon et al. (1994).

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- Simon, J.-L., Bretagnon, P., Chapront, J., Chapront-Touze, M.,
    Francou, G., Laskar, J. 1994, Astron.Astrophys. 282, 663-683

- Souchay, J., Loysel, B., Kinoshita, H., Folgueira, M. 1999,
    Astron.Astrophys.Supp.Ser. 135, 111

"""
fama03

"""
    fame03(t)

Fundamental argument, IERS Conventions (2003): Mean longitude of Mercury.

### Given ###

- `t`: TDB, Julian centuries since J2000.0 (Note 1)

### Returned ###

- Mean longitude of Mercury, radians (Note 2)

### Notes ###

1. Though t is strictly TDB, it is usually more convenient to use
   TT, which makes no significant difference.

2. The expression used is as adopted in IERS Conventions (2003) and
   comes from Souchay et al. (1999) after Simon et al. (1994).

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- Simon, J.-L., Bretagnon, P., Chapront, J., Chapront-Touze, M.,
    Francou, G., Laskar, J. 1994, Astron.Astrophys. 282, 663-683

- Souchay, J., Loysel, B., Kinoshita, H., Folgueira, M. 1999,
    Astron.Astrophys.Supp.Ser. 135, 111

"""
fame03

"""
    fane03(t)

Fundamental argument, IERS Conventions (2003): Mean longitude of Neptune.

### Given ###

- `t`: TDB, Julian centuries since J2000.0 (Note 1)

### Returned ###

- Mean longitude of Neptune, radians (Note 2)

### Notes ###

1. Though t is strictly TDB, it is usually more convenient to use
   TT, which makes no significant difference.

2. The expression used is as adopted in IERS Conventions (2003) and
   is adapted from Simon et al. (1994).

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- Simon, J.-L., Bretagnon, P., Chapront, J., Chapront-Touze, M.,
    Francou, G., Laskar, J. 1994, Astron.Astrophys. 282, 663-683

"""
fane03

"""
    faom03(t)

Fundamental argument, IERS Conventions (2003): Mean longitude of the Moon's ascending node.

### Given ###

- `t`: TDB, Julian centuries since J2000.0 (Note 1)

### Returned ###

- `Omega`, radians (Note 2)

### Notes ###

1. Though t is strictly TDB, it is usually more convenient to use
   TT, which makes no significant difference.

2. The expression used is as adopted in IERS Conventions (2003) and
   is from Simon et al. (1994).

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- Simon, J.-L., Bretagnon, P., Chapront, J., Chapront-Touze, M.,
    Francou, G., Laskar, J. 1994, Astron.Astrophys. 282, 663-683

"""
faom03

"""
    fapa03(t)

Fundamental argument, IERS Conventions (2003):

general accumulated precession in longitude.

### Given ###

- `t`: TDB, Julian centuries since J2000.0 (Note 1)

### Returned ###

- General precession in longitude, radians (Note 2)

### Notes ###

1. Though t is strictly TDB, it is usually more convenient to use
   TT, which makes no significant difference.

2. The expression used is as adopted in IERS Conventions (2003).  It
   is taken from Kinoshita & Souchay (1990) and comes originally
   from Lieske et al. (1977).

### References ###

- Kinoshita, H. and Souchay J. 1990, Celest.Mech. and Dyn.Astron.
    48, 187

- Lieske, J.H., Lederle, T., Fricke, W. & Morando, B. 1977,
    Astron.Astrophys. 58, 1-16

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

"""
fapa03

"""
    fasa03(t)

Fundamental argument, IERS Conventions (2003): Mean longitude of Saturn.

### Given ###

- `t`: TDB, Julian centuries since J2000.0 (Note 1)

### Returned ###

- Mean longitude of Saturn, radians (Note 2)

### Notes ###

1. Though t is strictly TDB, it is usually more convenient to use
   TT, which makes no significant difference.

2. The expression used is as adopted in IERS Conventions (2003) and
   comes from Souchay et al. (1999) after Simon et al. (1994).

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- Simon, J.-L., Bretagnon, P., Chapront, J., Chapront-Touze, M.,
    Francou, G., Laskar, J. 1994, Astron.Astrophys. 282, 663-683

- Souchay, J., Loysel, B., Kinoshita, H., Folgueira, M. 1999,
    Astron.Astrophys.Supp.Ser. 135, 111

"""
fasa03

"""
    faur03(t)

Fundamental argument, IERS Conventions (2003): Mean longitude of Uranus.

### Given ###

- `t`: TDB, Julian centuries since J2000.0 (Note 1)

### Returned  ###

- Mean longitude of Uranus, radians (Note 2)

### Notes ###

1. Though t is strictly TDB, it is usually more convenient to use
   TT, which makes no significant difference.

2. The expression used is as adopted in IERS Conventions (2003) and
   is adapted from Simon et al. (1994).

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- Simon, J.-L., Bretagnon, P., Chapront, J., Chapront-Touze, M.,
    Francou, G., Laskar, J. 1994, Astron.Astrophys. 282, 663-683

"""
faur03

"""
    fave03(t)

Fundamental argument, IERS Conventions (2003): Mean longitude of Venus.

### Given ###

- `t`: TDB, Julian centuries since J2000.0 (Note 1)

### Returned ###

- Mean longitude of Venus, radians (Note 2)

### Notes ###

1. Though t is strictly TDB, it is usually more convenient to use
   TT, which makes no significant difference.

2. The expression used is as adopted in IERS Conventions (2003) and
   comes from Souchay et al. (1999) after Simon et al. (1994).

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- Simon, J.-L., Bretagnon, P., Chapront, J., Chapront-Touze, M.,
    Francou, G., Laskar, J. 1994, Astron.Astrophys. 282, 663-683

- Souchay, J., Loysel, B., Kinoshita, H., Folgueira, M. 1999,
    Astron.Astrophys.Supp.Ser. 135, 111

"""
fave03

for name in ("fad03",
             "fae03",
             "faf03",
             "faju03",
             "fal03",
             "falp03",
             "fama03",
             "fame03",
             "fane03",
             "faom03",
             "fapa03",
             "fasa03",
             "faur03",
             "fave03")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval ($f)(d) = ccall(($fc, liberfa), Cdouble, (Cdouble,), d)
end

"""
    fk52h(ra, dec, dra, ddec, px, rv)

Transform FK5 (J2000.0) star data into the Hipparcos system.

### Given (all FK5, equinox J2000.0, epoch J2000.0) ###

- `r5`: RA (radians)
- `d5`: Dec (radians)
- `dr5`: Proper motion in RA (dRA/dt, rad/Jyear)
- `dd5`: Proper motion in Dec (dDec/dt, rad/Jyear)
- `px5`: Parallax (arcsec)
- `rv5`: Radial velocity (km/s, positive = receding)

### Returned (all Hipparcos, epoch J2000.0) ###

- `rh`: RA (radians)
- `dh`: Dec (radians)
- `drh`: proper motion in RA (dRA/dt, rad/Jyear)
- `ddh`: proper motion in Dec (dDec/dt, rad/Jyear)
- `pxh`: parallax (arcsec)
- `rvh`: radial velocity (km/s, positive = receding)

### Notes ###

1. This function transforms FK5 star positions and proper motions
   into the system of the Hipparcos catalog.

2. The proper motions in RA are dRA/dt rather than
   cos(Dec)*dRA/dt, and are per year rather than per century.

3. The FK5 to Hipparcos transformation is modeled as a pure
   rotation and spin;  zonal errors in the FK5 catalog are not
   taken into account.

4. See also eraH2fk5, eraFk5hz, eraHfk5z.

### Called ###

- `eraStarpv`: star catalog data to space motion pv-vector
- `eraFk5hip`: FK5 to Hipparcos rotation and spin
- `eraRxp`: product of r-matrix and p-vector
- `eraPxp`: vector product of two p-vectors
- `eraPpp`: p-vector plus p-vector
- `eraPvstar`: space motion pv-vector to star catalog data

### Reference ###

- F.Mignard & M.Froeschle, Astron. Astrophys. 354, 732-739 (2000).

"""
function fk52h(ra, dec, dra, ddec, px, rv)
    r = Ref(0.0)
    d = Ref(0.0)
    dr = Ref(0.0)
    dd = Ref(0.0)
    p = Ref(0.0)
    v = Ref(0.0)
    ccall((:eraFk52h, liberfa), Cvoid,
            (Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
            ra, dec, dra, ddec, px, rv, r, d, dr, dd, p, v)
    r[], d[], dr[], dd[], p[], v[]
end

"""
    fw2m(x, y, s, t)

Form rotation matrix given the Fukushima-Williams angles.

### Given ###

- `gamb`: F-W angle gamma_bar (radians)
- `phib`: F-W angle phi_bar (radians)
- `psi`: F-W angle psi (radians)
- `eps`: F-W angle epsilon (radians)

### Returned ###

- `r`: Rotation matrix

### Notes ###

1. Naming the following points:

         e = J2000.0 ecliptic pole,
         p = GCRS pole,
         E = ecliptic pole of date,
   and   P = CIP,

   the four Fukushima-Williams angles are as follows:

      gamb = gamma = epE
      phib = phi = pE
      psi = psi = pEP
      eps = epsilon = EP

2. The matrix representing the combined effects of frame bias,
   precession and nutation is:

      NxPxB = R_1(-eps).R_3(-psi).R_1(phib).R_3(gamb)

3. Three different matrices can be constructed, depending on the
   supplied angles:

   o  To obtain the nutation x precession x frame bias matrix,
      generate the four precession angles, generate the nutation
      components and add them to the psi_bar and epsilon_A angles,
      and call the present function.

   o  To obtain the precession x frame bias matrix, generate the
      four precession angles and call the present function.

   o  To obtain the frame bias matrix, generate the four precession
      angles for date J2000.0 and call the present function.

   The nutation-only and precession-only matrices can if necessary
   be obtained by combining these three appropriately.

### Called ###

- `eraIr`: initialize r-matrix to identity
- `eraRz`: rotate around Z-axis
- `eraRx`: rotate around X-axis

### Reference ###

- Hilton, J. et al., 2006, Celest.Mech.Dyn.Astron. 94, 351

"""
function fw2m(x, y, s, t)
    r = zeros((3, 3))
    ccall((:eraFw2m, liberfa), Cvoid,
            (Cdouble, Cdouble, Cdouble, Cdouble, Ptr{Cdouble}),
            x, y, s, t, r)
    r
end
