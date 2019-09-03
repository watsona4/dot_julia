"""
    fr = metagauss(f)

Generate a metagaussian field multiplying the spectralfield `f` with random phases and performing an inverse FFT transform to real space.
"""
	function metagauss(f);

        (ns,ns,nt)=size(f);
#	phases as fft of a gaussian noise random field
#        ph=zeros(ns,ns,nt,'single');

        ph=zeros(ns,ns,nt);
        for i=1:nt; ph[:,:,i]=(randn(ns,ns)); end;
	ph=fft(ph);  
	ph=ph./abs.(ph); ph[1,1,1]=0;
	ph=f.*ph;
	ph=real(ifft(ph)); 
end
