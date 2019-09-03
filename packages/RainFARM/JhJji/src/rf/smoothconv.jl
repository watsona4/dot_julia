"""
    zs = smoothconv(z,nas)

Smoothen field `z(ns,ns)` with a circular kernel of diameter `ns/nas` using convolution.
Takes into account missing values.
"""
	function smoothconv(zi,nas)

        @compat iinan=findall(isnan.(zi))
        @compat iinotnan=findall(.~isnan.(zi))
        zi[iinan].=0.

        nss=size(zi);
        ns=nss[1];
        sdim=div(ns,nas)/2; # the smoothing sigma is half large scale pixel wide 

        mask=zeros(ns,ns);
        for i=1:ns
           for j=1:ns
               kx=i-1;
               ky=j-1;
               if(i>ns/2+1)
                  kx=i-ns-1 ;
               end
               if(j>ns/2+1)
                  ky=j-ns-1 ;
               end
               r2=kx*kx+ky*ky;
               mask[i,j]=exp(-(r2/(sdim*sdim))/2);
           end
        end 
        fm=fft(mask)
        zf=real(ifft(fm.*fft(zi)))/sum(mask)
        if length(iinan)>0
           zi1=deepcopy(zi)
           zi1[iinotnan].=1.0
           zf=zf./(real(ifft(fm.*fft(zi1)))/sum(mask))
        end
	zf[iinan].=NaN
        return zf
   end
