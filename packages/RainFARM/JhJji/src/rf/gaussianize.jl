"""
    g = gaussianize(z)

Gaussianize field `z` using a sorted random sequence.
"""
function gaussianize(z)

(m,n)=size(z);
nn=m*n;
zr=z[:];
zs=sort(zr);
i=sortperm(zr);
rrk=zeros(Int16,nn,1);
rrk[i]=collect(1:nn);
gg=randn(nn);
w=sort(gg);
gr=w[rrk];
gs=Statistics.std(gr);
if gs==0
        gs=1;
end
gr=gr/gs;
g=reshape(gr,m,n);
end
