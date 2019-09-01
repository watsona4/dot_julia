"""

Method that handles showing (producing) output from a DutyCycle.

"""
function Base.show(io::IOContext, d::AbstractDutyCycle{T,U,V}) where {T,U,V}
    smallest = minimum(d.values)
    largest = maximum(d.values)
    constant = smallest == largest
    if d isa AbstractIncoherentDutyCycle
        print(io, "incoh. DutyCycle")
    elseif d isa AbstractCoherentDutyCycle
        print(io, "coh. DutyCycle")
    else
        print(io, typeof(d))
    end
    print(io, "(")
    if get(io, :compact, false)
        if constant
            print(io, "const. ")
            print(io, smallest)
        else
            print(io, smallest)
            print(io, " to ")
            print(io, largest)
        end
    else
        if constant
            print(io, "constant at ")
            print(io, smallest)
        else
            print(io, "varying from ")
            print(io, smallest)
            print(io, " to ")
            print(io, largest)
        end
        if false && smallest != largest
            print(io, " with mean ")
            print(io, mean(d))
            print(io, " and rms ")
            print(io, rms(d))
        end
    end
    if !constant && d.period != zero(T)
        print(io, " over ")
        print(io, d.period)
    end
    print(io, ")")
end
