import Wells
import Test

function runlinvtests()
	F1(s) = 1 / sqrt(s)
	f1(t) = 1 / sqrt(pi * t)
	F2(s) = log(s) / s
	f2(t) = -0.5772156649015328606065120 - log(t)
	F3(s) = 1 / s ^ 4
	f3(t) = t ^ 3 / 6
	F4(s) = 1 / (s + 1)
	f4(t) = exp(-t)
	F5(s) = sqrt(pi / (2 * s ^ 3)) * exp(-1 / (2 * s))
	f5(t) = sin(sqrt(2 * t))
	for (F, f) in zip([F1, F2, F3, F4, F5], [f1, f2, f3, f4, f5])
		Finv = Wells.Linv.makelaplaceinverse(F)
		@Test.test abs(max(map(x->f(x)-Finv(x), 1:10)...)) < 1e-5
	end
end

function runmonotonicitytest()
	T = 100
	S = 0.02
	Q = 2
	r = 10
	R = 100
	Qw = .1 # m^3/sec
	K1 = 1e-3 # m/sec -- pervious
	K2 = 1e-5 # m/sec -- semi-pervious
	L1 = 100 # m
	L2 = 200 # m
	Sc1 = 7e-5 # m^-1 -- dense, sandy gravel
	Sc2 = 1e-5 # m^-1 -- fissured rock
	ra = .1 # m
	R = 100 # m
	omega = 1e3 # no resistance
	deltah = 0 # m
	r1 = 50 # m
	r2 = 100 # m
	rw = 25 # m
	lambda = 100 * r
	ts = 3600:3600*24:3600*24*365*10
	fs = Function[]
	push!(fs, t->Wells.theisdrawdown(t, r, T, S, Q))
	theisdrawdownwithzerofluxboundary = Wells.makedrawdownwithzerofluxboundary(Wells.theisdrawdown)
	push!(fs, t->theisdrawdownwithzerofluxboundary(R, t, r, T, S, Q))
	push!(fs, Wells.makeavcideltahead1(Qw, K1, K2, L1, L2, Sc1, Sc2, ra, R, omega, deltah, r1))
	push!(fs, Wells.makeavcideltahead2(Qw, K1, K2, L1, L2, Sc1, Sc2, ra, R, omega, deltah, r2, rw))
	push!(fs, t->Wells.hantushleakydrawdown(t, r, T, S, Q, lambda))
	lastdrawdowns = zeros(length(fs))
	for t in ts
		for j = 1:length(fs)
			thisdrawdown = fs[j](t)
			@Test.test thisdrawdown >= lastdrawdowns[j]
			lastdrawdowns[j] = thisdrawdown
		end
	end
end

function hantushlimittest()
	T = 100
	S = 0.02
	Q = 2
	r = 10
	lambda = 1e6#theis and leakyhantush should be the same for large lambda
	ts = 0:3600*24:3600*24*365*10
	for t in ts
		@Test.test Wells.theisdrawdown(t, r, T, S, Q) ≈ Wells.hantushleakydrawdown(t, r, T, S, Q, lambda) atol=1e-6
	end
end

function timedepmacrotest()
	T = 100
	S = 0.02
	Q = 2
	r = 10
	Qm = Array{Float64}(undef, T, 2)
	for i = 1:size(Qm, 1)
		Qm[i, 1] = i#set the time
		Qm[i, 2] = 1 + 0.5 * randn()
	end
	for t in range(0; length=101, step=2)
		@Test.test Wells.theisdrawdown(t, r, T, S, Qm) == Wells.theisdrawdownmanual(t, r, T, S, Qm)
	end
end

runlinvtests()
runmonotonicitytest()
hantushlimittest()
timedepmacrotest()
