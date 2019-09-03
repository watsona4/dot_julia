# ranges.jl

(::Colon)(start::QDate, stop::QDate) = StepRange(start, Day(1), stop)

# Given a start and end date, how many steps/periods are in between
Dates.guess(a::QDate, b::QDate, c) = Int64(div(value(b - a), days(c)))

function Dates.len(a::QDate, b::QDate, c)
    lo, hi, st = min(a, b), max(a, b), abs(c)
    i = Dates.guess(a, b, c) - 1
    try
        while lo + st * i <= hi
            i += 1
        end
    catch ex
        if !isa(ex, ArgumentError) && !isa(ex, BoundsError)
            rethrow()
        # else
        #     #pass
        end
    end
    return i - 1
end
