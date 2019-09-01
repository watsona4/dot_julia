using Getopt
using Test

@testset "Getopt" begin
	args = ["-xxy1", "-y", "22", "--foo", "arg1", "-", "--wrong", "--bar=2", "--", "-x"]
	count, missing, n_x, l_y = 0, 0, 0, 0
	for (opt, arg) in Getopt.getopt(args, "xy:", ["foo", "bar="])
		if opt != "?" count += 1
		else missing += 1
		end
		if opt == "-x" n_x += 1
		elseif opt == "-y" l_y += length(arg)
		end
	end
	@test count == 6
	@test length(args) == 3
	@test missing == 1
	@test n_x == 2
	@test l_y == 3
end
