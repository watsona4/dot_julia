"""
    xy06(date1, date2)

X,Y coordinates of celestial intermediate pole from series based
on IAU 2006 precession and IAU 2000A nutation.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `x`, `y`: CIP X,Y coordinates (Note 2)

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

2. The X,Y coordinates are those of the unit vector towards the
   celestial intermediate pole.  They represent the combined effects
   of frame bias, precession and nutation.

3. The fundamental arguments used are as adopted in IERS Conventions
   (2003) and are from Simon et al. (1994) and Souchay et al.
   (1999).

4. This is an alternative to the angles-based method, via the ERFA
   function eraFw2xy and as used in eraXys06a for example.  The two
   methods agree at the 1 microarcsecond level (at present), a
   negligible amount compared with the intrinsic accuracy of the
   models.  However, it would be unwise to mix the two methods
   (angles-based and series-based) in a single application.

### Called ###

- `eraFal03`: mean anomaly of the Moon
- `eraFalp03`: mean anomaly of the Sun
- `eraFaf03`: mean argument of the latitude of the Moon
- `eraFad03`: mean elongation of the Moon from the Sun
- `eraFaom03`: mean longitude of the Moon's ascending node
- `eraFame03`: mean longitude of Mercury
- `eraFave03`: mean longitude of Venus
- `eraFae03`: mean longitude of Earth
- `eraFama03`: mean longitude of Mars
- `eraFaju03`: mean longitude of Jupiter
- `eraFasa03`: mean longitude of Saturn
- `eraFaur03`: mean longitude of Uranus
- `eraFane03`: mean longitude of Neptune
- `eraFapa03`: general accumulated precession in longitude

### References ###

- Capitaine, N., Wallace, P.T. & Chapront, J., 2003,
    Astron.Astrophys., 412, 567

- Capitaine, N. & Wallace, P.T., 2006, Astron.Astrophys. 450, 855

- McCarthy, D. D., Petit, G. (eds.), 2004, IERS Conventions (2003),
    IERS Technical Note No. 32, BKG

- Simon, J.L., Bretagnon, P., Chapront, J., Chapront-Touze, M.,
    Francou, G. & Laskar, J., Astron.Astrophys., 1994, 282, 663

- Souchay, J., Loysel, B., Kinoshita, H., Folgueira, M., 1999,
    Astron.Astrophys.Supp.Ser. 135, 111

- Wallace, P.T. & Capitaine, N., 2006, Astron.Astrophys. 459, 981

"""
function xy06(date1, date2)
    x = Ref(0.0)
    y = Ref(0.0)
    ccall((:eraXy06, liberfa), Cvoid,
          (Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}),
          date1, date2, x, y)
    x[], y[]
end

"""
    xys00a(date1, date2)

For a given TT date, compute the X,Y coordinates of the Celestial
Intermediate Pole and the CIO locator s, using the IAU 2000A
precession-nutation model.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `x`, `y`: Celestial Intermediate Pole (Note 2)
- `s`: The CIO locator s (Note 2)

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

2. The Celestial Intermediate Pole coordinates are the x,y
   components of the unit vector in the Geocentric Celestial
   Reference System.

3. The CIO locator s (in radians) positions the Celestial
   Intermediate Origin on the equator of the CIP.

4. A faster, but slightly less accurate result (about 1 mas for
   X,Y), can be obtained by using instead the eraXys00b function.

### Called ###

- `eraPnm00a`: classical NPB matrix, IAU 2000A
- `eraBpn2xy`: extract CIP X,Y coordinates from NPB matrix
- `eraS00`: the CIO locator s, given X,Y, IAU 2000A

### Reference ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

"""
xys00a

"""
    xys00b(date1, date2)

For a given TT date, compute the X,Y coordinates of the Celestial
Intermediate Pole and the CIO locator s, using the IAU 2000B
precession-nutation model.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `x`, `y`: Celestial Intermediate Pole (Note 2)
- `s`: The CIO locator s (Note 2)

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

2. The Celestial Intermediate Pole coordinates are the x,y
   components of the unit vector in the Geocentric Celestial
   Reference System.

3. The CIO locator s (in radians) positions the Celestial
   Intermediate Origin on the equator of the CIP.

4. The present function is faster, but slightly less accurate (about
   1 mas in X,Y), than the eraXys00a function.

### Called ###

- `eraPnm00b`: classical NPB matrix, IAU 2000B
- `eraBpn2xy`: extract CIP X,Y coordinates from NPB matrix
- `eraS00`: the CIO locator s, given X,Y, IAU 2000A

### Reference ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

"""
xys00b

"""
    xys06a(date1, date2)

For a given TT date, compute the X,Y coordinates of the Celestial
Intermediate Pole and the CIO locator s, using the IAU 2006
precession and IAU 2000A nutation models.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `x`, `y`: Celestial Intermediate Pole (Note 2)
- `s`: The CIO locator s (Note 2)

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

3. The CIO locator s (in radians) positions the Celestial
   Intermediate Origin on the equator of the CIP.

4. Series-based solutions for generating X and Y are also available:
   see Capitaine & Wallace (2006) and eraXy06.

### Called ###

- `eraPnm06a`: classical NPB matrix, IAU 2006/2000A
- `eraBpn2xy`: extract CIP X,Y coordinates from NPB matrix
- `eraS06`: the CIO locator s, given X,Y, IAU 2006

### References ###

- Capitaine, N. & Wallace, P.T., 2006, Astron.Astrophys. 450, 855

- Wallace, P.T. & Capitaine, N., 2006, Astron.Astrophys. 459, 981

"""
xys06a

for name in ("xys00a",
             "xys00b",
             "xys06a")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(date1, date2)
            x = Ref(0.0)
            y = Ref(0.0)
            s = Ref(0.0)
            ccall(($fc, liberfa), Cvoid,
                  (Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
                  date1, date2, x, y, s)
            x[], y[], s[]
        end
    end
end
