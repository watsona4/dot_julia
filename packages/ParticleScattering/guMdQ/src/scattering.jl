"""
    get_potential(kout, kin, P, s::ShapeParams) -> sigma_mu

Given a shape `s` with `2N` discretization nodes, outer and inner wavenumbers
`kout`,`kin`, and the cylindrical harmonics parameter `P`, returns the potential
densities `sigma_mu`. Each column contains the response to a different harmonic,
where the first `2N` entries contain the single-layer potential density
(``\\sigma``), and the lower entries contain the double-layer density (``\\mu``).
"""
function get_potential(kout, kin, P, t, ft, dft)
    N = length(t) #N here is 2N elesewhere.

    A = SDNTpotentialsdiff(kout, kin, t, ft, dft)
    LU = lu(A)

    sigma_mu = Array{Complex{Float64}}(undef, 2*N, 2*P+1)

    #assuming the wave is sampled on the shape
    nz = sqrt.(sum(abs2, ft, dims=2))
    θ = atan.(ft[:,2], ft[:,1])
    ndz = sqrt.(sum(abs2, dft, dims=2))
    nzndz = nz.*ndz
    wro = dft[:,2].*ft[:,1] - dft[:,1].*ft[:,2]
	zz = dft[:,1].*ft[:,1] + dft[:,2].*ft[:,2]

    bessp = besselj.(-P-1, kout*nz)
    bess = similar(bessp)
    du = Array{Complex{Float64}}(undef, length(bessp))
    rhs = Array{Complex{Float64}}(undef, 2*length(bessp))
    for p = -P:P
        bess[:] = besselj.(p, kout*nz)
		du[:] = kout*bessp.*wro - (p*bess./nz).*(wro + 1im*zz)
        rhs[:] = -[bess.*exp.(1.0im*p*θ);
               (du./nzndz).*exp.(1.0im*p*θ)]
        sigma_mu[:,p + P + 1] = LU\rhs
        copyto!(bessp, bess)
    end
    return sigma_mu
end

"""
    get_potential(kout, kin, P, t, ft, dft) -> sigma_mu
Same, but with the `ShapeParams` supplied directly.
"""
get_potential(kout, kin, P, s::ShapeParams) =
    get_potential(kout, kin, P, s.t, s.ft, s.dft)

function SDNTpotentialsdiff(k1, k2, t, ft, dft)
    #now just returns system matrix, utilizes similarities between upper and lower triangles
    iseven(length(t)) ?
    (N = div(length(t),2)) : (error("length(t) must be even"))

    (Rvec, kmlogvec) = KM_weights(N)
    A = Array{Complex{Float64}}(undef, 4*N, 4*N)

    ndft = sqrt.(vec(sum(abs2,dft,dims=2)))
    rij = Array{Float64}(undef, 2)
    for i=1:2*N, j=1:i
        if i == j
            T1 = -(k1^2 - k2^2)
            T2 = k1^2*(π*1im - 2MathConstants.γ + 1 - 2*log(k1*ndft[i]/2)) -
                k2^2*(π*1im - 2MathConstants.γ + 1 - 2*log(k2*ndft[i]/2))

            A[i,j] = (-ndft[i]/2/N)*log(k1/k2) #dS (dM1=0)
            A[i,j+2*N] = 1 #dD (dL=0)
            A[i+2*N,j] = -1 #dN=0
            A[i+2*N,j+2*N] = (ndft[i]/8π)*(Rvec[1]*T1 + (π/N)*T2) #dT
            continue
        end
        rij[1] = ft[i,1]-ft[j,1]
        rij[2] = ft[i,2]-ft[j,2] #ridiculous but much faster than ft[i,:]-ft[j,:]
        r = sqrt(rij[1]^2 +  rij[2]^2)
        didj = dft[i,1]*dft[j,1] + dft[i,2]*dft[j,2]

        J01 = besselj(0, k1*r)
        J02 = besselj(0, k2*r)
        H01 = besselh(0, 1, k1*r)
        H02 = besselh(0, 1, k2*r)
        k2J0 = k1^2*J01 - k2^2*J02
        k1J1 = k1*besselj(1,k1*r) - k2*besselj(1,k2*r)
        k2H0 = k1^2*H01 - k2^2*H02
        k1H1 = k1*besselh(1,k1*r) - k2*besselh(1,k2*r)

        kmlog = kmlogvec[abs(i-j)+1]
        R = Rvec[abs(i-j)+1]

        N2 = 1im*pi*k1H1 - k1J1*kmlog

        P1 = (-didj/π)*k2J0
        P2 = 1im*didj*k2H0 - P1*kmlog

        Qtilde = (dft[i,1]*rij[1] + dft[i,2]*rij[2])*(dft[j,1]*rij[1] + dft[j,2]*rij[2])/r^2

        Q1 = (-Qtilde*k2J0 + (1/r)*k1J1*(2*Qtilde - didj))/π
        Q2 = 1im*Qtilde*k2H0 + (-1im/r)*k1H1*(2*Qtilde - didj) - Q1*kmlog

        M1 = (J02 - J01)/π
        L1 = k1J1/π
        M2 = 1im*(H01 - H02) - M1*kmlog
        L2 = 1im*k1H1 - L1*kmlog

        wro_ij =  (dft[j,2]*rij[1] - dft[j,1]*rij[2])/r
        wro_ji = -(dft[i,2]*rij[1] - dft[i,1]*rij[2])/r
        cross_ij = -wro_ji*ndft[j]/ndft[i]
        cross_ji = -wro_ij*ndft[i]/ndft[j]

        #edited to remove division by wro which might be 0
        A[i,j] = (0.25*ndft[j])*(R*M1 + (π/N)*M2) #dS
        A[j,i] = A[i,j]*(ndft[i]/ndft[j]) #dS
        A[i,j+2*N] = (0.25*wro_ij)*(R*L1 + (π/N)*L2) #dD
        A[j,i+2*N] = (0.25*wro_ji)*(R*L1 + (π/N)*L2) #dD
        A[i+2*N,j] = (-0.25*cross_ij/π)*(R*k1J1 + (π/N)*N2) #dN
        A[j+2*N,i] = (-0.25*cross_ji/π)*(R*k1J1 + (π/N)*N2) #dN
        A[i+2*N,j+2*N] = (R*(P1-Q1) + (π/N)*(P2-Q2))/(4*ndft[i]) #dT
        A[j+2*N,i+2*N] = A[i+2*N,j+2*N]*(ndft[i]/ndft[j]) #dT
    end
    any(isnan.(A)) && error("SDNTpotentialsdiff: encountered NaN, check data and division by ndft.")
    return A
end

function KM_weights(N)
    #computes the weights necessary for Kussmaul-Martensen quadrature (evenly
    #spaced).
    #Input: N (integer>=1)
    #Output: R,K (float vectors of length 2N)
    arg1 = Float64[cos(m*j*π/N)/m for m=1:N-1, j=0:2*N-1]
    R = vec((-2π/N)*sum(arg1,dims=1)) - (π/N^2)*Float64[cos(j*π) for j=0:2*N-1]

    K = Float64[2*log(2*sin(0.5π*j/N)) for j = 0:2*N-1]
    return (R,K)
end

"""
    get_potentialPW(kout, kin, s::ShapeParams, θ_i) -> sigma_mu

Given a shape `s` with `2N` discretization nodes, outer and inner wavenumbers
`kout`,`kin`, and an incident plane-wave angle, returns the potential
densities vector `sigma_mu`. The first `2N` entries contain the single-layer
potential density (``\\sigma``), and the lower entries contain the double-layer
density (``\\mu``).
"""
function get_potentialPW(kout, kin, s, θ_i)
    N = length(s.t) #N here is different...

    A = SDNTpotentialsdiff(kout, kin, s.t, s.ft, s.dft)
    LU = lu(A)

	ndft = sqrt.(sum(abs2, s.dft, dims=2))
    ui = exp.(1.0im*kout*(cos(θ_i)*s.ft[:,1] + sin(θ_i)*s.ft[:,2]))
    rhs = -[ui;
			(1.0im*kout*ui).*((cos(θ_i)*s.dft[:,2] - sin(θ_i)*s.dft[:,1])./ndft)]

    sigma_mu = LU\rhs
end


"""
    scatteredfield(sigma_mu, k, s::ShapeParams, p) -> u_s

Computes field scattered by the particle `s` with pre-computed potential
densities `sigma_mu` at points `p`. All points must either be inside `k = kin`
or outside `k = kout` the particle.
"""
scatteredfield(sigma_mu, k, s::ShapeParams, p) =
    scatteredfield(sigma_mu, k, s.t, s.ft, s.dft, p)

"""
    scatteredfield(sigma_mu, k, t, ft, dft, p) -> u_s

Same, but with the `ShapeParams` supplied directly. Useful for computing `u_s`
for rotated shapes.
"""
function scatteredfield(sigma_mu, k, t, ft, dft, p)
    #calculates the scattered field of a shape with parametrization ft(t),...,dft(t)
    #in space with wavenumber k at points p *off* the boundary. For field on the boundary,
    #SDpotentials function must be used.
    if size(p,2) == 1 #single point, rotate it
        p = transpose(p)
    end
    N = length(t)
    M = size(p,1)
    r = zeros(Float64,2)
    #loop is faster here:
    SDout = Array{Complex{Float64}}(undef, M, 2*N)
    for j = 1:N
        ndft = hypot(dft[j,1],dft[j,2])
        for i = 1:M
            r[:] = [p[i,1] - ft[j,1];p[i,2] - ft[j,2]]
            nr = hypot(r[1],r[2])
            if nr < eps()
                #TODO: use SDNTpotentialsdiff here
                @warn("Encountered singularity in scatteredfield.")
                SDout[i,j] = 0
                SDout[i,j+N] = 0
                continue
            end
            SDout[i,j] = (2*pi/N)*0.25im*besselh(0,1, k*nr)*ndft
            SDout[i,j+N] = (2*pi/N)*0.25im*k*besselh(1,1, k*nr)*(dft[j,2]*r[1] - dft[j,1]*r[2])/nr
        end
    end
    u_s = SDout*sigma_mu
end


function shapeMultipoleExpansion(k, t, ft, dft, P)
    #unlike others (so far), this does *not* assume t_j=pi*j/N
    N = div(length(t),2)
    nz = vec(sqrt.(sum(abs2, ft, dims=2)))
    θ = atan.(ft[:,2], ft[:,1])
    ndz = vec(sqrt.(sum(abs2, dft, dims=2)))
    AB = Array{Complex{Float64}}(undef, 2*P + 1, 4*N)
    bessp = besselj.(-P-1,k*nz)
    bess = similar(bessp)
    for l = -P:0
        bess[:] = besselj.(l,k*nz)
        for j = 1:2*N
            AB[l+P+1,j] = 0.25im*(π/N)*bess[j]*exp(-1.0im*l*θ[j])*ndz[j]
            l != 0 && (AB[-l+P+1,j] = 0.25im*((-1.0)^l*π/N)*bess[j]*exp(1.0im*l*θ[j])*ndz[j])
            wro = ft[j,1]*dft[j,2] - ft[j,2]*dft[j,1]
            zdz = -1.0im*(ft[j,1]*dft[j,1] + ft[j,2]*dft[j,2])
            b1 = (-l*bess[j]/nz[j])*(zdz + wro)
            b1_ = (-l*bess[j]/nz[j])*(zdz - wro)
            b2 = k*bessp[j]*wro
            AB[l+P+1,j+2*N] = 0.25im*(π/N)*(exp(-1.0im*l*θ[j])/nz[j])*(b1 + b2)
            l != 0 && (AB[-l+P+1,j+2*N] = 0.25im*((-1.0)^l*π/N)*(exp(1.0im*l*θ[j])/nz[j])*(-b1_ + b2))
        end
        copyto!(bessp,bess)
    end
    return AB
end

function solvePotential_forError(kin, kout, shape, ls_pos, ls_amp, θ_i)
    #plane wave outside, line sources inside
    N = length(shape.t) #N here is different...

    A = SDNTpotentialsdiff(kout, kin, shape.t, shape.ft, shape.dft)
    LU = lu(A)

	ndft = sqrt.(sum(abs2, shape.dft, dims=2))

    r = sqrt.((shape.ft[:,1] .- ls_pos[1,1]).^2 +
            (shape.ft[:,2] .- ls_pos[1,2]).^2)

    uls = (-ls_amp[1]*0.25im)*besselh.(0,kout*r)
    duls = (ls_amp[1]*0.25im*kout)*besselh.(1,kout*r).*((shape.ft[:,1].-ls_pos[1,1]).*shape.dft[:,2]-(shape.ft[:,2].-ls_pos[1,2]).*shape.dft[:,1])./r./ndft
    for i = 2:length(ls_amp)
        r = sqrt.((shape.ft[:,1] - ls_pos[i,1]).^2 + (shape.ft[:,2] - ls_pos[i,2]).^2)
        uls -= ls_amp[i]*0.25im*besselh.(0,kout*r)
        duls -= -ls_amp[i]*0.25im*kout*besselh.(1,kout*r).*((shape.ft[:,1]-ls_pos[i,1]).*shape.dft[:,2]-(shape.ft[:,2]-ls_pos[i,2]).*shape.dft[:,1])./r./ndft
    end

    #outer plane wave
    ui = exp.(1.0im*kin*(cos(θ_i)*shape.ft[:,1] + sin(θ_i)*shape.ft[:,2]))
    dui = (1.0im*kin)*(ui.*(cos(θ_i)*shape.dft[:,2] - sin(θ_i)*shape.dft[:,1])./ndft)

    rhs = -[ui+uls;dui+duls]
    sigma_mu = LU\rhs
    return sigma_mu
end
