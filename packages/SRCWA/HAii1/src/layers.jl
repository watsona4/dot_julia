module layers
using LinearAlgebra
export halfspace,layer_plain,layer_patterned, modes_freespace,Layer,Halfspace

"""
    Layer(thi,V,W,X,q)
    Computed Eigenmodes and propagation properties of a layer
    thi: layer thickness
    V: coordinate transform between eigenmode amplitude and magnetic field
    W: coordinate transform between eigenmode amplitude and electric field
    X: transmission of amplitude vector through the layer
    q: effective propagation constant of the eigenmodes
"""
struct Layer
    thi::Float64
    V::AbstractArray{Complex{Float64},2}
    W::AbstractArray{Complex{Float64},2}
    X::AbstractArray{Complex{Float64},2}
    q::AbstractArray{Complex{Float64},2}
end
"""
Halfspace(V,W,Kz)
Computed Eigenmodes of an unpatterned, infinitely thin halfspace
V: coordinate transform between eigenmode amplitude and magnetic field
W: coordinate transform between eigenmode amplitude and electric field
Kz: z-axis component of the propagation vector
"""
struct Halfspace
    V::AbstractArray{Complex{Float64},2}
    W::AbstractArray{Complex{Float64},2}
    Kz::AbstractArray{Complex{Float64},2}
end
"""
modes_freespace(Kx,Ky)
Computes the eigenmodes of propagation through free space, for normalization
Kx: x-axis component of the propagation vector
Ky: y-axis component of the propagation vector
returns
V0: coordinate transform between free space eigenmode amplitude and magnetic field
Kz0: z-axis component of the propagation vector in free space
"""
function modes_freespace(Kx,Ky)
    #just because |k|=1
    Kz0=sqrt.(Complex.(I-Kx*Kx-Ky*Ky))
    #P0 is identity
    Q0=[Kx*Ky I-Kx*Kx;Ky*Ky-I -Ky*Kx]
    #propagation
    q0=1im*Kz0
    q0=[q0 q0*0;0*q0 q0]
    #Free space, so W is identity
    #W0=I+0*Q0
    V0=Q0/Diagonal(q0)
    return V0,Kz0
end
"""
modes_patterned(Kx,Ky,k0,thi,epsilon)
Computes the eigenmodes of propagation through a patterned layer
Kx: x-axis component of the propagation vector
Ky: y-axis component of the propagation vector
k0: is 2pi/lambda, to normalize the thickness
thi: layer thickness
epsilon: Permittivity of layer in reciprocal space
returns
V: coordinate transform between eigenmode amplitude and magnetic field in the layer
W: coordinate transform between eigenmode amplitude and electric field in the layer
X: transmission of amplitude vector through the layer
q: effective propagation constant of the eigenmodes
"""
function modes_patterned(Kx,Ky,k0,thi,epsilon)
    eta=I/epsilon
    P=[Kx*eta*Ky I-Kx*eta*Kx;Ky*eta*Ky-I -Ky*eta*Kx]
    Q=[Kx*Ky epsilon-Kx*Kx;Ky*Ky-epsilon -Ky*Kx]
    #eigenmodes
    ev=eigen(Matrix(P*Q))
    q=Diagonal(sqrt.(Complex.(ev.values)))
    q[real.(q).>0].*=-1
    #W is transform between amplitude vector and E-Field
    W=ev.vectors
    #V is transform between amplitude vector and H-Field
    V=Q*W/Diagonal(q)
    
    #X the factor applied to the amplitudes when propagatin through the layer
    X=exp(q*k0*thi)
    return V,W,X,q
end
"""
layer_patterned(Kx,Ky,k0,thi,epsilon)
Computes the eigenmodes of propagation through a patterned layer in a Layer object
Kx: x-axis component of the propagation vector
Ky: y-axis component of the propagation vector
k0: is 2pi/lambda, to normalize the thickness
thi: layer thickness
epsilon: Permittivity of layer in reciprocal space
returns
patterned layer object
"""
function layer_patterned(Kx,Ky,k0,thi,epsilon)
    V,W,X,q=modes_patterned(Kx,Ky,k0,thi,epsilon)
    return Layer(thi,V,W,X,q)
end
"""
modes_plain(Kx,Kyk0,thi,epsilon)
Computes the eigenmodes of propagation through a plain layer
Kx: x-axis component of the propagation vector
Ky: y-axis component of the propagation vector
k0: is 2pi/lambda, to normalize the thickness
thi: layer thickness
epsilon: Bulk permittivity of the layer
returns
V: coordinate transform between eigenmode amplitude and magnetic field in the layer
W: coordinate transform between eigenmode amplitude and electric field in the layer
X: transmission of amplitude vector through the layer
q: effective propagation constant of the eigenmodes
"""
function modes_plain(Kx,Ky,k0,thi,epsilon)
    #Kz=P*Q
    Kz=sqrt.(Complex.(epsilon*I-Kx*Kx-Ky*Ky))
    Q=[Kx*Ky epsilon*I-Kx*Kx;Ky*Ky-epsilon*I -Ky*Kx]
    q=[1im*Kz zeros(size(Kz));zeros(size(Kz)) 1im*Kz]
    q[real.(q).>0].*=-1
    #W is identity
    W=I
    V=Q/Diagonal(q)
    X=exp(Matrix(q*k0*thi))
    return V,W,X,q
end
"""
layer_plain(Kx,Kyk0,thi,epsilon)
Computes the eigenmodes of propagation through a plain layer, in a Layer object
Kx: x-axis component of the propagation vector
Ky: y-axis component of the propagation vector
k0: is 2pi/lambda, to normalize the thickness
thi: layer thickness
epsilon: Bulk permittivity of the layer
returns
layer object
"""
function layer_plain(Kx,Ky,k0,thi,epsilon)
    V,W,X,q=modes_plain(Kx,Ky,k0,thi,epsilon)
    return Layer(thi,V,V*0+W,X,q)
end
"""
modes_halfspace(Kx,Ky,epsilon)
Computes the eigenmodes of an infinitely thin halfspace
Kx: x-axis component of the propagation vector
Ky: y-axis component of the propagation vector
epsilon: bulk permittivity of the halfspace
returns
V: coordinate transform between eigenmode amplitude and magnetic field in the halfspace
W: coordinate transform between eigenmode amplitude and electric field in the halfspace
Kz: z-axis component of the propagation vector in the halfspace
"""
function modes_halfspace(Kx,Ky,epsilon)
    Kz=sqrt.(Complex.(epsilon*I-Kx*Kx-Ky*Ky))
    Q=[Kx*Ky epsilon*I-Kx*Kx;Ky*Ky-epsilon*I -Ky*Kx]
    q0=[1im*Kz zeros(size(Kz));zeros(size(Kz)) 1im*Kz]
    W=I
    V=Q/Diagonal(q0)
    return V,W+0*V,Kz
end
"""
halfspace(Kx,Ky,epsilon)
Computes the eigenmodes of an infinitely thin halfspace in a Halfspace object
Kx: x-axis component of the propagation vector
Ky: y-axis component of the propagation vector
epsilon: bulk permittivity of the halfspace
returns
halfspace object
"""
function halfspace(Kx,Ky,epsilon)
    V,W,Kz=modes_halfspace(Kx,Ky,epsilon)
    return Halfspace(V,W,Kz)
end

end
