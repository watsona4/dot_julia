"""
    tr(r)

Transpose an r-matrix.

### Given ###

- `r`: R-matrix

### Returned ###

- `rt`: Transpose

### Note ###

   It is permissible for r and rt to be the same array.

### Called ###

- `eraCr`: copy r-matrix

"""
function tr(r)
    rt = zeros((3, 3))
    ccall((:eraTr, liberfa), Cvoid,
          (Ptr{Cdouble}, Ptr{Cdouble}),
          r, rt)
    rt
end

"""
    trxpv(r, pv)

Multiply a pv-vector by the transpose of an r-matrix.

### Given ###

- `r`: R-matrix
- `pv`: Pv-vector

### Returned ###

- `trpv`: R * pv

### Note ###

   It is permissible for pv and trpv to be the same array.

### Called ###

- `eraTr`: transpose r-matrix
- `eraRxpv`: product of r-matrix and pv-vector

"""
function trxpv(r, p)
    rp = zeros((2, 3))
    ccall((:eraTrxpv, liberfa), Cvoid,
            (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
            r, p, rp)
    rp
end

"""
    trxp(r, p)

Multiply a p-vector by the transpose of an r-matrix.

### Given ###

- `r`: R-matrix
- `p`: P-vector

### Returned ###

- `trp`: R * p

### Note ###

   It is permissible for p and trp to be the same array.

### Called ###

- `eraTr`: transpose r-matrix
- `eraRxp`: product of r-matrix and p-vector

"""
function trxp(r, p)
    rp = zeros(3)
    ccall((:eraTrxp, liberfa), Cvoid,
            (Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
            r, p, rp)
    rp
end

"""
    taiut1(tai1, tai2, dta)

Time scale transformation:  International Atomic Time, TAI, to
Universal Time, UT1.

### Given ###

- `tai1`, `tai2`: TAI as a 2-part Julian Date
- `dta`: UT1-TAI in seconds

### Returned ###

- `ut11`, `ut12`: UT1 as a 2-part Julian Date

### Notes ###

1. tai1+tai2 is Julian Date, apportioned in any convenient way
   between the two arguments, for example where tai1 is the Julian
   Day Number and tai2 is the fraction of a day.  The returned
   UT11,UT12 follow suit.

2. The argument dta, i.e. UT1-TAI, is an observed quantity, and is
   available from IERS tabulations.

### Reference ###

- Explanatory Supplement to the Astronomical Almanac,
    P. Kenneth Seidelmann (ed), University Science Books (1992)

"""
taiut1

"""
    tdbtt(tdb1, tdb2, dtr)

Time scale transformation:  Barycentric Dynamical Time, TDB, to
Terrestrial Time, TT.

### Given ###

- `tdb1`, `tdb2`: TDB as a 2-part Julian Date
- `dtr`: TDB-TT in seconds

### Returned ###

- `tt1`, `tt2`: TT as a 2-part Julian Date

### Notes ###

1. tdb1+tdb2 is Julian Date, apportioned in any convenient way
   between the two arguments, for example where tdb1 is the Julian
   Day Number and tdb2 is the fraction of a day.  The returned
   tt1,tt2 follow suit.

2. The argument dtr represents the quasi-periodic component of the
   GR transformation between TT and TCB.  It is dependent upon the
   adopted solar-system ephemeris, and can be obtained by numerical
   integration, by interrogating a precomputed time ephemeris or by
   evaluating a model such as that implemented in the ERFA function
   eraDtdb.   The quantity is dominated by an annual term of 1.7 ms
   amplitude.

3. TDB is essentially the same as Teph, the time argument for the
   JPL solar system ephemerides.

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- IAU 2006 Resolution 3

"""
tdbtt

"""
    tttdb(tt1, tt2, dtr)

Time scale transformation:  Terrestrial Time, TT, to Barycentric
Dynamical Time, TDB.

### Given ###

- `tt1`, `tt2`: TT as a 2-part Julian Date
- `dtr`: TDB-TT in seconds

### Returned ###

- `tdb1`, `tdb2`: TDB as a 2-part Julian Date

### Notes ###

1. tt1+tt2 is Julian Date, apportioned in any convenient way between
   the two arguments, for example where tt1 is the Julian Day Number
   and tt2 is the fraction of a day.  The returned tdb1,tdb2 follow
   suit.

2. The argument dtr represents the quasi-periodic component of the
   GR transformation between TT and TCB.  It is dependent upon the
   adopted solar-system ephemeris, and can be obtained by numerical
   integration, by interrogating a precomputed time ephemeris or by
   evaluating a model such as that implemented in the ERFA function
   eraDtdb.   The quantity is dominated by an annual term of 1.7 ms
   amplitude.

3. TDB is essentially the same as Teph, the time argument for the JPL
   solar system ephemerides.

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- IAU 2006 Resolution 3

"""
tttdb

"""
    ttut1(tt1, tt2, dt)

Time scale transformation:  Terrestrial Time, TT, to Universal Time,
UT1.

### Given ###

- `tt1`, `tt2`: TT as a 2-part Julian Date
- `dt`: TT-UT1 in seconds

### Returned ###

- `ut11`, `ut12`: UT1 as a 2-part Julian Date

### Notes ###

1. tt1+tt2 is Julian Date, apportioned in any convenient way between
   the two arguments, for example where tt1 is the Julian Day Number
   and tt2 is the fraction of a day.  The returned ut11,ut12 follow
   suit.

2. The argument dt is classical Delta T.

### Reference ###

- Explanatory Supplement to the Astronomical Almanac,
    P. Kenneth Seidelmann (ed), University Science Books (1992)

"""
ttut1

for name in ("taiut1",
             "tdbtt",
             "tttdb",
             "ttut1")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(a, b, c)
            r1 = Ref(0.0)
            r2 = Ref(0.0)
            i = ccall(($fc, liberfa), Cint,
                      (Cdouble, Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}),
                      a, b, c, r1, r2)
            @assert i == 0
            r1[], r2[]
        end
    end
end

"""
    taitt(tai1, tai2)

Time scale transformation:  International Atomic Time, TAI, to
Terrestrial Time, TT.

### Given ###

- `tai1`, `tai2`: TAI as a 2-part Julian Date

### Returned ###

- `tt1`, `tt2`: TT as a 2-part Julian Date

### Note ###

   tai1+tai2 is Julian Date, apportioned in any convenient way
   between the two arguments, for example where tai1 is the Julian
   Day Number and tai2 is the fraction of a day.  The returned
   tt1,tt2 follow suit.

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- Explanatory Supplement to the Astronomical Almanac,
    P. Kenneth Seidelmann (ed), University Science Books (1992)

"""
taitt

"""
    taiutc(tai1, tai2)

Time scale transformation:  International Atomic Time, TAI, to
Coordinated Universal Time, UTC.

### Given ###

- `tai1`, `tai2`: TAI as a 2-part Julian Date (Note 1)

### Returned ###

- `utc1`, `utc2`: UTC as a 2-part quasi Julian Date (Notes 1-3)

### Notes ###

1. tai1+tai2 is Julian Date, apportioned in any convenient way
   between the two arguments, for example where tai1 is the Julian
   Day Number and tai2 is the fraction of a day.  The returned utc1
   and utc2 form an analogous pair, except that a special convention
   is used, to deal with the problem of leap seconds - see the next
   note.

2. JD cannot unambiguously represent UTC during a leap second unless
   special measures are taken.  The convention in the present
   function is that the JD day represents UTC days whether the
   length is 86399, 86400 or 86401 SI seconds.  In the 1960-1972 era
   there were smaller jumps (in either direction) each time the
   linear UTC(TAI) expression was changed, and these "mini-leaps"
   are also included in the ERFA convention.

3. The function eraD2dtf can be used to transform the UTC quasi-JD
   into calendar date and clock time, including UTC leap second
   handling.

4. The warning status "dubious year" flags UTCs that predate the
   introduction of the time scale or that are too far in the future
   to be trusted.  See eraDat for further details.

### Called ###

- `eraUtctai`: UTC to TAI

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- Explanatory Supplement to the Astronomical Almanac,
    P. Kenneth Seidelmann (ed), University Science Books (1992)

"""
taiutc

"""
    tcbtdb(tcb1, tcb2)

Time scale transformation:  Barycentric Coordinate Time, TCB, to
Barycentric Dynamical Time, TDB.

### Given ###

- `tcb1`, `tcb2`: TCB as a 2-part Julian Date

### Returned ###

- `tdb1`, `tdb2`: TDB as a 2-part Julian Date

### Notes ###

1. tcb1+tcb2 is Julian Date, apportioned in any convenient way
   between the two arguments, for example where tcb1 is the Julian
   Day Number and tcb2 is the fraction of a day.  The returned
   tdb1,tdb2 follow suit.

2. The 2006 IAU General Assembly introduced a conventional linear
   transformation between TDB and TCB.  This transformation
   compensates for the drift between TCB and terrestrial time TT,
   and keeps TDB approximately centered on TT.  Because the
   relationship between TT and TCB depends on the adopted solar
   system ephemeris, the degree of alignment between TDB and TT over
   long intervals will vary according to which ephemeris is used.
   Former definitions of TDB attempted to avoid this problem by
   stipulating that TDB and TT should differ only by periodic
   effects.  This is a good description of the nature of the
   relationship but eluded precise mathematical formulation.  The
   conventional linear relationship adopted in 2006 sidestepped
   these difficulties whilst delivering a TDB that in practice was
   consistent with values before that date.

3. TDB is essentially the same as Teph, the time argument for the
   JPL solar system ephemerides.

### Reference ###

- IAU 2006 Resolution B3

"""
tcbtdb

"""
    tcgtt(tcg1, tcg2)

Time scale transformation:  Geocentric Coordinate Time, TCG, to
Terrestrial Time, TT.

### Given ###

- `tcg1`, `tcg2`: TCG as a 2-part Julian Date

### Returned ###

- `tt1`, `tt2`: TT as a 2-part Julian Date

### Note ###

   tcg1+tcg2 is Julian Date, apportioned in any convenient way
   between the two arguments, for example where tcg1 is the Julian
   Day Number and tcg22 is the fraction of a day.  The returned
   tt1,tt2 follow suit.

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),.
    IERS Technical Note No. 32, BKG (2004)

- IAU 2000 Resolution B1.9

"""
tcgtt

"""
    tdbtcb(tdb1, tdb2)

Time scale transformation:  Barycentric Dynamical Time, TDB, to
Barycentric Coordinate Time, TCB.

### Given ###

- `tdb1`, `tdb2`: TDB as a 2-part Julian Date

### Returned ###

- `tcb1`, `tcb2`: TCB as a 2-part Julian Date

### Notes ###

1. tdb1+tdb2 is Julian Date, apportioned in any convenient way
   between the two arguments, for example where tdb1 is the Julian
   Day Number and tdb2 is the fraction of a day.  The returned
   tcb1,tcb2 follow suit.

2. The 2006 IAU General Assembly introduced a conventional linear
   transformation between TDB and TCB.  This transformation
   compensates for the drift between TCB and terrestrial time TT,
   and keeps TDB approximately centered on TT.  Because the
   relationship between TT and TCB depends on the adopted solar
   system ephemeris, the degree of alignment between TDB and TT over
   long intervals will vary according to which ephemeris is used.
   Former definitions of TDB attempted to avoid this problem by
   stipulating that TDB and TT should differ only by periodic
   effects.  This is a good description of the nature of the
   relationship but eluded precise mathematical formulation.  The
   conventional linear relationship adopted in 2006 sidestepped
   these difficulties whilst delivering a TDB that in practice was
   consistent with values before that date.

3. TDB is essentially the same as Teph, the time argument for the
   JPL solar system ephemerides.

### Reference ###

- IAU 2006 Resolution B3

"""
tdbtcb

"""
    tttai(tt1, tt2)

Time scale transformation:  Terrestrial Time, TT, to International
Atomic Time, TAI.

### Given ###

- `tt1`, `tt2`: TT as a 2-part Julian Date

### Returned ###

- `tai1`, `tai2`: TAI as a 2-part Julian Date

### Note ###

   tt1+tt2 is Julian Date, apportioned in any convenient way between
   the two arguments, for example where tt1 is the Julian Day Number
   and tt2 is the fraction of a day.  The returned tai1,tai2 follow
   suit.

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- Explanatory Supplement to the Astronomical Almanac,
    P. Kenneth Seidelmann (ed), University Science Books (1992)

"""
tttai

"""
    tttcg(tt1, tt2)

Time scale transformation:  Terrestrial Time, TT, to Geocentric
Coordinate Time, TCG.

### Given ###

- `tt1`, `tt2`: TT as a 2-part Julian Date

### Returned ###

- `tcg1`, `tcg2`: TCG as a 2-part Julian Date

### Note ###

   tt1+tt2 is Julian Date, apportioned in any convenient way between
   the two arguments, for example where tt1 is the Julian Day Number
   and tt2 is the fraction of a day.  The returned tcg1,tcg2 follow
   suit.

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- IAU 2000 Resolution B1.9

"""
tttcg

for name in ("taitt",
             "taiutc",
             "tcbtdb",
             "tcgtt",
             "tdbtcb",
             "tttai",
             "tttcg")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(a, b)
            r1 = Ref(0.0)
            r2 = Ref(0.0)
            i = ccall(($fc, liberfa), Cint,
                      (Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}),
                      a, b, r1, r2)
            @assert i == 0
            r1[], r2[]
        end
    end
end

"""
    tf2a(s, ihour, imin, sec)

Convert hours, minutes, seconds to radians.

### Given ###

- `s`: Sign:  '-' = negative, otherwise positive
- `ihour`: Hours
- `imin`: Minutes
- `sec`: Seconds

### Returned ###

- `rad`: Angle in radians

### Notes ###

1.  The result is computed even if any of the range checks fail.

2.  Negative ihour, imin and/or sec produce a warning status, but
    the absolute value is used in the conversion.

3.  If there are multiple errors, the status value reflects only the
    first, the smallest taking precedence.

"""
tf2a

"""
    tf2d(s, ihour, imin, sec)

Convert hours, minutes, seconds to days.

### Given ###

- `s`: Sign:  '-' = negative, otherwise positive
- `ihour`: Hours
- `imin`: Minutes
- `sec`: Seconds

### Returned ###

- `days`: Interval in days

### Notes ###

1.  The result is computed even if any of the range checks fail.

2.  Negative ihour, imin and/or sec produce a warning status, but
    the absolute value is used in the conversion.

3.  If there are multiple errors, the status value reflects only the
    first, the smallest taking precedence.

"""
tf2d

for name in ("tf2a",
             "tf2d")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(s, ideg, iamin, asec)
            rad = Ref(0.0)
            i = ccall(($fc, liberfa), Cint,
                      (Cchar, Cint, Cint, Cdouble, Ref{Cdouble}),
                       s, ideg, iamin, asec, rad)
            if i == 1
                throw(ERFAException("ihour outside range 0-23"))
            elseif i == 2
                throw(ERFAException("imin outside range 0-59"))
            elseif i == 3
                throw(ERFAException("sec outside range 0-59.999..."))
            end
            rad[]
        end
    end
end
