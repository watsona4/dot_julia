using Callbacks
using Lens

struct Loop end
function simulation(n)
  x = 0.0
  for i = 1:n
    y = sin(x)
    lens(Loop, (x = x, y = y))
    x += rand()
  end
end

@leval Loop => plotscalar() simulation(100)

@leval Loop => (everyn(100) → plotscalar()) simulation(100000)