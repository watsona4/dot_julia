# Jfire
#### Why Jfire <br>
&nbsp;&nbsp;&nbsp;&nbsp;inspired by python-fire(https://github.com/google/python-fire) and Fire(https://github.com/ylxdzsw/Fire.jl) <br>
#### Install<br>
```
julia> ] 
julia> add Jfire # need julia 0.7.0+
```
#### Feature<br>
&nbsp;&nbsp;&nbsp;&nbsp;1. support call single/multiple Function or single/multiple Module. <br>
#### Thanks<br>
&nbsp;&nbsp;&nbsp;&nbsp;thanks the  people: I learned from https://discourse.julialang.org/t/how-to-set-variable-to-key-of-keyword-arguments-of-function/18995/7, after that, I tried to write Jfire. <br>
#### Dependence<br>
```
julia 0.7.0/1.0.3/1.1.0-rc1
```

#### Usage<br>
doc/myth.jl is an example call from single Module:<br>
```
using Jfire

module myth
export hello
function hello(;name::String="myth", greet::String="how is the weather?", number::Number=3)
	println("hello, $name. $greet. $number")
end
end

if abspath(PROGRAM_FILE) == @__FILE__
	Jfire.Fire(myth, time=true, color=:yellow, info=false)
end
```
then run :
```
$ julia myth.jl hello --name world --number Int::5
hello, world. how is the weather?. 5
  0.032762 seconds (69.26 k allocations: 3.502 MiB)
```
doc/myths.jl is an example call from multiple Module:<br>
```
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
```
then run :
```
$ julia myths.jl  myth1.hello1 --name world --number Int::5
hello, world. how is the weather?. 5
```
doc/func.jl is an example call from single Function:<br>
```
using Jfire
function myth_func1(wow::String;name::String="myth", greet::String="how is the weather?")
	println("$wow, hello, $name ~ $greet")
end
if abspath(PROGRAM_FILE) == @__FILE__
	Jfire.Fire(myth_func1, info=false)
end
```
then run :
```
$ julia  func.jl wow
wow, hello, myth ~ how is the weather?
```
doc/funcs.jl is an example call from multiple Function:<br>
```
using Jfire
function myth_func1(wow;name::String="myth", greet::String="how is the weather?", fishing::Bool=true)
	if fishing
		fish = ""
	else
		fish = "not"
	end
	println("$wow, hello, $name ~ $greet, I will $fish go fishing today~")
end
function myth_func2(wow;name::String="myth", greet::String="how is the weather?")
	println("$wow, hello, $name ~ $greet")
end

if abspath(PROGRAM_FILE) == @__FILE__
	Jfire.Fire((myth_func1,myth_func2), time=true, color=:yellow)
end
```
then run :
```
$ julia  funcs.jl  myth_func1 well --greet 'nice day' --fishing Bool::true
[33mJfire version 0.1.0[39m
[33m2019-01-22T12:51:52.847 ... start fire[39m
position arguments: ("well",)
optional arguments: (greet = "nice day", fishing = true)

well, hello, myth ~ nice day, I will  go fishing today~
  0.024783 seconds (41.69 k allocations: 2.172 MiB, 27.47% gc time)
[33m2019-01-22T12:51:53.6 ... end fire[39m
```
<br>
detail test script is doc/test.sh<br>

#### Support function parameter types:<br>
&nbsp;&nbsp;&nbsp;&nbsp;default is String,you also can specify the type, like --parameter Int::32, support julia build-in type which is argument of parse(), like Int,Float32,Float64,etc<br>
&nbsp;&nbsp;&nbsp;&nbsp;position arguments or optional keywords argument<br>

#### Not support function parameter types:<br>
&nbsp;&nbsp;&nbsp;&nbsp;--help<br>

