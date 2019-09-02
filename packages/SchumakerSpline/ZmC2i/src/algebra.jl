import Base.+, Base.-, Base./, Base.*

function +(spl::Schumaker, num::Real)
    new_coefficients_ = hcat(spl.coefficient_matrix_[:,1:2],  spl.coefficient_matrix_[:,3] .+ num)
    return Schumaker(spl.IntStarts_, new_coefficients_)
end
function -(spl::Schumaker, num::Real)
    new_coefficients_ = hcat(spl.coefficient_matrix_[:,1:2],  spl.coefficient_matrix_[:,3] .- num)
    return Schumaker(spl.IntStarts_, new_coefficients_)
end
function *(spl::Schumaker, num::Real)
    new_coefficients_ = spl.coefficient_matrix_  .* num
    return Schumaker(spl.IntStarts_, new_coefficients_)
end
function /(spl::Schumaker, num::Real)
    new_coefficients_ = spl.coefficient_matrix_  ./ num
    return Schumaker(spl.IntStarts_, new_coefficients_)
end
function +(num::Real, spl::Schumaker)
    return +(spl,num)
end
function -(num::Real, spl::Schumaker)
    return (-1)*spl + num
end
function *(num::Real, spl::Schumaker)
    return *(spl,num)
end
function /(num::Real, spl::Schumaker)
    error("Dividing a real number by a schumaker spline is not supported in this package.")
end
