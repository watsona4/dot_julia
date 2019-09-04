module TwentyFour

import Combinatorics.multiset_permutations
import Base: length, show, getindex

export XXIV, solve

"""
`solve(nums...)` solves a Twenty-Four puzzle for the given numbers.
Returns a `String` giving the solution.
Example:
```
julia> solve(4,2,5,1)
"(4+2)*(5-1)"
```
"""
function solve(nums...)::String
  @assert length(nums)>1 "Please give two or more integers or rationals"
  X = XXIV(nums...)
  solver(X)
  if X.solved
    return X.solution[2:end-1]
  else
    return "No solution"
  end
end



"""
The default goal of a *Twenty Four* problem is 24.
"""
global DEFAULT_GOAL = 24

global const OPS = [ (+), (-), (*), (/)]
global const OP_SYMS = [ "+", "-", "*", "/"]


"""
`XXIV` is an instance of a Twenty Four problem.
"""
mutable struct XXIV
  nums::Vector{Rational{Int}}
  numstrs::Vector{String}
  goal::Int
  solved::Bool
  solution::String

  function XXIV(num_list::Vector{Rational{Int}})
    new(deepcopy(num_list),map(str,num_list),DEFAULT_GOAL,false,"")
  end
end

function XXIV(vals...)
  num_list = [ Rational(x) for x in vals ]
  return XXIV(num_list)
end

XXIV() = XXIV(Rational{Int}[])

getindex(X::XXIV,i::Int) = X.nums[i]

function show(io::IO,X::XXIV)
  n = length(X)
  print(io, "[ ")
  for a in X.numstrs
    print(io,a*" ")
  end
  print(io,"] with goal $(X.goal)")
  if X.solved
    print(io," and solution $(X.solution)")
  end
  nothing
end

length(X::XXIV) = length(X.nums)


"""
`get_goal(X::XXIV)` returns the targe goal of this instance
of a *Twenty Four* problem. This is typically 24.
"""
get_goal(X::XXIV) = X.goal

"""
`set_goal(X::XXIV, g)` sets the goal of this *Twenty Four* problem
to `g`. Default `g` is 24.
"""
function set_goal(X::XXIV, g::Int=DEFAULT_GOAL)
  if X.goal == g
    return nothing
  end
  X.goal = g
  X.solved=false
  X.solution=""
  nothing
end

"""
`str(x::Rational{Int})` returns a nice string form of `x`.
"""
function str(x::Rational{Int})
  if denominator(x)==1
    return "$(numerator(x))"
  end
  return "$(numerator(x))/$(denominator(x))"
end


function solver(X::XXIV)
  n = length(X)
  # basis cases
  if n==0
    X.solved = false
    X.solution = ""
    return 0
  end

  if n == 1
    a = X[1]
    if a == X.goal
      X.solved = true
      X.solution = X.numstrs[1]
      return true
    else
      X.solved = false
      X.solution = ""
      return false
    end
  end

  for i=1:n
    for j=1:n
      if i!=j
        ii = i
        jj = j
        if i>j
          ii,jj = jj,ii
        end

        a = X.nums[i]
        sa = X.numstrs[i]
        b = X.nums[j]
        sb = X.numstrs[j]

        for t = 1:4
          XX = deepcopy(X)

          f = OPS[t]
          sf = OP_SYMS[t]

          ab = f(a,b)
          sab = "(" * sa * sf * sb * ")"
          deleteat!(XX.nums,(ii,jj))
          deleteat!(XX.numstrs,(ii,jj))
          append!(XX.nums,[ab])
          append!(XX.numstrs,[sab])
          try
            if solver(XX)
              X.solution = XX.solution
              X.solved = true
              return true
            end
            catch
          end

        end # next t

      end  # endif
    end # next j
  end # next i
  return false


end  # end of function







end # end of module
