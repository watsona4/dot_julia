using FieldDefaults, FieldMetadata, Unitful, Test
using FieldDefaults: get_default
import FieldMetadata: @units, units

@default_kw struct TestStruct{A,B,C}
    a::A  | 1
    b::B  | :foo
    c::C  | :bar
end

@test get_default(TestStruct, Val{:a}) == 1
@test get_default(TestStruct, Val{:b}) == :foo
@test get_default(TestStruct, Val{:c}) == :bar

t = TestStruct()
@test t.a === 1
@test t.b === :foo
@test t.c === :bar

t = TestStruct(a = 2, b = 3.0, c = 4.0f0)
@test t.a === 2
@test t.b === 3.0
@test t.c === 4.0f0


@redefault_kw struct TestStruct
    a | 3
    b | :foobar
end

t = TestStruct()
@test t.a == 3
@test t.b == :foobar
@test t.c == :bar

@units @udefault_kw struct UnitfulTestStruct{A,B,C}
    a::A  | 1     | _
    b::B  | 2.0   | u"s"
    c::C  | 3.0f0 | u"g"
end

u = UnitfulTestStruct()
@test typeof(u.a) == Int
@test u.a === 1
@test u.b === 2.0u"s"
@test u.c === 3.0f0u"g"

@units @udefault_kw struct UTest2{A,B}
    a::A | 0.03  | _       
    b::A | 0.025 | _       
    c::B | 25.0  | u"g*mol^-1"
    d::B | 25.0  | u"g*mol^-1"
end

# Test Floats arent converted to NoDims units
u = UTest2(a=2.0, b=3.0, c=3.0u"g*mol^-1")

@test typeof(u.a) == Float64
@test u.a === 2.0
@test u.b === 3.0
@test u.c === 3.0u"g*mol^-1"
@test u.d === 25.0u"g*mol^-1"
