using SubMatrixSelectionSVD
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end


@testset "Basic Tests" begin
	X = randn(10,7)

	U,Σ,V,ps,signalDimensions,selectedVariables = smssvd(X,4,10 .^ range(-2,stop=0,length=5),nbrIter=2)
	@test size(U)==(10,4)
	@test size(Σ)==(4,)
	@test size(V)==(7,4)
	@test size(ps)==(4,5)
	@test length(signalDimensions)<=4
	@test sum(signalDimensions)==4
	@test all(x->size(x)==(10,), selectedVariables)

	U,Σ,V,ps,signalDimensions,selectedVariables = smssvd(X,7,10 .^ range(-2,stop=0,length=5),nbrIter=2)
	@test size(U)==(10,7)
	@test size(Σ)==(7,)
	@test size(V)==(7,7)
	@test size(ps)==(7,5)
	@test length(signalDimensions)<=7
	@test sum(signalDimensions)==7
	@test all(x->size(x)==(10,), selectedVariables)


	X = randn(7,10)

	U,Σ,V,ps,signalDimensions,selectedVariables = smssvd(X,4,10 .^ range(-2,stop=0,length=5),nbrIter=2)
	@test size(U)==(7,4)
	@test size(Σ)==(4,)
	@test size(V)==(10,4)
	@test size(ps)==(4,5)
	@test length(signalDimensions)<=4
	@test sum(signalDimensions)==4
	@test all(x->size(x)==(7,), selectedVariables)

	U,Σ,V,ps,signalDimensions,selectedVariables = smssvd(X,7,10 .^ range(-2,stop=0,length=5),nbrIter=2)
	@test size(U)==(7,7)
	@test size(Σ)==(7,)
	@test size(V)==(10,7)
	@test size(ps)==(7,5)
	@test length(signalDimensions)<=7
	@test sum(signalDimensions)==7
	@test all(x->size(x)==(7,), selectedVariables)
end
