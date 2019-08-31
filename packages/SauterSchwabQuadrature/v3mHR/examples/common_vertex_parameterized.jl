using CompScienceMeshes
using SauterSchwabQuadrature


Accuracy = 12
cv = CommonVertex(Accuracy)
pI = point(0,0,1)


function integrand(x,y)
			return(((x-pI)'*(y-pI))*exp(-im*1*norm(x-y))/(4pi*norm(x-y)))
end


function Sc(û)
	u = [û[1]/(1-û[2]), û[2]]	#mapping from referencetriangle to square
	return(u)
end


function Tc(v̂)
	v = [v̂[1]/(1-v̂[2]), v̂[2]]	#mapping from referencetriangle to square
	return(v)
end


function INTEGRAND(û,v̂)

	ϴ = Sc(û)[1]
	ϕ = Sc(û)[2]
	ϴ1= Tc(v̂)[1]
	ϕ1= Tc(v̂)[2] + 1.5

	x = [sin(ϴ)*cos(ϕ),   sin(ϴ)*sin(ϕ),   cos(ϴ)]		#spherical coordiantes
	y = [sin(ϴ1)*cos(ϕ1), sin(ϴ1)*sin(ϕ1), cos(ϴ1)]		#spherical coordinates

	output = integrand(x,y) * sin(ϴ)*sin(ϴ1) * (1/(1-û[2]))*(1/(1-v̂[2]))
	#sin(ϴ)*sin(ϴ1) = surface element of spherical coordinates
	#(1/(1-û[2]))*(1/(1-v̂[2]) = surface element of first two mappings

return(output)

end


result = sauterschwab_parameterized(INTEGRAND, cv)


println(result)
