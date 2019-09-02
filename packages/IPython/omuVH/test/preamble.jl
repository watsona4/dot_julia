@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

macro test_nothrow(ex)
    quote
        @test begin
            $(esc(ex))
            true
        end
    end
end

using IPython
using IPython: @compatattr, _setproperty!
using Compat
