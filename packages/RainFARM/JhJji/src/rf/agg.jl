"""
    za = agg(z,nas,nat)

Aggregate field `z` to an array `za` of size `(nas,nas,nat)`
"""
function agg(zi,nas,nat)
        nss=size(zi);
        if(length(nss)>=3)
           ns=nss[1]; nt=nss[3];
        else
           ns=nss[1]; nt=1;
        end
        sdim=div(ns,nas);
        tdim=div(nt,nat);
        ir=1:sdim; jr=ir; kr=1:tdim;
        rs=0:sdim:(ns-sdim);
        rt=0:tdim:(nt-tdim);
	z=zeros(Float64,nas,nas,nat);
        n=zeros(Int64,nas,nas,nat);
        for i=1:sdim
           for j=1:sdim
              for k=1:tdim
		 n=n+.~isnan.(zi[i.+rs,j.+rs,k.+rt]);
		 z=z+zi[i.+rs,j.+rs,k.+rt].*.~isnan.(zi[i.+rs,j.+rs,k.+rt]) ;
              end
           end
        end
        z=z./n;
end

