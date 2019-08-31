module LeapSeconds

using Dates: DateTime, datetime2julian

export offset_tai_utc

include(joinpath("..", "gen", "leap_seconds.jl"))

const MJD_EPOCH = 2400000.5

# Constants for calculating the offset between TAI and UTC for
# dates between 1960-01-01 and 1972-01-01
# See ftp://maia.usno.navy.mil/ser7/tai-utc.dat

const EPOCHS = [
    36934,
    37300,
    37512,
    37665,
    38334,
    38395,
    38486,
    38639,
    38761,
    38820,
    38942,
    39004,
    39126,
    39887,
]

const OFFSETS = [
    1.417818,
    1.422818,
    1.372818,
    1.845858,
    1.945858,
    3.240130,
    3.340130,
    3.440130,
    3.540130,
    3.640130,
    3.740130,
    3.840130,
    4.313170,
    4.213170,
]

const DRIFT_EPOCHS = [
    37300,
    37300,
    37300,
    37665,
    37665,
    38761,
    38761,
    38761,
    38761,
    38761,
    38761,
    38761,
    39126,
    39126,
]

const DRIFT_RATES = [
    0.0012960,
    0.0012960,
    0.0012960,
    0.0011232,
    0.0011232,
    0.0012960,
    0.0012960,
    0.0012960,
    0.0012960,
    0.0012960,
    0.0012960,
    0.0012960,
    0.0025920,
    0.0025920,
]

"""
    offset_tai_utc(jd)

Returns the offset between International Atomic Time (TAI) and Coordinated
Universal Time (UTC) for a given Julian Date `jd`. For dates after
1972-01-01, this is the number of leap seconds.
"""
function offset_tai_utc(jd)
    mjd = jd - MJD_EPOCH

    # Before 1960-01-01
    if mjd < 36934.0
        @warn "UTC is not defined for dates before 1960-01-01."
        return 0.0
    end

    # Before 1972-01-01
    if mjd < LS_EPOCHS[1]
        idx = searchsortedlast(EPOCHS, floor(Int, mjd))
        return OFFSETS[idx] + (mjd - DRIFT_EPOCHS[idx]) * DRIFT_RATES[idx]
    end

    LEAP_SECONDS[searchsortedlast(LS_EPOCHS, floor(Int, mjd))]
end


"""
    offset_tai_utc(dt::DateTime)

Returns the offset between International Atomic Time (TAI) and Coordinated
Universal Time (UTC) for a given `DateTime`. For dates after
1972-01-01, this is the number of leap seconds.
"""
offset_tai_utc(dt::DateTime) = offset_tai_utc(datetime2julian(dt))

end

