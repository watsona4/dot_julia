"""
Walk through `test_dir` directory and execute all tests, excluding `exclude`

```jldoctests
julia> using Spec
julia> walktests(Spec)
```
"""
function walktests(testmodule::Module;
                   test_dir = joinpath(dirname(pathof(testmodule)), "..", "test", "tests"),
                   exclude = [],
                   evalin::Module = Main)
  printstyled("Running tests:\n", color = :blue)

  # Single thread
  Random.seed!(345679)
  with_pre() do
    for (root, dirs, files) in walkdir(test_dir)
      for file in files
        if file ∈ exclude
          println("Skipping: ", file)
          continue
        end
        fn = joinpath(root, file)
        println("Testing: ", fn)
        evalin.eval(:(include($fn)))
      end
    end
  end
end