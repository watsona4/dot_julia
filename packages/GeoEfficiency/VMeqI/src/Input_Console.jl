#**************************************************************************************
# Input_Console.jl
# =============== part of the GeoEfficiency.jl package.
#
# all the input from the console to the package is handled by some function here.
#
#**************************************************************************************

#------------------ consts - globals - imports ----------------------------

using Compat, Compat.MathConstants
using Compat: @warn


#---------------------------- input ---------------------------------

"""# UnExported

	input(prompt::AbstractString = "?: ", incolor::Symbol = :green)

return a string represent the user respond delimited by new line excluding the new line.
prompt the user with the massage `prompt` defaults to `? `. 
wait until the user type its respond and press return. 
`incolor` specify the prompt text color, default to ``:green`` may take any of the values 
`:black`, `:blue`, `:cyan`, `:green`, `:light_black`, `:light_blue`, `:light_cyan`, `:light_green`,
`:light_magenta`, `:light_red`, `:light_yellow`, `:magenta`, `:red`, `:white`, or `:yellow`.

!!! color
		The effect of color is not allways respected in all teriminals as some color may be simplly 
		ignored by some teriminals.

"""
function input(prompt::AbstractString = "?: ", incolor::Symbol = :green)::AbstractString
    printstyled(prompt, color=incolor, bold=true); chomp(readline())
end # function


#---------------------------- getfloat -----------------------------------

"""# UnExported

	getfloat(prompt::AbstractString = "?: ", from::Real = -Inf, to::Real = Inf; KW...)::Float64

prompts the user with the massage `prompt` defaults to `?: ` to input a numerical **expression** 
evaluate to a numerical value.
check that the numerical value is in interval [`from`, `to`[ by default [-∞,	∞[ before returning it as a `Float64`. 
throws `ArgumentError` when the given interval is not valid.
if the numerical expression fail to evaluated to numerical value or the numerical value is not in the valid interval 
the function will warn the user and **reprompt** him to give a valid expresion.

## KW arguments
*  value::AbstractString`="nothing"` : if provided the function will not ask for input from the 
   `console` and take it as if it where inputted from the  `console` [`for test propose mainly`].
*  lower::Bool`=true` : whether or not to inculde `from` as accepted value.
*  upper::Bool`=false` : whether or not to inculde `to` as accepted value.

!!! note
		A blank input (i.e just a return) is considered as being `0.0`. 
		Input from the `console` can be numerical expression not just a number. 
		expression like ``5/2`` ; ``5//2`` ; ``pi`` ; ``π/2`` ; ``exp(2)`` ; ``1E-2 `` ; ``5.2/3`` ; 
		``sin(1)`` ;  ``sin(1)^2`` are all valid expressions.

# Examples
```
julia> getfloat("input a number:", value="3")
3.0

julia> getfloat("input a number:", value="")
0.0

julia> getfloat("input a number:", value="5/2")
2.5

julia> getfloat("input a number:", value="5//2")
2.5

julia> getfloat("input a number:", value="pi")
3.141592653589793

julia> getfloat("input a number:", value="-2")
-2.0

julia> getfloat("input a number:", value="sin(1)^2")
0.7080734182735712

julia> getfloat("input a number:", 1, 5, value="5", upper=true)
5.0
```

"""
function getfloat(prompt::AbstractString = "?: ", from::Real = -Inf, to::Real = Inf;
				value::AbstractString="nothing", lower::Bool=true, upper::Bool=false)::Float64
	"nothing" == value ? value = input(prompt) : nothing
	"" 		  == value ? value = "0.0" : nothing		# just pressing return is interpreted as <0.0>
	
	local val::Float64
	try
		val =  Meta.parse(value) |> eval |> float
		@assert from < val < to || (lower && from == val) || (upper && to == val) 	

	catch err
		if isa(err, AssertionError)
			let interval = "interval '$(lower ? '[' : ']') $from, $to $(upper ? ']' : '[')'"
				lower || upper || from != to ||	ArgumentError("the $interval is not valid") |> throw
				from <= to || ArgumentError("the $interval is not valid") |> throw
				@warn("""the input '$value' evaluated to be outside the $interval.
				\n Please: provide an adequate value""")
			end #let
    else
			@warn("""the input '$value' cannot be parsed to a valid numerical value!,
			\n Please: provide a valid expression""")
    end #if    
		
		return getfloat(prompt, from, to; lower=lower, upper=upper)
	end #try
	return val
end	
