module grid
using LinearAlgebra
export Spacegrid,grid_n,grid_k,grid_xy_square
struct Spacegrid
    x::Array{Float64,2}
    y::Array{Float64,2}
end

function grid_n(Nx,Ny)
    #reciprocal space coordinate indices
    ny=[c  for r in -Nx:Nx, c in -Ny:Ny]
    nx=[r  for r in -Nx:Nx, c in -Ny:Ny]
    nx=vec(nx)
    ny=vec(ny)
    #difference matrix for 2dft
    dnx=[nx[a]-nx[b] for a in 1:length(nx),b in 1:length(nx)]
    dny=[ny[a]-ny[b] for a in 1:length(ny),b in 1:length(ny)]
    return nx,ny,dnx,dny
end

function grid_k(nx,ny,theta,alpha,lambda,ax,ay,epsilon_ref)
    #straightforward
    #all k vectors are generally normalized to k0 here
    k0=2*pi/real(lambda)
    #The incoming wave, transformed from spherical coordinates to normalized cartesian coordinates, |kin|=1
    kin=[sin(theta*pi/180)*cos(alpha*pi/180),sin(theta*pi/180)*sin(alpha*pi/180),cos(theta*pi/180)]*real(sqrt(epsilon_ref))
    #the spatial vectors are the sum of the incoming vector and the reciprocal lattice vectors
    kx=kin[1].+(2*pi/ax)*nx/k0;
    ky=kin[2].+(2*pi/ay)*ny/k0;
    #need matrix for later computations
    Kx=Diagonal(kx)
    Ky=Diagonal(ky)  
    return k0,Kx,Ky,kin
end

function grid_xy_square(acc)
    #creating a square meshgrid
    x=[r  for r in -acc/2+.5:acc/2-.5, c in -acc/2+.5:acc/2-.5]/acc
    y=[c  for r in -acc/2+.5:acc/2-.5, c in -acc/2+.5:acc/2-.5]/acc
    return Spacegrid(x,y)
end

end
