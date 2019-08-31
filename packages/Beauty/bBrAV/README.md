# Beauty.jl

Beauty.jl provides Beauty for the output of your julia programs.

NEVER include it in a package (as a fixed dependency): Beauty.jl
achieves what it does through type piracy.  That is not a good idea in
general but the only way to alter output for types defined in other
packages.

DO include it as a user if you want to e.g. limit output of decimals.

Also, do read the
[documentation](https://quantum-factory.de/open-source/Beauty.jl/).

Beauty.jl: Beauty for julia programs is Copyright (C) 2019 Quantum
Factory GmbH and published under the
[GPL3](https://github.com/Quantum-Factory/Beauty.jl/blob/master/LICENSE).
