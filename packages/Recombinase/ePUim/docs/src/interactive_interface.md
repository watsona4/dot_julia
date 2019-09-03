# Interactive interface

Most of the available analyses can be selected from a simple [Interact](http://juliagizmos.github.io/Interact.jl/latest/)-based UI. To launch the UI simply do:

```julia
using Recombinase, Interact, StatsPlots, Blink
# here we give the functions we want to use for plotting
ui = Recombinase.gui(data, [plot, scatter, groupedbar]);
w = Window()
body!(w, ui)
```
![interactgui](https://user-images.githubusercontent.com/6333339/55816219-b3af4a00-5ae9-11e9-94f5-d3cc4e5d722d.png)
