using Spec
using Test

function f(x)
  @pre x > 0
  x
end

@test_throws ArgumentError f(-3)

