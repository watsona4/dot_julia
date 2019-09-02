`jlm`: System image manager for Julia
=====================================

Installation
------------

.. code-block:: jlcon

   (v1.1) pkg> add JuliaManager
   ...

   julia> using JuliaManager

   julia> JuliaManager.install_cli()
   ...

You need to add `~/.julia/bin` to `$PATH` as would be messaged if it
not.

Examples
--------

Standard usage
~~~~~~~~~~~~~~

.. code-block:: console

   $ cd PATH/TO/YOUR/PROJECT

   $ jlm init
   ...

   $ jlm run
                  _
      _       _ _(_)_     |  Documentation: https://docs.julialang.org
     (_)     | (_) (_)    |
      _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
     | | | | | | |/ _` |  |
     | | |_| | | | (_| |  |  Version 1.1.0 (2019-01-21)
    _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
   |__/                   |

   julia>


Using MKL.jl-patched Julia and standard Julia side-by-side
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

`MKL.jl`_ is a convenient way of using Intel's Math Kernel Library
(MKL) with Julia.  However, it still has some caveats and difficult to
use standard Julia installation since precompilation cache are shared.
This problem can be avoided by using ``jlm`` to separate compilation
cache paths for MKL.jl and non-MKL.jl Julia.  This way, both Julia
installations can be used simultaneously without invoking repeated
precompilation.

.. _`MKL.jl`: https://github.com/JuliaComputing/MKL.jl

As `MKL.jl`_ overwrites its Julia installation, you need to create a
dedicated Julia installation.  Suppose it's done by

.. code-block:: console

   $ mkdir -p ~/opt/julia-mkl
   $ cd ~/opt/julia-mkl
   $ cd tar xf ~/Downloads/julia-1.1.0-linux-x86_64.tar.gz

Then create a project and install MKL.jl in it.  Note that it is
better be done in a separate project to avoid installing MKL.jl where
standard (non-MKL.jl) Julia may accidentally instantiate and build it.
This isolation is done by ``--project=.``:

.. code-block:: console

   $ cd PATH/TO/PROJECT
   $ ~/opt/julia-mkl/julia-1.1.0/bin/julia \
       --startup-file=no --compiled-modules=no --project=.
   ...

   (PROJECT) pkg> add https://github.com/JuliaComputing/MKL.jl

You may also need to run ``pkg> build MKL``.

Finally, use `jlm` to isolate precompilation cache:

.. code-block:: console

   $ jlm init ~/opt/julia-mkl/julia-1.1.0/bin/julia
   ...

   $ jlm run --project=.
      _       _ _(_)_     |  Documentation: https://docs.julialang.org
     (_)     | (_) (_)    |
      _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
     | | | | | | |/ _` |  |
     | | |_| | | | (_| |  |  Version 1.1.0 (2019-01-21)
    _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
   |__/                   |

(This may cause (re)compilation of cache files if you import some
packages in ``~/.julia/config/startup.jl``.)

In Julia REPL, you can check if `jlm` is using the correct version of
Julia by

.. code-block:: jlcon

   julia> Base.julia_cmd().exec[1]
   "/home/USER/opt/julia-mkl/julia-1.1.0/bin/julia"

   julia> using LinearAlgebra

   julia> BLAS.vendor()
   :mkl


Manual
------

.. default-role:: code

.. argparse::
   :module: jlm.cli
   :func: make_parser
   :prog: jlm
