"""
    numat(epsa, dpsi, deps)

Form the matrix of nutation.

### Given ###

- `epsa`: Mean obliquity of date (Note 1)
- `dpsi`, `deps`: Nutation (Note 2)

### Returned ###

- `rmatn`: Nutation matrix (Note 3)

### Notes ###

1. The supplied mean obliquity epsa, must be consistent with the
   precession-nutation models from which dpsi and deps were obtained.

2. The caller is responsible for providing the nutation components;
   they are in longitude and obliquity, in radians and are with
   respect to the equinox and ecliptic of date.

3. The matrix operates in the sense V(true) = rmatn * V(mean),
   where the p-vector V(true) is with respect to the true
   equatorial triad of date and the p-vector V(mean) is with
   respect to the mean equatorial triad of date.

### Called ###

- `eraIr`: initialize r-matrix to identity
- `eraRx`: rotate around X-axis
- `eraRz`: rotate around Z-axis

### Reference ###

- Explanatory Supplement to the Astronomical Almanac,
    P. Kenneth Seidelmann (ed), University Science Books (1992),
    Section 3.222-3 (p114).

"""
function numat(epsa, dpsi, deps)
    rmatn = zeros((3, 3))
    ccall((:eraNumat, liberfa), Cvoid,
          (Cdouble, Cdouble, Cdouble, Ptr{Cdouble}),
          epsa, dpsi, deps, rmatn)
    rmatn
end

"""
    nut00a(date1, date2)

Nutation, IAU 2000A model (MHB2000 luni-solar and planetary nutation
with free core nutation omitted).

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `dpsi`, `deps`: Nutation, luni-solar + planetary (Note 2)

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

2. The nutation components in longitude and obliquity are in radians
   and with respect to the equinox and ecliptic of date.  The
   obliquity at J2000.0 is assumed to be the Lieske et al. (1977)
   value of 84381.448 arcsec.

   Both the luni-solar and planetary nutations are included.  The
   latter are due to direct planetary nutations and the
   perturbations of the lunar and terrestrial orbits.

3. The function computes the MHB2000 nutation series with the
   associated corrections for planetary nutations.  It is an
   implementation of the nutation part of the IAU 2000A precession-
   nutation model, formally adopted by the IAU General Assembly in
   2000, namely MHB2000 (Mathews et al. 2002), but with the free
   core nutation (FCN - see Note 4) omitted.

4. The full MHB2000 model also contains contributions to the
   nutations in longitude and obliquity due to the free-excitation
   of the free-core-nutation during the period 1979-2000.  These FCN
   terms, which are time-dependent and unpredictable, are NOT
   included in the present function and, if required, must be
   independently computed.  With the FCN corrections included, the
   present function delivers a pole which is at current epochs
   accurate to a few hundred microarcseconds.  The omission of FCN
   introduces further errors of about that size.

5. The present function provides classical nutation.  The MHB2000
   algorithm, from which it is adapted, deals also with (i) the
   offsets between the GCRS and mean poles and (ii) the adjustments
   in longitude and obliquity due to the changed precession rates.
   These additional functions, namely frame bias and precession
   adjustments, are supported by the ERFA functions eraBi00  and
   eraPr00.

6. The MHB2000 algorithm also provides "total" nutations, comprising
   the arithmetic sum of the frame bias, precession adjustments,
   luni-solar nutation and planetary nutation.  These total
   nutations can be used in combination with an existing IAU 1976
   precession implementation, such as eraPmat76,  to deliver GCRS-
   to-true predictions of sub-mas accuracy at current dates.
   However, there are three shortcomings in the MHB2000 model that
   must be taken into account if more accurate or definitive results
   are required (see Wallace 2002):

     (i) The MHB2000 total nutations are simply arithmetic sums,
         yet in reality the various components are successive Euler
         rotations.  This slight lack of rigor leads to cross terms
         that exceed 1 mas after a century.  The rigorous procedure
         is to form the GCRS-to-true rotation matrix by applying the
         bias, precession and nutation in that order.

    (ii) Although the precession adjustments are stated to be with
         respect to Lieske et al. (1977), the MHB2000 model does
         not specify which set of Euler angles are to be used and
         how the adjustments are to be applied.  The most literal
         and straightforward procedure is to adopt the 4-rotation
         epsilon_0, psi_A, omega_A, xi_A option, and to add DPSIPR
         to psi_A and DEPSPR to both omega_A and eps_A.

   (iii) The MHB2000 model predates the determination by Chapront
         et al. (2002) of a 14.6 mas displacement between the
         J2000.0 mean equinox and the origin of the ICRS frame.  It
         should, however, be noted that neglecting this displacement
         when calculating star coordinates does not lead to a
         14.6 mas change in right ascension, only a small second-
         order distortion in the pattern of the precession-nutation
         effect.

   For these reasons, the ERFA functions do not generate the "total
   nutations" directly, though they can of course easily be
   generated by calling eraBi00, eraPr00 and the present function
   and adding the results.

7. The MHB2000 model contains 41 instances where the same frequency
   appears multiple times, of which 38 are duplicates and three are
   triplicates.  To keep the present code close to the original MHB
   algorithm, this small inefficiency has not been corrected.

### Called ###

- `eraFal03`: mean anomaly of the Moon
- `eraFaf03`: mean argument of the latitude of the Moon
- `eraFaom03`: mean longitude of the Moon's ascending node
- `eraFame03`: mean longitude of Mercury
- `eraFave03`: mean longitude of Venus
- `eraFae03`: mean longitude of Earth
- `eraFama03`: mean longitude of Mars
- `eraFaju03`: mean longitude of Jupiter
- `eraFasa03`: mean longitude of Saturn
- `eraFaur03`: mean longitude of Uranus
- `eraFapa03`: general accumulated precession in longitude

### References ###

- Chapront, J., Chapront-Touze, M. & Francou, G. 2002,
    Astron.Astrophys. 387, 700

- Lieske, J.H., Lederle, T., Fricke, W. & Morando, B. 1977,
    Astron.Astrophys. 58, 1-16

- Mathews, P.M., Herring, T.A., Buffet, B.A. 2002, J.Geophys.Res.
    107, B4.  The MHB_2000 code itself was obtained on 9th September
    2002 from ftp//maia.usno.navy.mil/conv2000/chapter5/IAU2000A.

- Simon, J.-L., Bretagnon, P., Chapront, J., Chapront-Touze, M.,
    Francou, G., Laskar, J. 1994, Astron.Astrophys. 282, 663-683

- Souchay, J., Loysel, B., Kinoshita, H., Folgueira, M. 1999,
    Astron.Astrophys.Supp.Ser. 135, 111

- Wallace, P.T., "Software for Implementing the IAU 2000
    Resolutions", in IERS Workshop 5.1 (2002)

"""
nut00a

"""
    nut00b(date1, date2)

Nutation, IAU 2000B model.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `dpsi`, `deps`: Nutation, luni-solar + planetary (Note 2)

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

2. The nutation components in longitude and obliquity are in radians
   and with respect to the equinox and ecliptic of date.  The
   obliquity at J2000.0 is assumed to be the Lieske et al. (1977)
   value of 84381.448 arcsec.  (The errors that result from using
   this function with the IAU 2006 value of 84381.406 arcsec can be
   neglected.)

   The nutation model consists only of luni-solar terms, but
   includes also a fixed offset which compensates for certain long-
   period planetary terms (Note 7).

3. This function is an implementation of the IAU 2000B abridged
   nutation model formally adopted by the IAU General Assembly in
   2000.  The function computes the MHB_2000_SHORT luni-solar
   nutation series (Luzum 2001), but without the associated
   corrections for the precession rate adjustments and the offset
   between the GCRS and J2000.0 mean poles.

4. The full IAU 2000A (MHB2000) nutation model contains nearly 1400
   terms.  The IAU 2000B model (McCarthy & Luzum 2003) contains only
   77 terms, plus additional simplifications, yet still delivers
   results of 1 mas accuracy at present epochs.  This combination of
   accuracy and size makes the IAU 2000B abridged nutation model
   suitable for most practical applications.

   The function delivers a pole accurate to 1 mas from 1900 to 2100
   (usually better than 1 mas, very occasionally just outside
   1 mas).  The full IAU 2000A model, which is implemented in the
   function eraNut00a (q.v.), delivers considerably greater accuracy
   at current dates;  however, to realize this improved accuracy,
   corrections for the essentially unpredictable free-core-nutation
   (FCN) must also be included.

5. The present function provides classical nutation.  The
   MHB_2000_SHORT algorithm, from which it is adapted, deals also
   with (i) the offsets between the GCRS and mean poles and (ii) the
   adjustments in longitude and obliquity due to the changed
   precession rates.  These additional functions, namely frame bias
   and precession adjustments, are supported by the ERFA functions
   eraBi00  and eraPr00.

6. The MHB_2000_SHORT algorithm also provides "total" nutations,
   comprising the arithmetic sum of the frame bias, precession
   adjustments, and nutation (luni-solar + planetary).  These total
   nutations can be used in combination with an existing IAU 1976
   precession implementation, such as eraPmat76,  to deliver GCRS-
   to-true predictions of mas accuracy at current epochs.  However,
   for symmetry with the eraNut00a  function (q.v. for the reasons),
   the ERFA functions do not generate the "total nutations"
   directly.  Should they be required, they could of course easily
   be generated by calling eraBi00, eraPr00 and the present function
   and adding the results.

7. The IAU 2000B model includes "planetary bias" terms that are
   fixed in size but compensate for long-period nutations.  The
   amplitudes quoted in McCarthy & Luzum (2003), namely
   Dpsi = -1.5835 mas and Depsilon = +1.6339 mas, are optimized for
   the "total nutations" method described in Note 6.  The Luzum
   (2001) values used in this ERFA implementation, namely -0.135 mas
   and +0.388 mas, are optimized for the "rigorous" method, where
   frame bias, precession and nutation are applied separately and in
   that order.  During the interval 1995-2050, the ERFA
   implementation delivers a maximum error of 1.001 mas (not
   including FCN).

### References ###

- Lieske, J.H., Lederle, T., Fricke, W., Morando, B., "Expressions
    for the precession quantities based upon the IAU /1976/ system of
    astronomical constants", Astron.Astrophys. 58, 1-2, 1-16. (1977)

- Luzum, B., private communication, 2001 (Fortran code
    MHB_2000_SHORT)

- McCarthy, D.D. & Luzum, B.J., "An abridged model of the
    precession-nutation of the celestial pole", Cel.Mech.Dyn.Astron.
    85, 37-49 (2003)

- Simon, J.-L., Bretagnon, P., Chapront, J., Chapront-Touze, M.,
    Francou, G., Laskar, J., Astron.Astrophys. 282, 663-683 (1994)

"""
nut00b

"""
    nut06a(date1, date2)

IAU 2000A nutation with adjustments to match the IAU 2006
precession.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `dpsi`, `deps`: Nutation, luni-solar + planetary (Note 2)

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

2. The nutation components in longitude and obliquity are in radians
   and with respect to the mean equinox and ecliptic of date,
   IAU 2006 precession model (Hilton et al. 2006, Capitaine et al.
   2005).

3. The function first computes the IAU 2000A nutation, then applies
   adjustments for (i) the consequences of the change in obliquity
   from the IAU 1980 ecliptic to the IAU 2006 ecliptic and (ii) the
   secular variation in the Earth's dynamical form factor J2.

4. The present function provides classical nutation, complementing
   the IAU 2000 frame bias and IAU 2006 precession.  It delivers a
   pole which is at current epochs accurate to a few tens of
   microarcseconds, apart from the free core nutation.

### Called ###

- `eraNut00a`: nutation, IAU 2000A

### References ###

- Chapront, J., Chapront-Touze, M. & Francou, G. 2002,
    Astron.Astrophys. 387, 700

- Lieske, J.H., Lederle, T., Fricke, W. & Morando, B. 1977,
    Astron.Astrophys. 58, 1-16

- Mathews, P.M., Herring, T.A., Buffet, B.A. 2002, J.Geophys.Res.
    107, B4.  The MHB_2000 code itself was obtained on 9th September
    2002 from ftp//maia.usno.navy.mil/conv2000/chapter5/IAU2000A.

- Simon, J.-L., Bretagnon, P., Chapront, J., Chapront-Touze, M.,
    Francou, G., Laskar, J. 1994, Astron.Astrophys. 282, 663-683

- Souchay, J., Loysel, B., Kinoshita, H., Folgueira, M. 1999,
    Astron.Astrophys.Supp.Ser. 135, 111

- Wallace, P.T., "Software for Implementing the IAU 2000
    Resolutions", in IERS Workshop 5.1 (2002)

"""
nut06a

"""
    nut80(date1, date2)

Nutation, IAU 1980 model.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `dpsi`: Nutation in longitude (radians)
- `deps`: Nutation in obliquity (radians)

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

2. The nutation components are with respect to the ecliptic of
   date.

### Called ###

- `eraAnpm`: normalize angle into range +/- pi

### Reference ###

- Explanatory Supplement to the Astronomical Almanac,
    P. Kenneth Seidelmann (ed), University Science Books (1992),
    Section 3.222 (p111).

"""
nut80

for name in ("nut00a",
             "nut00b",
             "nut06a",
             "nut80")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(a, b)
            r1 = Ref(0.0)
            r2 = Ref(0.0)
            ccall(($fc, liberfa), Cvoid,
                  (Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}),
                  a, b, r1, r2)
            r1[], r2[]
        end
    end
end

"""
    num00a(date1, date2)

Form the matrix of nutation for a given date, IAU 2000A model.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `rmatn`: Nutation matrix

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

2. The matrix operates in the sense V(true) = rmatn * V(mean), where
   the p-vector V(true) is with respect to the true equatorial triad
   of date and the p-vector V(mean) is with respect to the mean
   equatorial triad of date.

3. A faster, but slightly less accurate result (about 1 mas), can be
   obtained by using instead the eraNum00b function.

### Called ###

- `eraPn00a`: bias/precession/nutation, IAU 2000A

### Reference ###

- Explanatory Supplement to the Astronomical Almanac,
    P. Kenneth Seidelmann (ed), University Science Books (1992),
    Section 3.222-3 (p114).

"""
num00a

"""
    num00b(date1, date2)

Form the matrix of nutation for a given date, IAU 2000B model.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `rmatn`: Nutation matrix

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

2. The matrix operates in the sense V(true) = rmatn * V(mean), where
   the p-vector V(true) is with respect to the true equatorial triad
   of date and the p-vector V(mean) is with respect to the mean
   equatorial triad of date.

3. The present function is faster, but slightly less accurate (about
   1 mas), than the eraNum00a function.

### Called ###

- `eraPn00b`: bias/precession/nutation, IAU 2000B

### Reference ###

- Explanatory Supplement to the Astronomical Almanac,
    P. Kenneth Seidelmann (ed), University Science Books (1992),
    Section 3.222-3 (p114).

"""
num00b

"""
    num06a(date1, date2)

Form the matrix of nutation for a given date, IAU 2006/2000A model.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `rmatn`: Nutation matrix

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

2. The matrix operates in the sense V(true) = rmatn * V(mean), where
   the p-vector V(true) is with respect to the true equatorial triad
   of date and the p-vector V(mean) is with respect to the mean
   equatorial triad of date.

### Called ###

- `eraObl06`: mean obliquity, IAU 2006
- `eraNut06a`: nutation, IAU 2006/2000A
- `eraNumat`: form nutation matrix

### Reference ###

- Explanatory Supplement to the Astronomical Almanac,
    P. Kenneth Seidelmann (ed), University Science Books (1992),
    Section 3.222-3 (p114).

"""
num06a

"""
    nutm80(date1, date2)

Form the matrix of nutation for a given date, IAU 1980 model.

### Given ###

- `date1`, `date2`: TDB date (Note 1)

### Returned ###

- `rmatn`: Nutation matrix

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

2. The matrix operates in the sense V(true) = rmatn * V(mean),
   where the p-vector V(true) is with respect to the true
   equatorial triad of date and the p-vector V(mean) is with
   respect to the mean equatorial triad of date.

### Called ###

- `eraNut80`: nutation, IAU 1980
- `eraObl80`: mean obliquity, IAU 1980
- `eraNumat`: form nutation matrix

"""
nutm80

for name in ("num00a",
             "num00b",
             "num06a",
             "nutm80")
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
