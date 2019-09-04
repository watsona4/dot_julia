
"Used for testing run_inline_stability_checks"
macro enable_inline_checks(enabled::Bool)
    enable_inline_stability_checks(enabled)

    quote end
end

"""Copies the variable `x` to the global variable `x_inline_check_testing_copy`"""
macro copy(vars...)
    copy_names = @. Symbol(String(vars) * "_inline_check_testing_copy")
    esc(quote
        global $(copy_names...)
        $((:($copy_name = $var)
            for (copy_name, var) in zip(copy_names, vars))...)
    end)
end

"""For variable `x` `@test's` if the global variable
`x_inline_check_testing_copy` is a function"""
macro check(vars...)
    copy_names = @. Symbol(String(vars) * "_inline_check_testing_copy")
    esc(quote
        global $(copy_names...)
        $((quote
                @test $copy_name isa Function
                @test $(QuoteNode(var)) == nameof($copy_name)
            end
            for (copy_name, var) in zip(copy_names, vars))...)
    end)
end

macro create_func()
    esc(quote
        function created_func()
            return 0
        end
    end)
end

@enable_inline_checks true

@testset "Inline Checker" begin

    @test_nowarn begin
        @stable_function([()],
        function f()
            1
        end)

        @copy f
    end
    @check f

    @test_nowarn begin
        @stable_function([()], nothing,
        function fb()
            1
        end)

        @copy fb
    end
    @check fb


    @test_nowarn begin
        @stable_function [()] begin
            function f1()
                1
            end
            function f2()
                3
            end
        end
        @copy f1 f2
    end
    @check f1 f2

    @test_nowarn begin
        @stable_function [()] nothing begin
            function fb1()
                1
            end
            function fb2()
                3
            end
        end
        @copy fb1 fb2
    end
    @check fb1 fb2

    @test_nowarn begin
        @stable_function([(Float64,)],
        function g(x)
            if x > 0
                x
            else
                0.0
            end
        end)
        @copy g
    end
    @check g

    @test_nowarn begin
        @stable_function [(Complex{Float64},)] begin
            function g1(x)
                if x == 0
                    x
                else
                    0.0im
                end
            end

            function g2(x::Complex{T}) where T
                if x == 0
                    x
                else
                    Complex{T}(2.5)
                end
            end
        end
        @copy g1 g2
    end
    @check g1 g2

    @test_warn [r".*not stable.*", r".*eturn.*"] begin
        @stable_function([(UInt8, Float64), (UInt16, Float32)],
        function h(x, y)
            if x > 1
                1
            else
                1.0
            end
        end)
        @copy h
    end
    @check h

    @test_nowarn begin
        @stable_function([(UInt8, Float64), (UInt16, Float32)], Dict(:return => Number),
        function hb(x, y)
            if x > 1
                1
            else
                1.0
            end
        end)
        @copy hb
    end
    @check hb

    @test_warn [r".*h1.*", r".*h2.*", (result)->!occursin(result, "h3"), r".*not stable.*", r".*eturn.*"] begin
        @stable_function [(UInt8, Float64), (UInt16, Float32)] begin
            function h1(x, y)
                if x > 1
                    1
                else
                    1.0
                end
            end
            function h2(x, y)
                if x > 1
                    1
                else
                    2.0
                end
            end
            function h3(x, y)
                Float64(x)
            end
        end
        @copy h1 h2 h3
    end
    @check h1 h2 h3

    @test_nowarn @stable_function [()] i() = 1
    @test_nowarn @stable_function [()] begin
                    i1() = 2
                    i2() = 3
                end

    @test_warn [r".*not stable.*", r".*eturn.*"] begin
        @stable_function([(UInt8,), (UInt16,)],
        h(x) = if x > 1
                   1
               else
                   1.0
               end
        )
        @copy h
    end
    @check h

    @test_nowarn @stable_function [()] @create_func

    @test_nowarn @stable_function [()] begin
        @create_func
        @copy created_func
    end
    @check created_func

    function foo(x)
        if x > 0
            x
        else
            0.0
        end
    end

    @test_nowarn @stable_function [(Float64,)] foo
    @test_nowarn @stable_function [(Float64,)] nothing foo
    @test_warn [r".*not stable.*", r".*eturn.*"] @stable_function [(Int,)] foo
    @test_warn [r".*not stable.*", r".*eturn.*"] @stable_function [(Int,)] nothing foo
    @test_nowarn @stable_function [(Int,)] Dict(:return => Number) foo

    @enable_inline_checks false
    @test_nowarn @stable_function [(Int,)] foo

    @test_nowarn begin
        @stable_function([(Int,)],
        function bar(x)
            if x > 1
                1
            else
                1.0
            end
        end)
        @copy bar
    end
    @check bar

    @test_nowarn begin
        @stable_function [(Int,)] begin
            function bar1(x)
                if x > 1
                    1
                else
                    1.0
                end
            end
            function bar2(x)
                if x > 1
                    1
                else
                    12
                end
            end
        end
        @copy bar1 bar2
    end
    @check bar1 bar2
end
