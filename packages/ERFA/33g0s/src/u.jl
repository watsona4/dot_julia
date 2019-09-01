"""
    ut1tai(ut11, ut12, dta)

Time scale transformation:  Universal Time, UT1, to International
Atomic Time, TAI.

### Given ###

- `ut11`, `ut12`: UT1 as a 2-part Julian Date
- `dta`: UT1-TAI in seconds

### Returned ###

- `tai1`, `tai2`: TAI as a 2-part Julian Date

### Notes ###

1. ut11+ut12 is Julian Date, apportioned in any convenient way
   between the two arguments, for example where ut11 is the Julian
   Day Number and ut12 is the fraction of a day.  The returned
   tai1,tai2 follow suit.

2. The argument dta, i.e. UT1-TAI, is an observed quantity, and is
   available from IERS tabulations.

### Reference ###

- Explanatory Supplement to the Astronomical Almanac,
    P. Kenneth Seidelmann (ed), University Science Books (1992)

"""
ut1tai

"""
    ut1tt(ut11, ut12, dt)

Time scale transformation:  Universal Time, UT1, to Terrestrial
Time, TT.

### Given ###

- `ut11`, `ut12`: UT1 as a 2-part Julian Date
- `dt`: TT-UT1 in seconds

### Returned ###

- `tt1`, `tt2`: TT as a 2-part Julian Date

### Notes ###

1. ut11+ut12 is Julian Date, apportioned in any convenient way
   between the two arguments, for example where ut11 is the Julian
   Day Number and ut12 is the fraction of a day.  The returned
   tt1,tt2 follow suit.

2. The argument dt is classical Delta T.

### Reference ###

- Explanatory Supplement to the Astronomical Almanac,
    P. Kenneth Seidelmann (ed), University Science Books (1992)

"""
ut1tt

"""
    ut1utc(ut11, ut12, dut1)

Time scale transformation:  Universal Time, UT1, to Coordinated
Universal Time, UTC.

### Given ###

- `ut11`, `ut12`: UT1 as a 2-part Julian Date (Note 1)
- `dut1`: Delta UT1: UT1-UTC in seconds (Note 2)

### Returned ###

- `utc1`, `utc2`: UTC as a 2-part quasi Julian Date (Notes 3,4)

### Notes ###

1. ut11+ut12 is Julian Date, apportioned in any convenient way
   between the two arguments, for example where ut11 is the Julian
   Day Number and ut12 is the fraction of a day.  The returned utc1
   and utc2 form an analogous pair, except that a special convention
   is used, to deal with the problem of leap seconds - see Note 3.

2. Delta UT1 can be obtained from tabulations provided by the
   International Earth Rotation and Reference Systems Service.  The
   value changes abruptly by 1s at a leap second;  however, close to
   a leap second the algorithm used here is tolerant of the "wrong"
   choice of value being made.

3. JD cannot unambiguously represent UTC during a leap second unless
   special measures are taken.  The convention in the present
   function is that the returned quasi JD day UTC1+UTC2 represents
   UTC days whether the length is 86399, 86400 or 86401 SI seconds.

4. The function eraD2dtf can be used to transform the UTC quasi-JD
   into calendar date and clock time, including UTC leap second
   handling.

5. The warning status "dubious year" flags UTCs that predate the
   introduction of the time scale or that are too far in the future
   to be trusted.  See eraDat for further details.

### Called ###

- `eraJd2cal`: JD to Gregorian calendar
- `eraDat`: delta(AT) = TAI-UTC
- `eraCal2jd`: Gregorian calendar to JD

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- Explanatory Supplement to the Astronomical Almanac,
    P. Kenneth Seidelmann (ed), University Science Books (1992)

"""
ut1utc

"""
    utcut1(utc1, utc2, dut1)

Time scale transformation:  Coordinated Universal Time, UTC, to
Universal Time, UT1.

### Given ###

- `utc1`, `utc2`: UTC as a 2-part quasi Julian Date (Notes 1-4)
- `dut1`: Delta UT1 = UT1-UTC in seconds (Note 5)

### Returned ###

- `ut11`, `ut12`: UT1 as a 2-part Julian Date (Note 6)

### Notes ###

1. utc1+utc2 is quasi Julian Date (see Note 2), apportioned in any
   convenient way between the two arguments, for example where utc1
   is the Julian Day Number and utc2 is the fraction of a day.

2. JD cannot unambiguously represent UTC during a leap second unless
   special measures are taken.  The convention in the present
   function is that the JD day represents UTC days whether the
   length is 86399, 86400 or 86401 SI seconds.

3. The warning status "dubious year" flags UTCs that predate the
   introduction of the time scale or that are too far in the future
   to be trusted.  See eraDat for further details.

4. The function eraDtf2d converts from calendar date and time of
   day into 2-part Julian Date, and in the case of UTC implements
   the leap-second-ambiguity convention described above.

5. Delta UT1 can be obtained from tabulations provided by the
   International Earth Rotation and Reference Systems Service.
   It is the caller's responsibility to supply a dut1 argument
   containing the UT1-UTC value that matches the given UTC.

6. The returned ut11,ut12 are such that their sum is the UT1 Julian
   Date.

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- Explanatory Supplement to the Astronomical Almanac,
    P. Kenneth Seidelmann (ed), University Science Books (1992)

### Called ###

- `eraJd2cal`: JD to Gregorian calendar
- `eraDat`: delta(AT) = TAI-UTC
- `eraUtctai`: UTC to TAI
- `eraTaiut1`: TAI to UT1

"""
utcut1

for name in ("ut1tai",
             "ut1tt",
             "ut1utc",
             "utcut1")
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
    utctai(utc1, utc2)

Time scale transformation:  Coordinated Universal Time, UTC, to
International Atomic Time, TAI.

### Given ###

- `utc1`, `utc2`: UTC as a 2-part quasi Julian Date (Notes 1-4)

### Returned ###

- `tai1`, `tai2`: TAI as a 2-part Julian Date (Note 5)

### Notes ###

1. utc1+utc2 is quasi Julian Date (see Note 2), apportioned in any
   convenient way between the two arguments, for example where utc1
   is the Julian Day Number and utc2 is the fraction of a day.

2. JD cannot unambiguously represent UTC during a leap second unless
   special measures are taken.  The convention in the present
   function is that the JD day represents UTC days whether the
   length is 86399, 86400 or 86401 SI seconds.  In the 1960-1972 era
   there were smaller jumps (in either direction) each time the
   linear UTC(TAI) expression was changed, and these "mini-leaps"
   are also included in the ERFA convention.

3. The warning status "dubious year" flags UTCs that predate the
   introduction of the time scale or that are too far in the future
   to be trusted.  See eraDat for further details.

4. The function eraDtf2d converts from calendar date and time of day
   into 2-part Julian Date, and in the case of UTC implements the
   leap-second-ambiguity convention described above.

5. The returned TAI1,TAI2 are such that their sum is the TAI Julian
   Date.

### Called ###

- `eraJd2cal`: JD to Gregorian calendar
- `eraDat`: delta(AT) = TAI-UTC
- `eraCal2jd`: Gregorian calendar to JD

### References ###

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- Explanatory Supplement to the Astronomical Almanac,
    P. Kenneth Seidelmann (ed), University Science Books (1992)

"""
function utctai(a, b)
    r1 = Ref(0.0)
    r2 = Ref(0.0)
    i = ccall((:eraUtctai, liberfa), Cint,
                (Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}),
                a, b, r1, r2)
    if i == 1
        @warn "dubious year (Note 3)"
    elseif i == -1
        throw(ERFAException("unacceptable date"))
    end
    r1[], r2[]
end
