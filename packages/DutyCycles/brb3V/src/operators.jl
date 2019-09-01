# specialized method definition is required at least for type Integer
# due to method ambiguities.
#
# To Do: Can't we simply define this on an AbstractDutyCycle?  Can we
#        alternatively specialize the applyphasewise method called to
#        _coherently or _incoherently?
for V2 in [:Integer, Rational{<:Integer}, :Real]
    @eval begin
        """

        Exponentiation works in the usual manner.

        """
        Base.:^(
            base::CoherentDutyCycle{T,U,V}, power::$V2
        ) where {T,U,V,V2} = applyphasewise(x -> x^power, base)
        Base.:^(
            base::IncoherentDutyCycle{T,U,V}, power::$V2
        ) where {T,U,V,V2} = applyphasewise(x -> x^power, base)
    end
end

# define the basic arithmetic operators
for op in [:+, :-, :*, :/, ://, :min, :max]
    behavior = "the usual manner"
    if op === :min || op === :max
        behavior = """a way that merits explanation: It returns the
        $(op)imum instantenous value, that is a new dutycycle which at
        every point in time assumes the $(op)imum value of either of
        the arguments"""
    end
    @eval begin
        # To Do: Consider if we can directly use the more specialized
        #        cases of applyphasewise_[in]coherently where we
        #        already know if there will an [in]coherence result
        #
        # start with the definitely coherent cases
        """
        
        The operator $($op) works in $($behavior).
        
        """
        Core.@__doc__ Base.$op(a::CoherentDutyCycle, b::NoDimNum) =
            applyphasewise(x -> Base.$op(x,b), a)
        Base.$op(a::NoDimNum, b::CoherentDutyCycle) =
            applyphasewise(y -> Base.$op(a,y), b)
        # (possibly) coherent cases
        Base.$op(
            a::CoherentDutyCycle{T,U,V},
            b::CoherentDutyCycle{T,U,V}
        ) where {T,U,V} = applyphasewise(Base.$op, a, b)
        # definitely incoherent cases
        Base.$op(a::IncoherentDutyCycle, b::NoDimNum) =
            applyphasewise(x -> Base.$op(x,b), a)
        Base.$op(a::NoDimNum, b::IncoherentDutyCycle) =
            applyphasewise(y -> Base.$op(a,y), b)
        Base.$op(
            a::IncoherentDutyCycle{T,U,V},
            b::CoherentDutyCycle{T,U,V}
        ) where {T,U,V} = applyphasewise(Base.$op, a, b)
        Base.$op(
            a::CoherentDutyCycle{T,U,V},
            b::IncoherentDutyCycle{T,U,V}
        ) where {T,U,V} = applyphasewise(Base.$op, a, b)
        Base.$op(
            a::IncoherentDutyCycle{T,U,V},
            b::IncoherentDutyCycle{T,U,V}
        ) where {T,U,V} = applyphasewise(Base.$op, a, b)
    end
end

for opname in [(:real, "real"), (:imag, "imaginary")]
    op, name = opname
    @eval begin
        """Return the $($name) part of a DutyCycle."""
        Core.@__doc__ Base.$op(
            a::CoherentDutyCycle{<:Number,<:Real,<:Real}
        ) = ($op == :real) ? a : 0
        Base.$op(a::IncoherentDutyCycle{<:Number,<:Real,<:Real}) =
            ($op == :real) ? a : 0
        Base.$op(a::CoherentDutyCycle{<:Number,<:Real,<:Complex}) =
            applyphasewise(Base.$op, a)
        Base.$op(a::IncoherentDutyCycle{<:Number,<:Real,<:Complex}) =
            applyphasewise(Base.$op, a)
    end
end

for op in [:isnan, :isinf]
    # implement these functions such that they return true if there is
    # any value the dutycycle can assume for which they would return
    # true
    @eval begin
        """
        
        Return true for a dutycycle that ever assumes a value for which
        `$($op)` is true, and false otherwise.
        
        """
        Core.@__doc__ Base.$op(a::AbstractDutyCycle) =
            _exists($op, values(a))
    end
end

for op in [:ismissing]
    # implement these functions such that they return true only if
    # they are true for all values the dutycycle assumes.
    @eval begin
        """
        
        Return true for a dutycycle if `$($op)` is true for _all_
        values assumed by the DutyCycle, and false otherwise.
        
        """
        Core.@__doc__ Base.$op(a::AbstractDutyCycle) =
            !_exists(!$op, values(a))
    end
end

if Base.VERSION >= v"1.1"
    for op in [:isnothing]
        # implement these functions such that they return true only if
        # they are true for all values the dutycycle assumes.
        @eval begin
            """
            
            Return true for a dutycycle if `$($op)` is true for _all_
            values assumed by the DutyCycle, and false otherwise.
            
            """
            Core.@__doc__ Base.$op(a::AbstractDutyCycle) =
                !_exists(!$op, values(a))
        end
    end
end
