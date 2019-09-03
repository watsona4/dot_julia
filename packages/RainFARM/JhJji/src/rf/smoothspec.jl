"""
    smoothconv(z,nas)

Smoothen field `z(ns,ns)` with a spectral method at scale `ns/nas`
Takes into account missing values.
"""
function smoothspec(zi,nas)

        @compat iinan=findall(isnan.(zi))
        @compat iinotnan=findall(.~isnan.(zi))
        zi[iinan]=0.

        nss=size(zi);
        ns=nss[1];
        sdim=div(ns,nas); # the smoothing radius is one large scale pixel wide (setting the diameter to 1 pixel is wrong)

        kx=[collect(0:ns/2)' collect(-ns/2+1:-1)']';
        kx=kx*ones(1,ns);       
        kx=kx.^2+permutedims(kx,[2 1]).^2;
       
        zif=fft(zi); 
        zif[kx[:].>(nas/2).^2]=0.0;
        zif[kx[:].==(nas/2).^2]=real(zif[kx[:].==(nas/2).^2]*2.0);
        zif=real(ifft(zif));
       
        return zif
end
