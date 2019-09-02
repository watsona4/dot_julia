function poynting_vector(k0, beta, centers, points, Ez_inc, Hx_inc, Hy_inc)
    #assumes points lie outside all scattering disks
    Ns = size(centers,1)
	P = div(div(length(beta),Ns)-1,2)
	len = size(points,1)
	pyntg = Array{Float64}(undef, len, 2)
    Ez = copy(Ez_inc)
    for ip in 1:len
        ∂Ez∂x = 0.0im
        ∂Ez∂y = 0.0im
        for ic in 1:Ns
		    ind = (ic-1)*(2*P+1) .+ P + 1
			pt1 = points[ip,1] - centers[ic,1]
			pt2 = points[ip,2] - centers[ic,2]

			R = hypot(pt1, pt2)
			θ = atan(pt2, pt1)
			R == 0 && error("R == 0, center=$(centers[ic,:]),
                                point=$(points[ip,:]), k0 = $k0, ic=$ic, ip=$ip")

            Hₚ₋₂ = besselh(-1, 1, k0*R)
            Hₚ₋₁ = besselh(0, 1, k0*R)

            Ez[ip] += beta[ind]*Hₚ₋₁
            ∂H∂R = k0*Hₚ₋₂
            ∂Ez∂x += beta[ind]*∂H∂R*pt1/R
            ∂Ez∂y += beta[ind]*∂H∂R*pt2/R

            for p = 1:P
                Hₚ = (2*(p-1)/(k0*R))*Hₚ₋₁ - Hₚ₋₂
                ∂H∂R = k0*(Hₚ₋₁ - p/(k0*R)*Hₚ)

                Ez[ip] += beta[ind - p]*(-1)^p*Hₚ*exp(-1im*p*θ)
                ∂Ez∂x += beta[ind - p]*(-1)^p*exp(-1im*p*θ)*(∂H∂R*pt1/R + Hₚ*1im*(-p)*(-pt2)/R^2)
                ∂Ez∂y += beta[ind - p]*(-1)^p*exp(-1im*p*θ)*(∂H∂R*pt2/R + Hₚ*1im*(-p)*(pt1)/R^2)

                Ez[ip] += beta[ind + p]*Hₚ*exp(1im*p*θ)
                ∂Ez∂x += beta[ind + p]*exp(1im*p*θ)*(∂H∂R*pt1/R + Hₚ*1im*p*(-pt2)/R^2)
                ∂Ez∂y += beta[ind + p]*exp(1im*p*θ)*(∂H∂R*pt2/R + Hₚ*1im*p*(pt1)/R^2)
                Hₚ₋₂ = Hₚ₋₁; Hₚ₋₁ = Hₚ
			end
		end
        Hx = Hx_inc[ip] + (1/1im/k0/eta0)*∂Ez∂y
        Hy = Hy_inc[ip] + (-1/1im/k0/eta0)*∂Ez∂x
        pyntg[ip,1] = (-0.5)*real(Ez[ip]*conj(Hy))
        pyntg[ip,2] = 0.5*real(Ez[ip]*conj(Hx))
	end
    pyntg
end

function poynting_vector(k0, points, Ez_inc, Hx_inc, Hy_inc)
    #assumes points lie outside all scattering disks
    len = size(points,1)
	pyntg = Array{Float64}(undef, len, 2)
    for ip in 1:len
        pyntg[ip,1] = (-0.5)*real(Ez_inc[ip]*conj(Hy_inc[ip]))
        pyntg[ip,2] = 0.5*real(Ez_inc[ip]*conj(Hx_inc[ip]))
	end
    pyntg
end

function calc_power(k0::Array, kin, P, sp, points, nhat, ui)
    #this assumes points are equidistant. correct result only after multiplying by arc length
    power = Array{Float64}(undef, length(k0))
    for i in eachindex(k0)
        Ez_inc = uinc(k0[i], points, ui)
        Hx_inc = hxinc(k0[i], points, ui)
        Hy_inc = hyinc(k0[i], points, ui)
        if sp == nothing
            pyntg = poynting_vector(k0[i], points, Ez_inc, Hx_inc, Hy_inc)
        else
            beta = solve_particle_scattering(k0[i], kin[i], P, sp, ui;
                        get_inner = false, verbose = false)
            pyntg = poynting_vector(k0[i], beta, sp.centers, points, Ez_inc, Hx_inc, Hy_inc)
        end
        power[i] = power_quadrature(nhat, pyntg)
    end
    power
end

function calc_power(k0::Number, kin, P, sp, points, nhat, ui)
    #this assumes points are equidistant. correct result only after multiplying by arc length
    Ez_inc = uinc(k0, points, ui)
    Hx_inc = hxinc(k0, points, ui)
    Hy_inc = hyinc(k0, points, ui)
    if sp == nothing
        pyntg = poynting_vector(k0, points, Ez_inc, Hx_inc, Hy_inc)
    else
        beta = solve_particle_scattering(k0, kin, P, sp, ui;
                    get_inner = false, verbose = false)
        pyntg = poynting_vector(k0, beta, sp.centers, points, Ez_inc, Hx_inc, Hy_inc)
    end
    power_quadrature(nhat, pyntg)
end

function power_quadrature(n, S)
    #trapezoidal rule
    len = size(S,1)
    (dot(n, S) - 0.5*(n[1,1]*S[1,1] + n[1,2]*S[1,2] +
        n[len,1]*S[len,1] + n[len,2]*S[len,2]))/(len - 1)
end

function rect_border(b, Nx, Ny)
    #clockwise from top
    points1 = [range(b[1], stop=b[2], length=Nx)     b[4]*ones(Nx)]
    points2 = [b[2]*ones(Ny)     range(b[4], stop=b[3], length=Ny)]
    points3 = [range(b[2], stop=b[1], length=Nx)     b[3]*ones(Nx)]
    points4 = [b[1]*ones(Ny)     range(b[3], stop=b[4], length=Ny)]

    n = [[zeros(Nx) ones(Nx)], [ones(Ny) zeros(Ny)], [zeros(Nx) -ones(Nx)], [-ones(Ny) zeros(Ny)]]
    [points1, points2, points3, points4], n
end
