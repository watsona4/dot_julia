module evaluations
using LinearAlgebra
using ..matrices,..layers,..ft2d,..grid
export prepare_source,a2p,absorption,field_expansion,stackamp

#just slices a vector e in half
function slicehalf(e)
    mylength=convert(Int64,length(e)/2)
    return e[1:mylength],e[mylength+1:end]
end

#create normalized source vector depending on propagation modes and grid size
function prepare_source(kinc,Wref,Nx,Ny)
    #the total number of scattering states
    width=(Nx*2+1)*(Ny*2+1)
    #vertical
    normal=[0,0,1]
    #te polarization E-field is perpendicular with z-axis and propagation direction (so, parallel with surface)
    kte=cross(normal,kinc)/norm(cross(normal,kinc))
    #tm polarization E-field is perpendicular with te and propagation direction (so, not necessarily parallel with surface)
    ktm=cross(kinc,kte)/norm(cross(kinc,kte))
    
    esource=zeros(width*2)*1im
    esource[convert(Int64,(width+1)/2)]=kte[1]
    esource[convert(Int64,(width+1)/2)+width]=kte[2]
    a0te=Wref\esource
    
    esource=zeros(width*2)*1im
    esource[convert(Int64,(width+1)/2)]=ktm[1]
    esource[convert(Int64,(width+1)/2)+width]=ktm[2]
    a0tm=Wref\esource#/sqrt(epsref)
    return a0te,a0tm
end

#convert amplitude vector to electric field
function a2e2(a,W)
    e=W*a
    ex,ey=slicehalf(e)
    return ex,ey
end

#convert amplitude vector to electric field
function a2e(a,W,Kx,Ky,Kz)
    e=W*a
    ex,ey=slicehalf(e)
    ez=-Kz\(Kx*ex+Ky*ey)
    return ex,ey,ez
end


#convert electric field to total power
function e2p(ex,ey,ez,Kz,kz0)
    P=abs.(ex).^2+abs.(ey).^2+abs.(ez).^2
    P=sum(real.(Kz)*P/real(kz0))
    return P
end

#convert amplitude vector to total power
function a2p(a,W,Kx,Ky,Kz,kz0)
    ex,ey,ez=a2e(a,W,Kx,Ky,Kz)
    return e2p(ex,ey,ez,Kz,kz0)
end



#convert amplitude vector to total power
function a2p(a,h::Halfspace,Kx,Ky,kz0)
    return a2p(a,h.W,Kx,Ky,h.Kz,kz0)
end

#compute the amplitudes before and after a layer in the stack
function stackamp(Sup,S,Slo,a0)
    Sbefore=Sup
    Safter=concatenate(S,Slo)
    ain=(I-Sbefore.S22*Safter.S11)\(Sbefore.S21*a0)
    bout=(I-Safter.S11*Sbefore.S22)\(Safter.S11*Sbefore.S21*a0)
    
    Sbefore=concatenate(Sup,S)
    Safter=Slo
    aout=(I-Sbefore.S22*Safter.S11)\(Sbefore.S21*a0)
    bin=(I-Safter.S11*Sbefore.S22)\(Safter.S11*Sbefore.S21*a0)
    return ain,aout,bin,bout
end

#compute the absorption in one layer within the stack
#not working properly, better use the alternative method
function absorption(Sabove,Sint,Sbelow,a0,W0,Kx,Ky,Kz0,kz0)
    #compute amplitudes before and after layer
    ain,aout,bin,bout=stackamp(Sabove,Sint,Sbelow,a0)
    #Power entering the layer
    pin=a2p(ain,W0,Kx,Ky,Kz0,kz0)+a2p(bin,W0,Kx,Ky,Kz0,kz0)
    #power leaving the layer
    pout=a2p(aout,W0,Kx,Ky,Kz0,kz0)+a2p(bout,W0,Kx,Ky,Kz0,kz0)
    return pin-pout
end



#compute the field expansion in a layer using fourier transform
function field_expansion(ain,aout,bin,bout,layer,V0,zpoints,Kx,Ky,Kz,k0,nx,ny,realgrid)
    W0*I+0*V0
    #create empty vector for result
    efield=zeros(size(realgrid.x,1),size(realgrid.y,2),zpoints,3)*1im
    hfield=zeros(size(realgrid.x,1),size(realgrid.y,2),zpoints,3)*1im
    #compute the waves transmitted into the layer
    outside=Matrix([W0 W0;V0 -V0])
    inside=Matrix([layer.W+0*layer.V layer.W+0*layer.V;layer.V -layer.V])
    ain,bout=slicehalf(inside\outside*[ain;bout])
    aout,bin=slicehalf(inside\outside*[aout;bin])

    for zind=1:zpoints
        #propagation of the waves
        a=exp(Matrix(layer.q)*k0*layer.thi/zpoints*(zind-.5))*ain
        #b=exp(-Matrix(q)*k0*(zind-1))*bout    
        b=exp(Matrix(layer.q)*k0*layer.thi/zpoints*(zpoints+.5-zind))*bin
        #convert amplitude vectors to electric fields
        ex,ey,ez=a2e(a+b,layer.W,Kx,Ky,Kz)
        hx,hy,hz=a2e(-a+b,layer.V,Kx,Ky,Kz)
        #convert from reciprocal lattice vectors to real space distribution
        efield[:,:,zind,1]=recipvec2real(nx,ny,ex,realgrid.x,realgrid.y)
        efield[:,:,zind,2]=recipvec2real(nx,ny,ey,realgrid.x,realgrid.y)
        efield[:,:,zind,3]=recipvec2real(nx,ny,ez,realgrid.x,realgrid.y)
        
        hfield[:,:,zind,1]=recipvec2real(nx,ny,hx,realgrid.x,realgrid.y)
        hfield[:,:,zind,2]=recipvec2real(nx,ny,hy,realgrid.x,realgrid.y)
        hfield[:,:,zind,3]=recipvec2real(nx,ny,hz,realgrid.x,realgrid.y)
end    
    return efield,hfield
end



#experimental_unverified: Kz for structured layers
function Kzpatt(Kx,Ky,epsilon)
    Kz=sqrt.(Complex.(conj.(epsilon)-Kx*Kx-Ky*Ky))'
    return Kz
end

function kzpatt2(Kx,Ky,epsilon)
    eta=I/epsilon
    P=[Kx*eta*Ky I-Kx*eta*Kx;Ky*eta*Ky-I -Ky*eta*Kx]
    Q=[Kx*Ky epsilon-Kx*Kx;Ky*Ky-epsilon -Ky*Kx]
    ev=eigen(Matrix(P*Q))
    q=Diagonal(sqrt.(Complex.(ev.values)))
    
    return q[1:size(epsilon,1),1:size(epsilon,2)]/1im
end

#compute the absorption in one layer within the stack
#this is with transformation to real space and subsequent integration, unnecessary overhead, legacy
function absorption(Sabove,Sint,Sbelow,V0,nx,ny,a0,Nreal)
    
    #compute amplitudes before and after layer
    ain,aout,bin,bout=stackamp(Sabove,Sint,Sbelow,a0)
    #We need a real space meshgrid for the spatial Fourier transform
    realgrid=grid_xy_square(Nreal)
    W0=0*V0+I
    #poynting vector z component before layer    
    ex,ey=a2e2(ain+bout,W0)
    hx,hy=a2e2(-ain+bout,V0)
    
    ex=recipvec2real(nx,ny,ex,realgrid.x,realgrid.y)
    ey=recipvec2real(nx,ny,ey,realgrid.x,realgrid.y)
    hx=recipvec2real(nx,ny,hx,realgrid.x,realgrid.y)
    hy=recipvec2real(nx,ny,hy,realgrid.x,realgrid.y)
    
    poynting=ex.*conj.(hy)-ey.*conj.(hx)
    #and after layer
    ex,ey=a2e2(aout+bin,W0)
    hx,hy=a2e2(-aout+bin,V0)
    
    ex=recipvec2real(nx,ny,ex,realgrid.x,realgrid.y)
    ey=recipvec2real(nx,ny,ey,realgrid.x,realgrid.y)
    hx=recipvec2real(nx,ny,hx,realgrid.x,realgrid.y)
    hy=recipvec2real(nx,ny,hy,realgrid.x,realgrid.y)
    
    poynting2=ex.*conj.(hy)-ey.*conj.(hx)
    #integrate, take imaginary part of difference
    return imag.(sum(poynting-poynting2)/Nreal/Nreal)
end

function absorption(Sabove,Sint,Sbelow,V0,a0,kz0)
    #compute amplitudes before and after layer
    ain,aout,bin,bout=stackamp(Sabove,Sint,Sbelow,a0)
    #W is just the identity matrix for unpatterned space
    W0=0*V0+I
    
    #in-plane fields "above" the layer   
    ex,ey=a2e2(ain+bout,W0)
    hx,hy=a2e2(-ain+bout,V0)
    #imaginary part of the z-component of the poynting vector integrated over reciprocal space
    p1=imag(sum(ex.*conj.(hy)-ey.*conj.(hx)))/kz0
    
    #and "below" layer
    ex,ey=a2e2(aout+bin,W0)
    hx,hy=a2e2(-aout+bin,V0)
    p2=imag(sum(ex.*conj.(hy)-ey.*conj.(hx)))/kz0
    
    return p1-p2
end

end
