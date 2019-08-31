"Signal returned by callback"
abstract type Signal end
abstract type Stop <: Signal end

"Default handle signal (do nothing)"
handlesignal(x) = nothing
handlesignal(::Type{Stop}) = throw(InterruptException)
