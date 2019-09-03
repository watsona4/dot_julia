"""
    fm = mergespec_spaceonly(ra,f,kmax)

Spectral merging of coarse field `ra` and fine field `f` at wavenumber `kmax`.
"""
function mergespec_spaceonly(ra,f,kmax)

(nx,ny)=size(f);
(nax,nay)=size(ra);

DFTr=zeros(Complex{Float64},nax,nax);
DFTf=zeros(Complex{Float64},nx,nx);

#fft di tutto il campo f
DFTf=fft(f)
   
#fft di tutto il campo r
DFTr=fft(ra);

DFTr=fftshift(DFTr); #centro la fft
DFTf=fftshift(DFTf); #centro la fft
DFTfm=zeros(Complex{Float64},nx,nx);
DFTr2=zeros(Complex{Float64},nax+1,nax+1);

#DFTr[nax+1,:,:]=NaN;
#DFTr[:,nax+1,:]=NaN;
DFTr2[1:nax,1:nax]=DFTr[:,:]
DFTr2[nax+1,1:nax]=conj(DFTr[1,:]);
DFTr2[1:nax,nax+1]=conj(DFTr[:,1]);

kmax2=kmax^2;

# We need to fix the phases of the large scale field!
# The first pixel of the large field is centered in dxl/2 with dxl=2pi/nax
# The first pixel of the fine field is centered in dxs/2 with dxf=2pi/nax
ddx=2*pi/nax/2-2*pi/nx/2;

 for j=1:nx
     for i=1:nx
            kx=-div(nx,2)+i-1;
            ky=-div(nx,2)+j-1;
            k2=(kx^2+ky^2); 
            ir=div(nax,2)+1+kx;
            jr=div(nax,2)+1+ky;
            if(k2<=kmax2)
                DFTfm[i,j]=DFTr2[ir,jr]*exp(-1im*ddx*kx-1im*ddx*ky);;
            else
                DFTfm[i,j]=DFTf[i,j];
            end
     end
end

DFTfm=ifftshift(DFTfm);
fm=ifft(DFTfm);
fm=real(fm);

end
