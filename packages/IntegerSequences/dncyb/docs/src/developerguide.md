# Developer Guide

##  Workflow

The workflow is characterized by the decision to keep functions and the
corresponding test functions in the same file.
This enables easier and faster development in separate modules
and is also suggested by the relative independence of many individual
modules implementing different sequences.

The modules are combined to a package in a separate step.
The prerequisite for this is an internal file format whose (simple)
conventions must be adhered to.


## Module format

```
    # This file is part of IntegerSequences.
    # Copyright Name. License is MIT.

    (@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

    module ModuleName
    using  ...
    export f

    function f()
    end

    #START-TEST-###########################

    using Test

    function test()
    end

    function demo()
    end

    function perf()
    end

    function main()
        test()
        demo()
        perf()
    end

    main()

    end # module
```

## Package build

The package is build by executing BuildSequences.jl.
This will pars the individual module files and
recombine and distribute their content into three new files:

* IntegerSequences.jl
* runtests.jl
* perftests.jl

The functions in the module which come before the line starting with
"#START-TEST" will be copied to IntegerSequences.jl, the function test() will be
copied to runtests.jl, and the function perf() will be copied to perftests.jl.
Everything else will be discarded.

In particular: Do not edit IntegerSequences.jl, it is generated from the modules and will be overwritten! Instead edit the modules in the 'src' directory. These modules can and
should be tested standalone. Only construct IntegerSequences.jl with BuildSequences.jl
in a final step.


## Integer type and unicode use

All terms of all sequences have the same type. Currently this is the
type fmpz as provided by the Nemo library.

IntegerSequences supports the use of notation using unicode characters, especially the traditional notation used in number theory. For example we define
```
    τ(n) = Nemo.sigma(n, 0)
    μ(n) = Nemo.moebiusmu(n)
    V006171(n) = EulerTransform(τ)(n)
```
We also support new notations like the proposal from Knuth, Graham and
Patashnik in Concrete Mathematics:
"Let us agree to write ``m ⊥ n``, and to say `m is prime to n`, if ``m`` and ``n`` are relatively prime."
```
    ⊥(m, n) = isPrimeTo(m, n)
```
where `isPrimeTo` is defined as:
```
    isPrimeTo(n, k) = Nemo.gcd(fmpz(n), fmpz(k)) == fmpz(1)
```

For example ``⊥(n, ϕ(n))`` indicates if there is just one group of order ``n``.
But this is not only a concise mathematical formula, this is also valid Julia
code (defined in IntegerSequences). The predicate gives rise to the sequence of cyclic numbers, A003277 in the OEIS.

Similarly possible definitions of some sequences (not necessarily efficient ones
in the computational sense) are

```
    isA008578(n) = all(⊥(k, n)     for k in 1:n-1)
    isA002182(n) = all(τ(k) < τ(n) for k in 1:n-1)
    isA002110(n) = all(ω(k) < ω(n) for k in 1:n-1)
    isA131577(n) = all(Ω(k) < Ω(n) for k in 1:n-1)
```

Other examples for the use of unicode are products. ``∏(a, b)`` is defined as the
product of ``i`` in ``a:b`` if ``a ≤ b`` and otherwise ``1``. Building on
this short notations for the rising and the falling factorial powers are supported:

```
    ↑(n, k) = RisingFactorial(n, k)
    RisingFactorial(n::Int, k::Int) = ∏(n, n + k - 1)
    ↓(n, k) = FallingFactorial(n, k)
    FallingFactorial(n::Int, k::Int) = ∏(n - k + 1, n)
```

## Muliti-dimensional sequences

### The concept of a sequence

Sequences as considered here are weakly ordered sets and in fact we consider only infinite ordered sets. Thus something like

    a ≺ b ≺ c ≺ d ≺ ...

is an adequate picture of our concept. (Note that ≺ means 'precedes', not 'is less'.) The dynamic counterpart to this static view
is the iteration, in which the individual terms of the sequence are successively
returned in the given order by a generating function.

    a, b, c, d, ...

In the OEIS, on the other hand, a sequence is an enumeration, a set with an index function where the first index (called offset o) is specified. With this we arrive at this picture:

    ``a_o, a_{o+1}, a_{o+2}, a_{o+3}, ...``

In this view a list (representing the initial segment of the sequence)
takes the place of the iteration.

    ``[ a_{o}, a_{o+1}, a_{o+2}, ..., a_{o+n-1} ]``

In contrast in our setup the concept of offset and indexing does not occur at all but is transferred to the interpretation: only the application decides about indexing and offset. In practice our setup avoiding the use of an offset turns out
to be more flexible.

Another difference serves to be highlighted: In an iteration the length does not have to be determined beforehand, an iteration can be terminated at any time. In the case of a list, however, the length must be specified beforehand.

### 1-dim sequences

All this does not exclude that while describing a sequence informally
it is often useful to assume an enumeration. If not explicitly stated otherwise
we assume a sequence to be based in the origin 0 in the one dimensional
case and in (0, 0) in the case of triangles; similar with higher order sequences.

The main reason for these conventions is the representation of sequences by
formal power series, i.e.

    ``g(x) = a_{0}x^0 + a_{1}x^1 + a_{2}x^2 + ...``

The function `coefficients(g)` maps the series to the sequence

    ``a_{0}, a_{1}, a_{2}, ...``.


### 2-dim sequences

2-dimensional arrays come in two flavors: as parametrized sequences (family of
sequences) and as triangles (family of polynomials).
In this view the setup is according to our conventions:

##### T enumerated as a triangle (or coefficients of a family of polynomials)

| n\k | 0    | 1    | 2    | 3    | 4    | 5    |
| --- | ---- | ---- | ---- | ---- | ---- | ---- |
|**0**|T(0,0)|
|**1**|T(1,0)|T(1,1)|
|**2**|T(2,0)|T(2,1)|T(2,2)|
|**3**|T(3,0)|T(3,1)|T(3,2)|T(3,3)|
|**4**|T(4,0)|T(4,1)|T(4,2)|T(4,3)|T(4,4)|
|**5**|T(5,0)|T(5,1)|T(5,2)|T(5,3)|T(5,4)|T(5,5)|

##### T enumerated as a rectangle (or parametrized family of sequences)

|n\k  | 0    | 1    | 2    | 3    | 4    |...|
|---- | ---- | ---- | ---- | ---- | ---- |---|
|**0**|T(0,0)|T(1,1)|T(2,2)|T(3,3)|T(4,4)|...|
|**1**|T(1,0)|T(2,1)|T(3,2)|T(4,3)|T(5,4)|...|
|**2**|T(2,0)|T(3,1)|T(4,2)|T(5,3)|T(6,4)|...|
|**3**|T(3,0)|T(4,1)|T(5,2)|T(6,3)|T(7,4)|...|
|**4**|T(4,0)|T(5,1)|T(6,2)|T(7,3)|T(8,4)|...|

Informally we can say that pushing the k-th column of a triangle
up k cells transforms the triangle into the rectangle. Formally the indices
are transformed ``(n, k) ↦ (n+k, k)`` when proceeding from the triangle
form to the rectangular form.

### 3-dim sequences

3-dimensional arrays are implemented here only as parametrized triangles
(family of triangles). For example consider:

    ``T(n,k,m) = [t^n] Γ(n+k+m+t)/Γ(k+m+t) for n,m ≥ 0 and 0 ≤ k ≤ n.``

    A307419(n, k) = T(n, k, 0)
    A325137(n, k) = T(n, k, 1)
    A325139(n, k) = T(n, k, 2)

    A000254(n) = T(n+1, 1, 0) = A307419(n+1, 1)
    A001706(n) = T(n+2, 2, 0) = A307419(n+2, 2)
    A001713(n) = T(n+3, 3, 0) = A307419(n+3, 3)
    A001719(n) = T(n+4, 4, 0) = A307419(n+4, 4)

    A001705(n) = T(n+1, 1, 1) = A325137(n+1, 1)
    A001712(n) = T(n+2, 2, 1) = A325137(n+2, 2)
    A001718(n) = T(n+3, 3, 1) = A325137(n+3, 3)
    A001724(n) = T(n+4, 4, 1) = A325137(n+4, 4)

    A001711(n) = T(n+1, 1, 2) = A325139(n+1, 1)
    A001717(n) = T(n+2, 2, 2) = A325139(n+2, 2)
    A001723(n) = T(n+3, 3, 2) = A325139(n+3, 3)

## Preferred contributions

We prefer parametrized sequences (family of sequences) over single ones and
triangles (family of polynomials) over straight sequences. In other words, we
strongly encourage an top-down approach of the presentation. An example of this
style can be seen above in the 3-dim section.

Implementations of sequence-to-sequence transformations are always welcome.
