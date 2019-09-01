"""
    hfk5z(rh, dh, date1, date2)

Transform a Hipparcos star position into FK5 J2000.0, assuming
zero Hipparcos proper motion.

### Given ###

- `rh`: Hipparcos RA (radians)
- `dh`: Hipparcos Dec (radians)
- `date1`, `date2`: TDB date (Note 1)

### Returned (all FK5, equinox J2000.0, date date1+date2) ###

- `r5`: RA (radians)
- `d5`: Dec (radians)
- `dr5`: FK5 RA proper motion (rad/year, Note 4)
- `dd5`: Dec proper motion (rad/year, Note 4)

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

2. The proper motion in RA is dRA/dt rather than cos(Dec)*dRA/dt.

3. The FK5 to Hipparcos transformation is modeled as a pure rotation
   and spin;  zonal errors in the FK5 catalogue are not taken into
   account.

4. It was the intention that Hipparcos should be a close
   approximation to an inertial frame, so that distant objects have
   zero proper motion;  such objects have (in general) non-zero
   proper motion in FK5, and this function returns those fictitious
   proper motions.

5. The position returned by this function is in the FK5 J2000.0
   reference system but at date date1+date2.

6. See also eraFk52h, eraH2fk5, eraFk5zhz.

### Called ###

- `eraS2c`: spherical coordinates to unit vector
- `eraFk5hip`: FK5 to Hipparcos rotation and spin
- `eraRxp`: product of r-matrix and p-vector
- `eraSxp`: multiply p-vector by scalar
- `eraRxr`: product of two r-matrices
- `eraTrxp`: product of transpose of r-matrix and p-vector
- `eraPxp`: vector product of two p-vectors
- `eraPv2s`: pv-vector to spherical
- `eraAnp`: normalize angle into range 0 to 2pi

### Reference ###

- F.Mignard & M.Froeschle, 2000, Astron.Astrophys. 354, 732-739.

"""
function hfk5z(rh, dh, date1, date2)
    r5 = Ref(0.0)
    d5 = Ref(0.0)
    dr5 = Ref(0.0)
    dd5 = Ref(0.0)
    ccall((:eraHfk5z, liberfa), Cvoid,
          (Cdouble, Cdouble, Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
          rh, dh, date1, date2, r5, d5, dr5, dd5)
    r5[], d5[], dr5[], dd5[]
end

"""
    h2fk5(ra, dec, dra, ddec, px, rv)

Transform Hipparcos star data into the FK5 (J2000.0) system.

### Given (all Hipparcos, epoch J2000.0) ###

- `rh`: RA (radians)
- `dh`: Dec (radians)
- `drh`: Proper motion in RA (dRA/dt, rad/Jyear)
- `ddh`: Proper motion in Dec (dDec/dt, rad/Jyear)
- `pxh`: Parallax (arcsec)
- `rvh`: Radial velocity (km/s, positive = receding)

### Returned (all FK5, equinox J2000.0, epoch J2000.0) ###

- `r5`: RA (radians)
- `d5`: Dec (radians)
- `dr5`: Proper motion in RA (dRA/dt, rad/Jyear)
- `dd5`: Proper motion in Dec (dDec/dt, rad/Jyear)
- `px5`: Parallax (arcsec)
- `rv5`: Radial velocity (km/s, positive = receding)

### Notes ###

1. This function transforms Hipparcos star positions and proper
   motions into FK5 J2000.0.

2. The proper motions in RA are dRA/dt rather than
   cos(Dec)*dRA/dt, and are per year rather than per century.

3. The FK5 to Hipparcos transformation is modeled as a pure
   rotation and spin;  zonal errors in the FK5 catalog are not
   taken into account.

4. See also eraFk52h, eraFk5hz, eraHfk5z.

### Called ###

- `eraStarpv`: star catalog data to space motion pv-vector
- `eraFk5hip`: FK5 to Hipparcos rotation and spin
- `eraRv2m`: r-vector to r-matrix
- `eraRxp`: product of r-matrix and p-vector
- `eraTrxp`: product of transpose of r-matrix and p-vector
- `eraPxp`: vector product of two p-vectors
- `eraPmp`: p-vector minus p-vector
- `eraPvstar`: space motion pv-vector to star catalog data

### Reference ###

- F.Mignard & M.Froeschle, Astron. Astrophys. 354, 732-739 (2000).

"""
function h2fk5(ra, dec, dra, ddec, px, rv)
    r = Ref(0.0)
    d = Ref(0.0)
    dr = Ref(0.0)
    dd = Ref(0.0)
    p = Ref(0.0)
    v = Ref(0.0)
    ccall((:eraH2fk5, liberfa), Cvoid,
            (Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}),
            ra, dec, dra, ddec, px, rv, r, d, dr, dd, p, v)
    r[], d[], dr[], dd[], p[], v[]
end
