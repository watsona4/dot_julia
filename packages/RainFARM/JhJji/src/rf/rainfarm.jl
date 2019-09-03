"""
    rainfarm(r,slope,nf,weight=1.;fglob=false, fsmooth=false, verbose=false)

Perform general RainFARM downscaling.

#Arguments
* `r`      : large-scale array to downscale
* `slope`  : spatial spectral slope
* `nf`     : refinement factor for spatial downscaling
* `weight` : weights for orographic downscaling
* `fglob`  : conserve global average over domain
* `fsmooth`: use smoothing instead of gp conservation
* `verbose`: provide some progress report 
"""
function rainfarm(r, slope, nf, weight=1.; fglob=false, fsmooth=false, verbose=false)

(nax,nay,ntime)=size(r[:,:,:]);

if( nax==nay)
   nas=nax
else
   error("The spatial dimensions of r(nax,nay,nat) must be square (nax==nay)")
end

ns=nas*nf
nt=1; nat=1; 
# This is the space_only version, downscaling nt is 1
#(ns, ns1)=size(lon); ns=max(ns,ns1); 
#ns=size(lon); ns=ns[1]; 
#Recover ns (the fine scale res) from lon; we assume that RF works on squares, nlon=nlat
f=initmetagauss(slope,1,ns,1);
rd=zeros(ns,ns,ntime);

  for k=1:ntime
    r1=r[:,:,k];    
    if verbose
@compat       @printf("Frame %d\r",k)
    end
    if Statistics.mean(r1)==0
	rd[:,:,k]=zeros(ns,ns);
    else	
   	fm=downscale_spaceonly(r1,f,weight,fglob=fglob,fsmooth=fsmooth);
	rd[:,:,k]=fm;
    end
  end
  return rd
end


