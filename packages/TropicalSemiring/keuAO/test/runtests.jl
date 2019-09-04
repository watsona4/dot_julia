using TropicalSemiring
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end


@test Trop(2.3) isa Trop{Max, Float64}
@test Trop(2) isa Trop{Max, Int64}
@test Trop{Min}(2) isa Trop{Min, Int64}
@test Trop{Min, Float64}(2) isa Trop{Min, Float64}

@test Trop{Max}(2.0, true) isa Trop{Max, Float64}
@test isinf(Trop{Max}(2.0, true))
@test isinf(inf(Max))
@test isinf(inf(Min))
@test inf() isa Trop{Max, Bool}
@test inf(Min) isa Trop{Min, Bool}
@test inf(Max) isa Trop{Max, Bool}

@test Trop(2) + Trop(3) == Trop(3)
@test Trop{Min}(2) + Trop{Min}(3) == Trop{Min}(2)
@test Trop{Min}(2) + inf(Min) == inf(Min)
@test Trop{Max}(2) + inf(Max) == inf(Max)

@test Trop{Min}(2) * Trop{Min}(3) == Trop{Min}(5)
@test Trop{Max}(2) * Trop{Max}(3) == Trop{Max}(5)
@test Trop{Max}(2) * inf() == inf()
@test Trop{Min}(2) * inf(Min) == inf(Min)

@test Trop(4)^4 == Trop(16)
@test -Trop(4) == Trop(4)

@test (Trop(3.1) == Trop(3.0)) == false
@test (Trop{Max}(3) == Trop{Min}(3)) == false

@test one(typeof(Trop(2))) == Trop(0)
@test one(Trop(3.0)) == Trop(0.0)

@test zero(typeof(Trop(3))) == Trop{Max}(zero(3), true)
@test zero(Trop(2.3)) == Trop{Max}(zero(3.2), true)

@test string(Trop(5.2)) == "5.2"
@test string(inf(Min)) == "-∞"
@test string(inf(Max)) == "∞"

@test promote_type(Trop{Max, Int}, Trop{Max, Float64}) == Trop{Max, Float64}
