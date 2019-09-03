
function (+)(a::RC, b::RC)
    if isnan(a) || isnan(b)
        return ComplexNaN
    end
    if isinf(a) && isinf(b)
        return ComplexNaN
    end
    if isinf(a) || isinf(b)
        return ComplexInf
    end
    return RC(a.val + b.val)
end

function (-)(a::RC)
    return RC(-a.val, a.nan_flag, a.inf_flag)
end

function (-)(a::RC,b::RC)
    return a + (-b)
end

function (*)(a::RC, b::RC)
    if isnan(a) || isnan(b)
        return ComplexNaN
    end
    if (isinf(a)&&iszero(b))||(iszero(a)&&isinf(b))  # 0 x Inf
        return ComplexNaN
    end
    if isinf(a) || isinf(b)
        return ComplexInf
    end
    return RC(a.val * b.val)
end

function inv(z::RC{T}) where T
    if isnan(z)
        return ComplexNaN
    end
    if iszero(z)
        return ComplexInf
    end
    if isinf(z) return
        RC(zero(T))
    end
    return RC(1/z.val)
end

function (/)(a::RC{S}, b::RC{T}) where {S,T}
    if isnan(a) || isnan(b)
        return ComplexNaN
    end

    # zero denominator cases
    if iszero(b) && !iszero(a)
        return ComplexInf
    end
    if iszero(b) && iszero(a)
        return ComplexNaN
    end

    # infinite denominator cases
    if isinf(a) && isinf(b)
        return ComplexNaN
    end
    if isinf(b)
        return RC(zero(S))
    end

    # infinite numerator, nonzero/noninf denominator
    if isinf(a)
        return a
    end

    return RC(a.val / b.val)
end
