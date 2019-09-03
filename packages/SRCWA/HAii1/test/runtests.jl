using SRCWA,Test

@testset "reflection" begin

    
    n1=rand()*10
    n2=rand()*10
nx,ny,dnx,dny=grid_n(0,0)
lambda=1000
theta=1E-30
phi=0
k0,Kx,Ky,kin=grid_k(nx,ny,theta,phi,lambda,100,100,n1^2)
upper=halfspace(Kx,Ky,n1^2)
lower=halfspace(Kx,Ky,n2^2)
V0,Kz0=modes_freespace(Kx,Ky)
Su=matrix_ref(upper,V0)
Sl=matrix_tra(lower,V0)
S=concatenate(Su,Sl)
a0te,a0tm=prepare_source(kin,upper.W,0,0)
cref=S.S11*a0tm#+a0tm
ctra=S.S21*a0tm
R=a2p(cref,upper,Kx,Ky,kin[3])
T=a2p(ctra,lower,Kx,Ky,kin[3]) 
    
    @test abs(((n1-n2)/(n1+n2))^2-R)<1E-6
    @test abs(1-((n1-n2)/(n1+n2))^2-T)<1E-6
end
