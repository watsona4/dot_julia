import Base.+, Base.-, Base./, Base.*

function evaluate(f::PE_Function, x::Float64)
    diff = x - f.base_
    return f.a_ * exp(f.b_ * diff) * (diff)^f.d_
end

function derivative(f::PE_Function)
    if f.d_ == 0
        return PE_Function(f.a_ * f.b_, f.b_, f.base_, f.d_)
    else
        return PE_Function(f.a_ * f.d_, f.b_, f.base_, f.d_ - 1) +  PE_Function(f.a_ * f.b_, f.b_, f.base_, f.d_)
    end
end

function indefinite_integral(f::PE_Function)
    if (abs(f.b_) < tol) & (f.d_ == 0)
        return PE_Function(f.a_, 0.0, 0.0, 1)
    elseif f.d_ == 0
        return PE_Function(f.a_/f.b_, f.b_, f.base_, 0)
    elseif abs(f.b_) < tol
        return PE_Function(f.a_/(1.0+f.d_), 0.0, f.base_, f.d_ + 1)
    end
    # Integration by parts:      $\int u v' = uv - \int u'v$
    # I use u = (x-c)^d and v' = ae^(b(x-c))
    v = PE_Function(f.a_/f.b_, f.b_, f.base_, 0)
    u = PE_Function(1.0,0.0,f.base_,f.d_)
    return u * v - indefinite_integral( derivative(u) *v    )
end

function +(f::PE_Function,number::Float64)
    constant_function = PE_Function(number, 0.0,0.0,0)
    return Sum_Of_Functions([f, constant_function])
end
function -(f::PE_Function, number::Float64)
    return +(f, -number)
end
function *(f::PE_Function, number::Float64)
    return PE_Function(f.a_*number, f.b_, f.base_, f.d_)
end
function /(f::PE_Function, number::Float64)
    return *(f, 1/number )
end

function +(f::PE_Function, number::Integer)
    number_as_float = convert(Float64, number)
    return +(f, number_as_float)
end
function -(f::PE_Function, number::Integer)
    number_as_float = convert(Float64, number)
    return -(f, number_as_float)
end
function *(f::PE_Function, number::Integer)
    number_as_float = convert(Float64, number)
    return *(f, number_as_float)
end
function /(f::PE_Function, number::Integer)
    number_as_float = convert(Float64, number)
    return /(f, number_as_float)
end

function +(f1::PE_Function, f2::PE_Function)
    return Sum_Of_Functions([f1,f2])
end
function +(f1::PE_Function, f2::Sum_Of_Functions)
    return Sum_Of_Functions([f1,f2])
end
function +(f1::PE_Function, f2::Piecewise_Function)
    return Piecewise_Function(f2.starts_, f1 .+ f2.functions_)
end

function +(f1::Sum_Of_Functions, f2::PE_Function)
    return +(f2,f1)
end
function +(f1::Piecewise_Function, f2::PE_Function)
    return +(f2,f1)
end

function -(f1::PE_Function, f2::PE_Function)
    return Sum_Of_Functions([f1,-1*f2])
end
function -(f1::PE_Function, f2::Sum_Of_Functions)
    return Sum_Of_Functions([f1,-1*f2])
end
function -(f1::PE_Function, f2::Piecewise_Function)
    return Piecewise_Function(f2.starts_, f1 .- f2.functions_)
end

function -(f1::Sum_Of_Functions, f2::PE_Function)
    return +(f1,1*f2)
end
function -(f1::Piecewise_Function, f2::PE_Function)
    return +(f1,-1*f2)
end

function *(f1::PE_Function,f2::PE_Function)
    base_func = f1
    other_func = f2
    diff = f2.base_ - f1.base_
    if abs(diff) < tol
        return PE_Function(f1.a_ * f2.a_, f1.b_ + f2.b_, f1.base_, f1.d_ + f2.d_ )
    elseif (f1.d_ < tol) & (f1.b_ < tol)
        return f1.a_ * f2
    elseif (f2.d_ < tol) & (f2.b_ < tol)
        return f2.a_ * f1
    end
    if diff < 0
        base_func = f2
        other_func = f1
    end
    converted_other = change_base_of_PE_Function(other_func, base_func.base_)
    return base_func * converted_other
end
function *(f1::PE_Function, f2::Sum_Of_Functions)
    multiplied_functions = f1 .* f2.functions_
    return Sum_Of_Functions(multiplied_functions)
end
function *(f1::PE_Function, f2::Piecewise_Function)
    return Piecewise_Function(f2.starts_, f1 .* f2.functions_)
end

function *(f1::Sum_Of_Functions, f2::PE_Function)
    return *(f2,f1)
end
function *(f1::Piecewise_Function, f2::PE_Function)
    return *(f2,f1)
end
