# DotTestSets

The `DotTestSets` module provides the [custom test
set](https://docs.julialang.org/en/v1/stdlib/Test/index.html#Creating-Custom-AbstractTestSet-Types-1)
type `DotTestSet`, which (to some extent) emulates the behavior of Python's
`unittest` (in non-verbose mode), with line-wrapping. For example, the
following test suite …

```
using Test, DotTestSets, Primes

@testset DotTestSet begin
    for i = 1:100
        @test i ≠ 39
    end
end
```

… produces the following output:

```text
......................................F...............................
..............................
----------------------------------------------------------------------
Test Failed at /Users/mlh/Dropbox/DotTestSets.jl/test/runtests.jl:5
  Expression: i ≠ 39
   Evaluated: 39 ≠ 39
----------------------------------------------------------------------
Ran 100 tests in 0.947 s

FAILED (failures=1)
```

Nesting `DotTestSet`s yield just a single stream of dots. Errors are marked
with `E`:

```
using Test, DotTestSets

@testset DotTestSet begin

    @test error()

end
```

This yields the following output:

```text
E
----------------------------------------------------------------------
Error During Test at ...
  Test threw exception
  Expression: error()

  Stacktrace:
   [1] error() at ./error.jl:42
   ...
----------------------------------------------------------------------
Ran 1 tests in 1.277 s

FAILED (errors=1)
```
