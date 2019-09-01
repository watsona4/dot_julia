"""
    ld(bm, p, q, e, em, dlim)

Apply light deflection by a solar-system body, as part of
transforming coordinate direction into natural direction.

### Given ###

- `bm`: Mass of the gravitating body (solar masses)
- `p`: Direction from observer to source (unit vector)
- `q`: Direction from body to source (unit vector)
- `e`: Direction from body to observer (unit vector)
- `em`: Distance from body to observer (au)
- `dlim`: Deflection limiter (Note 4)

### Returned ###

- `p1`: Observer to deflected source (unit vector)

### Notes ###

1. The algorithm is based on Expr. (70) in Klioner (2003) and
   Expr. (7.63) in the Explanatory Supplement (Urban & Seidelmann
   2013), with some rearrangement to minimize the effects of machine
   precision.

2. The mass parameter bm can, as required, be adjusted in order to
   allow for such effects as quadrupole field.

3. The barycentric position of the deflecting body should ideally
   correspond to the time of closest approach of the light ray to
   the body.

4. The deflection limiter parameter dlim is phi^2/2, where phi is
   the angular separation (in radians) between source and body at
   which limiting is applied.  As phi shrinks below the chosen
   threshold, the deflection is artificially reduced, reaching zero
   for phi = 0.

5. The returned vector p1 is not normalized, but the consequential
   departure from unit magnitude is always negligible.

6. The arguments p and p1 can be the same array.

7. To accumulate total light deflection taking into account the
   contributions from several bodies, call the present function for
   each body in succession, in decreasing order of distance from the
   observer.

8. For efficiency, validation is omitted.  The supplied vectors must
   be of unit magnitude, and the deflection limiter non-zero and
   positive.

### References ###

- Urban, S. & Seidelmann, P. K. (eds), Explanatory Supplement to
    the Astronomical Almanac, 3rd ed., University Science Books
    (2013).

- Klioner, Sergei A., "A practical relativistic model for micro-
    arcsecond astrometry in space", Astr. J. 125, 1580-1597 (2003).

### Called ###

- `eraPdp`: scalar product of two p-vectors
- `eraPxp`: vector product of two p-vectors

"""
function ld(bm, p::AbstractArray, q::AbstractArray, e::AbstractArray, em, dlim)
    p1 = zeros(3)
    ccall((:eraLd, liberfa), Cvoid,
          (Cdouble, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Cdouble, Cdouble, Ptr{Cdouble}),
          bm, p, q, e, em, dlim, p1)
    p1
end

"""
    ldn(l::Vector{LDBODY}, ob, sc)

For a star, apply light deflection by multiple solar-system bodies,
as part of transforming coordinate direction into natural direction.

### Given ###

- `n`: Number of bodies (note 1)
- `b`: Data for each of the n bodies (Notes 1,2):
    - `bm`: Mass of the body (solar masses, Note 3)
    - `dl`: Deflection limiter (Note 4)
    - `pv`: Barycentric PV of the body (au, au/day)
- `ob`: Barycentric position of the observer (au)
- `sc`: Observer to star coord direction (unit vector)

### Returned ###

- `sn`: Observer to deflected star (unit vector)

1. The array b contains n entries, one for each body to be
   considered.  If n = 0, no gravitational light deflection will be
   applied, not even for the Sun.

2. The array b should include an entry for the Sun as well as for
   any planet or other body to be taken into account.  The entries
   should be in the order in which the light passes the body.

3. In the entry in the b array for body i, the mass parameter
   b[i].bm can, as required, be adjusted in order to allow for such
   effects as quadrupole field.

4. The deflection limiter parameter b[i].dl is phi^2/2, where phi is
   the angular separation (in radians) between star and body at
   which limiting is applied.  As phi shrinks below the chosen
   threshold, the deflection is artificially reduced, reaching zero
   for phi = 0.   Example values suitable for a terrestrial
   observer, together with masses, are as follows:

      body i     b[i].bm        b[i].dl

      Sun        1.0            6e-6
      Jupiter    0.00095435     3e-9
      Saturn     0.00028574     3e-10

5. For cases where the starlight passes the body before reaching the
   observer, the body is placed back along its barycentric track by
   the light time from that point to the observer.  For cases where
   the body is "behind" the observer no such shift is applied.  If
   a different treatment is preferred, the user has the option of
   instead using the eraLd function.  Similarly, eraLd can be used
   for cases where the source is nearby, not a star.

6. The returned vector sn is not normalized, but the consequential
   departure from unit magnitude is always negligible.

7. The arguments sc and sn can be the same array.

8. For efficiency, validation is omitted.  The supplied masses must
   be greater than zero, the position and velocity vectors must be
   right, and the deflection limiter greater than zero.

### Reference ###

- Urban, S. & Seidelmann, P. K. (eds), Explanatory Supplement to
    the Astronomical Almanac, 3rd ed., University Science Books
    (2013), Section 7.2.4.

### Called ###

- `eraCp`: copy p-vector
- `eraPdp`: scalar product of two p-vectors
- `eraPmp`: p-vector minus p-vector
- `eraPpsp`: p-vector plus scaled p-vector
- `eraPn`: decompose p-vector into modulus and direction
- `eraLd`: light deflection by a solar-system body

"""
function ldn(l::Vector{LDBODY}, ob::AbstractArray, sc::AbstractArray)
    sn = zeros(3)
    n = length(l)
    ccall((:eraLdn, liberfa), Cvoid,
          (Cint, Ptr{LDBODY}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}),
          n, l, ob, sc, sn)
    sn
end

"""
    ldsun(p, e, em)

Deflection of starlight by the Sun.

### Given ###

- `p`: Direction from observer to star (unit vector)
- `e`: Direction from Sun to observer (unit vector)
- `em`: Distance from Sun to observer (au)

### Returned ###

- `p1`: Observer to deflected star (unit vector)

### Notes ###

1. The source is presumed to be sufficiently distant that its
   directions seen from the Sun and the observer are essentially
   the same.

2. The deflection is restrained when the angle between the star and
   the center of the Sun is less than a threshold value, falling to
   zero deflection for zero separation.  The chosen threshold value
   is within the solar limb for all solar-system applications, and
   is about 5 arcminutes for the case of a terrestrial observer.

3. The arguments p and p1 can be the same array.

### Called ###

- `eraLd`: light deflection by a solar-system body

"""
function ldsun(p, e, em)
    p1 = zeros(3)
    ccall((:eraLdsun, liberfa), Cvoid,
          (Ptr{Cdouble}, Ptr{Cdouble}, Cdouble, Ptr{Cdouble}),
          p, e, em, p1)
    p1
end

"""
    ltecm(dr, dd)

ICRS equatorial to ecliptic rotation matrix, long-term.

### Given ###

- `epj`: Julian epoch (TT)

### Returned ###

- `rm`: ICRS to ecliptic rotation matrix

### Notes ###

1. The matrix is in the sense

      E_ep = rm x P_ICRS,

   where P_ICRS is a vector with respect to ICRS right ascension
   and declination axes and E_ep is the same vector with respect to
   the (inertial) ecliptic and equinox of epoch epj.

2. P_ICRS is a free vector, merely a direction, typically of unit
   magnitude, and not bound to any particular spatial origin, such
   as the Earth, Sun or SSB.  No assumptions are made about whether
   it represents starlight and embodies astrometric effects such as
   parallax or aberration.  The transformation is approximately that
   between mean J2000.0 right ascension and declination and ecliptic
   longitude and latitude, with only frame bias (always less than
   25 mas) to disturb this classical picture.

3. The Vondrak et al. (2011, 2012) 400 millennia precession model
   agrees with the IAU 2006 precession at J2000.0 and stays within
   100 microarcseconds during the 20th and 21st centuries.  It is
   accurate to a few arcseconds throughout the historical period,
   worsening to a few tenths of a degree at the end of the
   +/- 200,000 year time span.

### Called ###

- `eraLtpequ`: equator pole, long term
- `eraLtpecl`: ecliptic pole, long term
- `eraPxp`: vector product
- `eraPn`: normalize vector

### References ###

- Vondrak, J., Capitaine, N. and Wallace, P., 2011, New precession
    expressions, valid for long time intervals, Astron.Astrophys. 534,
    A22

- Vondrak, J., Capitaine, N. and Wallace, P., 2012, New precession
    expressions, valid for long time intervals (Corrigendum),
    Astron.Astrophys. 541, C1

"""
ltecm

"""
    ltp(dr, dd)

Long-term precession matrix.

### Given ###

- `epj`: Julian epoch (TT)

### Returned ###

- `rp`: Precession matrix, J2000.0 to date

### Notes ###

1. The matrix is in the sense

      P_date = rp x P_J2000,

   where P_J2000 is a vector with respect to the J2000.0 mean
   equator and equinox and P_date is the same vector with respect to
   the equator and equinox of epoch epj.

2. The Vondrak et al. (2011, 2012) 400 millennia precession model
   agrees with the IAU 2006 precession at J2000.0 and stays within
   100 microarcseconds during the 20th and 21st centuries.  It is
   accurate to a few arcseconds throughout the historical period,
   worsening to a few tenths of a degree at the end of the
   +/- 200,000 year time span.

### Called ###

- `eraLtpequ`: equator pole, long term
- `eraLtpecl`: ecliptic pole, long term
- `eraPxp`: vector product
- `eraPn`: normalize vector

### References ###

- Vondrak, J., Capitaine, N. and Wallace, P., 2011, New precession
    expressions, valid for long time intervals, Astron.Astrophys. 534,
    A22

- Vondrak, J., Capitaine, N. and Wallace, P., 2012, New precession
    expressions, valid for long time intervals (Corrigendum),
    Astron.Astrophys. 541, C1

"""
ltp

"""
    ltpb(dr, dd)

Long-term precession matrix, including ICRS frame bias.

### Given ###

- `epj`: Julian epoch (TT)

### Returned ###

- `rpb`: Precession-bias matrix, J2000.0 to date

### Notes ###

1. The matrix is in the sense

      P_date = rpb x P_ICRS,

   where P_ICRS is a vector in the Geocentric Celestial Reference
   System, and P_date is the vector with respect to the Celestial
   Intermediate Reference System at that date but with nutation
   neglected.

2. A first order frame bias formulation is used, of sub-
   microarcsecond accuracy compared with a full 3D rotation.

3. The Vondrak et al. (2011, 2012) 400 millennia precession model
   agrees with the IAU 2006 precession at J2000.0 and stays within
   100 microarcseconds during the 20th and 21st centuries.  It is
   accurate to a few arcseconds throughout the historical period,
   worsening to a few tenths of a degree at the end of the
   +/- 200,000 year time span.

### References ###

- Vondrak, J., Capitaine, N. and Wallace, P., 2011, New precession
    expressions, valid for long time intervals, Astron.Astrophys. 534,
    A22

- Vondrak, J., Capitaine, N. and Wallace, P., 2012, New precession
    expressions, valid for long time intervals (Corrigendum),
    Astron.Astrophys. 541, C1

"""
ltpb

for name in ("ltecm",
             "ltp",
             "ltpb")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(epj)
            rp = zeros((3, 3))
            ccall(($fc, liberfa), Cvoid,
                  (Cdouble, Ptr{Cdouble}),
                  epj, rp)
            rp
        end
    end
end

"""
    ltpecl(epj)

Long-term precession of the ecliptic.

### Given ###

- `epj`: Julian epoch (TT)

### Returned ###

- `vec`: Ecliptic pole unit vector

### Notes ###

1. The returned vector is with respect to the J2000.0 mean equator
   and equinox.

2. The Vondrak et al. (2011, 2012) 400 millennia precession model
   agrees with the IAU 2006 precession at J2000.0 and stays within
   100 microarcseconds during the 20th and 21st centuries.  It is
   accurate to a few arcseconds throughout the historical period,
   worsening to a few tenths of a degree at the end of the
   +/- 200,000 year time span.

### References ###

- Vondrak, J., Capitaine, N. and Wallace, P., 2011, New precession
    expressions, valid for long time intervals, Astron.Astrophys. 534,
    A22

- Vondrak, J., Capitaine, N. and Wallace, P., 2012, New precession
    expressions, valid for long time intervals (Corrigendum),
    Astron.Astrophys. 541, C1

"""
ltpecl

"""
    ltpequ(epj)

Long-term precession of the equator.

### Given ###

- `epj`: Julian epoch (TT)

### Returned ###

- `veq`: Equator pole unit vector

### Notes ###

1. The returned vector is with respect to the J2000.0 mean equator
   and equinox.

2. The Vondrak et al. (2011, 2012) 400 millennia precession model
   agrees with the IAU 2006 precession at J2000.0 and stays within
   100 microarcseconds during the 20th and 21st centuries.  It is
   accurate to a few arcseconds throughout the historical period,
   worsening to a few tenths of a degree at the end of the
   +/- 200,000 year time span.

### References ###

- Vondrak, J., Capitaine, N. and Wallace, P., 2011, New precession
    expressions, valid for long time intervals, Astron.Astrophys. 534,
    A22

- Vondrak, J., Capitaine, N. and Wallace, P., 2012, New precession
    expressions, valid for long time intervals (Corrigendum),
    Astron.Astrophys. 541, C1

"""
ltpequ

for name in ("ltpecl",
             "ltpequ")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(epj)
            vec = zeros(3)
            ccall(($fc, liberfa), Cvoid,
                  (Cdouble, Ptr{Cdouble}),
                  epj, vec)
            vec
        end
    end
end

"""
    lteceq(epj, dr, dd)

Transformation from ecliptic coordinates (mean equinox and ecliptic
of date) to ICRS RA,Dec, using a long-term precession model.

### Given ###

- `epj`: Julian epoch (TT)
- `dl`, `db`: Ecliptic longitude and latitude (radians)

### Returned ###

- `dr`, `dd`: ICRS right ascension and declination (radians)

1. No assumptions are made about whether the coordinates represent
   starlight and embody astrometric effects such as parallax or
   aberration.

2. The transformation is approximately that from ecliptic longitude
   and latitude (mean equinox and ecliptic of date) to mean J2000.0
   right ascension and declination, with only frame bias (always
   less than 25 mas) to disturb this classical picture.

3. The Vondrak et al. (2011, 2012) 400 millennia precession model
   agrees with the IAU 2006 precession at J2000.0 and stays within
   100 microarcseconds during the 20th and 21st centuries.  It is
   accurate to a few arcseconds throughout the historical period,
   worsening to a few tenths of a degree at the end of the
   +/- 200,000 year time span.

### Called ###

- `eraS2c`: spherical coordinates to unit vector
- `eraLtecm`: J2000.0 to ecliptic rotation matrix, long term
- `eraTrxp`: product of transpose of r-matrix and p-vector
- `eraC2s`: unit vector to spherical coordinates
- `eraAnp`: normalize angle into range 0 to 2pi
- `eraAnpm`: normalize angle into range +/- pi

### References ###

- Vondrak, J., Capitaine, N. and Wallace, P., 2011, New precession
    expressions, valid for long time intervals, Astron.Astrophys. 534,
    A22

- Vondrak, J., Capitaine, N. and Wallace, P., 2012, New precession
    expressions, valid for long time intervals (Corrigendum),
    Astron.Astrophys. 541, C1

"""
lteceq

"""
    lteqec(epj, dr, dd)

Transformation from ICRS equatorial coordinates to ecliptic
coordinates (mean equinox and ecliptic of date) using a long-term
precession model.

### Given ###

- `epj`: Julian epoch (TT)
- `dr`, `dd`: ICRS right ascension and declination (radians)

### Returned ###

- `dl`, `db`: Ecliptic longitude and latitude (radians)

1. No assumptions are made about whether the coordinates represent
   starlight and embody astrometric effects such as parallax or
   aberration.

2. The transformation is approximately that from mean J2000.0 right
   ascension and declination to ecliptic longitude and latitude
   (mean equinox and ecliptic of date), with only frame bias (always
   less than 25 mas) to disturb this classical picture.

3. The Vondrak et al. (2011, 2012) 400 millennia precession model
   agrees with the IAU 2006 precession at J2000.0 and stays within
   100 microarcseconds during the 20th and 21st centuries.  It is
   accurate to a few arcseconds throughout the historical period,
   worsening to a few tenths of a degree at the end of the
   +/- 200,000 year time span.

### Called ###

- `eraS2c`: spherical coordinates to unit vector
- `eraLtecm`: J2000.0 to ecliptic rotation matrix, long term
- `eraRxp`: product of r-matrix and p-vector
- `eraC2s`: unit vector to spherical coordinates
- `eraAnp`: normalize angle into range 0 to 2pi
- `eraAnpm`: normalize angle into range +/- pi

### References ###

- Vondrak, J., Capitaine, N. and Wallace, P., 2011, New precession
    expressions, valid for long time intervals, Astron.Astrophys. 534,
    A22

- Vondrak, J., Capitaine, N. and Wallace, P., 2012, New precession
    expressions, valid for long time intervals (Corrigendum),
    Astron.Astrophys. 541, C1

"""
lteqec

for name in ("lteceq",
             "lteqec")
    f = Symbol(name)
    fc = "era" * uppercasefirst(name)
    @eval begin
        function ($f)(epj, d1, d2)
            r1 = [0.0]
            r2 = [0.0]
            ccall(($fc, liberfa), Cvoid,
                  (Cdouble, Cdouble, Cdouble, Ptr{Cdouble}, Ptr{Cdouble}),
                  epj, d1, d2, r1, r2)
            r1[1], r2[1]
        end
    end
end
