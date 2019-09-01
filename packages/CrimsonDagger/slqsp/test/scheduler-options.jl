@everywhere begin

function checkwid(x...)
    @assert myid() == 2
    return 1
end

end

@testset "Scheduler options" begin
    @testset "single worker" begin
        a = delayed(checkwid)(1)
        b = delayed(checkwid)(2)
        c = delayed(checkwid)(a,b)

        @test collect(Context(), c; single=2) == 1
    end
end

