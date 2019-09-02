"""
This creates an enum which details how extrapolation from the interpolation domain should be done.
"""
@enum Schumaker_ExtrapolationSchemes begin
    Curve = 0
    Linear = 1
    Constant = 2
end


"""
    Schumaker(x::Array{T,1},y::Array{T,1} ; gradients::Union{Missing,Array{T,1}} = missing, extrapolation::Schumaker_ExtrapolationSchemes = Curve,
                  left_gradient::Union{Missing,T} = missing, right_gradient::Union{Missing,T} = missing)
    Schumaker(x::Array{Int,1},y::Array{T,1} ; gradients::Union{Missing,Array{T,1}} = missing, extrapolation::Schumaker_ExtrapolationSchemes = Curve,
                  left_gradient::Union{Missing,T} = missing, right_gradient::Union{Missing,T} = missing)
    Schumaker(x::Array{Date,1},y::Array{T,1} ; gradients::Union{Missing,Array{T,1}} = missing, extrapolation::Schumaker_ExtrapolationSchemes = Curve,
                  left_gradient::Union{Missing,T} = missing, right_gradient::Union{Missing,T} = missing)
Creates a Schumaker spline.
### Takes
* x - A vector of x coordinates.
* y - A vector of y coordinates.
* extrapolation (optional) - This should be Curve, Linear or Constant specifying how to interpolate outside of the sample domain. By default it is Curve which extends out the first and last quadratic curves. The other options are Linear which extends the line (from first and last curve) out from the first and last point and Constant which extends out the y value at the first and last point.
* gradients (optional)- A vector of gradients at each point. If not supplied these are imputed from x and y.
* left_gradient - The gradient at the lowest value of x in the domain. This will override the gradient imputed or submitted in the gradients optional argument (if it is submitted there)
* right_gradient - The gradient at the highest value of x in the domain. This will override the gradient imputed or submitted in the gradients optional argument (if it is submitted there)

### Returns
* A Schumaker object which details the spline. This object can then be evaluated with evaluate or evaluate_integral.
 """
struct Schumaker{T<:AbstractFloat}
    IntStarts_::Array{T,1}
    coefficient_matrix_::Array{T,2}
    function Schumaker(x::Array{<:Real,1},y::Array{<:Real,1} ; gradients::Union{Missing,Array{<:Real,1}} = missing, left_gradient::Union{Missing,<:Real} = missing, right_gradient::Union{Missing,<:Real} = missing,
                       extrapolation::Tuple{Schumaker_ExtrapolationSchemes,Schumaker_ExtrapolationSchemes} = (Curve,Curve))
        T = typeof(AbstractFloat(0.0)) # TODO This is pretty dodgy. Try to not have to do this.
        if length(x) == 0
            error("Zero length x vector is insufficient to create Schumaker Spline.")
        elseif length(x) == 1
            IntStarts = Array{T,1}(x)
            SpCoefs = [0 0 y[1]]
            # Note that this hardcodes in constant extrapolation. This is only
            # feasible one as we do not have derivative or curve information.
            return new{T}(IntStarts, SpCoefs)
        elseif length(x) == 2
            IntStarts = Array{T,1}([x[1]])
            IntEnds   = Array{T,1}([x[2]])
            linear_coefficient = (y[2]- y[1]) / (x[2]-x[1])
            SpCoefs = [0 linear_coefficient y[1]]
            # In this case it defaults to curve extrapolation (which is same as linear here)
            # So we just alter in case constant is specified.
            if extrapolation[1] == Constant || extrapolation[2] == Constant
                matrix_without_extrapolation = hcat(IntStarts , SpCoefs)
                matrix_with_extrapolation    = extrapolate(matrix_without_extrapolation, extrapolation, x[2], y)
                return new{T}(matrix_with_extrapolation[:,1], matrix_with_extrapolation[:,2:4])
            else
                return new{T}(IntStarts, SpCoefs)
            end
        end
        if ismissing(gradients)
           gradients = imputeGradients(x,y)
        end
        if !ismissing(left_gradient)
            gradients[1] = left_gradient
        end
        if !ismissing(right_gradient)
            gradients[length(gradients)] = right_gradient
        end
        IntStarts, SpCoefs = getCoefficientMatrix(x,y,gradients, extrapolation)
        return new{T}(IntStarts, SpCoefs)
     end
    function Schumaker(IntStarts_::Array{T,1}, coefficient_matrix_::Array{T,2}) where {T<:Real}
        return new{T}(IntStarts_, coefficient_matrix_)
    end
    function Schumaker{Q}(IntStarts_::Array{<:Real,1}, coefficient_matrix_::Array{<:Real,2}) where Q<:Real
        return new{Q}(Q.(IntStarts_), Q.(coefficient_matrix_))
    end
    function Schumaker(x::Array{Date,1},y::Array{<:Real,1} ; gradients::Union{Missing,Array{<:Real,1}} = missing, left_gradient::Union{Missing,<:Real} = missing, right_gradient::Union{Missing,<:Real} = missing,
                       extrapolation::Tuple{Schumaker_ExtrapolationSchemes,Schumaker_ExtrapolationSchemes} = (Curve,Curve))
        days_as_ints = Dates.days.(x)
        return Schumaker(days_as_ints , y; gradients = gradients , extrapolation = extrapolation, left_gradient = left_gradient, right_gradient = right_gradient)
    end
    function Schumaker(x::Union{Array{T,1},Array{Union{Missing,T},1}},y::Union{Array{R,1},Array{Union{Missing,R},1}} ; gradients::Union{Missing,Array{<:Real,1}} = missing, left_gradient::Union{Missing,Real} = missing, right_gradient::Union{Missing,Real} = missing,
                       extrapolation::Tuple{Schumaker_ExtrapolationSchemes,Schumaker_ExtrapolationSchemes} = (Curve,Curve)) where T<:Real where R<:Real
        got_both = (!).(ismissing.(x) .| ismissing.(y))
        promo_type = promote_type(R,T)
        new_x = convert.(promo_type, x[got_both])
        new_y = convert.(promo_type, y[got_both])
        new_gradients = ismissing(gradients)        ? missing : convert.(promo_type, gradients[got_both])
        converted_left  = ismissing(left_gradient)  ? missing : convert(promo_type, left_gradient)
        converted_right = ismissing(right_gradient) ? missing : convert(promo_type, right_gradient)
        new_left  = got_both[1]                     ? converted_left  : missing
        new_right = got_both[length(got_both)]      ? converted_right : missing
        if length(new_x) == 0 error("After removing missing elements there are no points left to estimate schumaker spline") end
        return Schumaker(new_x , new_y; gradients = new_gradients , extrapolation = extrapolation, left_gradient = new_left, right_gradient = new_right)
    end
    function Schumaker{Q}(x::AbstractArray, y::AbstractArray ; gradients::Union{Missing,AbstractArray} = missing, left_gradient::Union{Missing,Real} = missing, right_gradient::Union{Missing,Real} = missing,
                          extrapolation::Tuple{Schumaker_ExtrapolationSchemes,Schumaker_ExtrapolationSchemes} = (Curve,Curve)) where Q<:Real
        got_both = (!).(ismissing.(x) .| ismissing.(y))
        new_x = convert.(Q, x[got_both])
        new_y = convert.(Q, y[got_both])
        new_gradients = ismissing(gradients)        ? missing : convert.(Q, gradients[got_both])
        converted_left  = ismissing(left_gradient)  ? missing : convert(Q, left_gradient)
        converted_right = ismissing(right_gradient) ? missing : convert(Q, right_gradient)
        new_left  = got_both[1]                     ? converted_left  : missing
        new_right = got_both[length(got_both)]      ? converted_right : missing
        if length(new_x) == 0 error("After removing missing elements there are no points left to estimate schumaker spline") end
        return Schumaker(new_x , new_y; gradients = new_gradients , extrapolation = extrapolation, left_gradient = new_left, right_gradient = new_right)
    end
    function Schumaker(x::Union{AbstractArray{T,1},AbstractArray{Union{Missing,T},1}},y::Union{AbstractArray{R,1},AbstractArray{Union{Missing,R},1}} ; gradients::Union{Missing,AbstractArray{<:Real,1}} = missing, left_gradient::Union{Missing,Real} = missing, right_gradient::Union{Missing,Real} = missing,
                       extrapolation::Tuple{Schumaker_ExtrapolationSchemes,Schumaker_ExtrapolationSchemes} = (Curve,Curve)) where T<:Real where R<:Real
       promo_type = promote_type(T,R)
       return Schumaker{promo_type}(x, y; gradients = gradients, extrapolation = extrapolation, left_gradient = left_gradient, right_gradient = right_gradient)
   end
end
Base.broadcastable(e::Schumaker) = Ref(e)

"""
Evaluates the spline at a point. The point can be specified as a Real number (Int, Float, etc) or a Date.
Derivatives can also be taken.
### Takes
 * spline - A Schumaker type spline
 * PointToExamine - The point at which to evaluate the integral
 * derivative - The derivative being sought. This should be 0 to just evaluate the spline, 1 for the first derivative or 2 for a second derivative.
 Higher derivatives are all zero (because it is a quadratic spline). Negative values do not give integrals. Use evaluate_integral instead.
### Returns
 * A value of the spline or appropriate derivative in the same format as specified in the spline.
"""
function evaluate(spline::Schumaker, PointToExamine::T,  derivative::Integer = 0) where T<:Real
    # Derivative of 0 means normal spline evaluation.
    # Derivative of 1, 2 are first and second derivatives respectively.
    IntervalNum = searchsortedlast(spline.IntStarts_, PointToExamine)
    IntervalNum = max(IntervalNum, 1)
    xmt = PointToExamine - spline.IntStarts_[IntervalNum]
    Coefs = spline.coefficient_matrix_[IntervalNum,:]
    if derivative == 0
        return reshape(Coefs' * [xmt^2 xmt 1]', 1)[1]
    elseif derivative == 1
        return reshape(Coefs' * [2*xmt 1 0]', 1)[1]
    elseif derivative == 2
        return reshape(Coefs' * [2 0 0]', 1)[1]
    elseif derivative < 0
        error("This function cannot do integrals. Use evaluate_integral instead")
    else
        return 0.0
    end
end
function evaluate(spline::Schumaker, PointToExamine::Date,  derivative::Int = 0)
    days_as_int = Dates.days.(PointToExamine)
    return evaluate(spline,days_as_int,  derivative)
end
function (s::Schumaker)(x::Union{Real,Date}, deriv::Integer = 0)
    return evaluate(s, x, deriv)
end


"""
Estimates the integral of the spline between lhs and rhs. These end points can be input
as Reals or Dates.
### Takes
 * spline - A Schumaker type spline
 * lhs - The left hand limit of the integral
 * rhs - The right hand limit of the integral

### Returns
 * A Float64 value of the integral.
"""
function evaluate_integral(spline::Schumaker, lhs::Real, rhs::Real)
    first_interval = searchsortedlast(spline.IntStarts_, lhs)
    last_interval = searchsortedlast(spline.IntStarts_, rhs)
    number_of_intervals = last_interval - first_interval
    if number_of_intervals == 0
        return section_integral(spline , lhs, rhs)
    elseif number_of_intervals == 1
        first = section_integral(spline , lhs , spline.IntStarts_[first_interval + 1])
        last  = section_integral(spline , spline.IntStarts_[last_interval]  , rhs)
        return first + last
    else
        interior_areas = 0.0
        first = section_integral(spline , lhs , spline.IntStarts_[first_interval + 1])
        for i in 1:(number_of_intervals-1)
            interior_areas = interior_areas + section_integral(spline ,  spline.IntStarts_[first_interval + i] , spline.IntStarts_[first_interval + i+1] )
        end
        last  = section_integral(spline , spline.IntStarts_[last_interval]  , rhs)
        return first + interior_areas + last
    end
end
function evaluate_integral(spline::Schumaker, lhs::Date, rhs::Date)
    return evaluate_integral(spline, Dates.days.(lhs) , Dates.days.(rhs))
end
function section_integral(spline::Schumaker, lhs::Real,  rhs::Real)
    # Note that the lhs is used to infer the interval.
    IntervalNum = searchsortedlast(spline.IntStarts_, lhs)
    IntervalNum = max(IntervalNum, 1)
    Coefs = spline.coefficient_matrix_[ IntervalNum , :]
    r_xmt = rhs - spline.IntStarts_[IntervalNum]
    l_xmt = lhs - spline.IntStarts_[IntervalNum]
    return reshape(Coefs' * [(1/3)*r_xmt^3 0.5*r_xmt^2 r_xmt]', 1)[1] - reshape(Coefs' * [(1/3)*l_xmt^3 0.5*l_xmt^2 l_xmt]', 1)[1]
end


"""
find_derivative_spline(spline::Schumaker)
    Returns a SchumakerSpline that is the derivative of the input spline
"""
function find_derivative_spline(spline::Schumaker)
    coefficient_matrix = Array{Float64,2}(undef, size(spline.coefficient_matrix_)...   )
    coefficient_matrix[:,3] .= spline.coefficient_matrix_[:,2]
    coefficient_matrix[:,2] .= 2 .* spline.coefficient_matrix_[:,1]
    coefficient_matrix[:,1] .= 0.0
    return Schumaker(spline.IntStarts_, coefficient_matrix)
end



"""
    imputeGradients(x::Array{T,1}, y::Array{T,1})
Imputes gradients based on a vector of x and y coordinates.
"""
function imputeGradients(x::Array{<:Real,1}, y::Array{<:Real,1})
     n = length(x)
     # Judd (1998), page 233, second last equation
     L = sqrt.( (x[2:n]-x[1:(n-1)]).^2 + (y[2:n]-y[1:(n-1)]).^2)
     # Judd (1998), page 233, last equation
     d = (y[2:n]-y[1:(n-1)])./(x[2:n]-x[1:(n-1)])
     # Judd (1998), page 234, Eqn 6.11.6
     Conditionsi = d[1:(n-2)].*d[2:(n-1)] .> 0
     MiddleSiwithoutApplyingCondition = (L[1:(n-2)].*d[1:(n-2)]+L[2:(n-1)].* d[2:(n-1)]) ./ (L[1:(n-2)]+L[2:(n-1)])
     sb = Conditionsi .* MiddleSiwithoutApplyingCondition
     # Judd (1998), page 234, Second Equation line plus 6.11.6 gives this array of slopes.
     ff = [((-sb[1]+3*d[1])/2);  sb ;  ((3*d[n-1]-sb[n-2])/2)]
     return ff
 end

"""
Splits an interval into 2 subintervals and creates the quadratic coefficients
### Takes
 * s - A 2 entry vector with gradients at either end of the interval
 * z - A 2 entry vector with y values at either end of the interval
 * Smallt - A 2 entry vector with x values at either end of the interval

### Returns
 * A 2 x 5 matrix. The first column is the x values of start of the two subintervals. The second column is the ends. The last 3 columns are quadratic coefficients in two subintervals.
"""
function schumakerIndInterval(s::Array{<:Real,1}, z::Array{<:Real,1}, Smallt::Array{<:Real,1}) where T<:Real
   # The SchumakerIndInterval function takes in each interval individually
   # and returns the location of the knot as well as the quadratic coefficients in each subinterval.

   # Judd (1998), page 232, Lemma 6.11.1 provides this if condition:
   if (sum(s)*(Smallt[2]-Smallt[1]) == 2*(z[2]-z[1]))
     tsi = Smallt[2]
   else
     # Judd (1998), page 233, Algorithm 6.3 along with equations 6.11.4 and 6.11.5 provide this whole section
     delta = (z[2] -z[1])/(Smallt[2]-Smallt[1])
     Condition = ((s[1]-delta)*(s[2]-delta) >= 0)
     Condition2 = abs(s[2]-delta) < abs(s[1]-delta)
     if (Condition)
       tsi = sum(Smallt)/2
     elseif (Condition2)
       tsi = (Smallt[1] + (Smallt[2]-Smallt[1])*(s[2]-delta)/(s[2]-s[1]))
     else
       tsi = (Smallt[2] + (Smallt[2]-Smallt[1])*(s[1]-delta)/(s[2]-s[1]))
     end
   end

   # Judd (1998), page 232, 3rd last equation of page.
   alpha = tsi-Smallt[1]
   beta = Smallt[2]-tsi
   # Judd (1998), page 232, 4th last equation of page.
   sbar = (2*(z[2]-z[1])-(alpha*s[1]+beta*s[2]))/(Smallt[2]-Smallt[1])
   # Judd (1998), page 232, 3rd equation of page. (C1, B1, A1)
   Coeffs1 = [ (sbar-s[1])/(2*alpha)  s[1]  z[1] ]
   if (beta == 0)
     Coeffs2 = Coeffs1
   else
     # Judd (1998), page 232, 4th equation of page. (C2, B2, A2)
     Coeffs2 = [ (s[2]-sbar)/(2*beta)  sbar  Coeffs1 * [alpha^2, alpha, 1] ]
   end
   Machine4Epsilon = 4*eps()
     if (tsi  <  Smallt[1] + Machine4Epsilon )
         return [Smallt[1] Coeffs2]
     elseif (tsi + Machine4Epsilon > Smallt[2] )
         return [Smallt[1]  Coeffs1]
     else
         return [Smallt[1] Coeffs1 ; tsi Coeffs2]
     end
 end

 """
 Calls SchumakerIndInterval many times to get full set of spline intervals and coefficients. Then calls extrapolation for out of sample behaviour
### Takes
 * gradients - A vector of gradients at each point
 * x - A vector of x coordinates
 * y - A vector of y coordinates
 * extrapolation - A string in ("Curve", "Linear", "Constant") that gives behaviour outside of interpolation range.

### Returns
 * A vector of interval starts
 * A vector of interval ends
 * A matrix of all coefficients
  """
 function getCoefficientMatrix(x::Array{<:Real,1}, y::Array{<:Real,1}, gradients::Array{<:Real,1},
                               extrapolation::Tuple{Schumaker_ExtrapolationSchemes,Schumaker_ExtrapolationSchemes})
   n = length(x)
   fullMatrix = schumakerIndInterval([gradients[1], gradients[2]], [y[1], y[2]], [x[1], x[2]] )
    for intrval = 2:(n-1)
      Smallt = [ x[intrval] , x[intrval + 1] ]
      s = [ y[intrval], y[intrval + 1] ]
      z = [ gradients[intrval], gradients[intrval + 1] ]
      intMatrix = schumakerIndInterval(z,s,Smallt)
      fullMatrix = vcat(fullMatrix,intMatrix)
    end
    fullMatrix = extrapolate(fullMatrix, extrapolation, x[n], y)
   return fullMatrix[:,1], fullMatrix[:,2:4]
 end

"""
 Adds a row on top and bottom of coefficient matrix to give out of sample prediction.
### Takes
 * fullMatrix - output from GetCoefficientMatrix first few lines
 * extrapolation - A tuple with two enums in (Curve, Linear, Constant) that gives behaviour outside of interpolation range.
 * x - A vector of x coordinates
 * y - A vector of y coordinates

### Returns
  * A new version of fullMatrix with out of sample prediction built into it.
"""
function extrapolate(fullMatrix::Array{<:Real,2}, extrapolation::Tuple{Schumaker_ExtrapolationSchemes,Schumaker_ExtrapolationSchemes}, Topx::Real, y::Array{<:Real,1})
    # In the fullMatrix the first column are the x values and then the next 3 columns are a, b, c in the expression a(x-start)^2 + b(x-start) + c
  if (extrapolation[1] == Curve) && (extrapolation[2] == Curve)
    return fullMatrix
  end
  # Preliminaries used throughout
  dim = size(fullMatrix)[1]
  Botx   = fullMatrix[1,1]
  Boty   = y[1]
  Topy = y[length(y)]
  # Initialising variable so their domain is not restricted to the if statement spaces.
  BotB = 0.0
  BotC = 0.0
  TopA = 0.0
  TopB = 0.0
  TopC = 0.0
  # Now creating the extrapolation to the left.
  if extrapolation[1] == Linear
    BotB = fullMatrix[1 , 3]
    BotC   = Boty - BotB
  elseif extrapolation[1] == Constant
    BotB = 0.0
    BotC = Boty
  end # Note for the curve case we will simply not append the new block.
  BotRow = [Botx-1e-10, 0.0, BotB, BotC]

  # Now doing the extrapolation to the right.
  if extrapolation[2] == Linear # This is a bit more complicated than before because the
                                # coefficients by themselves give the gradients at the left
                                # of the interval. Here we want the gradient at the right.
    last_interval_width = Topx - fullMatrix[dim , 1]
    grad_at_right = 2 * fullMatrix[dim , 2] * last_interval_width + fullMatrix[dim , 3]
    TopB = grad_at_right
    TopC = Topy
  elseif extrapolation[2] == Constant
    TopB = 0.0
    TopC = Topy
  elseif extrapolation[2] == Curve # We are just going to add this one on regardless as otherwise end of data interval information is lost.
    Gap  =  Topx - fullMatrix[dim ,1]
    TopA = fullMatrix[dim ,2]
    TopB = fullMatrix[dim ,3] + 2 * TopA * Gap
    TopC = fullMatrix[dim ,4] + TopB * Gap - TopA * Gap*Gap
  end
  TopRow = [ Topx, TopA ,TopB ,TopC]
  # Appending blocks and returning.
  if extrapolation[1] != Curve fullMatrix = vcat(BotRow' , fullMatrix) end
  fullMatrix = vcat(fullMatrix,  TopRow')
  return fullMatrix
end
