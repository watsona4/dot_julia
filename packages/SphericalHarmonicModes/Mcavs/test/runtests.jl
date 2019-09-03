using Test,SphericalHarmonicModes

@testset "constructors" begin

	@testset "st" begin
		@test st(0:3,-1:1) == st(0,3,-1,1)
		@test st(0:3,1) == st(0,3,1,1)
		@test st(2,1:2) == st(2,2,1,2)
		@test st(0:3) == st(0,3,-3,3)
		@test st(2) == st(2,2,-2,2)
	end

	@testset "ts" begin
		@test ts(0:3,-1:1) == ts(0,3,-1,1)
		@test ts(0:3,1) == ts(0,3,1,1)
		@test ts(2,1:2) == ts(2,2,1,2)
		@test ts(0:3) == ts(0,3,-3,3)
		@test ts(2) == ts(2,2,-2,2)
	end

	@testset "s′s " begin
		Δs_max = rand(1:3)
		s_range = rand(1:3):rand(4:10)
		@test s′s(s_range,Δs_max) == s′s(s_range,st(0:Δs_max,0))
		@test s′s(s_range,Δs_max) == s′s(s_range,ts(0:Δs_max,0))
	end
end

@testset "length" begin
	@testset "ts" begin
		for smin=0:10,smax=smin:10,tmin=-smax:smax,tmax=tmin:smax
			m = ts(smin,smax,tmin,tmax)
			@test begin 
				res = length(m) == sum(length(t_valid_range(m,s)) 
								for s in s_range(m))
				if !res
					println(m)
				end
				res
			end
		end
	end

	@testset "st" begin
		for smin=0:10,smax=smin:10,tmin=-smax:smax,tmax=tmin:smax
			m = st(smin,smax,tmin,tmax)
			@test begin
				res = length(m) == sum(length(s_valid_range(m,t)) 
								for t in t_range(m))
				if !res
					println(m)
				end
				res
			end
		end
	end

	@testset "st==ts" begin
	    for smin=0:10,smax=smin:10,tmin=-smax:smax,tmax=tmin:smax
			m1 = st(smin,smax,tmin,tmax)
			m2 = ts(smin,smax,tmin,tmax)
			@test length(m1) == length(m2)
		end
	end

	@testset "s′s default s′minmax" begin
		for smin=0:10,smax=smin:10,Δs_max=0:10
			m = s′s(smin,smax,Δs_max)
			@test length(m) == sum(length(s′_valid_range(m,s)) for s in s_range(m))			
		end
	end

	@testset "s′s all" begin
		for smin=0:10,smax=smin:10,Δs_max=0:10
			m = s′s(smin,smax,Δs_max)
			for spmin=0:smax+Δs_max,spmax=spmin:smax+Δs_max
				m = s′s(smin,smax,Δs_max,spmin,spmax)
				@test begin
					res = length(m) == sum(length(s′_valid_range(m,s)) for s in s_range(m))
					if !res
						println(m)
					end
					res
				end
			end
		end
	end
end

@testset "st ts modes" begin
	for smin in 0:10,smax=smin:10,tmin=-smax:smax,tmax=tmin:smax
		s_range = smin:smax
		t_range = tmin:tmax
		m1 = st(s_range,t_range)
		m2 = ts(s_range,t_range)
		@test sort(collect(m1)) == sort(collect(m2))
	end
end

@testset "modeindex" begin

	function modeindex2(m::ts,s::Integer,t::Integer)
		N_skip = 0
		for si in m.smin:s-1
			N_skip += length(t_valid_range(m,si))
		end

		N_skip + searchsortedfirst(t_valid_range(m,s),t)
	end

	function modeindex2(m::st,s::Integer,t::Integer)
		N_skip = 0
		for ti in m.tmin:t-1
			N_skip += length(s_valid_range(m,ti))
		end

		N_skip + searchsortedfirst(s_valid_range(m,t),s)
	end

	function modeindex2(m::s′s,s′::Integer,s::Integer)
		N_skip = 0
		for si in m.smin:s-1
			N_skip += length(s′_valid_range(m,si))
		end

		N_skip + searchsortedfirst(s′_valid_range(m,s),s′)
	end

	modeindex2(m::SHModeRange,(s,t)::Tuple) = modeindex(m,s,t)

	@testset "st" begin
		for smin=0:3,smax=smin:3,tmin=-smax:smax,tmax=tmin:smax
			m1 = st(smin,smax,tmin,tmax)
			for (s,t) in m1
				@test modeindex(m1,s,t) == modeindex2(m1,s,t)
			end
			m1c = collect(m1)
			for t in t_range(m1), s1 in s_valid_range(m1,t), 
					s2 in s_valid_range(m1,t)
				
				smin,smax=minmax(s1,s2)
				@test modeindex(m1,smin:smax,t) == 
				findfirst(isequal((smin,t)),m1c):findfirst(isequal((smax,t)),m1c)
			end
		end
	end

	@testset "ts" begin
		for smin=0:3,smax=smin:3,tmin=-smax:smax,tmax=tmin:smax
			m2 = ts(smin,smax,tmin,tmax)
			for (s,t) in m2
				@test modeindex(m2,s,t) == modeindex2(m2,s,t)
			end
			m2c = collect(m2)
			for s in s_range(m2), t1 in  t_valid_range(m2,s), 
					t2 in t_valid_range(m2,s)

				tmin,tmax = minmax(t1,t2)
				@test modeindex(m2,s,tmin:tmax) == 
				findfirst(isequal((s,tmin)),m2c):findfirst(isequal((s,tmax)),m2c)
			end
		end
	end

	@testset "s′s" begin
		smax = 5
		for smin=0:smax,smax=smin:smax,
			Δs_max=0:smax,s′min=0:smax,s′max=s′min:smax

			m3 = s′s(smin,smax,Δs_max,s′min,s′max)
			for (s′,s) in m3
				@test begin 
					res = modeindex(m3,s′,s) == modeindex2(m3,s′,s)
					if !res
						println(m3)
					end
					res
				end
			end
			m3c = collect(m3)
			for s in s_range(m3), s′1 in s′_valid_range(m3,s), 
				s′2 in s′_valid_range(m3,s)

				s′min,s′max = minmax(s′1,s′2)
				@test begin 
					res = modeindex(m3,s′min:s′max,s) == 
					findfirst(isequal((s′min,s)),m3c):findfirst(isequal((s′max,s)),m3c)
					if !res
						println(m3)
					end
					res
				end
			end
		end
	end
end

@testset "last" begin
	@testset "ts" begin
		m1 = ts(rand(1:5),rand(6:10))
		@test last(collect(m1)) == last(m1)    
	end

	@testset "st" begin
		m2 = st(rand(1:5),rand(6:10))
		@test last(collect(m2)) == last(m2)
	end
	
	@testset "s′s" begin
		m3 = s′s(rand(1:3):rand(4:10),rand(1:5))
		@test last(collect(m3)) == last(m3)
	end
end

