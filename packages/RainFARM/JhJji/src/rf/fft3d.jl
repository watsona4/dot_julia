"""
    (fx,ft)=fft3d(z)

Compute spatial (`fx`) and temporal (`ft`) Fourier spectra of field `z`.
"""
        function fft3d(z)

@static        if VERSION < v"0.7.0-DEV.2005"
           function sum(a;dims=1)
              return Base.sum(a,dims);
           end
        end

#       function [fx,fy,ft]=fft3d(ss);
        nss=size(z); ns=nss[1]; 
        if(length(nss)>=3) 
            nt=nss[3]
	else
	    nt=1 
        end
 
        ns2=div(ns,2); 
        nt2=div(nt,2);
        if((nt>1)&&(mod(nt,2)!=0))
            z=z[:,:,1:(nt-1)];
            nt=nt-1;
        end

        zf=abs.(fft(z)/(ns*ns*nt)).^2;
        zf0=zf;
        zf[ns2+1,:,:]=zf0[ns2+1,:,:]/2;
        zf[:,ns2+1,:]=zf0[:,ns2+1,:]/2;
        if(nt>1)
          zf[:,:,nt2+1]=zf0[:,:,nt2+1]/2;
        end

@compat        fs=reshape(sum(zf,dims=3),ns,ns);
@compat        ft=reshape(sum(sum(zf,dims=1),dims=2),nt,1);

        fs=fftshift(fs) ;
        fs=fs/nt;

        nn=zeros(ns,1);
        fx=zeros(ns,1);
        for j=-ns2:ns2-1
           for i=-ns2:ns2-1
              k2=sqrt(i*i+j*j);
              ik2=floor(Integer,k2+1.5);
              if(ik2>1)
                fx[ik2]=fx[ik2]+fs[i+ns2+1,j+ns2+1];
                nn[ik2]=nn[ik2]+1;
              end
           end
        end
    if(nt>1)
        ft=ft[2:nt2+1];
    end
   fx=fx[2:ns2+1]./nn[2:ns2+1];
   return (fx,ft,fs)
   end
