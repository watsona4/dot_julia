module Helper
using Compat
using Compat: stdin, @warn #, split

"""# UnExported

	@console 	expresion 	[console_inputs...]

execute the expresion `expresion` after putting `console_inputs` into the standar input buffer.

for functions that meant to run iteractivelly while require user intput, this macro provid a tool to 
allow for noninteractive testing such functions by providing the input in advance by `console_inputs`.
"""
macro console(expression, console_inputs...)
	quote
		bffr = readavailable(stdin.buffer) # empty input stream to ensure later only the `console_inputs` is in `stdin` buffer.
		bffr == UInt8[] || @warn "buffer not empty, see the pervious process to 'stdin'"  buffer = String(bffr)
		if 0 == length($console_inputs)
			write(stdin.buffer, "\n")   					# [1of2] empty `console_inputs` simulate return or enter .
		else
			for input in $console_inputs
				if typeof(input) == String && input != "" 	# [2of2]empty `console_inputs` simulate return or enter .
					for npt in string.(split(input))
						write(stdin.buffer, npt, "\n")
					end
				else
					write(stdin.buffer, string(input), "\n")
				end #if
			end # for
		end #IF
		$expression		#:($(esc(expression)))
	end |> esc
end

"""# UnExported

	exec_console_unattended(Fn::Union{Function, Type}, console_inputs::Vector = []; 
																	Fn_ARGs::Vector=[])


execute the expresion `Fn(Fn_ARGs...)` after putting `console_inputs` into the standar input buffer.

for functions that meant to run iteractivelly while require user intput, this function provid a tool to 
allow for noninteractive testing such functions by providing the input in advance by `console_inputs`.
"""
function exec_console_unattended(Fn::Union{Function, Type}, console_inputs::Vector = []; Fn_ARGs::Vector=[])
	bffr = readavailable(stdin.buffer) # empty input stream to ensure later only the `console_inputs` is in `stdin` buffer.
	bffr == UInt8[] || @warn "buffer not empty, see the pervious process to 'stdin'"  buffer = String(bffr) 
	
	if 0 == length(console_inputs)
		write(stdin.buffer, "\n")   # empty `console_inputs` simulate return or enter .

	else
		for input in  string.(console_inputs)
			write(stdin.buffer, input, "\n") 
		end # for

	end #IF
	
	return Fn(Fn_ARGs...)		# call and return the value	
end

"""# UnExported

	exec_console_unattended(Fn::Union{Function, Type}, console_inputs...; 
																	Fn_ARGs::Vector=[])


execute the expresion `Fn(Fn_ARGs...)` after putting `console_inputs` into the standar input buffer.

for functions that meant to run iteractivelly while require user intput, this function provid a tool to 
allow for noninteractive testing such functions by providing the input in advance by `console_inputs`.
"""
exec_console_unattended(Fn::Union{Function, Type}, console_inputs...; Fn_ARGs::Vector=[]) = exec_console_unattended(Fn, [console_inputs...]; Fn_ARGs=Fn_ARGs)

"""# UnExported

	exec_console_unattended(Fn::Union{Function, Type}, console_inputs::String; 
																	Fn_ARGs::Vector=[])


execute the expresion `Fn(Fn_ARGs...)` after putting `console_inputs` into the standar input buffer.

for functions that meant to run iteractivelly while require user intput, this function provid a tool to 
allow for noninteractive testing such functions by providing the input in advance by `console_inputs`.
"""
exec_console_unattended(Fn::Union{Function, Type}, console_inputs::String; Fn_ARGs::Vector=[]) = exec_console_unattended(Fn, split(console_inputs); Fn_ARGs=Fn_ARGs)

end
const H = Helper
