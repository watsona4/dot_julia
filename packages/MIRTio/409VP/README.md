# MIRTio.jl
https://github.com/JeffFessler/MIRTio.jl


File I/O routines for
[MIRT (Michigan Image Reconstruction Toolbox) in Julia](https://github.com/JeffFessler/MIRT.jl)

This code is isolated from the main MIRT.jl toolbox,
because testing these functions
requires large files
that are not part of the repo.
By such isolation,
the code coverage reported
over at
[MIRT.jl](https://github.com/JeffFessler/MIRT.jl)
is representative of the algorithms there,
separate from I/O issues.

This software was developed at the
[University of Michigan](https://umich.edu/)
by
[Jeff Fessler](http://web.eecs.umich.edu/~fessler)
and his
[group](http://web.eecs.umich.edu/~fessler/group).

This code is a package dependency of MIRT.jl,
so most users will never clone this repo directly.
Installing MIRT
by following the instructions at
https://github.com/JeffFessler/MIRT.jl
will automatically include this code
through the magic of Julia's package manager.
