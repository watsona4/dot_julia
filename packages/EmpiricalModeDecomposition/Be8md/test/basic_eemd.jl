@testset "EEMD" begin
    @testset "EEMD Test 1" begin
        n = 200
        s = EEMDSetting(n, 50, 10, 2, 10, 0.2, 450)

        t = collect(range(0,1, length=n))
        x = zeros(n)

        for i=1:n
            x[i] = cos(22*pi*t[i]^2) + 6*t[i]^2
        end

        output = eemd(x, s)

        @test size(output, 2) == s.emd_setting.m

        recovered = zeros(n)

        for i=1:size(output, 2)
            recovered += output[:, i]
        end

        @test recovered == x || isapprox(recovered, x, rtol=0.05)
    end

    @testset "EEMD Test 2" begin
        N = 1024
        s = EEMDSetting(N, 50, 10, 10, 250, 0.3, 200)

        function input_signal(x::Float64)
            omega = 2*pi/(N-1)
            return sin(17*omega*x)+0.5*(1.0-exp(-0.002*x))*sin(51*omega*x+1)
        end

        input = zeros(N)

        for i=1:N
            input[i] = input_signal(float(i))
        end


        output = eemd(input, s)

        @test size(output, 2) == s.emd_setting.m

        recovered = zeros(N)

        for i=1:size(output, 2)
            recovered += output[:, i]
        end

        @test isapprox(recovered,input, rtol=0.03)
    end
end

