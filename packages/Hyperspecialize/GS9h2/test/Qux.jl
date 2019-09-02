module Qux

using Hyperspecialize

struct Wobble <: Real
  w::Int
end

f(::Real) = false
g(::Real) = false
@concretize TypicalTag []
@replicable f(::@hyperspecialize(TypicalTag)) = true
@replicable g(::@hyperspecialize(TypicalTag)) = true

h(::Real, ::Wobble) = false

export h, Wobble

end #module
