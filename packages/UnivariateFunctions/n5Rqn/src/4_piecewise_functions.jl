function evaluate(f::Piecewise_Function, point::Float64)
    which_function = searchsortedlast(f.starts_, point)
    return evaluate(f.functions_[which_function], point)
end

function derivative(f::Piecewise_Function)
    derivatives = derivative.( f.functions_)
    return Piecewise_Function(f.starts_, derivatives)
end

function indefinite_integral(f::Piecewise_Function)
    indef_integrals = indefinite_integral.( f.functions_)
    return Piecewise_Function(f.starts_, indef_integrals)
end

function +(f::Piecewise_Function,number::Float64)
    functions_with_addition = f.functions_ .+ number
    return Piecewise_Function(f.starts_, functions_with_addition)
end
function -(f::Piecewise_Function,number::Float64)
    functions_with_subtraction = f.functions_ .- number
    return Piecewise_Function(f.starts_, functions_with_subtraction)
end
function *(f::Piecewise_Function,number::Float64)
    functions_with_multiplication = f.functions_ .* number
    return Piecewise_Function(f.starts_, functions_with_multiplication)
end
function /(f::Piecewise_Function,number::Float64)
    functions_with_division = f.functions_ ./ number
    return Piecewise_Function(f.starts_, functions_with_division)
end
function +(f::Piecewise_Function,number::Integer)
    number_as_float = convert(Float64, number)
    return +(f,number_as_float)
end
function -(f::Piecewise_Function,number::Integer)
    number_as_float = convert(Float64, number)
    return -(f,number_as_float)
end
function *(f::Piecewise_Function,number::Integer)
    number_as_float = convert(Float64, number)
    return *(f,number_as_float)
end
function /(f::Piecewise_Function,number::Integer)
    number_as_float = convert(Float64, number)
    return /(f,number_as_float)
end

function create_common_pieces(f1::Piecewise_Function,f2::Piecewise_Function)
    starts_ = unique(sort!(vcat(f1.starts_,f2.starts_)))
    functions1_ = Array{UnivariateFunction}(undef, length(starts_))
    functions2_ = Array{UnivariateFunction}(undef, length(starts_))
    for i in 1:length(starts_)
        point = starts_[i]
        which_1 = searchsortedlast(f1.starts_, point)
        functions1_[i] = f1.functions_[which_1]
        which_2 = searchsortedlast(f2.starts_, point)
        functions2_[i] = f2.functions_[which_2]
    end
    return Piecewise_Function(starts_, functions1_) , Piecewise_Function(starts_, functions2_)
end

function +(f1::Piecewise_Function,f2::Piecewise_Function)
    c_f1, c_f2 = create_common_pieces(f1,f2)
    starts_ = c_f1.starts_
    number_of_pieces = length(starts_)
    functions_ = Array{UnivariateFunction}(undef, number_of_pieces)
    for i in 1:number_of_pieces
        functions_[i] = c_f1.functions_[i] + c_f2.functions_[i]
    end
    return Piecewise_Function(starts_, functions_)
end
function *(f1::Piecewise_Function,f2::Piecewise_Function)
    c_f1, c_f2 = create_common_pieces(f1,f2)
    starts_ = c_f1.starts_
    number_of_pieces = length(starts_)
    functions_ = Array{UnivariateFunction}(undef, number_of_pieces)
    for i in 1:number_of_pieces
        functions_[i] = c_f1.functions_[i] * c_f2.functions_[i]
    end
    return Piecewise_Function(starts_, functions_)
end
function -(f1::Piecewise_Function,f2::Piecewise_Function)
    c_f1, c_f2 = create_common_pieces(f1,f2)
    starts_ = c_f1.starts_
    number_of_pieces = length(starts_)
    functions_ = Array{UnivariateFunction}(undef, number_of_pieces)
    for i in 1:number_of_pieces
        functions_[i] = c_f1.functions_[i] - c_f2.functions_[i]
    end
    return Piecewise_Function(starts_, functions_)
end
