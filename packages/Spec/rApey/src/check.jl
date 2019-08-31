"A generator is any object which adheres to the interface `rand(rng, X)`"
function gen end

gen(::Type{T}) where T = rng -> rand(rng, T)

"Generator for arguments of method  random variable for inputs"
function gen(f, argtypes)
  map(gen, argtypes)
end

function check(f, argtypes, gen = gen(f, argtypes))
end