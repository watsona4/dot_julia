# This file is part of Kpax3. License is MIT.

function shuffleunits!(x::Vector{Int})
  for i = length(x):-1:2
    j = rand(1:i)
    x[i], x[j] = x[j], x[i]
  end

  nothing
end

function shuffleunits!(x::Vector{Int},
                       S::Int)
  for i = S:-1:2
    j = rand(1:i)
    x[i], x[j] = x[j], x[i]
  end

  nothing
end
