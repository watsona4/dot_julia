@testset "BasicEMD" begin
    @testset "BasicEMD Test 1" begin
        n = 200
        s = EMDSetting(n, 50, 10, 2)

        t = collect(range(0,1, length=n))
        x = zeros(n)

        for i=1:n
            x[i] = cos(22*pi*t[i]^2) + 6*t[i]^2
        end

        output = emd(x, s)

        @test size(output, 2) == s.m

        recovered = zeros(n)

        for i=1:size(output, 2)
            recovered += output[:, i]
        end

        @test recovered == x || isapprox(recovered, x)
    end

    @testset "BasicEMD Test 2" begin
        N = 1024
        s = EMDSetting(N, 50, 10, 10)

        function input_signal(x::Float64)
            omega = 2*pi/(N-1)
            return sin(17*omega*x)+0.5*(1.0-exp(-0.002*x))*sin(51*omega*x+1)
        end

        input = zeros(N)

        for i=1:N
            input[i] = input_signal(float(i))
        end


        output = emd(input, s)

        @test size(output, 2) == s.m

        recovered = zeros(N)

        for i=1:size(output, 2)
            recovered += output[:, i]
        end

        @test recovered == input || isapprox(recovered, input)
    end
end

