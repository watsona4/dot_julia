const eta0 = 4π*299792458e-7

#plane wave
function u2α(k, u::PlaneWave, centers::Array{T,2}, P) where T <: Real
	#build incoming coefficients for plane wave incident field
	α = Array{Complex{Float64}}(undef, size(centers,1)*(2P + 1))
	for ic = 1:size(centers,1)
		phase = exp(1.0im*k*(cos(u.θi)*centers[ic,1] + sin(u.θi)*centers[ic,2])) #phase shift added to move cylinder coords
		for p = -P:P
			α[(ic-1)*(2P+1) + p + P + 1] = phase*exp(1.0im*p*(π/2-u.θi))
		end
	end
	α
end

"""
    uinc(k, points, u::Einc)

Computes incident field produced by `u` with outer wavenumber `k` at `points`.
"""
function uinc(k, points::Array{T,2}, u::PlaneWave) where T <: Real
	exp.(1.0im*k*(cos(u.θi)*points[:,1] + sin(u.θi)*points[:,2]))
end

function uinc(k, points::Array{T,1}, u::PlaneWave) where T <: Real
	exp(1.0im*k*(cos(u.θi)*points[1] + sin(u.θi)*points[2]))
end

#line (filament) source
function u2α(k, u::LineSource, centers::Array{T,2}, P) where T <: Real
	α = Array{Complex{Float64}}(undef, size(centers,1)*(2P + 1))
	for ic = 1:size(centers,1)
		R = hypot(centers[ic,1] - u.x, centers[ic,2] - u.y)
		θ = atan(centers[ic,2] - u.y, centers[ic,1] - u.x)
		α[(ic-1)*(2P+1) + 0 + P + 1] = 0.25im*besselh(0, 1, k*R)
		for p = 1:P
			α[(ic-1)*(2P+1) - p + P + 1] = 0.25im*exp(1im*p*θ)*besselh(p, 1, k*R)
			α[(ic-1)*(2P+1) + p + P + 1] = 0.25im*exp(-1im*p*θ)*besselh(-p, 1, k*R)
		end
	end
	α
end

function uinc(k, points::Array{T,2}, u::LineSource) where T <: Real
	r = hypot.(u.x .- points[:,1], u.y .- points[:,2])
	if any(r .== 0)
		@warn("uinc: encountered singularity in incident field, returned NaN")
		r[r.==0] = NaN
	end
	0.25im*besselh.(0, 1, k*r)
end

function uinc(k, points::Array{T,1}, u::LineSource) where T <: Real
	r = hypot(u.x - points[1], u.y - points[2])
	if r == 0
		@warn("uinc: encountered singularity in incident field, returned NaN")
		return NaN
	end
	0.25im*besselh(0, 1, k*r)
end

#current source TODO: simple avg->trap rule
function u2α(k, u::CurrentSource, centers::Array{T,2}, P) where T <: Real
	α = zeros(Complex{Float64}, size(centers,1)*(2P + 1))
	c = 0.25im*u.len/length(u.σ)
	for ic = 1:size(centers,1)
		for is = 1:length(u.σ)
			R = hypot(centers[ic,1] - u.p[is,1], centers[ic,2] - u.p[is,2])
			θ = atan(centers[ic,2] - u.p[is,2], centers[ic,1] - u.p[is,1])

			α[(ic-1)*(2P+1) + P + 1] +=	c*u.σ[is]*besselh(0, 1, k*R)
			for p = 1:P
				H = besselh(p, 1, k*R)
				α[(ic-1)*(2P+1) - p + P + 1] +=	c*u.σ[is]*H*exp(1im*p*θ)
				α[(ic-1)*(2P+1) + p + P + 1] +=	c*u.σ[is]*(-1)^p*H*exp(-1im*p*θ)
			end
		end
	end
	α
end

function uinc(k, points::Array{T,2}, u::CurrentSource) where T <: Real
	res = Array{Complex{Float64}}(undef, size(points, 1))
	r = Array{Float64}(undef, size(u.p, 1))
	for i = 1:size(points, 1)
		r .= hypot.(u.p[:,1] - points[i,1], u.p[:,2] - points[i,2])
		if any(r .== 0) #point is on source
			@warn("uinc: encountered singularity in incident field, returned NaN")
			res[i] = NaN
		end
		res[i] = (0.25im*u.len/length(u.σ))*sum(besselh.(0, 1, k*r).*u.σ)
	end
	res
end

function uinc(k, points::Array{T,1}, u::CurrentSource) where T <: Real
	r = hypot.(u.p[:,1] - points[1], u.p[:,2] - points[2])
	if any(r .== 0) #point is on source
		@warn("uinc: encountered singularity in incident field, returned NaN")
		return NaN
	end
	(0.25im*u.len/length(u.σ))*sum(besselh.(0, 1, k*r).*u.σ)
end

#compute error in field approximation (on multipole disk)
function err_α(k, ui::Einc, P, shape, center)
	#first assert shape and field source do not intersect
	if isa(ui, LineSource)
		hypot(center[1] - ui.x, center[2] - ui.y) <= shape.R && error("LineSource is in shape")
	elseif isa(ui, CurrentSource)
		#assuming straight line, see mathworld.wolfram.com/Circle-LineIntersection.html
		x1 = ui.p[1,1] - center[1]
		y1 = ui.p[1,2] - center[2]
		x2 = ui.p[end,1] - center[1]
		y2 = ui.p[end,2] - center[2]
		dr2 = (x2 - x1)^2 + (y2 - y1)^2
		D2 = (x1*y2 - x2*y1)^2
		shape.R^2*dr2 - D2 < 0 || error("CurrentSource is in shape")
	end

	Nt = 10_000
	θ = range(0, stop=2π, length=Nt)[1:end-1]
	α = u2α(k, ui, center, P)
	u_exact = uinc(k, center .+ shape.R*[cos.(θ) sin.(θ)], ui)
	u_α = sum(α[p + P + 1]*besselj(p, k*shape.R)*exp.(1im*p*θ) for p = -P:P)
	norm(u_α - u_exact)/norm(u_exact)
end


function hxinc(k, p, u::PlaneWave)
    (sin(u.θi)/eta0)*exp.(1.0im*k*(cos(u.θi)*p[:,1] + sin(u.θi)*p[:,2]))
end

function hyinc(k, p, u::PlaneWave)
    (-cos(u.θi)/eta0)*exp.(1.0im*k*(cos(u.θi)*p[:,1] + sin(u.θi)*p[:,2]))
end

function hxinc(k, p, u::LineSource)
    R = sqrt.((view(p,:,1) .- u.x).^2 + (view(p,:,2) .- u.y).^2)
    if any(R .== 0)
		@warn("Hinc: encountered singularity in incident field, returned NaN")
		R[R.==0] = NaN
	end
    h = (0.25/eta0./R).*besselh.(1,k*R).*(u.y .- view(p,:,2))
end

function hyinc(k, p, u::LineSource)
    R = sqrt.((view(p,:,1) .- u.x).^2 + (view(p,:,2) .- u.y).^2)
    if any(R .== 0)
		@warn("Hinc: encountered singularity in incident field, returned NaN")
		R[R.==0] = NaN
	end
    h = (0.25/eta0./R).*besselh.(1,k*R).*(view(p,:,1) .- u.x)
end

#these untested
function hxinc(k, points, u::CurrentSource)
    res = Array{Complex{Float64}}(undef, size(points, 1))
	r = Array{Float64}(undef, size(u.p, 1))
    y = Array{Float64}(undef, size(u.p, 1))
	for i = 1:size(points, 1)
		y[:] = points[i,2] - view(u.p,:,2)
        r[:] = hypot.(points[i,1] .- view(u.p,:,1), y)
		if any(r .== 0) #point is on source
			@warn("Hinc: encountered singularity in incident field, returned NaN")
			res[i] = NaN
		end
		res[i] = (-0.25*u.len/length(u.σ)/eta0)*sum(besselh.(1, 1, k*r).*u.σ.*y./r)
	end
	res
end
function hyinc(k, points, u::CurrentSource)
    res = Array{Complex{Float64}}(undef, size(points, 1))
	r = Array{Float64}(undef, size(u.p, 1))
    x = Array{Float64}(undef, size(u.p, 1))
	for i = 1:size(points, 1)
		x[:] = points[i,1] .- view(u.p,:,1)
        r[:] = hypot.(x, points[i,2] .- view(u.p,:,2))
		if any(r .== 0) #point is on source
			@warn("Hinc: encountered singularity in incident field, returned NaN")
			res[i] = NaN
		end
		res[i] = (0.25*u.len/length(u.σ)/eta0)*sum(besselh.(1, 1, k*r).*u.σ.*x./r)
	end
	res
end
