using Test
using Exercism

@info "copy notebook and tests to temp dir"
temp_path = mktempdir()
cp("example-exercise.ipynb", joinpath(temp_path, "example-exercise.ipynb"))
cp("example-exercise-tests.jl", joinpath(temp_path, "example-exercise-tests.jl"))

# submission creator
p = pwd()
cd(temp_path)
@info "create submission from notebook"
Exercism.create_submission("example-exercise")
cd(p)
include(joinpath(temp_path, "example-exercise.jl"))
@info "run exercise tests on solution extracted by the package"
include(joinpath(temp_path, "example-exercise-tests.jl"))
