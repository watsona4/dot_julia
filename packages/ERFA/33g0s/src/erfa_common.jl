"""
Pi
"""
const DPI = 3.141592653589793

"""
2Pi
"""
const D2PI = 6.283185307179586

"""
Radians to degrees
"""
const DR2D = 57.29577951308232

"""
Degrees to radians
"""
const DD2R = 0.017453292519943295

"""
Radians to arcseconds
"""
const DR2AS = 206264.80624709636

"""
Arcseconds to radians
"""
const DAS2R = 4.84813681109536e-6

"""
Seconds of time to radians
"""
const DS2R = 7.27220521664304e-5

"""
Arcseconds in a full circle
"""
const TURNAS = 1.296e6

"""
Milliarcseconds to radians
"""
const DMAS2R = DAS2R / 1000.0

"""
Length of tropical year B1900 (days)
"""
const DTY = 365.242198781

"""
Seconds per day
"""
const DAYSEC = 86400.0

"""
Days per Julian year
"""
const DJY = 365.25

"""
Days per Julian century
"""
const DJC = 36525.0

"""
Days per Julian millennium
"""
const DJM = 365250.0

"""
Reference epoch (J2000.0), Julian Date
"""
const DJ00 = 2.451545e6

"""
Julian Date of Modified Julian Date zero
"""
const DJM0 = 2.4000005e6

"""
Reference epoch (J2000.0), Modified Julian Date
"""
const DJM00 = 51544.5

"""
1977 Jan 1.0 as MJD
"""
const DJM77 = 43144.0

"""
TT minus TAI (s)
"""
const TTMTAI = 32.184

"""
Astronomical unit (m, IAU 2012)
"""
const DAU = 1.4959787e11

"""
Speed of light (m/s)
"""
const CMPS = 2.99792458e8

"""
Light time for 1 au (s)
"""
const AULT = 499.004782

"""
Speed of light (au per day)
"""
const DC = DAYSEC / AULT

"""
L_G = 1 - d(TT)/d(TCG)
"""
const ELG = 6.969290134e-10

"""
L_B = 1 - d(TDB)/d(TCB)
"""
const ELB = 1.550519768e-8

"""
TDB (s) at TAI 1977/1/1.0
"""
const TDB0 = -6.55e-5

"""
Schwarzschild radius of the Sun (au) =
2 * 1.32712440041e20 / (2.99792458e8)^2 / 1.49597870700e11
"""
const SRS = 1.97412574336e-8

@enum Ellipsoid WGS84 = 1 GRS80 = 2 WGS72 = 3

mutable struct ASTROM
    pmt::Cdouble
    eb::NTuple{3,Cdouble}
    eh::NTuple{3,Cdouble}
    em::Cdouble
    v::NTuple{3,Cdouble}
    bm1::Cdouble
    bpn::NTuple{9,Cdouble}
    along::Cdouble
    phi::Cdouble
    xpl::Cdouble
    ypl::Cdouble
    sphi::Cdouble
    cphi::Cdouble
    diurab::Cdouble
    eral::Cdouble
    refa::Cdouble
    refb::Cdouble
end

struct LDBODY
    bm::Cdouble
    dl::Cdouble
    pv::NTuple{6,Cdouble}
end

struct ERFAException <: Exception
    msg::String
end

Base.showerror(io::IO, ex::ERFAException) = print(io, ex.msg)

export ERFAException
