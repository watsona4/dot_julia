module Peter
  import Base.+

  using Hyperspecialize

  struct PeterNumber <: Number
    x::Number
  end

  @replicable Base.:+(p::PeterNumber, y::@hyperspecialize(Number)) = PeterNumber(p.x + y)

  export PeterNumber
end

module Jarrett
  import Base.+

  struct JarrettNumber <: Number
    y::Number
  end

  Base.:+(x::Number, j::JarrettNumber) = JarrettNumber(x + j.y)

  export JarrettNumber
end

using .Peter
using .Jarrett

p = PeterNumber(1.0) + 3
j = 2.0 + JarrettNumber(2.0)
friends = p + j

println("Peter and Jarrett are friends! $friends")
