using RainFARM, Compat
using Compat.Statistics
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

# write your own tests here

print("Testing main RainFARM function and aggregation:\n")
print("-----------------------------------------------\n")
nt=2; nf=8; ns=64; nas=8; 
prf=rand(ns,ns,nt);
prf[2,2,1]=NaN;
prl=agg(prf,nas,nt);
ww=ones(64,64);
print("Testing fglob=false, fsmooth=false\n")
pr=rainfarm(prl,1.7,nf,1.;fglob=false, fsmooth=false, verbose=false);
pra=agg(pr,nas,nt);
eps1=Statistics.mean((pra-prl).^2);
@test eps1 < 1e-20
print("Testing fglob=true, fsmooth=false, weights\n")
pr=rainfarm(prl,1.7,nf,ww;fglob=true, fsmooth=false, verbose=false);
pra=agg(pr,nas,nt);
eps1=(Statistics.mean(pra[:,:,1])-Statistics.mean(prl[:,:,1])).^2;
@test eps1 < 1e-20
print("Testing fglob=false, fsmooth=true\n")
pr=rainfarm(prl,1.7,nf,1.;fglob=false, fsmooth=true, verbose=false);
pra=agg(pr,nas,nt);
eps1=(Statistics.mean(pra[:,:,1])-Statistics.mean(prl[:,:,1])).^2;
@test eps1 < 0.005
print("\nTesting auxiliary functions:\n")
print("----------------------------\n")
print("Testing fitslopex\n")
fx=(1.:10.).^-2;
sx=fitslopex(fx);
eps1=abs(sx-1);
@test eps1 < 1e-8
print("Testing lon_lat_fine\n")
lon=0:7; lat=0:7; nf=2;
(lon_f,lat_f) = lon_lat_fine(lon, lat,nf)
lon_c=collect(-0.25:0.5:7.25);
eps1=sum((lon_c-lon_f).^2)
@test eps1 < 1e-20
