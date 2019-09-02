using Jfire

module myth1
export hello1
function hello1(;name::String="myth", greet::String="how is the weather?", number::Number=3)
	println("hello, $name. $greet. $number")
end
end

module myth2
export hello2
function hello2(;name::String="myth", greet::String="how is the weather?", number::Float32=3.0)
	println("hello, $name. $greet. $number")
end
end

if abspath(PROGRAM_FILE) == @__FILE__
	ms = (myth1, myth2)
	Jfire.Fire(ms, info=false,  time=false)
end
