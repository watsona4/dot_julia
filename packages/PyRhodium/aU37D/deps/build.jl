using PyCall
using Conda

Conda.add("pip")
Conda.add("seaborn")
Conda.add("scikit-learn")
Conda.add("qt")
Conda.add("graphviz")
Conda.add("pydot")

pip = joinpath(Conda.SCRIPTDIR, "pip")
run(`$pip install --no-deps --force-reinstall mpldatacursor`)
run(`$pip install --no-deps --force-reinstall SAlib`)
run(`$pip install --no-deps --force-reinstall git+https://github.com/Project-Platypus/PRIM.git\#egg=prim`)
run(`$pip install --no-deps --force-reinstall git+https://github.com/Project-Platypus/Platypus.git\#egg=platypus`)
run(`$pip install --no-deps --force-reinstall git+https://github.com/Project-Platypus/Rhodium.git\#egg=rhodium`)
