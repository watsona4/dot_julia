function getDCResistivitySourcesAndRecAll(n,Mesh;srcSpacing::Vector=[1,1],srcPad::Vector=[4,4],
	                                                               wPad=2,offset=12,offsetRec=1)

	offset    = 12	
	offsetRec = 1
	i1  =  srcPad[1]+offset:srcSpacing[1]:n[1]-srcPad[2]-offset
	i2  =  srcPad[3]+offset:srcSpacing[2]:n[2]-srcPad[4]-offset
	nsrc = 2*length(i1)*length(i2)
	
	println("number of sources =",nsrc)
	nrec = 4
	# generate pFors for x1 dipoles
	Wd   = Array{Array}(nsrc)
	Sources   = spzeros(prod(Mesh.n+1),nsrc)
	
	
	# Sources
	cnt = 1
	# x-direction source dipoles
	for i=i1
		for j=i2
        	# source
			S                  = zeros(tuple(n+1...));
			S[i-offset,j,1]  = -1;
        	S[i+offset,j,1]  =  1;
			Sources[:,cnt]     = sparse(vec(S))
			cnt +=1
		end
	end
	
	# y direction dipoles sources
	for i=i1
		for j=i2
	        	# source
			S              = zeros(tuple(n+1...));
			S[i,j-offset,1]     = -1;
	      S[i,j+offset,1]   =  1;
	      Sources[:,cnt] = sparse(vec(S))
			cnt +=1
		end
	end
	
	
	###### Receivers
	# x-direction receiver dipoles
	i1  =  srcPad[1]+offsetRec:1:n[1]-srcPad[2]-offsetRec
	i2  =  srcPad[3]+offsetRec:1:n[2]-srcPad[4]-offsetRec
	
	Receivers = spzeros(prod(Mesh.n+1),2*length(i1)*length(i2))

	
	cnt = 1
	for i=i1
		for j=i2
        	# source
			S                  = zeros(tuple(n+1...));
			S[i-offsetRec,j,1]  = -1;
        	S[i+offsetRec,j,1]  =  1;
			Receivers[:,cnt]     = sparse(vec(S))
			cnt +=1
			
		end
	end
	
	# y direction dipoles
	for i=i1
		for j=i2
	        	# source
			S              = zeros(tuple(n+1...));
			S[i,j-offsetRec,1]     = -1;
	      S[i,j+offsetRec,1]   =  1;
	      Receivers[:,cnt] = sparse(vec(S))
			cnt +=1
			
		end
	end
	
	Wd = ones(nsrc,nsrc)*1e-3
	
	
	
	return Sources,Receivers,Wd
end