__precompile__()

module LogProbs

import Base: show, log, float, rand, isapprox
import Base: ==, hash
import Base: zero, one, +, -, *, /, isless

using StatsFuns: logaddexp, log1mexp

export LogProb, information

"""
    LogProb(x)

Create a container of a positive real number `x`
for convenient calculations with logspace probabilities

see https://en.wikipedia.org/wiki/Log_probability
"""
struct LogProb <: Number
    log :: Float64
    LogProb(number; islog::Bool=false) = islog ? new(number) : new(log(number))
end

show(io::IO, x::LogProb)  = print(io, "LogProb($(float(x)))")

==(x::LogProb,y::LogProb) = x.log == y.log
hash(x::LogProb)          = hash(LogProb, hash(x.log))

rand(::Type{LogProb})     = LogProb(rand())

float(x::LogProb)         = exp(x.log)
log(x::LogProb)           = x.log

"""
    information(p::LogProb)

Calculate the Shannon information content of `p` in bits
"""
information(x::LogProb)   = - log(x) / log(2)

one( ::Type{LogProb})     = LogProb(1)
zero(::Type{LogProb})     = LogProb(0)

*(x::LogProb, y::LogProb) = LogProb(x.log + y.log, islog=true)
/(x::LogProb, y::LogProb) = LogProb(x.log - y.log, islog=true)
+(x::LogProb, y::LogProb) = LogProb(logaddexp(x.log, y.log), islog=true)
-(x::LogProb, y::LogProb) = LogProb(x.log + log1mexp(y.log-x.log), islog=true)

isless(  x::LogProb, y::LogProb) = isless(  x.log, y.log)
isapprox(x::LogProb, y::LogProb) = isapprox(x.log, y.log)

end # Module
