using CompScienceMeshes
using SauterSchwabQuadrature



pI = point(1,5,3)
pII = point(2,5,3)
pIII = point(7,1,0)
pVI = point(10,11,12)
pVII = point(10,11,13)
pVIII = point(11,11,12)

Sourcechart = simplex(pI,pII,pIII)
Testchart = simplex(pVIII,pVII,pVI)

Accuracy = 12


function integrand(x,y)
			return(((x-pI)'*(y-pVII))*exp(-im*1*norm(x-y))/(4pi*norm(x-y)))
end



result = sauterschwabintegral(Sourcechart, Testchart, integrand, Accuracy, Accuracy)
println(result)

#=For those who want to test the sauterschwab_nonparameterized() function,
may uncomment the following three lines=#

#pd = PositiveDistance(Accuracy)
#result2 = sauterschwab_nonparameterized(Sourcechart, Testchart, integrand, pd)
#println(result2)

#=In this case the two charts from above can be used and the order of the points
within the simplex() fucntions can be changed arbitrarily. The user may also
compare the two results and see that both are equal.=#
