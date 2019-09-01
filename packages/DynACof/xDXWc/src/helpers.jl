"""
    is_missing(MetData, "Date")
Find if a column is missing from a DataFrame.

# Arguments
- `data::DataFrame`: a DataFrame
- `key::String`: a column name

# Return
A boolean: `true` if the column is missing, `false` if it is present.

# Examples
```julia
df= DataFrame(A = 1:10)
is_missing(df,"A")
false
is_missing(df,"B")
true
```
"""
function is_missing(data::DataFrame,key::String)::Bool
  columns= names(data)
  for i in 1:length(columns)
    is_in_col= columns[i] == Symbol(key)
    if is_in_col
      return false
    end
  end
  return true
end


"""
    is_missing(data::NamedTuple,key::String)
Find if a key is missing from a tuple.

# Arguments
- `data::NamedTuple`: a named tuple
- `key::String`: a key (parameter) name

# Return
A boolean: `true` if the key is missing, `false` if it is present.

# Examples
```julia
Parameters= Dict("Stocking_Coffee"=> 5580)
is_missing(Parameters,"Stocking_Coffee")
false
is_missing(Parameters,"B")
true
```
"""
function is_missing(data::NamedTuple,key::String)::Bool
  try
    getfield(data,Symbol(key))
  catch error
    if isa(error, ErrorException)
      return true
    end
  end
  return false
end



"""
    warn_var("Date","Start_Date from Parameters","warn")
Warn or stop execution if mandatory meteorology input variables are not provided.
It helps the user to know which variable is missing and/or if there are replacements

# Arguments
- `Var::String`: Input variable name
- `replacement::String`: Replacement variable that is used to compute `"Var"`
- `type::String`: Type of error to return : either

# Note
* This function helps to debug the model when some mandatory meteorological variables
are missing from input: either an error (default), or a warning.
* If the `"replacement"` variable is not provided in the meteorology file either, this function
will return an error with a hint on which variables can be provided to compute `"Var"`

# Examples
```julia
warn_var("Date","Start_Date from Parameters","warn")
```
"""
function warn_var(Var::String,replacement::String,type::String="error")
  if type=="error"
    error(string("$Var missing from input Meteo. Cannot proceed unless provided.",
                 " Hint: $Var can be computed alternatively using $replacement if provided in Meteo file")
               )
  else
    println("$Var missing from input Meteo. Computed from $replacement")
  end
end

"""
    warn_var("Date")
Stop execution if mandatory meteorology input variable is not provided.

# Arguments
- `Var::String`: Input variable name

"""
function warn_var(Var::String)
  error("$Var missing from input Meteo. Cannot proceed unless provided.")
end

function cos°(x::Float64)::Float64
  cos(x*π/180.0)
end

function sin°(x::Float64)::Float64
  sin(x*π/180.0)
end

function tan°(x::Float64)::Float64
  tan(x*π/180.0)
end

function acos°(x::Float64)::Float64
  acos(x)*180.0/π
end

function asin°(x::Float64)::Float64
  asin(x)*180.0/π
end


function atan°(x::Float64)::Float64
  atan(x)*180.0/π
end


"""
Trigonometric Functions (degree)

These functions give the obvious trigonometric functions. They respectively compute the cosine, sine, tangent,
arc-cosine, arc-sine, arc-tangent with input and output in degree.

# Returns
The output in degree

# Details
The conversions between radian to degree is: 

```math
x \\cdot \\frac{pi,180}
```


# Examples
```julia
# cosinus of an angle of 120 degree:
cos°(120)
# should yield -0.5, as in the base version:
cos(120*π/180)
```
"""
cos°,sin°,tan°,acos°,asin°,atan°




"""
    struct_to_tuple(structure::DataType,instance)
Transform a `struct` instance into a tuple, keeping the field names and values.  
    
# Arguments 
- `structure::DataType`: Any `struct`
- `instance`: An instance of `structure`.

# Returns
A named tuple with names and values from the structure. 

# Examples
```julia
struct_to_tuple(constants, constants())
```
"""
function struct_to_tuple(structure::DataType,instance)
  structure_names= fieldnames(structure)
  structure_values= map(x -> getfield(instance, x), structure_names)
  NamedTuple{structure_names}(structure_values)
end



"""
Find the ith previous index, avoiding 0 or negative indexes.

# Arguments
- `i::DataType`: Current index
- `n`: Target number of indexes before x

# Details
This function is used to find the nth previous index without making an error with negative or 0 index.

# Examples
```julia
# Find the 10th index before 15:
previous_i(15,10)
5
# Find the 10th index before 5:
previous_i(5,10)
1
```
"""
function previous_i(x::Int64,n::Int64=1)
  x-n<=0 ? 1 : x-n
end



"""
Compute a logistic function or its derivative

# Arguments
- `x::Float`:       The x value
- `u_log::Float64`:  Inflexion point (x-value of the sigmoid's midpoint)
- `s_log::Float64`:  Steepness of the curve

# Return
- logistic: the logistic function
- logistic_deriv: the derivative of the logistic function

# Seealso
More informations can be found in [the wikipedia page](https://en.wikipedia.org/wiki/Logistic_function)

# Examples
```julia
logistic(1:10,5,0.1)
logistic_deriv(1:10,5,0.1)
```
"""
logistic,logistic_deriv

function logistic(x,u_log,s_log)
  1.0 / (1.0 + exp(-((x - u_log) / s_log)))
end

function logistic_deriv(x,u_log,s_log)
  # logistic(x,u_log,s_log) * (1.0 - logistic(x,u_log,s_log))
  exp(-((x-u_log)/s_log))/(s_log*(1+exp(-((x-u_log)/s_log)))^2)
end

"""
    mean(x)
 Mean of a vector
"""
function mean(x)
 sum(x)/length(x)
end
