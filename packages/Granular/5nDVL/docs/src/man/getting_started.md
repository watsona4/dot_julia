# Getting started
In this section, it is assumed that [Julia](https://julialang.org) and 
[Granular.jl](https://github.com/anders-dc/Granular.jl) have been successfully 
installed.  If not, please consult the [Installation](@ref Installation) 
section of this manual.  If you are new to the [Julia](https://julialang.org) 
programming language, the official manual has a useful guide to [getting 
started with 
Julia](https://docs.julialang.org/en/latest/manual/getting-started/).

In the following, two simple examples are presented using some of the core 
functionality of Granular.jl.  For more examples, see the scripts in the 
[examples/](https://github.com/anders-dc/Granular.jl/tree/master/examples) 
directory.

The relevant functions are all contained in the `Granular` module, which can be 
imported with `import Granular`.  *Note:* As per Julia conventions, functions 
that contain an exclamation mark (!) modify the values of the arguments.

All of the functions called below are documented in the source code, and their 
documentation can be found in the [Public API Index](@ref main-index) in the 
online documentation, or simply from the Julia shell by typing `?<function 
name>`.  An example:

```julia-repl
julia> ?Granular.createSimulation
  createSimulation([id])

  Create a simulation object to contain all relevant variables such as temporal 
  parameters, fluid grids, grains, and contacts. The parameter id is used to 
  uniquely identify the simulation when it is written to disk.

  The function returns a Simulation object, which you can add grains to, e.g. 
  with addGrainCylindrical!.

     Optional argument
    ≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡

    •    id::String="unnamed": simulation identifying string.
```

You can go through the examples below by typing in the lines starting with 
`julia>` into the Julia interactive shell, which comes up when you start the 
Julia app or run `julia` from the command line in a terminal.  Do not include 
the `julia> ` part, just the remaining text of that line.

Alternatively, you can create a Julia script with the file name extension 
`.jl`.  This file should contains all of the relevant commands in succession, 
which is useful for quickly repeating runs.  Julia scripts can be evaluated 
form the command line using `julia <scriptname>.jl`.

## Collision between two particles
For the first example (`examples/two-grains.jl`), we will create two grains and 
make the first grain bump in to the second grain.

As the first step, we import all the Granular.jl functionality:

```julia-repl
julia> import Granular
```

### Simulation setup
Next, we create our simulation object which holds all information related to 
the simulated grains.  In this documentation, we will use the name `sim` for 
the simulation object:

```julia-repl
julia> sim = Granular.createSimulation(id="two-grains")
Granular.Simulation("two-grains", 0, 0.0, -1.0, -1.0, -1.0, 0, 0.0, 
Granular.GrainCylindrical[], Granular.Ocean(false, [0.0], [0.0], [0.0], [0.0], 
[0.0], [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], Array{Int64,1}[#undef], 1, 1, 
1, 1), Granular.Atmosphere(false, [0.0], [0.0], [0.0], [0.0], [0.0], [0.0], 
[0.0], [0.0], Array{Int64,1}[#undef], 1, 1, 1, 1, false), 16)
```

After creating the simulation object `sim`, we will be presented with some 
output about the default contents of the `sim` simulation object.  This is of 
minor importance as of now, and can safely be ignored.

In the above `createSimulation` call, the `id` argument is optional. It is used 
to name simulation output files that are written to the disk.

### Adding grains one by one
We have now created a simulation object `sim`, which will be used during all of 
the following commands.  Next, we can add grains to this object.  The first 
grain is cylinder shaped, placed at the x-y position (0,0) m.  It has a radius 
of 0.1 m, and has a thickness of 0.05 m.  As this call modifies the `sim` 
object, the function contains an exclamation mark (!).  For further information 
regarding this call, see the reference to [`addGrainCylindrical!`](@ref), found 
in the [Public API documentation](@ref).

```julia-repl
julia> Granular.addGrainCylindrical!(sim, [0.0, 0.0], 0.1, 0.05)
INFO: Added Grain 1
```

Let's add another grain, placed at some distance from the first grain:

```julia-repl
julia> Granular.addGrainCylindrical!(sim, [0.5, 0.0], 0.1, 0.05)
INFO: Added Grain 2
```

We now want to prescribe a linear (not rotational or angular) velocity to the 
first grain to make it bump into the second grain.

The simulation object `sim` contains an array of all grains that are added to 
it.  We can directly inspect the grains and their values from the simulation 
object.  Let's take a look at the default value of the linear velocity, called 
`lin_vel`:

```julia-repl
julia> sim.grains[1].lin_vel
2-element Array{Float64, 1}:
 0.0
 0.0
```

The default value is a (0,0) vector, which means that it is not moving in 
space.  With a similar call, we can modify the properties of the first grain 
directly and prescribe a velocity to it:

```julia-repl
julia> sim.grains[1].lin_vel = [1.0, 0.0]
2-element Array{Float64, 1}:
 1.0
 0.0
```

The first grain (index 1 in `sim.grains`) now has a positive velocity along `x` 
with the value of 1.0 meter per second.

### Setting temporal parameters for the simulation
Before we can start the simulation we need to set some more parameters vital to 
the simulation, like what time step to use, how often to write output files to 
the disk, and for how long to run the simulation.  To set the computational 
time step, we call the following:

```julia-repl
julia> Granular.setTimeStep!(sim)
INFO: Time step length t=8.478741928617433e-5 s
```

A suitable time step is automatically determined based on the size and elastic 
properties of the grain.

The two grains are 0.3 meters apart, as the centers are placed 0.5 meter from 
each other and each grain has a radius of 0.1 m.  With a linear velocity of 1.0 
m/s, the collision should occur after 0.3 seconds.  For that reason it seems 
reasonable to run the simulation for a total of 1.0 seconds.  We choose to 
produce an output file every 0.05 seconds, but this can be tweaked to taste.  
We will later use the produced output files for visualization purposes.

```julia-repl
julia> Granular.setOutputFileInterval!(sim, 0.05)

julia> Granular.setTotalTime!(sim, 1.0)
```

### Running the simulation
We are now ready to run the simulation.  For illustrative purposes, let us 
compare the kinetic energy in the granular system before and after the 
collision.  For now, we compute the initial value using the following call:

```julia-repl
julia> Granular.totalGrainKineticTranslationalEnergy(sim)
0.7335618846132168
```

The above value is the total translational (not angular) kinetic energy in 
Joules before the simulation is started.

We have two choices for running the simulation; we can either run the entire 
simulation length with a single call, which steps time until the total time is 
reached and generates output files along the way.  Alternatively, we can run 
the simulation for a single time step a time, and inspect the progress or do 
other modifications along the way.

Here, we will run the entire simulation in one go, and afterwards visualize the 
grains from their output files using ParaView.

```julia-repl
julia> Granular.run!(sim)

INFO: Output file: ./two-grains/two-grains.grains.1.vtu
INFO: wrote status to ./two-grains/two-grains.status.txt
  t = 0.04239370964308682/1.0 s
INFO: Output file: ./two-grains/two-grains.grains.2.vtu
INFO: wrote status to ./two-grains/two-grains.status.txt

...

INFO: Output file: ./two-grains/two-grains.grains.20.vtu
INFO: wrote status to ./two-grains/two-grains.status.txt
  t = 0.9920128056483803/1.0 s
INFO: ./two-grains/two-grains.py written, execute with 'pvpython /Users/ad/code/Granular-ext/two-grains/two-grains.py'
INFO: wrote status to ./two-grains/two-grains.status.txt
  t = 1.0000676104805686/1.0 s
```

The code informs us of the simulation progress along the way.  It also and 
notifies us as output files are generated.  This output can be disabled by 
passing `verbose=false` to the `run!()` command.  Finally, the code tells us 
that it has generated a ParaView python file for visualization, called 
`two-grains.py`, located in the `two-grains/` directory.

We are interested in getting an immediate idea of how the collision went, 
before going further.  We can print the new velocities with the following 
commands:

```julia-repl
julia> sim.grains[1].lin_vel
2-element Array{Float64, 1}:
 7.58343e-5
 0.0

julia> sim.grains[2].lin_vel
2-element Array{Float64, 1}:
 0.999924
 0.0
```

The first grain has transferred effectively all of its kinetic energy to the 
second grain during the cause of the simulation.  The total kinetic energy now 
is the following:

```julia-repl
julia> Granular.totalGrainKineticTranslationalEnergy(sim)
0.7334506347624973
```

The before and after values for total kinetic energy are reasonably close (to 
less than 0.1 percent), which is what can be expected given the computation 
accuracy of the algorithm.

### Visualizing the output
To visualize the output we open [ParaView](https://www.paraview.org).  The 
output files of the simulation are written using the VTK (visualization 
toolkit) format, which is natively supported by ParaView.

While the `.vtu` files produced during the simulation can be opened with 
ParaView and visualized manually using *Glyph* filters, the simplest and 
fastest way to visualize the data is to use the Python script generated for the 
simulation by Granular.jl.

Open ParaView and open the *Python Shell*, found under the menu *Tools > Python 
Shell*.  In the pop-up dialog we select *Run Script*, which opens yet another 
dialog prompting us to locate the visualization script 
(`two-grains/two-grains.py` in our example).  We locate this file, which is 
placed under the directory from where we launched the `julia` session with the 
commands above.  If you are not sure what the current working directory for the 
Julia session is, it can be displayed with the command `pwd()` in the Julia 
shell.

After selecting the `two-grains/two-grains.py` script, we can close the *Python 
Shell* window to inspect our simulation visually.  Press the *Play* symbol in 
the top toolbar, and see what happens.

By default, the grains are colored according to their size.  Alternatively, you 
can color the grains using different parameters, such as linear velocity, 
number of contacts, etc.  These parameters can be selected by changing the 
chosen field under the *Glyph1* object in the *Pipeline Browser* on the left, 
and by selecting a parameter for *Coloring*.  Press the *Apply* button at the 
top of  the panel on the left to see the changes in effect.

**Tip:** If you have the command `pvpython` (ParaView Python) is available from 
the command line, you can visualize the simulation directly from the Julia 
shell without entering ParaView by the command `Granular.render(sim)`.  The 
program `pvpython` is included in the ParaView download, and is in the macOS 
application bundle located in 
`/Applications/Paraview-5.4.0.app/Contents/bin/pvpython`.  Furthermore, if you 
have the `convert` command from ImageMagick installed (`brew install 
imagemagick` on macOS), the output images will be merged into an animated GIF.

### Exercises
To gain more familiarity with the simulation procedure, I suggest experimenting 
with the following exercises.  *Tip:* You can rerun an experiment after 
changing one or more parameters by calling `Granular.resetTime!(sim); 
Granular.run!(sim)`.  Changes in grain size, grain mass, or elastic properties 
require a recomputation of the numerical time step 
(`Granular.setTimeStep!(sim)`) before calling `Granular.run!(sim)`.  The output 
files will be overwritten, and changes will be immediately available in 
ParaView.

- What effect does the grain size have on the time step?
- Try to make an oblique collision by placing one of the grains at a different 
    `y` position.
- What happens if the second grain is set to be fixed in space 
    (`sim.grains[2].fixed = true`)?
- How is the relationship between total kinetic energy before and after 
    affected by the choice of time step length?  Try setting different time 
    step values, e.g. with `sim.time_step = 0.1234` and rerun the simulation.

## Sedimentation of grains
Grains are known to settle under gravitation in water according to *Stoke's 
law*, where resistive drag acts opposite of gravity and with a magnitude 
according to the square root of velocity difference between water and grain.
Granular.jl offers simple fluid grids with prescribed velocity fields, and the 
grains are met with drag in this grid.

In this example (`examples/sedimentation.jl`) we will initialize grains with a 
range of grain sizes in a loose configuration, add gravity and a surrounding 
fluid grid, and let the grains settle towards the bottom.

As in the previous example, we start by creating a fluid grid:

```julia-repl
julia> import Granular
julia> sim = Granular.createSimulation(id="sedimentation")
```

### Creating a pseudo-random grain packing
Instead of manually adding grains one by one, we can use the 
`regularPacking!()` function to add a regular grid of random-sized grains to 
the simulation.  Below, we specify that we want the grid of grains to be 7 
grains wide along x, and 25 grains tall along y.  We also specify the grain 
radii to fall between 0.02 and 0.2 m.  The sizes will be drawn from a power-law 
distribution by default.

```julia-repl
julia> Granular.regularPacking!(sim, [7, 25], 0.02, 0.2)
```

Since we haven't explicitly set the grain sizes for this example, we can 
inspect the values by plotting a histogram of sizes (only works if the `PyPlot` 
package is installed with `Pkg.add("PyPlot")`):

```julia-repl
julia> Granular.plotGrainSizeDistribution(sim)
INFO: sedimentation-grain-size-distribution.png
```

The output informs us that we have the plot saved as an image with the file 
name `sedimentation-grain-size-distribution.png`.

### Creating a fluid grid
We can now create a fluid (ocean) grid spanning the extent of the grains 
created above:

```julia-repl
julia> Granular.fitGridToGrains!(sim, sim.ocean)
INFO: Created regular Granular.Ocean grid from [0.06382302477946442, 
0.03387419706945263] to [3.0386621000253293, 10.87955941983313] with a cell 
size of 0.3862075959573571 ([7, 28]).
```

The code informs us of the number of grid cells in each dimension (7 by 28 
cells), and the edge positions (x = 0.0638 to 3.04 m, y = 0.0339 to 10.9 m).

We want the boundaries of the above grid to be impermeable for the grains, so 
they stack up at the bottom.  Granular.jl acknowledges the boundary types with 
a confirmation message:

```julia-repl
julia> Granular.setGridBoundaryConditions!(sim.ocean, "impermeable")
West  (-x): impermeable (3)
East  (+x): impermeable (3)
South (-y): impermeable (3)
North (+y): impermeable (3)
```

### Adding gravitational acceleration
If we start the simulation now nothing would happen as gravity is disabled by 
default.  We can enable gravitational acceleration as a constant body force for 
each grain (`Force = mass * acceleration`):

```julia-repl
julia> g = [0.0, -9.8];
julia> for grain in sim.grains
       Granular.addBodyForce!(grain, grain.mass*g)
       end
```

### Setting temporal parameters
As before, we ask the code to select a suitable computational time step based 
on grain sizes and properties:

```julia-repl
julia> Granular.setTimeStep!(sim)
INFO: Time step length t=1.6995699879716792e-5 s
```

We also, as before, set the total simulation time as well as the output file 
interval:

```julia-repl
julia> Granular.setTotalTime!(sim, 10.0)
julia> Granular.setOutputFileInterval!(sim, 0.2)
```

### Running the simulation
We are now ready to run the simulation:

```julia-repl
julia> Granular.run!(sim)
INFO: Output file: ./sedimentation/sedimentation.grains.1.vtu
INFO: Output file: ./sedimentation/sedimentation.ocean.1.vts
INFO: wrote status to ./sedimentation/sedimentation.status.txt
  t = 0.19884968859273294/10.0 s
INFO: Output file: ./sedimentation/sedimentation.grains.2.vtu
INFO: Output file: ./sedimentation/sedimentation.ocean.2.vts
INFO: wrote status to ./sedimentation/sedimentation.status.txt
  t = 0.3993989471735396/10.0 s

...

INFO: Output file: ./sedimentation/sedimentation.grains.50.vtu
INFO: Output file: ./sedimentation/sedimentation.ocean.50.vts
INFO: wrote status to ./sedimentation/sedimentation.status.txt
  t = 9.998435334626701/10.0 s
INFO: ./sedimentation/sedimentation.py written, execute with 'pvpython /Users/ad/code/Granular-ext/examples/sedimentation/sedimentation.py'
INFO: wrote status to ./sedimentation/sedimentation.status.txt
  t = 10.00001593471549/10.0 s
```

The output can be plotted in ParaView as described in the `two-grain` example 
above, or, if `pvpython` is available from the command line, directly from 
Julia with the following command:

```julia-repl
julia> Granular.render(sim, trim=false)
```

### Exercises
- How are the granular contact pressures distributed in the final result?  You 
    can visualize this by selecting "Contact Pressure [Pa]" in the *Coloring* 
    field inside ParaView.
- Try running the above example, but without fluid drag.  Disable the drag by 
    including the call `Granlar.disableOceanDrag!(grain)` in the `for` loop 
    where gravitational acceleration is set for each grain.
- How does the range of grain sizes affect the result?  Try making all grains 
    bigger or smaller.
- How is the model performance effected if the grain-size distribution is 
    wide or narrow?
- Create a landslide by turning the gravitational acceleration vector (set the 
    `y` component to a non-zero value, and setting the side boundaries to be 
    periodic with `Granular.setGridBoundaryConditions!(sim.ocean, "periodic", 
    "east west")`.
