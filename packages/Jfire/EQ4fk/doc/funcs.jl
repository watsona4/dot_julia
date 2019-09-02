using Jfire
function myth_func1(wow;name::String="sikaiwei", greet::String="how is the weather?", fishing::Bool=true)
	if fishing
		fish = ""
	else
		fish = "not"
	end
	println("$wow, hello, $name ~ $greet, I will $fish go fishing today~")
end
function myth_func2(wow;name::String="sikaiwei", greet::String="how is the weather?")
	println("$wow, hello, $name ~ $greet")
end

if abspath(PROGRAM_FILE) == @__FILE__
	Jfire.Fire((myth_func1,myth_func2), time=true, color=:yellow)
end

