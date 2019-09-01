"""
    bi00()

Frame bias components of IAU 2000 precession-nutation models (part
of MHB2000 with additions).

### Returned ###

- `dpsibi`, `depsbi`: Longitude and obliquity corrections
- `dra`: The ICRS RA of the J2000.0 mean equinox

### Notes ###

1. The frame bias corrections in longitude and obliquity (radians)
   are required in order to correct for the offset between the GCRS
   pole and the mean J2000.0 pole.  They define, with respect to the
   GCRS frame, a J2000.0 mean pole that is consistent with the rest
   of the IAU 2000A precession-nutation model.

2. In addition to the displacement of the pole, the complete
   description of the frame bias requires also an offset in right
   ascension.  This is not part of the IAU 2000A model, and is from
   Chapront et al. (2002).  It is returned in radians.

3. This is a supplemented implementation of one aspect of the IAU
   2000A nutation model, formally adopted by the IAU General
   Assembly in 2000, namely MHB2000 (Mathews et al. 2002).

### References ###

- Chapront, J., Chapront-Touze, M. & Francou, G., Astron.
    Astrophys., 387, 700, 2002.

- Mathews, P.M., Herring, T.A., Buffet, B.A., "Modeling of nutation
    and precession   New nutation series for nonrigid Earth and
    insights into the Earth's interior", J.Geophys.Res., 107, B4,
    2002.  The MHB2000 code itself was obtained on 9th September 2002
    from ftp://maia.usno.navy.mil/conv2000/chapter5/IAU2000A.

"""
function bi00()
    dpsibi = Ref(0.0)
    depsbi = Ref(0.0)
    dra = Ref(0.0)
    ccall((:eraBi00, liberfa), Cvoid,
          (Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
          dpsibi, depsbi, dra)
    dpsibi[], depsbi[], dra[]
end

"""
    bpn2xy(rbpn)

Extract from the bias-precession-nutation matrix the X,Y coordinates
of the Celestial Intermediate Pole.

### Given ###

- `rbpn`: Celestial-to-true matrix (Note 1)

### Returned ###

- `x`, `y`: Celestial Intermediate Pole (Note 2)

### Notes ###

1. The matrix rbpn transforms vectors from GCRS to true equator (and
   CIO or equinox) of date, and therefore the Celestial Intermediate
   Pole unit vector is the bottom row of the matrix.

2. The arguments x,y are components of the Celestial Intermediate
   Pole unit vector in the Geocentric Celestial Reference System.

### Reference ###

- "Expressions for the Celestial Intermediate Pole and Celestial
    Ephemeris Origin consistent with the IAU 2000A precession-
    nutation model", Astron.Astrophys. 400, 1145-1154
    (2003)

- n.b. The celestial ephemeris origin (CEO) was renamed "celestial
    intermediate origin" (CIO) by IAU 2006 Resolution 2.

"""
function bpn2xy(rbpn)
    x = Ref(0.0)
    y = Ref(0.0)
    ccall((:eraBpn2xy, liberfa), Cvoid,
          (Ptr{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
          rbpn, x, y)
    x[], y[]
end

"""
    bp00(date1, date2)

Frame bias and precession, IAU 2000.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `rb`: Frame bias matrix (Note 2)
- `rp`: Precession matrix (Note 3)
- `rbp`: Bias-precession matrix (Note 4)

### Notes ###

1. The TT date date1+date2 is a Julian Date, apportioned in any
   convenient way between the two arguments.  For example,
   JD(TT)=2450123.7 could be expressed in any of these ways,
   among others:

           date1         date2

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

2. The matrix rb transforms vectors from GCRS to mean J2000.0 by
   applying frame bias.

3. The matrix rp transforms vectors from J2000.0 mean equator and
   equinox to mean equator and equinox of date by applying
   precession.

4. The matrix rbp transforms vectors from GCRS to mean equator and
   equinox of date by applying frame bias then precession.  It is
   the product rp x rb.

5. It is permissible to re-use the same array in the returned
   arguments.  The arrays are filled in the order given.

### Called ###

- `eraBi00`: frame bias components, IAU 2000
- `eraPr00`: IAU 2000 precession adjustments
- `eraIr`: initialize r-matrix to identity
- `eraRx`: rotate around X-axis
- `eraRy`: rotate around Y-axis
- `eraRz`: rotate around Z-axis
- `eraCr`: copy r-matrix
- `eraRxr`: product of two r-matrices

### Reference ###

- "Expressions for the Celestial Intermediate Pole and Celestial
    Ephemeris Origin consistent with the IAU 2000A precession-
    nutation model", Astron.Astrophys. 400, 1145-1154 (2003)

- n.b. The celestial ephemeris origin (CEO) was renamed "celestial
    intermediate origin" (CIO) by IAU 2006 Resolution 2.

"""
bp00

"""
    bp06(date1, date2)

Frame bias and precession, IAU 2006.

### Given ###

- `date1`, `date2`: TT as a 2-part Julian Date (Note 1)

### Returned ###

- `rb`: Frame bias matrix (Note 2)
- `rp`: Precession matrix (Note 3)
- `rbp`: Bias-precession matrix (Note 4)

### Notes ###

1. The TT date date1+date2 is a Julian Date, apportioned in any
   convenient way between the two arguments.  For example,
   JD(TT)=2450123.7 could be expressed in any of these ways,
   among others:

           date1         date2

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

2. The matrix rb transforms vectors from GCRS to mean J2000.0 by
   applying frame bias.

3. The matrix rp transforms vectors from mean J2000.0 to mean of
   date by applying precession.

4. The matrix rbp transforms vectors from GCRS to mean of date by
   applying frame bias then precession.  It is the product rp x rb.

5. It is permissible to re-use the same array in the returned
   arguments.  The arrays are filled in the order given.

### Called ###

- `eraPfw06`: bias-precession F-W angles, IAU 2006
- `eraFw2m`: F-W angles to r-matrix
- `eraPmat06`: PB matrix, IAU 2006
- `eraTr`: transpose r-matrix
- `eraRxr`: product of two r-matrices
- `eraCr`: copy r-matrix

### References ###

- Capitaine, N. & Wallace, P.T., 2006, Astron.Astrophys. 450, 855

- Wallace, P.T. & Capitaine, N., 2006, Astron.Astrophys. 459, 981

"""
bp06

for name in ("bp00",
             "bp06")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(a, b)
            rb = zeros((3, 3))
            rp = zeros((3, 3))
            rbp = zeros((3, 3))
            ccall(($fc, liberfa),
                  Cvoid,
                  (Cdouble, Cdouble, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
                  a, b, rb, rp, rbp)
            rb, rp, rbp
        end
    end
end
