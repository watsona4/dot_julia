using LatinSquares

if length(ARGS) == 0
	println("Usage: julia run_latin n")
	exit()
end
n = parse(ARGS[1])
println("n = $n")
println("Starting up")

# Here's a place to adjust Gurobi settings
# env = Gurobi.Env()
# setparam!(env,"Threads", 8)
# setparam!(env,"ConcurrentMIP", 2)

tic();
try
	A,B = ortho_latin(n)
	println("A = $A")
	println("B = $B")
end
toc()
