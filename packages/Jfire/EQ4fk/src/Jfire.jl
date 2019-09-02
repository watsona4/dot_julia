__precompile__()


module Jfire

export Fire

using Dates


function Fire(the_called::Union{Function, Module, Tuple};time::Bool=false, color::Symbol=:green, info::Bool=true)
	version = "0.1.0"
	show_info(info, color, true, version)
	the_called_type = check_called_type(the_called, ARGS)
	help_info(the_called, the_called_type, ARGS)
	need, kws, the_called = parse_args(ARGS, the_called_type, the_called, info, color)
	
	if the_called_type  == "module"
		the_func = ARGS[1]
		if time
			@time call_module(the_called, the_func, need, kws)
		else
			call_module(the_called, the_func, need, kws)
		end
	elseif the_called_type == "modules"
		the_func = replace(ARGS[1], r"^.*\."=>"")
		if time
			@time call_module(the_called, the_func, need, kws)
		else
			call_module(the_called, the_func, need, kws)
		end
	elseif the_called_type == "function" || the_called_type == "functions" 
		if time
			@time call_function(the_called, need, kws)
		else
			call_function(the_called, need, kws)
		end
	else
		myexit("sorry, not support the_called_type = $the_called_type for $the_called yet")
	end
	show_info(info, color, false, version)
end

function show_info(info::Bool=true, color::Symbol=:green, head::Bool=true, version::String="0.1.0")
	if info && head
		io = IOContext(stdout, :color => true)
		printstyled(io, "Jfire version $version\n",color=color)
		printstyled(io, "$(now()) ... start fire\n", color=color)	
	end
	if info && head == false
		io = IOContext(stdout, :color => true)
		printstyled(io, "$(now()) ... end fire\n", color=color)	
	end
end

function help_info(the_called::Union{Function, Module, Tuple}, the_called_type::String, args::Array)
	#println("22")
	if occur_help(args[end]) == false
		return
	end
	if the_called_type == "module"
		module_help(the_called, args, the_called_type)
	elseif the_called_type == "modules"
		for m in the_called
			#println("1")
			module_help(m, args, the_called_type)
			#println("3")
		end
	elseif the_called_type == "function"
		function_help(args, the_called)
	elseif the_called_type == "functions"
		for func in the_called
			function_help(args, func)
		end
	else
		myexit("sorry, not support $the_called_type")
	end
	#println("isis")
	if occur_help(args[end])
		exit()
	end
end


function check_called_type(the_called::Union{Function, Module, Tuple},args::Array)
	the_called_type = typeof(the_called)
	if the_called_type == Module
		the_called_type = "module"
		if length(args) == 0
			myexit("error, need to give a Function name in module $the_called")
		end
	elseif occursin(r"^Tuple{Module", string(the_called_type))
		the_called_type = "modules"
		if length(args) == 0
			myexit("error, need to give a Function name in modules $the_called")
		end
	elseif occursin(r"^typeof", string(the_called_type))
		the_called_type = "function"
	elseif occursin(r"^Tuple{typeof", string(the_called_type))
		the_called_type = "functions"
		if length(args) == 0
			myexit("error, need to give a Function name in functions $the_called")
		end
	else
		myexit("sorry, not support the_called_type = $the_called_type for $the_called yet")
	end
	return the_called_type
end

function module_help(the_called::Module, args::Array{String}, the_called_type::String="")
	the_name = replace(string(the_called), r"^Main\."=>"")
	printstyled("\nModule $the_name\n", color=:green)
	if length(args) >=1 && occur_help(args[1])
		funcs = names(the_called)
		for i in firstindex(funcs):lastindex(funcs)
			func = funcs[i]
			the_type = typeof(getfield(the_called, func))
			if the_type != Module
				show_function_info(getfield(the_called, Symbol(func))) 
			end
		end
	end
	if length(args) >=2 && occur_help(args[2])
		if occursin(r"\.", args[1])
			func = replace(args[1], r"^.*\."=>"")
			show_function_info(getfield(the_called, Symbol(func)))
		end
	end
end

function occur_help(str::String)
	if occursin(r"^-?-help$", str) || occursin(r"^-?-[Hh]$", str)
		return true
	else
		return false
	end
end

function parse_args(args::Array{String}, the_called_type::String, the_called::Union{Function, Module, Tuple}, info::Bool=true, color::Symbol=:green)
	if the_called_type == "module"
		need, kws = parse_kws(args[2:end], info)
		return need, kws, the_called
	elseif the_called_type == "modules"
		if length(args) >=1 && ! occursin(r"\.", args[1]) && ! occur_help(args[1])
			myexit("format should like: module_name.fuction_name , not $(args[1]) for $the_called")
		end
		for m in the_called
			the_type = typeof(m)
			if the_type != Module
				myexit("error, $m is not a Module name")
			end
			module_name = replace(string(m), r"^Main\."=>"")
			if replace(args[1], r"\..*"=>"") == module_name && info
				printstyled("\nmodule $module_name\n", color=color)
			end
			if length(args)>=1 &&  replace(string(m), r".*\."=>"") == replace(args[1], r"\..*"=>"")
				need, kws = parse_kws(args[2:end], info)
				return need, kws, m
			end
		end
		if length(args)>=1
			if ! occur_help(args[1])
				if length(args)>=2 && occur_help(args[2])
					exit()
				end
				myexit("error: cannot find module $(args[1]), only support $the_called")
			end
		end
	elseif the_called_type == "function"
		need, kws = parse_kws(args, info)
		return need, kws, the_called
	elseif the_called_type == "functions"
		if length(args) == 0
			myexit("error, you shold give function name")
		end
		for func in the_called
			if string(func) == args[1]
				need, kws = parse_kws(args[2:end], info)
				return need, kws, func
			end
		end
		if ! occur_help(args[1])
			myexit("error, cannot find Function $(args[1]) in $the_called")
		else
			exit()
		end
	else
		myexit("sorry, not support $the_called_type yet, only Module or Funciton or tuple like (Module1,Module2)")
	end
end

function myexit(info::String)
	println("\n$info\n")
	exit()
	#@error info
	#@info info
	#@warn info # https://docs.julialang.org/en/v1/stdlib/Logging/index.html
end

function function_help(args::Array{String}, the_called::Function)
	the_name = string(the_called)
	printstyled("\nFunction $the_name\n", color=:green)
	if length(args) >=1 && occur_help(args[1])
		show_function_info(the_called)
	end
end

function show_function_info(func::Function)
	#dump(func)
	println(methods(func))
end

function get_help(the_called)
	if typeof(the_called) == Module
		#println("here")
		funcs = names(the_called)
		for i in firstindex(funcs):lastindex(funcs)
			func = funcs[i]
			the_type = typeof(getfield(the_called, func))
			if the_type != Module
				println(the_type)
				println(Main.myth.hello)
			end
		end
	else
		println("dd")
	end

end
#methods(the_called.hello) # it works too !

function parse_kws(args::Array{String}, info::Bool=true)
	need = param_keys = param_values = []
	flag = 0
	# gather must need parameter
	for (i,j) in enumerate(args)
		if flag == 0
			if ! occursin(r"^-", j)
				push!(need, convert_type(j))
			else
				flag = i
			end
		end
	end
	
	need = tuple(need...)
	if flag == 0
		if length(need) != 0 && info
			println("position arguments: $need\n")
		end
		return need,NamedTuple{tuple()}(tuple())
	end
	args = args[flag:end]
	if isodd(length(args)) || length(args) == 0
		myexit("sorry, parameter $args number should >=0 and is odd number")
	end

	# check parameter if start with --
	[ occursin("-", args[i]) || myexit("sorry, $(args[i]) maybe is paramter, should start with --, like --$(args[i])") for i in 1:2:length(args)]
	
	# gather keys of parameter
	param_keys = [ Symbol(replace(args[i], '-' => "")) for i in 1:2:length(args)]

	# gather value of parameter
	param_values = [convert_type(args[i]) for i in 2:2:length(args)]
		
	kws = NamedTuple{tuple(param_keys...)}(tuple(param_values...)) # genearate keywords argument for function, ... mean unpack the array, convert array to tuple
	if length(need) != 0 && info
		println("position arguments: $need")
	end
	if length(kws) != 0 && info
		println("optional arguments: $kws\n")
	end
	return need, kws
end

function convert_type(str::String)
	m = match(r"^([^:]*)::(.*)", str)
	if m === nothing
		return str
	end
	if m[1] == "string" ||  m[1] == "String"
		return string(m[2])
	end
	try
		the_type = getfield(Main, Symbol(m[1]))
		return parse(the_type, m[2])
	catch
		myexit("error: $(m[1]) in $str is not support by julia Main Module")
	end
end



function call_module(the_called::Module, the_func, need::Tuple, kws::NamedTuple)
	the_func = replace(the_func, r"^.*\."=>"")
	funcs = names(the_called)
	flag = 1
	for i in firstindex(funcs):lastindex(funcs)
		func = funcs[i]
		the_type = typeof(getfield(the_called, func))
		if the_type != Module && string(func) == the_func
			flag = 0
			#println("match $(hello) $(func)")
			#getfield(the_called, func)(;NamedTuple{(Symbol(hello_k1), )}((hello_w1, ))...) # it works!
			#ins = Symbol(hello_k1) => hello_w1, Symbol("greet") => "how is today?" # it works too !
			#ins = NamedTuple{(Symbol(hello_k1), Symbol("greet"))}((hello_w1, "hot is today")) # it works !
			getfield(the_called, func)(need...;kws...) # it works too !
			#getfield(the_called, func)(;Symbol(hello_k1) => hello_w1, Symbol("greet") => "how is today?") # it works too !
			#getfield(the_called, func)(;Symbol(hello_k1) = hello_w1) # it not works 
			#getfield(the_called, func)(;(Symbol(hello_k1) => hello_w1, Symbol("greet") => "how is today?")...) # it works too !
		end
	end

	if flag == 1 && ! occur_help(the_func)
		myexit("sorry, not find function $the_func in $the_called")
	end
	# thanks to https://discourse.julialang.org/t/how-to-set-variable-to-key-of-keyword-arguments-of-function/18995
	#
end

function call_function(the_called::Function, need::Tuple, kws::NamedTuple)
	the_called(need...;kws...)
end

function help(func::Function)
	vinfo = code_lowered(func)
	vinfo_type = code_typed(func)
	println(vinfo_type)
	println("\n")
	println(split(string(vinfo[1]), r"Main.:")[end])
	println("\n")
	println(vinfo[1].slotnames)
	println(func.kwargs)
	error()
end


end
