

function stable_test_method(foo::UInt32)
    foo+foo
end

#Used to ensure check_method gets right method
function stable_test_method(foo::Number)
    bar = "unstable"
    if foo > 10
        bar = foo
    end
    bar
end

function unstable_variables(foo::UInt8)
    bar = 1
    if foo > 8
        bar = foo
    end
    "result:$bar"
end

function unstable_return(foo::UInt32)
    if foo > 1
        1
    else
        1.0
    end
end

function unstable_combo(foo::UInt32)
    bar = 1
    if foo > 1
        bar = foo
    end
    bar
end

@testset "Stability Analysis" begin
    #check_function
    @test Tuple{Any, StabilityReport}[((UInt32,), StabilityReport())] == check_function(stable_test_method, ((UInt32,),))

    @test Tuple{Any, StabilityReport}[((UInt32,), StabilityReport()), ((Float64,), StabilityReport(Tuple{Symbol, Type}[(:bar, Union{String, Float64}), (:return, Union{String, Float64})]))] == check_function(stable_test_method, ((UInt32,), (Float64,)))

    #check_method
    @test StabilityReport() == check_method(stable_test_method, (UInt32,))
    @test StabilityReport() == check_method(unstable_return, (UInt32,), Dict(:return=>Number))
    @test StabilityReport() == check_method(unstable_variables, (UInt8,), Dict(:bar=>Integer))

    @test StabilityReport(Tuple{Symbol, Type}[(:bar, Union{UInt8, Int})]) == check_method(unstable_variables, (UInt8,))
    @test StabilityReport(Tuple{Symbol, Type}[(:return, Union{Int, Float64})]) == check_method(unstable_return, (UInt32,))

    @test StabilityReport(Tuple{Symbol, Type}[(:bar, Union{UInt32, Int})]) == check_method(unstable_combo, (UInt32,), Dict(:return=>Number))
    @test StabilityReport(Tuple{Symbol, Type}[(:return, Union{Int, UInt32})]) == check_method(unstable_combo, (UInt32,), Dict(:bar=>Integer))
    @test StabilityReport(Tuple{Symbol, Type}[(:bar, Union{UInt32, Int}), (:return, Union{Int, UInt32})]) == check_method(unstable_combo, (UInt32,))

    #is_stable(::StabilityReport)
    @test is_stable(StabilityReport())
    @test is_stable(StabilityReport(Vector{Tuple{Symbol, Type}}(undef, 0)))
    @test !is_stable(StabilityReport(Tuple{Symbol, Type}[(:x, Number)]))
    @test !is_stable(StabilityReport(Tuple{Symbol, Type}[(:x, Number),
                                                         (:y, Array),
                                                         (:z, AbstractArray{UInt8, 1})]))
    @test !is_stable(StabilityReport(Tuple{Symbol, Type}[(:return, Number)]))
    @test !is_stable(StabilityReport(Tuple{Symbol, Type}[(:x, Number), (:return, Number)]))

    #is_stable(::Vector{StabilityReport})
    @test is_stable([StabilityReport()])
    @test is_stable([StabilityReport(), StabilityReport(), StabilityReport()])
    @test !is_stable([StabilityReport(Tuple{Symbol, Type}[(:return, Number)])])
    @test !is_stable([StabilityReport(), StabilityReport(Tuple{Symbol, Type}[(:return, Number)])])
    @test !is_stable([StabilityReport(Tuple{Symbol, Type}[(:return, Number)]), StabilityReport()])

    #is_stable(::Vector{Tuple{Any, StabilityReport}})
    @test is_stable([((), StabilityReport())])
    @test is_stable([((), StabilityReport()), ((Int32,), StabilityReport()), ((Float64,),StabilityReport())])
    @test !is_stable([((String,),StabilityReport(Tuple{Symbol, Type}[(:return, Number)]))])
    @test !is_stable([((String,),StabilityReport()), ((), StabilityReport(Tuple{Symbol, Type}[(:return, Number)]))])
    @test !is_stable([((Tuple, String),StabilityReport(Tuple{Symbol, Type}[(:return, Number)])), ((),StabilityReport())])
end
