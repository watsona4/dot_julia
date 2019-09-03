using ParserCombinator
using Dates

const WEEKDAYS = Dict(zip(map(uppercase, Dates.ENGLISH.days_of_week_abbr),range(1,stop=7)))
const MONTHS = Dict(zip(map(uppercase, Dates.ENGLISH.months_abbr),range(1,stop=12)))
const PERIODS = Dict(
    "1st" => 1, "2nd" => 2, "3rd" => 3, "4th" => 4, "5th" => 5,
    "Last" => 1, "2nd Last" => 2, "3rd Last" => 3, "4th Last" => 4, "5th Last" => 5)

space = Drop(Star(Space()))

PNonZeroInt64() = Parse(p"-?[1-9][0-9]*", Int64)
PPosInt64() = Parse(p"[1-9][0-9]*", Int64)

@with_pre space begin
    sum = Delayed()
    d = PInt64() + E"d" > RDateDay
    w = PInt64() + E"w" > RDateWeek
    m = PInt64() + E"m" > RDateMonth
    y = PInt64() + E"y" > RDateYear
    fdom = E"FDOM" > RDateFDOM
    ldom = E"LDOM" > RDateLDOM
    easter = PInt64() + E"E" > RDateEaster
    weekday_short = Alt(map(x -> Pattern(uppercase(x)), Dates.ENGLISH.days_of_week_abbr)...)
    month_short = Alt(map(x -> Pattern(uppercase(x)), Dates.ENGLISH.months_abbr)...)
    weekday = PNonZeroInt64() + weekday_short > (i,wd) -> RDateWeekdays(WEEKDAYS[wd], i)
    day_month = PPosInt64() + month_short > (d,m) -> RDateDayMonth(d,MONTHS[m])
    nth_weekdays = (p"1st" | p"2nd" | p"3rd" | p"4th" | p"5th") + space + weekday_short > (p,wd) -> RDateNthWeekdays(WEEKDAYS[wd], PERIODS[p])
    nth_last_weekdays = (p"Last" | p"2nd Last" | p"3rd Last" | p"4th Last" | p"5th Last") + space + weekday_short > (p,wd) -> RDateNthLastWeekdays(WEEKDAYS[wd], PERIODS[p])

    rdate_term = d | w | m | y | fdom | ldom | easter | weekday | day_month | nth_weekdays | nth_last_weekdays
    rdate_expr = rdate_term | (E"(" + space + sum + space + E")")

    # Add support for multiple negatives --2d for example...
    neg = Delayed()
    neg.matcher = rdate_expr | (E"-" + neg > negate)

    mul = E"*" + (neg | PPosInt64())
    prod = (neg | ((PPosInt64() | neg) + mul[0:end])) |> Base.prod
    add = E"+" + prod
    sub = E"-" + prod > negate
    sum.matcher = prod + (add | sub)[0:end] |> x -> length(x) == 1 ? x[1] : RDateCompound(x)

    entry = sum + Eos()
end

macro rd_str(arg::String)
    val = parse_one(arg, entry)[1]
    isa(val, RDate) || error("Unable to parse $(arg) as RDate")
    return val
end

function rdate(arg::String)
    val = parse_one(arg, entry)[1]
    isa(val, RDate) || error("Unable to parse $(arg) as RDate")
    return val
end
