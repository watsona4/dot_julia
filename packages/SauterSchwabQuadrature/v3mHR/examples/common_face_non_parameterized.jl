using CompScienceMeshes
using SauterSchwabQuadrature



pI = point(1,5,3)
pII = point(2,5,3)
pIII = point(7,1,0)

Sourcechart = simplex(pI, pII, pIII)
Testchart = simplex(pII, pIII, pI)

Accuracy = 12

function integrand(x,y)
			return(((x-pI)'*(y-pII))*exp(-im*1*norm(x-y))/(4pi*norm(x-y)))
end




result = sauterschwabintegral(Sourcechart, Testchart, integrand, Accuracy, Accuracy)
println(result)

#=For those who want to test the sauterschwab_nonparameterized() function,
may uncomment the following five lines=#

#sourcechart = simplex(pI,pII,pIII)
#testchart = simplex(pI,pII,pIII)
#cf = CommonFace(Accuracy)
#result2 = sauterschwab_nonparameterized(sourcechart, testchart, integrand, cf)
#println(result2)

#=sourcechart = testchart, hence the required condition is fulfilled.
The user may also compare the two results and see that both are equal=#
