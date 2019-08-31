using ApproxFunFourier, ApproxFunBase, Test, BlockArrays, BlockBandedMatrices, SpecialFunctions, LinearAlgebra
    import ApproxFunBase: testspace, testtransforms, testmultiplication,
                      testbandedoperator, testblockbandedoperator, testbandedblockbandedoperator, testcalculus, Block, Vec, testfunctional
    import SpecialFunctions: factorial

@testset "Periodic Domains" begin    
    @test 0.1 ∈ PeriodicSegment(2π,0)
    @test 100.0 ∈ PeriodicSegment(0,2π)
    @test -100.0 ∈ PeriodicSegment(0,2π)

    @test 10.0 ∈ PeriodicLine()
    @test -10.0 ∈ PeriodicLine()
    @test -10.0+im ∉ PeriodicLine()

    @test ApproxFunBase.Vec(0,0.5) ∈ PeriodicSegment(ApproxFunBase.Vec(0.0,0), ApproxFunBase.Vec(0,1))

    @test ApproxFunBase.Vec(1,0) ∈ Circle((0.,0.),1.)
end

@testset "Cos/SinSpace" begin
    for d in (PeriodicSegment(0.1,0.5),Circle(1.0+im,2.0))
        testtransforms(CosSpace(d);minpoints=2)
        testtransforms(SinSpace(d))
    end
    @test sum(Fun(1,CosSpace())) ≈ 2π
    @test sum(Fun(SinSpace(),[1])) == 0

    f=Fun(t->cos(t)+cos(3t),CosSpace)
    @test f(0.1) ≈ cos(0.1)+cos(3*0.1)
    @test (f*f-Fun(t->(cos(t)+cos(3t))^2,CosSpace)).coefficients|>norm <100eps()

    ## Calculus
    f=Fun(t->cos(t),CosSpace)
    D=Derivative(space(f))
    @test (D*f)(.1) ≈ -sin(.1)
    @test f'(.1) ≈ -sin(.1)

    f=Fun(t->sin(t),SinSpace)
    D=Derivative(space(f))
    @test (D*f)(.1) ≈ cos(.1)
    @test f'(.1) ≈ cos(.1)


    ## Multiplication
    s=Fun(t->(sin(t)+sin(2t))*cos(sin(t)),SinSpace)
    b=Fun(t->(sin(t)+sin(3t)),SinSpace)

    @test (s*s)(.1) ≈ s(.1)^2
    @test (s*b)(.1) ≈ s(.1)*b(.1)

    s=Fun(t->(cos(t)+cos(2t))*cos(cos(t)),CosSpace)
    b=Fun(t->(1+cos(t)+cos(3t)),CosSpace)

    @test (s*s)(.1) ≈ s(.1)^2
    @test (s*b)(.1) ≈ s(.1)*b(.1)

    s=Fun(t->(cos(t)+cos(2t))*cos(cos(t)),CosSpace)
    b=Fun(t->(sin(t)+sin(3t)),SinSpace)

    @test (s*b)(.1) ≈ s(.1)*b(.1)


    s=Fun(t->(sin(t)+sin(2t))*cos(sin(t)),SinSpace)
    b=Fun(t->(1+cos(t)+cos(3t)),CosSpace)

    @test (s*b)(.1) ≈ s(.1)*b(.1)

    ##  Norms
    @test sum(Fun(CosSpace(),[1.]))/(2π) ≈ 1.
    @test sum(Fun(CosSpace(),[0.,1.])^2)/(2π) ≈ 0.5
    @test sum(Fun(CosSpace(),[0.,0.,1.])^2)/(2π) ≈ 0.5
    @test sum(Fun(CosSpace(),[0.,0.,0.,1.])^2)/(2π) ≈ 0.5


    @test sum(Fun(SinSpace(),[0.,1.])^2)/(2π) ≈ 0.5
    @test sum(Fun(SinSpace(),[0.,0.,1.])^2)/(2π) ≈ 0.5
    @test sum(Fun(SinSpace(),[0.,0.,0.,1.])^2)/(2π) ≈ 0.5

    ## Bug in multiplicaiton
    @test Fun(SinSpace(),Float64[])^2 == Fun(SinSpace(),Float64[])
end


@testset "Taylor/Hardy" begin
    for d in (PeriodicSegment(0.1,0.5),Circle(1.0+im,2.0))
        testtransforms(Taylor(d))
        testtransforms(Hardy{false}(d))
    end
    f=Fun(exp,Taylor(Circle()))
    @test f(exp(0.1im)) ≈ exp(exp(0.1im))
    @test f(1.0) ≈ exp(1.0)
    g=Fun(z->1/(z-0.1),Hardy{false}(Circle()))
    @test (f(1.)+g(1.)) ≈ (exp(1.) + 1/(1-.1))

    @test Fun(Taylor())  == Fun(Taylor(),[0.,1.])

    @test Fun(Taylor())(1.0) ≈ 1.0
    @test Fun(Taylor(Circle(0.1,2.2)))(1.0) ≈ 1.0
    @test Fun(Taylor(Circle(0.1+0.1im,2.2)))(1.0) ≈ 1.0

    @test Multiplication(Fun(Taylor()),Taylor())[1:3,1:3] == [0. 0. 0.; 1. 0. 0.; 0. 1. 0.]   

    # check's Derivative constructor works
    D=Derivative(Taylor(PeriodicSegment()))
end

@testset "Fourier" begin
    for d in (PeriodicSegment(0.1,0.5),Circle(1.0+im,2.0))
        testspace(Laurent(d);hasintegral=false)
        testspace(Fourier(d);hasintegral=false)
    end

    P = ApproxFunBase.plan_transform(Fourier(),4)
    v = randn(4) .+ im.*randn(4)
    @test P*v == P*real(v) + im*(P*imag(v))

    @test norm(Fun(cos,Fourier)'+Fun(sin,Fourier)) < 100eps()

    f=Fun(x->exp(-10sin((x-.1)/2)^2),Fourier)
    @test real(f)(.1) ≈ f(.1)

    f=Fun(cos,Fourier)
    @test norm((Derivative(space(f))^2)*f+f)<100eps()

    a=Fun(t->exp(cos(t)+sin(t)),Fourier)
    b=Fun(t->sin(t)+cos(3t)+1,Fourier)

    @test (a*b)(.1) ≈ a(.1)*b(.1)

    a=Fun(t->exp(cos(t)),CosSpace)
    b=Fun(t->sin(t)+cos(3t)+1,Fourier)

    @test (a*b)(.1) ≈ a(.1)*b(.1)

    a=Fun(t->sin(sin(t)),SinSpace)
    b=Fun(t->sin(t)+cos(3t)+1,Fourier)

    @test (a*b)(.1) ≈ a(.1)*b(.1)

    @test Fun(Fourier(),[1.])^2 ≈ Fun(Fourier(),[1.])

    ## Conversion between reverse
    C = Conversion(SinSpace()⊕CosSpace(),Fourier())
    @test C[Block(1), Block(1)] ≈ [0 1; 1 0]
    @test ApproxFunBase.defaultgetindex(C, Block.(1:2), Block.(1:2)) isa AbstractMatrix
    testbandedoperator(C)

    ## Test Multiplication
    mySin = Fun(Fourier(),[0,1.0])
    A = Multiplication(mySin,Fourier())
    @test A.op[1,1] == 0

    mySin = Fun(Fourier(),[0,1])
    A = Multiplication(mySin,Fourier())
    @test A.op[1,1] == 0

    @test norm(ApproxFunBase.Reverse(Fourier())*Fun(t->cos(cos(t-0.2)-0.1),Fourier()) - Fun(t->cos(cos(-t-0.2)-0.1),Fourier())) < 10eps()
    @test norm(ApproxFunBase.ReverseOrientation(Fourier())*Fun(t->cos(cos(t-0.2)-0.1),Fourier()) - Fun(t->cos(cos(t-0.2)-0.1),Fourier(PeriodicSegment(2π,0)))) < 10eps()
end

@testset "Laurent" begin
    f=Fun(x->exp(-10sin((x-.1)/2)^2),Laurent)
    @test f(.5) ≈ (Conversion(space(f),Fourier(domain(f)))*f)(.5)
    @test f(.5) ≈ Fun(f,Fourier)(.5)

    @test Fun(Laurent(0..2π),[1,1.,1.])(0.1) ≈ 1+2cos(0.1)
    @test Fun(Laurent(-1..1),[1,1.,1.])(0.1) ≈ 1+2cos(π*(0.1+1))
    @test Fun(Laurent(0..1),[1,1.,1.])(0.1) ≈ 1+2cos(2π*0.1)

    @test norm(Fun(cos,Laurent)'+Fun(sin,Laurent)) < 100eps()

    B=Evaluation(Laurent(0..2π),0,1)
    @test B*Fun(sin,domainspace(B)) ≈ 1.0

    ## Diagonal Derivative
    D = Derivative(Laurent())
    @test isdiag(D)
end

@testset "Circle" begin
    Γ=Circle(1.1,2.2)
    z=Fun(Fourier(Γ))
    @test space(z)==Fourier(Γ)
    @test z(1.1+2.2exp(0.1im)) ≈ 1.1+2.2exp(0.1im)

    @test abs(Fun(cos,Circle())(exp(0.1im))-cos(exp(0.1im)))<100eps()
    @test abs(Fun(cos,Circle())'(exp(0.1im))+sin(exp(0.1im)))<100eps()
    @test abs(Fun(cos,Circle())'(exp(0.1im))+Fun(sin,Circle())(exp(0.1im)))<100eps()

    @test norm(Fun(cos,Circle())'+Fun(sin,Circle()))<100eps()

    f=Fun(exp,Circle())
    @test component(f,1)(exp(0.1im)) ≈ exp(exp(0.1im))
    @test f(exp(0.1im)) ≈ exp(exp(0.1im))
    @test norm(f'-f)<100eps()
    @test norm(integrate(f)+1-f)<100eps()

    @test (Fun(z->sin(z)*cos(1/z),Circle())*Fun(z->exp(z)*airyai(1/z),Circle()))(exp(.1im)) ≈
                (z->sin(z)*cos(1/z)*exp(z)*airyai(1/z))(exp(.1im))

    for d in (Circle(),Circle(0.5),Circle(-0.1,2.))
        S=Taylor(d)
        D=Derivative(S)
        ef=Fun(exp,S)
        @test norm((D*ef-ef).coefficients)<4000eps()
        @test norm((D^2*ef-ef).coefficients)<200000eps()
        u=[Evaluation(S,0.),D-I]\[1.;0.]
        @test norm((u-ef).coefficients)<200eps()
        @test norm((Integral(S)*Fun(exp,S)+ef.coefficients[1]-ef).coefficients)<100eps()
    
    
        f=Fun(z->exp(1/z)-1,Hardy{false}(d))
        df=Fun(z->-1/z^2*exp(1/z),Hardy{false}(d))
        @test norm((Derivative()*f-df).coefficients)<1000eps()
        @test norm((Derivative()^2*f-df').coefficients)<100000eps()
        @test norm((f'-df).coefficients)<1000eps()
    end      
      
    d=Circle()
    S=Taylor(d)
    D=Derivative(S)
    D-I
    ef=Fun(exp,S)
    @test norm((D*ef-ef).coefficients)<1000eps()
    @test norm((D^2*ef-ef).coefficients)<100000eps()
    u=[Evaluation(S,0.),D-I]\[1.;0.]

    # Check bug in off centre Circle
    c2=-0.1+.2im;r2=0.3;
    d2=Circle(c2,r2)
    z=Fun(identity,d2)

    @test z(-0.1+.2im+0.3*exp(0.1im)) ≈ (-0.1+.2im+0.3*exp(0.1im))

    # false Circle
    @test Fun(exp,Fourier(Circle(0.,1.,false)))(exp(0.1im)) ≈ exp(exp(.1im))
    @test Fun(exp,Laurent(Circle(0.,1.,false)))(exp(0.1im)) ≈ exp(exp(.1im))

    ## Reverse orientation
    f=Fun(z->1/z,Taylor(1/Circle()))
    @test f(exp(0.1im)) ≈ exp(-0.1im)

    ## exp(z)
    z=Fun(identity,Circle())
    cfs=exp(z).coefficients[1:2:end]
    for k=1:length(cfs)
        @test abs(cfs[k]-1/factorial(1.0(k-1))) ≤ 1E-10
    end

    ## Test bug in multiplication
    y = Fun(Circle())
    @test (y^2) ≈ Fun(z->z^2,domain(y))
end


@testset "Calculus" begin
    for f in (Fun(θ->sin(sin(θ)),SinSpace()),Fun(θ->cos(θ)+cos(3θ),CosSpace()),
                Fun(θ->sin(sin(θ)),Fourier()),Fun(θ->cos(θ)+cos(3θ),CosSpace()))
        @test norm(integrate(f)'-f)<10eps()
    end
end


@testset "Negatively oriented circles" begin
    f1 = Fun(z -> exp(1/z), Circle(0.0,0.2))
    f̃1 = Fun(z -> exp(1/z), Circle(0.0,0.2,false))
    f̃2 = Fun(z -> exp(1/z), Circle(0.0,0.3,false))

    @test f1(0.2exp(0.1im)) ≈ exp(1/(0.2exp(0.1im)))
    @test f̃1(0.2exp(0.1im)) ≈ exp(1/(0.2exp(0.1im)))
    @test f̃2(0.3exp(0.1im)) ≈ exp(1/(0.3exp(0.1im)))

    @test sum(f1) ≈ -sum(f̃1)
    @test sum(f̃1) ≈ sum(f̃2)
end


@testset "Fourier inplace" begin
    S = Fourier()

    x = [1.,2,3,4,5]
    y = similar(x)
    z = similar(x)
    P = ApproxFunBase.plan_transform(S, x)
    P! = ApproxFunBase.plan_transform!(S, x)
    mul!(y, P, x)
    @test x ≈ [1.,2,3,4,5]
    mul!(z, P!, x)
    @test x ≈ [1.,2,3,4,5]
    @test y ≈ z ≈ P*x ≈ P!*copy(x)

    P = ApproxFunBase.plan_itransform(S, x)
    P! = ApproxFunBase.plan_itransform!(S, x)
    mul!(y, P, x)
    @test x ≈ [1.,2,3,4,5]
    mul!(z, P!, x)
    @test x ≈ [1.,2,3,4,5]
    @test y ≈ z ≈ P*x ≈ P!*copy(x)
end


@testset "Vec circle" begin
    d=Circle((0.,0.),1.)
    f=Fun(xy->exp(-xy[1]-2cos(xy[2])),Fourier(d),40)
    @test f(cos(0.1),sin(0.1)) ≈ exp(-cos(0.1)-2cos(sin(0.1)))
    @test f(Vec(cos(0.1),sin(0.1))) ≈ exp(-cos(0.1)-2cos(sin(0.1)))

    f=Fun((x,y)->exp(-x-2cos(y)),Fourier(d),40)
    @test f(cos(0.1),sin(0.1)) ≈ exp(-cos(0.1)-2cos(sin(0.1)))


    f=Fun((x,y)->exp(-x-2cos(y)),Fourier(d))
    @test f(cos(0.1),sin(0.1)) ≈ exp(-cos(0.1)-2cos(sin(0.1)))
end

@testset "Operators" begin
    d=PeriodicSegment(0.,2π)
    a=Fun(t-> 1+sin(cos(10t)),d)
    D=Derivative(d)
    L=D+a

    @time testbandedoperator(D)
    @time testbandedoperator(Multiplication(a,Space(d)))


    f=Fun(t->exp(sin(t)),d)
    u=L\f

    @test norm(L*u-f) < 100eps()

    d=PeriodicSegment(0.,2π)
    a1=Fun(t->sin(cos(t/2)^2),d)
    a0=Fun(t->cos(12sin(t)),d)
    D=Derivative(d)
    L=D^2+a1*D+a0

    @time testbandedoperator(L)

    f=Fun(space(a1),[1,2,3,4,5])

    testbandedoperator(Multiplication(a0,Fourier(0..2π)))

    @test (Multiplication(a0,Fourier(0..2π))*f)(0.1)  ≈ (a0(0.1)*f(0.1))
    @test ((Multiplication(a1,Fourier(0..2π))*D)*f)(0.1)  ≈ (a1(0.1)*f'(0.1))
    @test (L.ops[1]*f)(0.1) ≈ f''(0.1)
    @test (L.ops[2]*f)(0.1) ≈ a1(0.1)*f'(0.1)
    @test (L.ops[3]*f)(0.1) ≈ a0(0.1)*f(0.1)
    @test (L*f)(0.1) ≈ f''(0.1)+a1(0.1)*f'(0.1)+a0(0.1)*f(0.1)

    f=Fun(t->exp(cos(2t)),d)
    u=L\f

    @test norm(L*u-f) < 1000eps()

    @time for M in (Multiplication(Fun(CosSpace(),[1.]),CosSpace()),
            Multiplication(Fun(CosSpace(),[1.]),SinSpace()),
            Multiplication(Fun(SinSpace(),[1.]),SinSpace()),
            Multiplication(Fun(SinSpace(),[1.]),CosSpace()),
            Derivative(SinSpace()),Derivative(CosSpace()))
        testbandedoperator(M)
    end
end

@testset "Integral equations" begin    
    @time for S in (Fourier(Circle()),Laurent(Circle()),Taylor(Circle()),CosSpace(Circle()))
        testfunctional(DefiniteLineIntegral(S))
    end

    Σ = DefiniteIntegral()
    f1 = Fun(t->cos(cos(t))/t,Laurent(Circle()))
    f2 = Fun(t->cos(cos(t))/t,Fourier(Circle()))
    @test Σ*f1 ≈ Σ*f2

    f1=Fun(t->cos(cos(t)),Laurent(-π..π))
    f2=Fun(t->cos(cos(t)),Fourier(-π..π))
    @test Σ*f1 ≈ Σ*f2
end

@testset "tensor of mult for Fourier #507" begin
    mySin = Fun(Fourier(),[0,1])
    A = Multiplication(mySin,Fourier())
    L = A ⊗ A
    @test L[1,1] == 0
end

@testset "Piecewise + Constant" begin
    Γ=Circle() ∪ Circle(0.0,0.4)
    o=ones(Γ)
    @test o(1.) ≈ 1.0
    @test o(0.4) ≈ 1.0

    @time G=Fun(z->in(z,component(Γ,2)) ? [1 0; -1/z 1] : [z 0; 0 1/z],Γ)
    @test (G-I)(exp(0.1im)) ≈ (G(exp(0.1im))-I)
end

@testset "Array" begin
    @testset "Fourier Vector" begin
        a = [1 2; 3 4]
        f = Fun(θ->[sin(θ),sin(2θ)],Fourier())
        @test (a*f)(0.1) ≈ a*f(0.1)
        @test Fun(a)*f ≈ a*f
        @test Fun(a*Array(f)) ≈ a*f
        @test norm(f) ≈ sqrt(2π)
        @test norm(f,2) ≈ sqrt(2π)
    end

    @testset "CosSpace Vector" begin
        a = [1 2; 3 4]
        f = Fun(θ->[1,cos(θ)],CosSpace())
        @test (a*f)(0.1) ≈ [1+2cos(0.1); 3+4cos(0.1)]
        @test (a*f)(0.1) ≈ a*f(0.1)
        @test Fun(a)*f ≈ a*f
        @test Fun(a*Array(f)) ≈ a*f
    end

    @testset "CosSpace Matrix" begin
        a = [1 2; 3 4]
        m = Fun(θ->[1 cos(θ); cos(2θ) cos(cos(θ))],CosSpace())
        @test (a*m)(0.1) ≈ a*m(0.1)
        @test (m*a)(0.1) ≈ m(0.1)*a
        @test Fun(a)*m   ≈ a*m
        @test Fun(a*Array(m))   ≈ a*m

        @test (a+m)(0.1) ≈ a+m(0.1)
        @test (m+a)(0.1) ≈ m(0.1)+a

        @test (m+I)(0.1) ≈ m(0.1)+I
    end

    @testset "SinSpace Vector" begin
        a = [1 2; 3 4]
        f = Fun(θ->[sin(θ),sin(2θ)],SinSpace())
        @test (a*f)(0.1) ≈ a*f(0.1)
        @test Fun(a)*f ≈ a*f
        @test Fun(a*Array(f)) ≈ a*f

        @test all(sp -> sp isa SinSpace, space(a*f).spaces)
    end

    @testset "CosSpace Matrix" begin
        a = [1 2; 3 4]
        m = Fun(θ->[sin(3θ) sin(θ); sin(2θ) sin(sin(θ))],SinSpace())
        @test (a*m)(0.1) ≈ a*m(0.1)
        @test (m*a)(0.1) ≈ m(0.1)*a
        @test Fun(a)*m   ≈ a*m
        @test Fun(a*Array(m))   ≈ a*m

        @test all(sp -> sp isa SinSpace, space(a*m).spaces)

        @test (a+m)(0.1) ≈ a+m(0.1)
        @test (m+a)(0.1) ≈ m(0.1)+a

        @test (m+I)(0.1) ≈ m(0.1)+I
    end

        @testset "Two circles" begin
        Γ = Circle() ∪ Circle(0.5)

        f = Fun(z -> in(z,component(Γ,2)) ? 1 : z,Γ)
        @test f(exp(0.1im)) ≈ exp(0.1im)
        @test f(0.5exp(0.1im)) ≈ 1

        G = Fun(z -> in(z,component(Γ,2)) ? [1 -z^(-1); 0 1] :
                                            [z 0; 0 z^(-1)], Γ);

        @test G(exp(0.1im)) ≈ [exp(0.1im) 0 ; 0 exp(-0.1im)]
        @test G(0.5exp(0.1im)) ≈ [1 -2exp(-0.1im) ; 0 1]

        G1=Fun(Array(G)[:,1])

        @test G1(exp(0.1im)) ≈ [exp(0.1im),0.]
        @test G1(0.5exp(0.1im)) ≈ [1,0.]

        M = Multiplication(G, space(G1))
        testblockbandedoperator(M)

        for z in (0.5exp(0.1im),exp(0.2im))
            @test G[1,1](z) ≈ G[1](z)
            @test (M.op.ops[1,1]*G1[1])(z) ≈ M.f[1,1](z)*G1[1](z)
            @test (M.op.ops[2,1]*G1[1])(z) ≈ M.f[2,1](z)*G1[1](z)
            @test (M.op.ops[1,2]*G1[2])(z) ≈ M.f[1,2](z)*G1[2](z)
            @test (M.op.ops[2,2]*G1[2])(z) ≈ M.f[2,2](z)*G1[2](z)
        end

        u = M*G1
        @test norm(u(exp(.1im))-[exp(.2im),0])<100eps()
        @test norm(u(.5exp(.1im))-[1,0])<100eps()
    end

    @testset "Circle" begin
        G = Fun(z->[-1 -3; -3 -1]/z +
                   [ 2  2;  1 -3] +
                   [ 2 -1;  1  2]*z, Circle())

        @test G[1,1](exp(0.1im)) == G(exp(0.1im))[1,1]

        F̃ = Array((G-I)[:,1])
        F = (G-I)[:,1]

        @test Fun(F) ≡ F

        @test F(exp(0.1im)) ≈ [-exp(-0.1im)+1+2exp(0.1im);-3exp(-0.1im)+1+1exp(0.1im)]
        @test Fun(F̃,space(F))(exp(0.1im)) ≈ [-exp(-0.1im)+1+2exp(0.1im);-3exp(-0.1im)+1+1exp(0.1im)]

        @test coefficients(F̃,space(F)) == F.coefficients
        @test Fun(F̃,space(F)) == F

        @test F == Fun(vec(F),space(F))

        @test inv(G(exp(0.1im))) ≈ inv(G)(exp(0.1im))

        @test Fun(Matrix(I,2,2),space(G))(exp(0.1im)) ≈ Matrix(I,2,2)
        @test Fun(I,space(G))(exp(0.1im)) ≈ Matrix(I,2,2)
    end
end

@testset "Taylor()^2, checks bug in type of plan_transform" begin
    f = Fun((x,y)->exp((x-0.1)*cos(y-0.2)),Taylor()^2)
    @test f(0.2,0.3) ≈ exp(0.1*cos(0.1))
end

@testset "Periodic Poisson" begin
    d=PeriodicSegment()^2
    S=Space(d)

    f=Fun((x,y)->exp(-10(sin(x/2)^2+sin(y/2)^2)),d)
    A=Laplacian(d)+0.1I
    testbandedblockbandedoperator(A)
    @time u=A\f
    @test u(.1,.2) ≈ u(.2,.1)
    @test (lap(u)+.1u-f)|>coefficients|>norm < 1000000eps()
end

@testset "Low Rank" begin
    ## Periodic
    f=LowRankFun((x,y)->cos(x)*sin(y),PeriodicSegment(),PeriodicSegment())
    @test f(.1,.2) ≈ cos(.1)*sin(.2)

    f=LowRankFun((x,y)->cos(cos(x)+sin(y)),PeriodicSegment(),PeriodicSegment())
    @test f(.1,.2) ≈ cos(cos(.1)+sin(.2))
    @test norm(Float64[cos(cos(x)+sin(y)) for x=ApproxFunBase.vecpoints(f,1),y=ApproxFunBase.vecpoints(f,2)]-values(f))<10000eps()

    f=ProductFun((x,y)->cos(cos(x)+sin(y)),PeriodicSegment()^2)
    @test f(.1,.2) ≈ cos(cos(.1)+sin(.2))
    x,y=points(f)
    @test norm(Float64[cos(cos(x[k,j])+sin(y[k,j])) for k=1:size(f,1),j=1:size(f,2)]-values(f))<10000eps()

    d=PeriodicSegment()^2
    f=ProductFun((x,y)->exp(-10(sin(x/2)^2+sin(y/2)^2)),d)
    @test (transpose(f)-f|>coefficients|>norm)< 1000eps()
end

@testset "off domain evaluate" begin
    g = Fun(1, PeriodicSegment(Vec(0,-1) , Vec(π,-1)))
    @test g(0.1,-1) ≈ 1
    @test g(0.1,1) ≈ 0
end


@testset "PeriodicLine" begin
    d=PeriodicLine()
    D=Derivative(d)

    f = Fun(x->sech(x-0.1),d,200)
    @test f(1.) ≈ sech(1-0.1)

    f=Fun(x->sech(x-0.1),d)
    @test f(1.) ≈ sech(1-0.1)

    @test ≈((D*f)(.2),-0.0991717226583897;atol=100000eps())
    @test ≈((D^2*f)(.2),-0.9752522555114987;atol=1000000eps())

    f=Fun(z->2exp(z^2),PeriodicLine(0.,π/2))
    @test f(1.1im) ≈ 2exp(-1.1^2)
end