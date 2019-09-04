"""
function getDCResistivitySourcesAndRecAll
	
sets up dipole sources for DC resistivity survey. Sources and receivers
are spaced equidistantly on nodes of top x1-x2 surface of 3D cube with Mesh.n 
cells. 
Sources are dipoles of width 2*offset and are placed in x1 and x2 direction. 
Receivers (with much shorter width) are placed on entire domain and measure
potential differences in x1 and x2 direction.
	
Input:

	Mesh - mesh for forward problem
	
Optional Inputs:

	srcSpacing - spacing between sources      (default=[2,2])
	srcPad     - padding from boundary        (default=[2,2])
	offset     - half the length of sources   (default=12)
	offsetRec  - half the length of receivers (default-1)
	
Outputs:

	Sources    - discretized sources
	Receivers  - discretized receivers
"""
function getDCResistivitySourcesAndRecAll(Mesh;srcSpacing::Vector=[2,2],srcPad::Vector=[4,4,4,4],
	                                                               offset=12,offsetRec=1)

	n    = Mesh.n
	i1   =  srcPad[1]+offset:srcSpacing[1]:n[1]-srcPad[2]-offset
	i2   =  srcPad[3]+offset:srcSpacing[2]:n[2]-srcPad[4]-offset
	nsrc = 2*length(i1)*length(i2)
	
	
	println("--- generate $nsrc sources ---")
	Sources   = spzeros(prod(Mesh.n+1),nsrc)
	cnt = 1
	# x1-direction source dipoles
	for i=i1
		for j=i2
			# source
			S                  = zeros(tuple(n+1...))
			S[i-offset,j,1]  = -1
			S[i+offset,j,1]  =  1
			Sources[:,cnt]     = sparse(vec(S))
			cnt +=1
		end
	end
	# y2 direction dipoles sources
	for i=i1
		for j=i2
			S               = zeros(tuple(n+1...))
			S[i,j-offset,1] = -1
			S[i,j+offset,1] =  1
			Sources[:,cnt]  = sparse(vec(S))
			cnt +=1
		end
	end
	
	
	i1   =  srcPad[1]+offsetRec:1:n[1]-srcPad[2]-offsetRec
	i2   =  srcPad[3]+offsetRec:1:n[2]-srcPad[4]-offsetRec
	nrec = 2*length(i1)*length(i2)
	
	println("--- generate $nrec receivers ---")
	# x1-direction receiver dipoles
	Receivers = Sources;
	return Sources,Receivers
end