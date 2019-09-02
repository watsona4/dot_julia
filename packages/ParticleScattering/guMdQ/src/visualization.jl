"""
    plot_near_field(k0, kin, P, sp::ScatteringProblem, ui::Einc;
                        opt::FMMoptions = FMMoptions(), method = "multipole",
                        x_points = 201, y_points = 201, border = find_border(sp),
                        normalize = 1.0)

Plots the total electric field as a result of a plane wave with incident
TM field `ui` scattering from the ScatteringProblem `sp`, using matplotlib's
`pcolormesh`. Can accept number of sampling points in each direction plus
bounding box or calculate automatically.

Uses the FMM options given by `opt` (FMM is disabled by default);
`method = "multipole"` dictates whether electric field is calculated using the
multipole/cylindrical harmonics, uses a faster but less accurate Hankel recurrence
formula (`"recurrence"`), or falls back on potential densities (`"density"`).
Either way, the multiple-scattering system is solved in the cylindrical
harmonics space. Normalizes all distances and sizes in plot (but not output) by
`normalize`.

Returns the calculated field in two formats:
1. `(points, Ez)` where `Ez[i]` is the total electric field at `points[i,:]`, and
2. `(xgrid,ygrid,zgrid)`, the format suitable for `pcolormesh`, where `zgrid[i,j]`
contains the field at `(mean(xgrid[i, j:j+1]), mean(ygrid[i:i+1, j]))`.
"""
function plot_near_field(k0, kin, P, sp::ScatteringProblem, ui::Einc;
                        opt::FMMoptions = FMMoptions(), method = "multipole",
                        x_points = 201, y_points = 201, border = find_border(sp),
                        normalize = 1.0)

    x_min, x_max, y_min, y_max = border

    # with pcolormesh, the field is calculated at the center of each rectangle.
    # thus we need two grids - the rectangle grid and the sampling grid.
    x = range(x_min, stop=x_max, length=x_points + 1)
    y = range(y_min, stop=y_max, length=y_points + 1)
    xgrid = repeat(transpose(x), y_points + 1)
    ygrid = repeat(y, 1, x_points + 1)
    dx = (x_max - x_min)/2/x_points
    dy = (y_max - y_min)/2/y_points
    points = cat(vec(xgrid[1:y_points, 1:x_points]) .+ dx,
                vec(ygrid[1:y_points, 1:x_points]) .+ dy, dims=2)

    Ez = calc_near_field(k0, kin, P, sp, points, ui,
            method = method, opt = opt)
    zgrid = reshape(Ez, y_points, x_points)
    figure()
    pcolormesh(xgrid/normalize, ygrid/normalize, abs.(zgrid))

    ax = gca()
    draw_shapes(sp.shapes, sp.ids, sp.centers, sp.φs, ax = ax, normalize = normalize)
    xlim([x_min/normalize;x_max/normalize])
    ylim([y_min/normalize;y_max/normalize])
    tight_layout()
    ax.set_aspect("equal", adjustable = "box")
    return (points,Ez),(xgrid,ygrid,zgrid)
end

"""
    plot_far_field(k0, kin, P, sp::ScatteringProblem, pw::PlaneWave;
                        opt::FMMoptions = FMMoptions(), method = "multipole",
                        plot_points = 200)

Plots and returns the echo width (radar cross section in two dimensions) for a
given scattering problem. `opt`, `method` are as in `plot_near_field`.
"""
function plot_far_field(k0, kin, P, sp::ScatteringProblem, pw::PlaneWave;
                    opt::FMMoptions = FMMoptions(), method = "multipole",
                    plot_points = 200)

    Rmax = maximum(s.R for s in sp.shapes)

    x_max,y_max = maximum(sp.centers, dims=1) + 2*Rmax
    x_min,y_min = minimum(sp.centers, dims=1) - 2*Rmax
    Raggregate = 0.5*max(x_max - x_min, y_max - y_min) #radius of bounding circle
    x_center = 0.5*(x_max + x_min)
    y_center = 0.5*(y_max + y_min)
    Rfar = Raggregate*1e6
    theta_far = range(0, stop=2π, length=plot_points)
    x_far = x_center + Rfar*cos.(theta_far)
    y_far = y_center + Rfar*sin.(theta_far)
    points = [x_far y_far]

    Ez = calc_far_field(k0, kin, P, points, sp, pw,
            method = method, opt = opt)
    Ez[:] = (k0*Rfar)*abs2.(Ez)
    #plot echo width
    figure()
    plot(theta_far/π, Ez)
    xlabel("\$ \\theta/\\pi \$")
    ylabel("\$ \\sigma/\\lambda_0 \$")
    title("Echo Width")
    tight_layout()
    xlim([0;2])
    return Ez
end

"""
    draw_shapes(shapes, ids, centers, φs; ax = gca(), normalize = 1.0)
    draw_shapes(sp; ax = gca(), normalize = 1.0)

Draws all of the shapes in a given scattering problem in the PyPlot axis 'ax'.
Parametrized shapes are drawn as polygons while circles are drawn using
matplotlib's `patch.Circle`. Divides all lengths by 'normalize'.
"""
function draw_shapes(shapes, ids, centers, φs; ax = gca(), normalize = 1.0)
    #draw shapes
    for ic = 1:size(centers,1)
        if typeof(shapes[ids[ic]]) == ShapeParams
            if φs[ic] == 0.0
                ft_rot = shapes[ids[ic]].ft .+ centers[ic,:]'
            else
                Rot = cartesianrotation(φs[ic])'
                ft_rot = shapes[ids[ic]].ft*Rot .+ centers[ic,:]'
            end
            ax.plot([ft_rot[:,1];ft_rot[1,1]]/normalize,
                    [ft_rot[:,2];ft_rot[1,2]]/normalize, "k", linewidth = 2)
        else
            ax.add_patch(patch.Circle((centers[ic,1]/normalize,
                            centers[ic,2]/normalize),
                            radius = shapes[ids[ic]].R/normalize,
                            edgecolor="k", facecolor="none", linewidth = 2))
        end
    end
end

draw_shapes(sp; ax = gca(), normalize = 1.0) = draw_shapes(sp.shapes,
                    sp.ids, sp.centers, sp.φs; ax = ax, normalize = normalize)

"""
    calc_near_field(k0, kin, P, sp::ScatteringProblem, points, ui::Einc;
                            opt::FMMoptions = FMMoptions(), method = "multipole",
                            verbose = true)

Calculates the total electric field as a result of a plane wave with incident
field `ui` scattering from the ScatteringProblem `sp`, at `points`.
Uses the FMM options given by `opt` (default behaviour is disabled FMM);
`method = "multipole"` dictates whether electric field is calculated using the
multipole/cylindrical harmonics, uses a faster but less accurate Hankel recurrence
formula (`"recurrence"`), or falls back on potential densities (`"density"`).
Either way, the multiple-scattering system is solved in the cylindrical
harmonics space, and the field by a particular scatterer inside its own scattering
discs is calculated by potential densities, as the cylindrical harmonics
approximation is not valid there.
"""
function calc_near_field(k0, kin, P, sp::ScatteringProblem, points, ui::Einc;
                            opt::FMMoptions = FMMoptions(), method = "multipole",
                            verbose = true)

    shapes = sp.shapes;	ids = sp.ids; centers = sp.centers; φs = sp.φs
    u = zeros(Complex{Float64},size(points,1))
    if opt.FMM
        result,sigma_mu =  solve_particle_scattering_FMM(k0, kin, P, sp,
                            ui, opt, verbose = verbose)
        if result[2].isconverged == false
            @warn("FMM process did not converge")
            return
        end
        beta = result[1]
    else
        beta, sigma_mu = solve_particle_scattering(k0, kin, P, sp, ui,
                            verbose = verbose)
    end

    #first, let's mark which points are in which shapes in tags:
    #0 denotes outside everything, +-i means inside shape i or between it and its "multipole disk"
    dt_tag = @elapsed begin
        tags = tagpoints(sp, points)
    end

    dt_in = @elapsed begin
        rng_in = zeros(Bool,size(points,1))
        rng_out = zeros(Bool,size(points,1))
        Rot = Array{Float64}(undef, 2,2)
        for ic = 1:size(sp)
            rng_in[:] = (tags .== ic)
            rng_out[:] = (tags .== -ic)
            (any(rng_in) || any(rng_out)) || continue
            if typeof(shapes[ids[ic]]) == ShapeParams
                if φs[ic] == 0.0
                    ft_rot = shapes[ids[ic]].ft .+ centers[ic,:]'
                    dft_rot = shapes[ids[ic]].dft
                else
                    Rot[:] = cartesianrotation(φs[ic])'
                    ft_rot = shapes[ids[ic]].ft*Rot .+ centers[ic,:]'
                    dft_rot = shapes[ids[ic]].dft*Rot
                end
            end
            #field inside shape
            if any(rng_in)
                if typeof(shapes[ids[ic]]) == ShapeParams
                    u[rng_in] += scatteredfield(sigma_mu[ic], kin, shapes[ids[ic]].t,
                                    ft_rot, dft_rot, points[rng_in,:])
                else
                    u[rng_in] += innerFieldCircle(kin, sigma_mu[ic], centers[ic,:],
                                    points[rng_in,:])
                end
            end
            #field between shape and multipole disk (impossible for circle)
            if any(rng_out)
                u[rng_out] += scatteredfield(sigma_mu[ic], k0, shapes[ids[ic]].t,
                                ft_rot, dft_rot, points[rng_out,:])
                u[rng_out] += uinc(k0, points[rng_out,:], ui)
                for ic2 = 1:size(sp)
                    ic == ic2 && continue
                    if method == "multipole"
                        scattered_field_multipole!(u, k0, beta, P, centers, ic2, points,
                            findall(rng_out))
                    elseif method == "recurrence"
                        scattered_field_multipole_recurrence!(u, k0, beta, P, centers, ic2, points,
                            findall(rng_out))
                    else
                        if φs[ic2] == 0.0
                            ft_rot2 = shapes[ids[ic2]].ft .+ centers[ic2,:]'
                            dft_rot2 = shapes[ids[ic2]].dft
                        else
                            Rot[:] = cartesianrotation(φs[ic2])'
                            ft_rot2 = shapes[ids[ic2]].ft*Rot .+ centers[ic2,:]'
                            dft_rot2 = shapes[ids[ic2]].dft*Rot
                        end
                        u[rng_out] += scatteredfield(sigma_mu[ic2], k0, shapes[ids[ic2]].t,
                                        ft_rot2, dft_rot2, points[rng_out,:])
                    end
                end
            end
        end
    end

    #now compute field outside all shapes
    dt_out = @elapsed begin
        rng = (tags .== 0)
        #incident field
        u[rng] = uinc(k0, points[rng,:], ui)
        if method == "multipole"
            scattered_field_multipole!(u, k0, beta, P, centers, 1:size(sp), points, findall(rng))
        elseif method == "recurrence"
            scattered_field_multipole_recurrence!(u, k0, beta, P, centers, 1:size(sp), points, findall(rng))
        else
            for ic = 1:size(centers,1)
                if typeof(shapes[ids[ic]]) == ShapeParams
                    if φs[ic] == 0.0
                        ft_rot = shapes[ids[ic]].ft .+ centers[ic,:]'
                        u[rng] += scatteredfield(sigma_mu[ic], k0, shapes[ids[ic]].t,
                                    ft_rot, shapes[ids[ic]].dft, points[rng,:])
                    else
                        Rot[:] = copy(transpose(cartesianrotation(φs[ic])))
                        ft_rot = shapes[ids[ic]].ft*Rot .+ centers[ic,:]'
                        dft_rot = shapes[ids[ic]].dft*Rot
                        u[rng] += scatteredfield(sigma_mu[ic], k0, shapes[ids[ic]].t,
                                    ft_rot, dft_rot, points[rng,:])
                    end
                else
                    scattered_field_multipole!(u, k0, beta, P, centers, ic, points,
                        findall(rng))
                end
            end
        end
    end
    if verbose
        println("Time spent calculating field:")
        println("Location tagging: $dt_tag")
        println("In/around scatterers: $dt_in")
        println("Outside scatterers: $dt_out")
    end
    return u
end

function calc_far_field(k0, kin, P, points, sp::ScatteringProblem, pw::PlaneWave;
                        opt::FMMoptions = FMMoptions(), method = "multipole")
    #calc only scattered field + assumes all points are outside shapes
    shapes = sp.shapes; centers = sp.centers; ids = sp.ids; φs = sp.φs
    if opt.FMM
        result,sigma_mu =  solve_particle_scattering_FMM(k0, kin, P, sp, pw, opt)
        if result[2].isconverged == false
            @warn("FMM process did not converge")
            return
        end
        beta = result[1]
    else
        beta, sigma_mu = solve_particle_scattering(k0, kin, P, sp, pw)
    end
    Ez = zeros(Complex{Float64}, size(points,1))

    if method == "multipole"
        scattered_field_multipole!(Ez, k0, beta, P, centers, 1:size(sp),
            points, 1:size(points,1))
    elseif method == "recurrence"
        scattered_field_multipole_recurrence!(Ez, k0, beta, P, centers,
            1:size(sp), points, 1:size(points,1))
    else
        for ic = 1:size(sp)
            if typeof(shapes[ids[ic]]) == ShapeParams
                if φs[ic] == 0.0
                    ft_rot = shapes[ids[ic]].ft .+ centers[ic,:]'
                    Ez[:] += scatteredfield(sigma_mu[ic], k0, shapes[ids[ic]].t,
                                ft_rot, shapes[ids[ic]].dft, points)
                else
                    Rot = copy(transpose(cartesianrotation(φs[ic])))
                    ft_rot = shapes[ids[ic]].ft*Rot .+ centers[ic,:]'
                    dft_rot = shapes[ids[ic]].dft*Rot
                    Ez[:] += scatteredfield(sigma_mu[ic], k0, shapes[ids[ic]].t,
                                ft_rot, dft_rot, points)
                end
            else
                warning("should be only subset of beta!")
                scattered_field_multipole!(Ez, k0, beta, P, centers, ic, points,
                    1:size(points,1))
            end
        end
    end
    return Ez
end

function tagpoints_old(sp, points)
    shapes = sp.shapes;	ids = sp.ids; centers = sp.centers; φs = sp.φs

    tags = zeros(Integer, size(points,1))
    X = Array{Float64}(undef, 2)
    for ix = 1:size(points,1)
        for ic = 1:size(sp)
            X .= points[ix,:] - centers[ic,:]
            if sum(abs2,X) <= shapes[ids[ic]].R^2
                if typeof(shapes[ids[ic]]) == ShapeParams
                    if φs[ic] != 0.0 #rotate point backwards instead of shape forwards
                        Rot = [cos(-φs[ic]) -sin(-φs[ic]);sin(-φs[ic]) cos(-φs[ic])]
                        X = Rot*X
                    end
                    tags[ix] = pInPolygon(X, shapes[ids[ic]].ft) ? ic : -ic
        			break #can't be in two shapes
                else #CircleParams
                    tags[ix] = ic
                    break #can't be in two shapes
                end
        	end
        end
    end
    tags
end

function tagpoints(sp, points)
    shapes = sp.shapes;	ids = sp.ids; centers = sp.centers; φs = sp.φs

    tags = zeros(Integer, size(points,1))
    X = Array{Float64}(undef, 2) #tmp arrays
    for ix = 1:size(points,1) #need two loops due to "break"
        for ic = 1:size(sp)
            X[1] = points[ix,1] - centers[ic,1]
            X[2] = points[ix,2] - centers[ic,2]
            if hypot(X[1], X[2]) ≤ shapes[ids[ic]].R
                if isa(shapes[ids[ic]], ShapeParams)
                    if φs[ic] != 0.0 #rotate point backwards instead of shape forwards
                        Rot = cartesianrotation(-φs[ic])
                        X = Rot*X
                    end
                    tags[ix] = pInPolygon(X, shapes[ids[ic]].ft) ? ic : -ic
                else #CircleParams
                    tags[ix] = ic
                end
                break #can't be in two shapes
        	end
        end
    end
    tags
end
