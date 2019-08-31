using CompScienceMeshes
using SauterSchwabQuadrature


Accuracy = 12
pd = PositiveDistance(Accuracy)
pI = point(0,0,-1)
pII = point(0,0,1)


function integrand(x,y)
			return(((x-pI)'*(y-pII))*exp(-im*1*norm(x-y))/(4pi*norm(x-y)))
end


function Sc(û)
	u = [(pi/2)*û[1]/(1-û[2]) , û[2]]	#mapping from referencetriangle to rectangle
	return(u)
end


function Tc(v̂)
	v = [v̂[1]/(1-v̂[2]), v̂[2]]			#mapping from referencetriangle to square
	return(v)
end


function INTEGRAND(û,v̂)

	ϴ = Sc(û)[1] + pi/2
	ϕ = Sc(û)[2]
	ϴ1= Tc(v̂)[1]
	ϕ1= Tc(v̂)[2]

	x = [sin(ϴ)*cos(ϕ),   sin(ϴ)*sin(ϕ),   cos(ϴ) ]		#spherical coordinates
	y = [sin(ϴ1)*cos(ϕ1), sin(ϴ1)*sin(ϕ1), cos(ϴ1)]		#spherical coordiantes

	output = integrand(x,y) * sin(ϴ)*sin(ϴ1) * (pi/2)*(1/(1-û[2]))*(1/(1-v̂[2]))
	#sin(ϴ)*sin(ϴ1) = surface element of spherical coordinates
	#(pi/2)*(1/(1-û[2]))*(1/(1-v̂[2])) = surface element of first two mappings

return(output)

end


result = sauterschwab_parameterized(INTEGRAND, pd)


println(result)
