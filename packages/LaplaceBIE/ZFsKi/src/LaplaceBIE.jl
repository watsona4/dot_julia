module LaplaceBIE

using SurfaceTopology
using GeometryTypes
using LinearAlgebra
using FastGaussQuadrature

eye(A::AbstractMatrix{T}) where T = Matrix{eltype(A)}(I,size(A))
eye(m::Integer) = Matrix(1.0I,m,m)
diagm(x) = Matrix(Diagonal(x))

function vertexareas(points,topology)
    vareas = zeros(Float64,length(points))
    for face in Faces(topology)
        v1,v2,v3 = face
        area = norm(cross(points[v2]-points[v1],points[v3]-points[v1])) /2
        vareas[v1] += area/3
        vareas[v2] += area/3
        vareas[v3] += area/3
    end
    return vareas
end

# function surfacefield(points,normals,topology,psi,mup,Htime)
#     H = tangentderivatives(points,normals,topology,psi)
#     Hn = normalderivatives(points,normals,topology,H,mup,Htime)
#     H .= Hn .* normals
#     return H
# end    

@generated function strquad(q::Function,x1,x2,x3,NP::Val{T}) where T
    t, w = gausslegendre(T)
    @inbounds quote # Need to test if that improves performance
        B = dot(x3-x1,x2-x1)/norm(x2-x1)^2
        C = norm(x3-x1)^2/norm(x2-x1)^2
        hS = norm(cross(x2-x1,x3-x1))

        s = 0.
        for i in 1:$T
            Chi = pi/4*(1 + $t[i])

            R = 1/(cos(Chi) + sin(Chi))
            si = 0.
            @simd for j in 1:$T
                rho = R/2*(1 + $t[j])
                si += q(rho*cos(Chi),rho*sin(Chi))*$w[j]
            end

            s += si*R/2 / sqrt(cos(Chi)^2 + B*sin(2*Chi) + C*sin(Chi)^2) * $w[i]
        end
        s *= pi/4
        return s*hS/norm(x2 - x1)
    end
end

strquad(q::Function,x1,x2,x3,NP::Int64) = strquad(q,x1,x2,x3,Val(NP))

normalderivatives(points,normals,topology,Ht,hmag,H0; eps=0.0001, NP=10) = normalderivatives(points,normals,topology,Ht,hmag,x->H0; eps=0.0001, NP=10)

"""
    normalderivatives(points,normals,topology,P∇ψ,μ,∇ψ0::Function; eps=0.0001, NP=100)

Calculates ∇ψ.n approached to the object surface from *interior* region. To use the function surface properties `points`, `normals` and `topology` are required. To use the function it is required to have a tangential field components (see `tangentialderivatives` and `surfacepotential`), boundary jump condition μ and a gradient of external free field. 
"""
function normalderivatives(points,normals,topology,Ht,hmag,H0::Function; eps=0.0001, NP=100)

    ### Tangential field
    for xkey in 1:length(points)
        nx = normals[xkey]
        Ht[xkey] = (eye(3) - nx*nx')*Ht[xkey]
    end

    vareas = vertexareas(points,topology)

    function qs(xi,eta,v1,v2,v3,x,nx,Htx)
        y = (1 - xi - eta)*points[v1] + xi*points[v2] + eta*points[v3]
        Hty = (1 - xi - eta)*Ht[v1] + xi*Ht[v2] + eta*Ht[v3]
        ny =  (1 - xi - eta)*normals[v1] + xi*normals[v2] + eta*normals[v3]
        s = - dot(nx,cross(Hty - Htx,cross(ny,-(y-x)/norm(y-x)^2)))
    end

    Hn = Array{Float64}(undef,length(points))
    
    for xkey in 1:length(points)

        nx = normals[xkey]
        x = points[xkey] + eps*nx
        Htx = Ht[xkey]

        s = 0 
        for ykey in 1:length(points)
            !(xkey==ykey) || continue
            y = points[ykey]
            ny = normals[ykey]
            Hty = Ht[ykey]

            s += dot(nx,-(Hty-Htx)*dot((y-x)/norm(y-x)^3,ny)) * vareas[ykey]
            s += -dot(nx,cross(Hty-Htx,cross(ny,-(y-x)/norm(y-x)^3))) * vareas[ykey]
        end

        ### Making a proper hole
        for (v2,v3) in EdgeRing(xkey,topology) #DoubleVertexVRing(xkey,faces)
            area = norm(cross(points[v2]-x,points[v3]-x))/2

            ny = normals[v2]
            y = points[v2]
            s -= -dot(nx,cross(Ht[v2]-Htx,cross(ny,-(y-x)/norm(y-x)^3))) * area/3

            ny = normals[v3]
            y = points[v3]
            s -= -dot(nx,cross(Ht[v3]-Htx,cross(ny,-(y-x)/norm(y-x)^3))) * area/3

            ### Singular triangle integration
            s += strquad((xi,eta) -> qs(xi,eta,xkey,v2,v3,x,nx,Htx),x,points[v2],points[v3],NP)
        end

        Hn[xkey] = dot(H0(points[xkey]),nx)/hmag + 1/4/pi * (1-hmag)/hmag * s
    end

    return Hn
end

"""
    tangentderivatives(points,normals,topology,ψ)

Returns tangential derivative P∇ψ for a shape defined by `points`, `normals` and `topology`.
"""
function tangentderivatives(points,normals,topology,psi)

    H = HField(points,topology,psi)
    for xkey in 1:length(points)
        nx = normals[xkey]
        H[xkey] = (eye(3) - nx*nx')*H[xkey]
    end

    return H
end

function HField(points,topology,psi)

    H = Array{Point{3,Float64}}(undef,length(points))

    for xkey in 1:length(points)
        x = points[xkey]
        psix = psi[xkey]

        vvec = Point{3,Float64}[]
        dphi = Float64[]

        for ykey in VertexRing(xkey,topology)
            y = points[ykey]
            push!(vvec,y-x)
            push!(dphi,psi[ykey]-psix)
        end
        
        A, B = vvec, dphi

        A = Array(hcat(A...))
        A = transpose(reshape(A,3,div(length(A),3))) ### This looks unecesarry
        H[xkey] = inv(transpose(A)*A)*transpose(A)*B
    end

    return H
end

### Potential simple
surfacepotential(points,normals,topology,hmag,H0) = surfacepotential(points,normals,topology,hmag,x->dot(H0,x))

"""
    surfacepotential(points,normals,topology,μ,ψ0::Function)

Returns a surface field for a given shape defined by a triangular mesh with `points`, `normals` and `topology` and for a boundary conditions where ∇ψ has a jump in th e normal direction charectarized with μ and for the external free field given by a potential ψ0.
"""
function surfacepotential(points,normals,topology,hmag,ψ::Function)

    A = zeros(Float64,length(points),length(points))
    vareas = vertexareas(points,topology)

    for xkey in 1:length(points)

        x = points[xkey]
        nx = normals[xkey]

        for ykey in 1:length(points)
            if xkey==ykey
                continue
            end

            y = points[ykey]
            ny = normals[ykey]
            
            A[ykey,xkey] = dot(y-x,ny)/norm(y-x)^3 * vareas[ykey]
        end
    end

    B = zeros(Float64,length(points))
    for xkey in 1:length(points)
        B[xkey] = 2*ψ(points[xkey])/(hmag+1) 
    end

    A = A'
    psi = (eye(A)*(1- (hmag-1)/(hmag+1)) - 1/2/pi * (hmag-1)/(hmag+1) * (A - diagm(Float64[sum(A[i,:]) for i in 1:size(A,2)]))) \ B
    
    return psi
end

# ### A method for calculating the field energy
# fieldenergy(points,normals,topology,psix,mup,H0) = fieldenergy(points,normals,topology,psix,mup,x->H0) 
# function fieldenergy(points,normals,topology,psix,mup,H0::Function)
#     vareas = vertexareas(points,topology)
#     Area = sum(vareas)

#     s = 0
#     for xkey in 1:length(points)
#         s += psix[xkey]*dot(H0(points[xkey]),normals[xkey]) * vareas[xkey]
#     end

#     Em = 1/8/pi * (1 - mup) * s
#     return Em
# end


export surfacepotential, tangentderivatives, normalderivatives #, fieldenergy

end # module
