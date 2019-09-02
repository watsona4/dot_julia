using Jfire
function myth_func1(wow::String;name::String="myth", greet::String="how is the weather?")
	println("$wow, hello, $name ~ $greet")
end
if abspath(PROGRAM_FILE) == @__FILE__
	Jfire.Fire(myth_func1, info=false)
end

