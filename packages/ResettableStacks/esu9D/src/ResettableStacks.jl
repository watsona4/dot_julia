__precompile__()

module ResettableStacks

  const FULL_RESET_COUNT = 10000

  using StaticArrays

  import Base: isempty, length, push!, pop!, iterate

  include("core.jl")

  export ResettableStack, reset!
end # module
