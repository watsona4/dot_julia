"""
	rounded_star(r, d, num, N)

Return a `ShapeParams` object containing the shape parametrized by
\$(x(θ),y(θ)) = (r + d*cos(θ*num))*(cos(θ),sin(θ))\$ with 2`N` nodes.
"""
function rounded_star(r, d, num, N)
    t = Float64[pi*j/N for j=0:(2*N-1)]
    Rt = r .+ d*cos.(num*t)
    dRt = (-d*num)*sin.(num*t)
    ft = [Rt.*cos.(t) Rt.*sin.(t)]
    dft = [dRt.*cos.(t) - Rt.*sin.(t)     dRt.*sin.(t) + Rt.*cos.(t)]
    return ShapeParams(t, ft, dft)
end

"""
	squircle(r, N)

Return a `ShapeParams` object containing the shape parametrized by
\$x(θ)^4 + y(θ)^4 = r^4\$ with 2`N` nodes.
"""
function squircle(r, N)
    #substituting x = rho*cost, y = rho*sint in x^4+y^4=R^4
    t = Float64[pi*j/N for j=0:(2*N-1)]
    cost = cos.(t); cos4t = cos.(4*t);
    sint = sin.(t); sin4t = sin.(4*t);
    rho = (sqrt(2)*r)./((3 .+ cos4t).^0.25)
    ft = [rho.*cost rho.*sint]
    drho = rho.*sin4t./(3 .+ cos4t)
    dx = drho.*cost - rho.*sint
    dy = drho.*sint + rho.*cost
    dft = [dx dy]
    return ShapeParams(t, ft, dft)
end

"""
	ellipse(r1, r2, N)

Return a `ShapeParams` object containing the shape parametrized by
`(x/r1)^2 + (y/r2)^2 = 1` with 2`N` nodes.
"""
function ellipse(r1, r2, N)
	t = Float64[pi*j/N for j=0:(2*N-1)]
    ft = [r1*cos.(t) r2*sin.(t)]
    dft = [(-r1)*sin.(t) r2*cos.(t)]
    return ShapeParams(t, ft, dft)
end

"""
	square_grid(a::Integer, d)

Return `centers`, an `(a^2,2)` array containing the points on an `a` by `a`
grid of points distanced `d`.
"""
function square_grid(a::Integer, d)
    offsetx = -0.5*(a-1)
    offsety = -0.5*(a-1)
    centers = d*[mod.(0:a^2-1, a) .+ offsetx   div.(0:a^2-1, a) .+ offsety]
end

"""
	rect_grid(a::Integer, b::Integer, dx, dy)

Return `centers`, an `(a*b,2)` array containing the points spanned by `a` points
distanced `dx` and `b` points distanced `dy`, in the x and y directions,
respectively.
"""
function rect_grid(a::Integer, b::Integer, dx, dy)
    offsetx = -0.5*(a-1)
    offsety = -0.5*(b-1)
	xpoints = dx*((0:a-1) .+ offsetx)
	ypoints = dy*((0:b-1) .+ offsety)

    centers = [repeat(xpoints, outer=[b]) 	repeat(ypoints, inner=[a])]
end

"""
	hex_grid(a::Integer, rows::Integer, d; minus1 = false)

Return `centers`, an `(M,2)` array containing points on a hexagonal lattice
with horizontal rows, with `a` points distanced `d` in each row and `rows` rows.
If `minus1` is true, the last point in every odd row is omitted.
"""
function hex_grid(a::Integer, rows::Integer, d; minus1 = false)
	h = d*sqrt(0.75) #row height
	M = minus1 ? a*rows - div(rows,2) : a*rows
	centers = Array{Float64}(undef, M, 2)
	ind = 1
	for r = 0:rows-1
		if mod(r,2) == 0
			for i = 1:a
				centers[ind,1] = i*d
				centers[ind,2] = (r - 1)*h
				ind += 1
			end
		else
			for i = 1:a-1
				centers[ind,1] = (i + 0.5)*d
				centers[ind,2] = (r - 1)*h
				ind += 1
			end
			if !minus1
				centers[ind,1] = (a + 0.5)*d
				centers[ind,2] = (r - 1)*h
				ind += 1
			end
		end
	end
	offset = mean(centers, dims=1)
    centers .-= offset
end

"""
	randpoints(M, dmin, width, height; failures = 100)

Return `centers`, an `(M,2)` array containing `M` points distanced at least
`dmin` in a `width` by `height` box. Fails `failures` times successively before
giving up.
"""
function randpoints(M, dmin, width, height; failures = 100)
    x_res = [rand(Float64)*width]
    y_res = [rand(Float64)*height]
    fail = 0
    dmin2 = dmin^2

    while fail < failures && length(x_res) < M
        accepted = true
        x_try = rand(Float64)*width
        y_try = rand(Float64)*height

        for i = 1:length(x_res)
            dist2 = (x_res[i] - x_try)^2 + (y_res[i] - y_try)^2
            if dist2 <= dmin2
                accepted = false
                break
            end
        end
        if accepted
            push!(x_res,x_try)
            push!(y_res,y_try)
            fail = 0
        else
            fail = fail + 1
        end
    end
    if length(x_res) < M
        error("""randpoints: Could not generate random points.
                Try increasing domain, decreasing minimum distance,
                or increasing subsequent failures allowed""")
    end
    centers = [x_res y_res]
end

"""
	randpoints(M, dmin, width, height, points; failures = 100)

Same as randpoints(M, dmin, width, height; failures = 100) but also
requires centers to be distanced at least `dmin` from `points`.
"""
function randpoints(M, dmin, width, height, points; failures = 100)
    dmin2 = dmin^2
    for i = 2:size(points,1), j = 1:i-1
        dist2 = sum(x -> x^2, points[i,:] - points[j,:])
        dist2 <= dmin2 && error("randpoints: given points have distance <= dmin")
    end

    x_res = Array{Float64}(undef, 0)
    y_res = Array{Float64}(undef, 0)
    fail = 0
    while fail < failures && length(x_res) < M
        accepted = true
        x_try = rand(Float64)*width
        y_try = rand(Float64)*height

        for i = 1:size(points,1)
            dist2 = (points[i,1] - x_try)^2 + (points[i,2] - y_try)^2
            if dist2 <= dmin2
                accepted = false
                break
            end
        end
        accepted && for i = 1:length(x_res)
            dist2 = (x_res[i] - x_try)^2 + (y_res[i] - y_try)^2
            if dist2 <= dmin2
                accepted = false
                break
            end
        end
        if accepted
            push!(x_res,x_try)
            push!(y_res,y_try)
            fail = 0
        else
            fail = fail + 1
        end
    end
    if length(x_res) < M
        error("""randpoints: Could not generate random points.
                Try increasing domain, decreasing minimum distance,
                or increasing subsequent failures allowed""")
    end
    centers = [x_res y_res]
end

"""
    verify_min_distance(shapes, centers::Array{Float64,2}, ids)
    verify_min_distance(sp::ScatteringProblem)
Returns `true` if the shapes placed at `centers` are properly distanced
(non-intersecting scattering disks).
"""
function verify_min_distance(shapes, centers::Array{Float64,2}, ids)
    Ns = size(centers,1)
    for ic = 1:Ns, ic2 = ic+1:Ns
        d = sqrt((centers[ic,1] - centers[ic2,1])^2 +
                (centers[ic,2] - centers[ic2,2])^2)
        d > shapes[ids[ic]].R + shapes[ids[ic2]].R || (return false)
    end
    true
end

"""
    verify_min_distance(shapes, centers::Array{Float64,2}, ids, points::Array{Float64,2})
    verify_min_distance(sp::ScatteringProblem, points)
Returns `true` if the shapes placed at `centers` are properly distanced
(non-intersecting scattering disks), and all `points` are outside the scattering
disks.
"""
function verify_min_distance(shapes, centers::Array{Float64,2}, ids, points::Array{Float64,2})
    Ns = size(centers,1)
    for ic = 1:Ns
        for ip = 1:size(points,1)
            d = sqrt((points[ip,1] - centers[ic,1])^2 +
                    (points[ip,2] - centers[ic,2])^2)
            d > shapes[ids[ic]].R || (return false)
        end
        for ic2 = ic+1:Ns
            d = sqrt((centers[ic,1] - centers[ic2,1])^2 +
                    (centers[ic,2] - centers[ic2,2])^2)
            d > (shapes[ids[ic]].R + shapes[ids[ic2]].R) || (return false)
        end
    end
    true
end

verify_min_distance(sp::ScatteringProblem, points) =
	verify_min_distance(sp.shapes, sp.centers, sp.ids, points)
verify_min_distance(sp::ScatteringProblem) =
	verify_min_distance(sp.shapes, sp.centers, sp.ids)

"""
    luneburg_grid(R_lens, N_cells, er; levels = 0, TM = true) -> centers, ids, rs

Returns the coordinates and radii of the circular inclusions in a Luneburg lens
device of radius `R_lens` with `N_cells` unit cells across its diameter. Radii
are determined by averaging over cell permittivity, assuming air outside and
relative permittivity `er` in the rods, and depends on incident field polarization
(TM/TE with respect to z-axis).
If `levels` == 0, groups identical radii together, such that rs[ids[n]]
is the radius of the rod centered at `(center[n,1],center[n,2])`. Otherwise
quantizes the radii to uniformly spaced levels.
"""
function luneburg_grid(R_lens, N_cells, er; levels = 0, TM = true)
    r_cell = Array{Float64}(undef, N_cells^2)
    centers = Array{Float64}(undef, N_cells^2, 2)
    flag_outside = Array{Bool}(undef, N_cells^2)
    a = 2*R_lens/N_cells #cell dimension
    for ix = 1:N_cells, iy = 1:N_cells
        ind = (ix-1)*N_cells + iy
        centers[ind,1] = a*(ix - N_cells/2.0 - 0.5)
        centers[ind,2] = a*(iy - N_cells/2.0 - 0.5)
        rho2 = sum(abs2,centers[ind,:])
        if rho2 > R_lens^2 #for now
            flag_outside[ind] = false
        else
            flag_outside[ind] = true
            r_cell[ind] = getLuneburgRadius(rho2, R_lens, a, er, TM)
        end
    end
    r_cell = r_cell[flag_outside]
    centers = centers[flag_outside,:]

    if levels > 0
        #uniform quantization
        rs = collect(range(minimum(r_cell), stop=maximum(r_cell), length=levels))
        ddd = (r_cell - rs[1])/(rs[2] - rs[1])
        ids = convert(Array{Int,1},round(ddd)) + 1
    else
        #only store unique vals
        ids,rs = uniqueind(r_cell)
    end
    return centers, ids, rs
end

function getLuneburgRadius(rho2, R_lens, a, er, TM)
    er_host = 1
    n_0 = 1
    n_eff = n_0*sqrt(2-rho2/R_lens^2)
    xx = a^2*(er_host-n_eff^2)/(pi*(er_host-er))
    if TM
        r = sqrt(xx)
    else #TE
        r = sqrt(xx*(er_host + er)/(er_host + n_eff^2))
    end
    return r
end
