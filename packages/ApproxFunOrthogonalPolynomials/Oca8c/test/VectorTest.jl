using ApproxFunOrthogonalPolynomials, ApproxFunBase, LazyArrays, FillArrays, LinearAlgebra, SpecialFunctions, Test
    import ApproxFunBase: interlace, Multiplication, ConstantSpace, PointSpace,
                        ArraySpace, testblockbandedoperator, blocklengths, ∞,
                        testraggedbelowoperator, Vec




@testset "Vector" begin
    @testset "Construction" begin
        f = Fun(x->[1.,0.])
        @test f(0.) ≈ [1.,0.]
        @test f[end] ≈ 0
        @test f[firstindex(f)] ≈ 1
    end

    @testset "Broadcast" begin
        x = Fun()

        @test x .+ [1,2] ≈ [x+1,x+2]
        @test [1,2] .+ x ≈ [x+1,x+2]

        @test x.*[1,2] ≈ [x,2x]
        @test [1,2].*x ≈ [x,2x]
        @test (x*[1,2])(0.1) ≈ [0.1,0.2]
        @test ([1,2]*x)(0.1) ≈ [0.1,0.2]

        @test (x*[1,2])(0.1) ≈ [0.1,0.2]
        @test ([1,2]*x)(0.1) ≈ [0.1,0.2]

        @test (x*Fun([1,2]))(0.1) ≈ [0.1,0.2]
        @test (Fun([1,2])*x)(0.1) ≈ [0.1,0.2]

        @test (Fun(x->[1., 2.]) + [2, 2])(0.) ≈ [3., 4.]
    end

    @testset "Vector*Vector{Fun}" begin
        f = Fun(x->[exp(x),cos(x)])
        @test f(0.1) ≈ [exp(0.1),cos(0.1)]
        @test ([1 2]*f)(0.1) ≈ [1 2]*f(0.1)
        @test (f*3)(0.1) ≈ f(0.1)*3
        @test (3*f)(0.1) ≈ f(0.1)*3

        @test_broken transpose(f)*[1,2] ≈ transpose(f(0.1))*[1,2]

        @test norm(f) ≈ sqrt(sinh(2)+1+cos(1)sin(1))
        @test norm(f,2) ≈ sqrt(sinh(2)+1+cos(1)sin(1))
        @test norm(f,1) ≈ sqrt(sinh(2))+sqrt(1+cos(1)sin(1))
    end

    @testset "Chebyshev Vector" begin
        a = [1 2; 3 4]
        f = Fun(x->[exp(x),cos(x)])
        @test (a*f)(0.1) ≈ [exp(0.1)+2cos(0.1); 3exp(0.1)+4cos(0.1)]
        @test (a*f)(0.1) ≈ a*f(0.1)
        @test Fun(a)*f ≈ a*f
        @test Fun(a*Array(f)) ≈ a*f
    end

    @testset "Chebyshev Matrix" begin
        a = [1 2; 3 4]
        m = Fun(x->[exp(x) cos(x); sin(x) airyai(x)])
        @test (a*m)(0.1) ≈ [exp(0.1)+2sin(0.1) cos(0.1)+2airyai(0.1);
                            3exp(0.1)+4sin(0.1) 3cos(0.1)+4airyai(0.1)]
        @test (a*m)(0.1) ≈ a*m(0.1)
        @test (m*a)(0.1) ≈ m(0.1)*a
        @test Fun(a)*m   ≈ a*m
        @test m*Fun(a)   ≈ m*a
        @test Fun(a*Array(m))   ≈ a*m
        @test Fun(Array(m)*a)   ≈ m*a

        @test (a+m)(0.1) ≈ a+m(0.1)
        @test (m+a)(0.1) ≈ m(0.1)+a

        @test (m+I)(0.1) ≈ m(0.1)+I
    end

    @testset "Matrix{Fun}*Matrix{Fun}" begin
    # note that 2x2 and 3x3 mult are special cases
        x=Fun()
        A = [x x; x x]

        @test A isa Fun

        @test norm(map(norm,A*A-[2x^2 2x^2; 2x^2 2x^2])) <eps()
        @test norm(map(norm,A*Array(A)-[2x^2 2x^2; 2x^2 2x^2])) < eps()
        @test norm(map(norm,Array(A)*A-[2x^2 2x^2; 2x^2 2x^2])) < eps()
        @test norm(map(norm,Array(A)*Array(A)-Array([2x^2 2x^2; 2x^2 2x^2]))) < eps()


        @test [x;x] == A[:,1]
        @test [[x;2x] [3x;4x]] == [x 3x; 2x 4x]
        @test [x x] == A[1:1,:]


        A = fill(x,3,3)
        @test norm(map(norm,A^3-fill(9x^3,3,3))) <eps()
        @test norm((A^2*Fun(A)-fill(9x^3,3,3)).coefficients) < eps()
        @test norm((A*Fun(A)^2-fill(9x^3,3,3)).coefficients) < eps()
        @test norm((Fun(A)^3-fill(9x^3,3,3)).coefficients) < eps()


        A = fill(x,4,4)
        @test norm(map(norm,A^2-fill(4x^2,4,4))) <eps()
        @test norm((A*Fun(A)-fill(4x^2,4,4)).coefficients) < eps()
        @test norm((Fun(A)*A-fill(4x^2,4,4)).coefficients) < eps()
        @test norm((Fun(A)^2-fill(4x^2,4,4)).coefficients) < eps()
    end

    @testset "Vector ODE" begin
        d=ChebyshevInterval()
        D=Derivative(d);
        B=ldirichlet();
        Bn=lneumann();
        A=[B 0;
           0 B;
           D-I 2I;
           0I D+I];

        f=Fun(x->[exp(x),cos(x)],d)

        b=Any[0.,0.,f...]
        f1,f2=vec(f)
        @time u=A\b
        u1=vec(u)[1];u2=vec(u)[2];

        @test norm(u1'-u1+2u2-f1)<10eps()
        @test norm(u2'+u2-f2)<10eps()

        A=[B 0;
           Bn 0;
           0 B;
           D^2-I 2I;
           0 D+I];

        b=Any[0.,0.,0.,f...]

        @time u=A\b
        u1=vec(u)[1];u2=vec(u)[2];


        @test norm(differentiate(u1,2)-u1+2u2-f1) < 4eps()
        @test norm(u2'+u2-f2) < 4eps()
    end

    @testset "Matrix exponential" begin
        n=4
        d=fill(Interval(0.,1.),n)
        B=Evaluation(d,0.)
        D=Derivative(d)
        A=rand(n,n)
        L=[B;D-A]
        @time u=L\Matrix(I,2n,n)
        @test norm(u(1.)-exp(A))<eps(1000.)

        n=4
        d=fill(Interval(0.,1.),n)
        B=Evaluation(d,0.)
        D=Derivative(d)
        A=rand(n,n)
        L=[B;D-A]
        @time u=L\Matrix(I,2n,2)
        @test norm(u(1.)-exp(A)[:,1:2])<eps(1000.)
    end

    @testset "Multiplication" begin
        d = ChebyshevInterval()
        t=Fun(identity,d)
        f = Fun([t^2, sin(t)])
        @test norm(((Derivative(space(f))*f)-Fun(t->[2t,cos(t)])).coefficients)<100eps()
        @test norm((([1 2;3 4]*f)-Fun(t->[t^2+2sin(t),3t^2+4sin(t)])).coefficients)<100eps()
    end
    
    @testset "Interlace" begin
        S1 = Chebyshev()^2
        S2 = Chebyshev()
        TS = ArraySpace([ConstantSpace(),S1,ConstantSpace(),S2,PointSpace([1.,2.])])
        f = Fun(TS,collect(1:13))
        @test f[1] == Fun(TS[1],[1.])
        @test f[2] == Fun(TS[2],[2.,7.,8.,10.,11.,12.])
        @test f[3] == Fun(TS[3],[3.])
        @test f[4] == Fun(TS[4],[4.,9.,13.])
        @test f[5] == Fun(TS[5],[5.,6.])
    end

    @testset "Operator * Matrix" begin
        f = [Fun(exp) Fun(cos)]
        @test f(0.1) ≈ [exp(0.1) cos(0.1)]

        D=Derivative()
        u=D*f
        @test u(0.1) ≈ [exp(0.1) -sin(0.1)]
        u=D*Array(f)
        @test u(0.1) ≈ [exp(0.1) -sin(0.1)]
    end

    @testset "Floquet" begin
        # TODO: fix when IntervalSets.jl is fixed
        T = Float64(π, RoundUp); a=0.15
        t = Fun(identity,0..T)
        d=domain(t)
        D=Derivative(d)
        B=ldirichlet(d)

        B_row = [D             -I  0I            0I]

        f=Fun(exp,d)
        @test norm((B_row*[f;f;f;f])[1]) ≤ 1000eps()
        @test B_row isa ApproxFunBase.MatrixInterlaceOperator

        @test size([B_row;B_row].ops) == (2,4)

        @test norm(([B_row;B_row]*[f;f;f;f])[1]) ≤ 1000eps()

        n=4
        Dg = Operator(diagm(0 => fill(ldirichlet(d),n)))

        @test Dg isa ApproxFunBase.MatrixInterlaceOperator
        @test size([Dg; B_row].ops) == (5,4)

        L = [Dg; B_row]
        testraggedbelowoperator(L)
        @test ([Dg; B_row]*[f;f;f;f])(0.1) ≈ [fill(1.0,4);0]

        @test hcat(Dg).ops == Dg.ops

        B_row2 = [(2+a*cos(2t))   D  -I            0I]
        @test ([B_row;B_row2]*[f;f;f;f])(0.1) ≈ [0.,(2+a*cos(2*0.1))*f(0.1) + f'(0.1) - f(0.1)]

        A=[ Operator(diagm(0 => fill(ldirichlet(d),n)));
            D             -I  0I            0I;
           (2+a*cos(2t))   D  -I            0I;
           0I             0I   D            -I;
           -I             0I  (2+a*cos(2t))  D]

        Φ = A\Matrix(I,2n,n);

        @test Φ(π) ≈ [-0.170879 -0.148885 -0.836059 0.265569;
                 0.732284 -0.170879 -0.612945 -0.836059;
                 -0.836059 0.265569 -0.170879 -0.148885;
                 -0.612945 -0.836059 0.732284 -0.170879] atol=1E-3
    end

    @testset "diagonal" begin
        x = Fun(0.0..1)
        @test isambiguous(domain(zero(typeof(x))))
        @test diagm(0 => [x,x]) * [1,2] == [x,2x]
    end
end
