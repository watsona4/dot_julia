using Hilbert
using Test

# Example from https://www.mathworks.com/help/signal/ref/hilbert.html
@testset "Real vector" begin
    signal = [1 2 3 4]
    analytical_signal = hilbert(signal)
    @test analytical_signal == [1+1im 2-1im 3-1im 4+im]
end

@testset "Complex numbers" begin
    complex_signal = Complex.([1 2 3 4])
    # verify that the warning is thrown
    @test_logs (:warn, "Using real part, ignoring complex part") hilbert(complex_signal)
    # verify that the output is correct assuming only the real part is used
    analytical_signal = hilbert(complex_signal)
    @test analytical_signal == [1+1im 2-1im 3-1im 4+im]
end