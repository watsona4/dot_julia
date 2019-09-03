"""
    zi = interpola(z,ns,nt)

Interpolate field `z` to size `(ns,ns,nt)` using nearest neighbors.
"""
	function interpola(z,ns,nt)
       
        nss=size(z);
        if(length(nss)>=3) 
            nas=nss[1]; nat=nss[3];
        else
            nas=nss[1]; nat=1;
        end

	sdim=div(ns,nas);
	tdim=div(nt,nat);
	ir=1:sdim; jr=ir; kr=1:tdim;
	rs=0:sdim:(ns-sdim);
	rt=0:tdim:(nt-tdim);
	zi=zeros(ns,ns,nt);
	for i=1:sdim
	 for j=1:sdim
	  for k=1:tdim
		zi[i.+rs,j.+rs,k.+rt]=z;
	  end
	 end
	end

        return zi
        end


