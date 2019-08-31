using Distributed

procschage = false
if Distributed.nworkers() < 2
	procschage = true
	Distributed.addprocs(2)
	import RobustPmap
	import Test
end

if !isdefined(Base, Symbol("@stderrcapture"))
	@Distributed.everywhere macro stderrcapture(block)
		quote
			if ccall(:jl_generating_output, Cint, ()) == 0
				errororiginal = stderr;
				(errR, errW) = redirect_stderr();
				errorreader = @async read(errR, String);
				evalvalue = $(esc(block))
				redirect_stderr(errororiginal);
				close(errW);
				close(errR);
				return evalvalue
			end
		end
	end
end

@stderrcapture @everywhere f1(x) = x > 0 ? 1 : 1.
@stderrcapture function testtypecheck()
	@Test.test_throws TypeError RobustPmap.rpmap(f1, [-1, 0, 1]; t=Int)
end
@stderrcapture function testworks()
	@Test.test RobustPmap.rpmap(f1, [-1, 0, 1]) == Any[1., 1., 1]
end
@stderrcapture function testparallel()
	@Test.test length(unique(RobustPmap.rpmap(i->Distributed.myid(), 1:2))) != 1
end
@stderrcapture function testcheckpoint()
	result = RobustPmap.crpmap(x->x, 2, joinpath(pwd(), "test"), [-1, 0, 1]; t=Int)
	result2 = RobustPmap.crpmap(x->pi, 2, joinpath(pwd(), "test"), [-1, 0, 1]; t=Int)#test it with a different function to make sure it loads from the checkpoints
	rm(joinpath(pwd(), string("test", "_", hash(([-1, 0, 1],)), "_1.jld2")))
	rm(joinpath(pwd(), string("test", "_", hash(([-1, 0, 1],)), "_2.jld2")))
	@Test.test result == RobustPmap.rpmap(x->x, [-1, 0, 1]; t=Int)
	@Test.test result == result2
	x = rand(100)
	y = rand(100)
	result = RobustPmap.crpmap((x, y)->x + y, 10, joinpath(pwd(), "test"), x, y; t=Float64)
	result2 = RobustPmap.crpmap((x, y)->pi, 10, joinpath(pwd(), "test"), x, y; t=Float64)#test it with a different function to make sure it loads from the checkpoints
	for i = 1:10
		rm(joinpath(pwd(), string("test", "_", hash((x, y)), "_$i.jld2")))
	end
	@Test.test result == RobustPmap.rpmap((x, y)->x + y, x, y; t=Float64)
	@Test.test result == result2
end
@stderrcapture function onlyonproc1(x)
	return x
end

@Test.testset "RobustPmap" begin
	testtypecheck()
	testworks()
	testparallel()
	testcheckpoint()
	@Test.test_throws Distributed.RemoteException RobustPmap.rpmap(onlyonproc1, 1:10)
end

if procschage
	Distributed.rmprocs(Distributed.workers())
end

:passed
