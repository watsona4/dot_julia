"""
    f = initmetagauss(sx,st,nso,nto)

Generate the spectral amplitudes `f` for a metagaussian field of size `nso * nso * nto`
with slopes `sx` and `st`. 
"""
function initmetagauss(sx,st,ns,nt);

        sx=abs(sx);
        st=abs(st);

#       This spares a lot of memory!
#       [kx,ky,kt]=ndgrid([0:ns/2 -ns/2+1:-1],[0:ns/2 -ns/2+1:-1],[0:nt/2 -nt/2+1:-1]);
        kx=[collect(0:ns/2)' collect(-ns/2+1:-1)']';
        kx=repeat(kx*ones(1,ns),outer=[1,1,nt]);
# kky=permdute(kkx,[2 1 3]);

if(nt>1)
        kt=[collect(0:nt/2)' collect(-nt/2+1:-1)']';
        kt=repeat(kt*ones(1,ns),outer=[1 1 ns]);
        kt=permute(kt,[3 2 1]).^2;

        kt[:,:,1]=0.000001;
end

        kx=kx.^2+permutedims(kx,[2 1 3]).^2;

        kx[1,1,:].=0.000001;
# f = (kx.^(-(sx+1)/4)).*kt.^(-st/4);
    if(nt>1)
        kx = (kx.^(-(sx+1)/4)).*kt.^(-st/4);
    else
        kx = (kx.^(-(sx+1)/4));
    end
    kx[1,1,1]=0;
    kx[1,1,:].=0;
    if(nt>1)
       kx[:,:,1]=0;
    end
   #  kx=kx./sqrt(sum(lin(abs(kx).^2)))*ns*ns*nt;
   kx=kx./sqrt(sum(abs2.(kx[:])))*ns*ns*nt;
end
