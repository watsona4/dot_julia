"""
    dtdb(date1, date2, ut, elong, u, v)

An approximation to TDB-TT, the difference between barycentric
dynamical time and terrestrial time, for an observer on the Earth.

The different time scales - proper, coordinate and realized - are
related to each other:

          TAI             <-  physically realized
           :
        offset            <-  observed (nominally +32.184s)
           :
          TT              <-  terrestrial time
           :
  rate adjustment (L_G)   <-  definition of TT
           :
          TCG             <-  time scale for GCRS
           :
    "periodic" terms      <-  eraDtdb  is an implementation
           :
  rate adjustment (L_C)   <-  function of solar-system ephemeris
           :
          TCB             <-  time scale for BCRS
           :
  rate adjustment (-L_B)  <-  definition of TDB
           :
          TDB             <-  TCB scaled to track TT
           :
    "periodic" terms      <-  -eraDtdb is an approximation
           :
          TT              <-  terrestrial time

Adopted values for the various constants can be found in the IERS
Conventions (McCarthy & Petit 2003).

### Given ###

- `date1`, `date2`: Date, TDB (Notes 1-3)
- `ut`: Universal time (UT1, fraction of one day)
- `elong`: Longitude (east positive, radians)
- `u`: Distance from Earth spin axis (km)
- `v`: Distance north of equatorial plane (km)

### Returned ###

- TDB-TT (seconds)

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

   Although the date is, formally, barycentric dynamical time (TDB),
   the terrestrial dynamical time (TT) can be used with no practical
   effect on the accuracy of the prediction.

2. TT can be regarded as a coordinate time that is realized as an
   offset of 32.184s from International Atomic Time, TAI.  TT is a
   specific linear transformation of geocentric coordinate time TCG,
   which is the time scale for the Geocentric Celestial Reference
   System, GCRS.

3. TDB is a coordinate time, and is a specific linear transformation
   of barycentric coordinate time TCB, which is the time scale for
   the Barycentric Celestial Reference System, BCRS.

4. The difference TCG-TCB depends on the masses and positions of the
   bodies of the solar system and the velocity of the Earth.  It is
   dominated by a rate difference, the residual being of a periodic
   character.  The latter, which is modeled by the present function,
   comprises a main (annual) sinusoidal term of amplitude
   approximately 0.00166 seconds, plus planetary terms up to about
   20 microseconds, and lunar and diurnal terms up to 2 microseconds.
   These effects come from the changing transverse Doppler effect
   and gravitational red-shift as the observer (on the Earth's
   surface) experiences variations in speed (with respect to the
   BCRS) and gravitational potential.

5. TDB can be regarded as the same as TCB but with a rate adjustment
   to keep it close to TT, which is convenient for many applications.
   The history of successive attempts to define TDB is set out in
   Resolution 3 adopted by the IAU General Assembly in 2006, which
   defines a fixed TDB(TCB) transformation that is consistent with
   contemporary solar-system ephemerides.  Future ephemerides will
   imply slightly changed transformations between TCG and TCB, which
   could introduce a linear drift between TDB and TT;  however, any
   such drift is unlikely to exceed 1 nanosecond per century.

6. The geocentric TDB-TT model used in the present function is that of
   Fairhead & Bretagnon (1990), in its full form.  It was originally
   supplied by Fairhead (private communications with P.T.Wallace,
   1990. as a Fortran subroutine.  The present C function contains an
   adaptation of the Fairhead code.  The numerical results are
   essentially unaffected by the changes, the differences with
   respect to the Fairhead & Bretagnon original being at the 1e-20 s
   level.

   The topocentric part of the model is from Moyer (1981) and
   Murray (1983), with fundamental arguments adapted from
   Simon et al. 1994.  It is an approximation to the expression
   ( v / c ) . ( r / c ), where v is the barycentric velocity of
   the Earth, r is the geocentric position of the observer and
   c is the speed of light.

   By supplying zeroes for u and v, the topocentric part of the
   model can be nullified, and the function will return the Fairhead
   & Bretagnon result alone.

7. During the interval 1950-2050, the absolute accuracy is better
   than +/- 3 nanoseconds relative to time ephemerides obtained by
   direct numerical integrations based on the JPL DE405 solar system
   ephemeris.

8. It must be stressed that the present function is merely a model,
   and that numerical integration of solar-system ephemerides is the
   definitive method for predicting the relationship between TCG and
   TCB and hence between TT and TDB.

### References ###

- Fairhead, L., & Bretagnon, P., Astron.Astrophys., 229, 240-247
    (1990).

- IAU 2006 Resolution 3.

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- Moyer, T.D., Cel.Mech., 23, 33 (1981).

- Murray, C.A., Vectorial Astrometry, Adam Hilger (1983).

- Seidelmann, P.K. et al., Explanatory Supplement to the
    Astronomical Almanac, Chapter 2, University Science Books (1992).

- Simon, J.L., Bretagnon, P., Chapront, J., Chapront-Touze, M.,
    Francou, G. & Laskar, J., Astron.Astrophys., 282, 663-683 (1994).

"""
function dtdb(date1, date2, ut, elong, u, v)
    ccall((:eraDtdb, liberfa), Cdouble,
          (Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble),
          date1, date2, ut, elong, u, v)
end

"""
    dat(iy, im, id, fd)

For a given UTC date, calculate delta(AT) = TAI-UTC.

!!! warning "IMPORTANT"
    A new version of this function must be
    produced whenever a new leap second is
    announced.  There are four items to   
    change on each such occasion:         
                                            
    1. A new line must be added to the set
        of statements that initialize the  
        array "changes".                   
                                            
    2. The constant IYV must be set to the
        current year.                      
                                            
    3. The "Latest leap second" comment   
        below must be set to the new leap  
        second date.                       
                                            
    4. The "This revision" comment, later,
        must be set to the current date.   
                                            
    Change (2) must also be carried out   
    whenever the function is re-issued,   
    even if no leap seconds have been     
    added.                                
                                            
    Latest leap second:  2016 December 31 

### Given ###

- `iy`: UTC:  year (Notes 1 and 2)
- `im`: Month (Note 2)
- `id`: Day (Notes 2 and 3)
- `fd`: Fraction of day (Note 4)

### Returned ###

- `deltat`: TAI minus UTC, seconds

### Notes ###

1. UTC began at 1960 January 1.0 (JD 2436934.5) and it is improper
   to call the function with an earlier date.  If this is attempted,
   zero is returned together with a warning status.

   Because leap seconds cannot, in principle, be predicted in
   advance, a reliable check for dates beyond the valid range is
   impossible.  To guard against gross errors, a year five or more
   after the release year of the present function (see the constant
   IYV) is considered dubious.  In this case a warning status is
   returned but the result is computed in the normal way.

   For both too-early and too-late years, the warning status is +1.
   This is distinct from the error status -1, which signifies a year
   so early that JD could not be computed.

2. If the specified date is for a day which ends with a leap second,
   the TAI-UTC value returned is for the period leading up to the
   leap second.  If the date is for a day which begins as a leap
   second ends, the TAI-UTC returned is for the period following the
   leap second.

3. The day number must be in the normal calendar range, for example
   1 through 30 for April.  The "almanac" convention of allowing
   such dates as January 0 and December 32 is not supported in this
   function, in order to avoid confusion near leap seconds.

4. The fraction of day is used only for dates before the
   introduction of leap seconds, the first of which occurred at the
   end of 1971.  It is tested for validity (0 to 1 is the valid
   range) even if not used;  if invalid, zero is used and status -4
   is returned.  For many applications, setting fd to zero is
   acceptable;  the resulting error is always less than 3 ms (and
   occurs only pre-1972).

5. The status value returned in the case where there are multiple
   errors refers to the first error detected.  For example, if the
   month and day are 13 and 32 respectively, status -2 (bad month)
   will be returned.  The "internal error" status refers to a
   case that is impossible but causes some compilers to issue a
   warning.

6. In cases where a valid result is not available, zero is returned.

### References ###

- 1) For dates from 1961 January 1 onwards, the expressions from the
    file ftp://maia.usno.navy.mil/ser7/tai-utc.dat are used.

- 2) The 5ms timestep at 1961 January 1 is taken from 2.58.1 (p87) of
    the 1992 Explanatory Supplement.

### Called ###

- `eraCal2jd`: Gregorian calendar to JD

"""
function dat(iy, im, id, fd)
    d = Ref(0.0)
    i = ccall((:eraDat, liberfa), Cint,
              (Cint, Cint, Cint, Cdouble, Ref{Cdouble}),
              iy, im, id, fd, d)
    if i == 1
        @warn "dubious year (Note 1)"
    elseif i == -1
        throw(ERFAException("bad year"))
    elseif i == -2
        throw(ERFAException("bad month"))
    elseif i == -3
        throw(ERFAException("bad day (Note 3)"))
    elseif i == -4
        throw(ERFAException("bad fraction (Note 4)"))
    elseif i == -5
        throw(ERFAException("internal error (Note 5)"))
    end
    d[]
end

"""
    d2dtf(scale, ndp, d1, d2)

Format for output a 2-part Julian Date (or in the case of UTC a
quasi-JD form that includes special provision for leap seconds).

### Given ###

- `scale`: Time scale ID (Note 1)
- `ndp`: Resolution (Note 2)
- `d1`, `d2`: Time as a 2-part Julian Date (Notes 3,4)

### Returned ###

- `iy`, `im`, `id`: Year, month, day in Gregorian calendar (Note 5)
- `ihmsf`: Hours, minutes, seconds, fraction (Note 1)

### Notes ###

1. scale identifies the time scale.  Only the value "UTC" (in upper
   case) is significant, and enables handling of leap seconds (see
   Note 4).

2. ndp is the number of decimal places in the seconds field, and can
   have negative as well as positive values, such as:

   ndp         resolution
   -4            1 00 00
   -3            0 10 00
   -2            0 01 00
   -1            0 00 10
    0            0 00 01
    1            0 00 00.1
    2            0 00 00.01
    3            0 00 00.001

   The limits are platform dependent, but a safe range is -5 to +9.

3. d1+d2 is Julian Date, apportioned in any convenient way between
   the two arguments, for example where d1 is the Julian Day Number
   and d2 is the fraction of a day.  In the case of UTC, where the
   use of JD is problematical, special conventions apply:  see the
   next note.

4. JD cannot unambiguously represent UTC during a leap second unless
   special measures are taken.  The ERFA internal convention is that
   the quasi-JD day represents UTC days whether the length is 86399,
   86400 or 86401 SI seconds.  In the 1960-1972 era there were
   smaller jumps (in either direction) each time the linear UTC(TAI)
   expression was changed, and these "mini-leaps" are also included
   in the ERFA convention.

5. The warning status "dubious year" flags UTCs that predate the
   introduction of the time scale or that are too far in the future
   to be trusted.  See eraDat for further details.

6. For calendar conventions and limitations, see eraCal2jd.

### Called ###

- `eraJd2cal`: JD to Gregorian calendar
- `eraD2tf`: decompose days to hms
- `eraDat`: delta(AT) = TAI-UTC

"""
function d2dtf(scale::AbstractString, ndp, d1, d2)
    iy = Ref{Cint}(0)
    imo = Ref{Cint}(0)
    id = Ref{Cint}(0)
    ihmsf = Cint[0, 0, 0, 0]
    i = ccall((:eraD2dtf, liberfa), Cint,
              (Cstring, Cint, Cdouble, Cdouble, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ptr{Cint}),
              scale, ndp, d1, d2, iy, imo, id, ihmsf)
    if i == +1
        @warn "dubious year (Note 5)"
    elseif i == -1
        throw(ERFAException("unacceptable date (Note 6)"))
    end
    iy[], imo[], id[], ihmsf[1], ihmsf[2], ihmsf[3], ihmsf[4]
end

"""
    dtf2d(scale, iy, imo, id, ih, imi, sec)

Encode date and time fields into 2-part Julian Date (or in the case
of UTC a quasi-JD form that includes special provision for leap
seconds).

### Given ###

- `scale`: Time scale ID (Note 1)
- `iy`, `im`, `id`: Year, month, day in Gregorian calendar (Note 2)
- `ihr`, `imn`: Hour, minute
- `sec`: Seconds

### Returned ###

- `d1`, `d2`: 2-part Julian Date (Notes 3,4)

### Notes ###

1. scale identifies the time scale.  Only the value "UTC" (in upper
   case) is significant, and enables handling of leap seconds (see
   Note 4).

2. For calendar conventions and limitations, see eraCal2jd.

3. The sum of the results, d1+d2, is Julian Date, where normally d1
   is the Julian Day Number and d2 is the fraction of a day.  In the
   case of UTC, where the use of JD is problematical, special
   conventions apply:  see the next note.

4. JD cannot unambiguously represent UTC during a leap second unless
   special measures are taken.  The ERFA internal convention is that
   the quasi-JD day represents UTC days whether the length is 86399,
   86400 or 86401 SI seconds.  In the 1960-1972 era there were
   smaller jumps (in either direction) each time the linear UTC(TAI)
   expression was changed, and these "mini-leaps" are also included
   in the ERFA convention.

5. The warning status "time is after end of day" usually means that
   the sec argument is greater than 60.0.  However, in a day ending
   in a leap second the limit changes to 61.0 (or 59.0 in the case
   of a negative leap second).

6. The warning status "dubious year" flags UTCs that predate the
   introduction of the time scale or that are too far in the future
   to be trusted.  See eraDat for further details.

7. Only in the case of continuous and regular time scales (TAI, TT,
   TCG, TCB and TDB) is the result d1+d2 a Julian Date, strictly
   speaking.  In the other cases (UT1 and UTC) the result must be
   used with circumspection;  in particular the difference between
   two such results cannot be interpreted as a precise time
   interval.

### Called ###

- `eraCal2jd`: Gregorian calendar to JD
- `eraDat`: delta(AT) = TAI-UTC
- `eraJd2cal`: JD to Gregorian calendar

"""
function dtf2d(scale::AbstractString, iy, imo, id, ih, imi, sec)
    r1 = Ref(0.0)
    r2 = Ref(0.0)
    i = ccall((:eraDtf2d, liberfa), Cint,
              (Cstring, Cint, Cint, Cint, Cint, Cint, Cdouble, Ref{Cdouble}, Ref{Cdouble}),
              scale, iy, imo, id, ih, imi, sec, r1, r2)
    if i == 3
        @warn "both of next two"
    elseif i == 2
        @warn "time is after end of day (Note 5)"
    elseif i == 1
        @warn "dubious year (Note 6)"
    elseif i == -1
        throw(ERFAException("bad year"))
    elseif i == -2
        throw(ERFAException("bad month"))
    elseif i == -3
        throw(ERFAException("bad day"))
    elseif i == -4
        throw(ERFAException("bad hour"))
    elseif i == -5
        throw(ERFAException("bad minute"))
    elseif i == -6
        throw(ERFAException("bad second (<0)"))
    end
    r1[], r2[]
end

"""
    d2tf(ndp, a)

Decompose days to hours, minutes, seconds, fraction.

### Given ###

- `ndp`: Resolution (Note 1)
- `days`: Interval in days

### Returned ###

- `sign`: '+' or '-'
- `ihmsf`: Hours, minutes, seconds, fraction

### Notes ###

1. The argument ndp is interpreted as follows:

   ndp         resolution
    :      ...0000 00 00
   -7         1000 00 00
   -6          100 00 00
   -5           10 00 00
   -4            1 00 00
   -3            0 10 00
   -2            0 01 00
   -1            0 00 10
    0            0 00 01
    1            0 00 00.1
    2            0 00 00.01
    3            0 00 00.001
    :            0 00 00.000...

2. The largest positive useful value for ndp is determined by the
   size of days, the format of double on the target platform, and
   the risk of overflowing ihmsf[3].  On a typical platform, for
   days up to 1.0, the available floating-point precision might
   correspond to ndp=12.  However, the practical limit is typically
   ndp=9, set by the capacity of a 32-bit int, or ndp=4 if int is
   only 16 bits.

3. The absolute value of days may exceed 1.0.  In cases where it
   does not, it is up to the caller to test for and handle the
   case where days is very nearly 1.0 and rounds up to 24 hours,
   by testing for ihmsf[0]=24 and setting ihmsf[0-3] to zero.

"""
function d2tf(ndp, a)
    s = Ref{Cchar}('+')
    i = zeros(Cint, 4)
    ccall((:eraD2tf, liberfa), Cvoid,
            (Cint, Cdouble, Ptr{Cchar}, Ptr{Cint}),
            ndp, a, s, i)
    Char(s[]), i[1], i[2], i[3], i[4]
end
