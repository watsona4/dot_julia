# periods.jl

function Base.:+(x::QDate, y::Dates.CompoundPeriod)
    for p in y.periods
        if isa(p, Dates.Week)
            x += Dates.Day(value(p) * 7)
        else
            x += p
        end
    end
    return x
end

function Base.:-(x::QDate, y::Dates.CompoundPeriod)
    for p in y.periods
        if isa(p, Dates.Week)
            x -= Dates.Day(value(p) * 7)
        else
            x -= p
        end
    end
    return x
end
