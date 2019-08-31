using CompScienceMeshes
using SauterSchwabQuadrature



pI = point(1,5,3)
pII = point(2,5,3)
pIII = point(7,1,0)
pIV = point(5,1,-3)

Sourcechart = simplex(pII,pI,pIII)
Testchart = simplex(pII,pI,pIV)

Accuracy = 12




function integrand(x,y)
			return(((x-pI)'*(y-pII))*exp(-im*1*norm(x-y))/(4pi*norm(x-y)))
end






result = sauterschwabintegral(Sourcechart, Testchart, integrand, Accuracy, Accuracy)
println(result)

#=For those who want to test the sauterschwab_nonparameterized() function,
may uncomment the following five lines=#

#sourcechart = simplex(pI,pIII,pII)
#testchart = simplex(pI,pIV,pII)
#ce = CommonEdge(Accuracy)
#result2 = sauterschwab_nonparameterized(sourcechart, testchart, integrand, ce)
#println(result2)

#=The first argument and the third argument of both simplex() functions are
equal, hence the required conditions are fulfilled. The user may also compare
the two results, and see that both are equal=#
