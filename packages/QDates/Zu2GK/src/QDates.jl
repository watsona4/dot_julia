module QDates

# # Load dependencies
include(joinpath(dirname(@__FILE__), "qref", "QREF.jl"))

import Dates
import Dates:
    year,
    month,
    day,
    dayofweek,
    yearmonth,
    monthday,
    yearmonthday,
    days

const DAYS_OFFSET = 1721425
const FIRST_VALUE = QREF.FIRST_JULIAN - DAYS_OFFSET
# Note: FIRST_VALUE == 162193
const LAST_VALUE = QREF.LAST_JULIAN - DAYS_OFFSET
# Note: LAST_VALUE == 803567
const FIRST_YEAR = QREF.FIRST_YEAR
# Note: FIRST_YEAR == 445
const LAST_YEAR = QREF.LAST_YEAR
# Note: LAST_YEAR == 2200

include("types.jl")
include("periods.jl")
include("accessors.jl")
include("query.jl")
include("arithmetic.jl")
include("conversions.jl")
include("ranges.jl")
include("adjusters.jl")
include("rounding.jl")
include("io.jl")

export
    QDate,
    year,
    month,
    day,
    dayofweek,
    yearmonth,
    monthday,
    yearmonthday,
    days,
    firstdayofyear,
    lastdayofyear,
    firstdayofmonth,
    lastdayofmonth,
    today,
    isleapmonth,
    yearmonthleap,
    monthleapday,
    yearmonthleapday

end # module