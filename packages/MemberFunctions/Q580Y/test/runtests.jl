using MemberFunctions
using Test

#
# Basics
#
mutable struct Foo
  value
end

@member get_value(foo::Foo) = value

@member function set_value!(foo::Foo, v)
  value = v
end

foo = Foo(1)

@test get_value(foo) == 1

set_value!(foo, 2)
@test get_value(foo) == 2

#
# Let syntax
#
set_value!(foo, 1)
@member function let_test(foo::Foo)
  let value
    value = 2
  end
end

let_test(foo)
@test foo.value == 1
