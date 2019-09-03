# standard complex number functions

import Base: conj, abs, sqrt, exp, angle, real, imag, log




function real(a::RC)
    if isnan(a)
        return NaN
    end
    if isinf(a)
        return Inf
    end
    return real(a.val)
end


function imag(a::RC)
    if isnan(a)
        return NaN
    end
    if isinf(a)
        return Inf
    end
    return imag(a.val)
end

function conj(a::RC)::RC
    if isinf(a) || isnan(a)
        return a
    end
    return RC(conj(a.val))
end

function abs(a::RC)::Real
    if isinf(a)
        return Inf
    end

    if isnan(a)
        return NaN
    end

    return abs(a.val)
end

function sqrt(a::RC)::RC
    if isnan(a) || isinf(a)
        return a
    end
    return RC(sqrt(a.val))
end

function exp(a::RC)::RC
    if isnan(a) || isinf(a)
        return ComplexNaN
    end
    return RC(exp(a.val))
end

function log(a::RC)::RC
    if isnan(a) || iszero(a) || isinf(a)
        return ComplexNaN
    end
    return RC(log(a.val))
end

function angle(a::RC)::Real
    if isnan(a) || isinf(a)
        return NaN
    end
    return angle(a.val)
end
