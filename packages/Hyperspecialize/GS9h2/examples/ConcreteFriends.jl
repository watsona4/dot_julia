module Peter
  import Base.+

  using Hyperspecialize

  struct PeterNumber <: Number
    x::Number
  end

  @concretize myNumber [BigFloat, Float16, Float32, Float64, Bool, BigInt, Int128, Int16, Int32, Int64, Int8, UInt128, UInt16, UInt32, UInt64, UInt8]

  @replicable Base.:+(p::PeterNumber, y::@hyperspecialize(myNumber)) = PeterNumber(p.x + y)

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

using Hyperspecialize
@widen (Peter, myNumber) JarrettNumber

friends = p + j

println("Peter and Jarrett are bffs! $friends")
