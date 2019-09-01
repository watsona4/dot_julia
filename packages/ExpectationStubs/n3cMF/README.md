# ExpectationStubs
[![Build Status](https://travis-ci.org/oxinabox/ExpectationStubs.jl.svg?branch=master)](https://travis-ci.org/oxinabox/ExpectationStubs.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/46sjp95g6xy9wwt1/branch/master?svg=true)](https://ci.appveyor.com/project/oxinabox/expectationstubs-jl/branch/master)





This package exists to help you make testing stubs.
Its not to help you do patch mocks into code:
for that see [Mocking.jl](https://github.com/invenia/Mocking.jl).

In theory the stubs created using ExpectationStubs
are ideal for patching in with Mocking.jl.
This is still in alpha, and that hasn't been tested yet.
(Raise an issue and let me know if that works.)

These stub are ideal for if you already have dependency injection of functions set up.

For purposes of this package, a stub and a mock at the same thing.


There are 5 key functions (check their docstrings on the REPL).

 - `@stub foo`: declares a stub called `foo`
 - `@expect foo(::Integer, 8.5)=77`: sets up an expectation that `foo` will be called with an `Integer` and the exact value `8.5`. and if so it is to return `77`
 - `@used  foo(100, ::Real)` checks to see if `foo` was called with the the exact value `100` and something of type `Real`
 - `@usecount foo(100, ::Real)` as per `@used` except returns the number of times called
 - `all_expectations_used(foo)` checks that every expectation declared on `foo` was used (returns a `Bool`).

### Example Usage

Lets say I have a function that checks on the status of say some pipe
and if it has too much pressure, takes some response:
normally calling a function called `email`


```julia
function check_status(pressure, its_bad_callback=email)
    if pressure > 9000
        its_bad_callback("phil@example.com", "Darn it Phil, the thing is gonna blow")
        return false
    end
    true
end
```

Now, when testing this function out, I don't want Phil to get 100s of emails.
So I want to replace the `its_bad_callback` with some mock.

So I could write a little closure in my testing code,
and have that closure set a variable and then check that variable,
to see how it was called.
And that is pretty good.
But it is a bit adhock.

Enter ExpectationStubs.jl

```julia
using Base.Test
using ExpectationStubs

@testset "Check the pipe" begin
    @stub fakeemail
    @expect fakeemail("phil@example.com", ::AbstractString) = nothing # no return

    # check what happens if everything is OK
    @test check_status(1000, fakeemail) == true
    @test !@used fakeemail("phil@example.com", ::Any)
    ### Better not email Phil if everything is going ok.
    @test check_status(9007, fakeemail) == false
    @test @used fakeemail("phil@example.com", ::Any)
end
```
