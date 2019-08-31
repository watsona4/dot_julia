using CompScienceMeshes
using SauterSchwabQuadrature



pI = point(1,5,3)
pII = point(2,5,3)
pIII = point(7,1,0)
pIV = point(5,1,-3)
pV = point(0,0,0)

Sourcechart = simplex(pI,pIII,pII)
Testchart = simplex(pV,pIV,pI)

Accuracy = 12


function integrand(x,y)
			return(((x-pI)'*(y-pV))*exp(-im*1*norm(x-y))/(4pi*norm(x-y)))
 end



result = sauterschwabintegral(Sourcechart, Testchart, integrand, Accuracy, Accuracy)
println(result)

#=For those who want to test the sauterschwab_nonparameterized() function,
may uncomment the following five lines=#

#sourcechart = simplex(pI,pIII,pII)
#testchart = simplex(pI,pIV,pV)
#cv = CommonVertex(Accuracy)
#result2 = sauterschwab_nonparameterized(sourcechart, testchart, integrand, cv)
#println(result2)

#=The common vertex is the first input argument of both simplex() functions,
hence the required condition is fulfilled. The user may also compare the two
results and see that both are equal=#
