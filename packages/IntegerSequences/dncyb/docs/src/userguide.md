# User Guide

## Naming conventions

The function names follow the registration numbers of the
[OEIS](https://oeis.org "Online Encyclopedia of Integer Sequences").
We use the following prefixes to indicate the type of the function.

Prefix | Function Type
------ | -------------
C  | Coroutine (channel)
F  | Filter (not exceeding n)
G  | Generating function
I  | Iteration (over n terms)
L  | List (array based)
M  | Matrix (2-dim square)
R  | Real function (Float64)
S  | Staircase (list iteration)
T  | Triangle (list iteration)
TA | Triangle (triangular array)
TL | Triangle (flat-list array)
V  | Value (single term)
is | is a member (predicate query)

These conventions can be seen as an application programming interface
which we explain by three examples.

### Example 1: Fibonacci numbers

For the Fibonacci numbers we offer 7 functions:

    I000045, F000045, G000045, L000045, V000045, R000045, is000045.

Four of those are based on the iteration protocol `FiboIterate` which is kept intern.
The implementations are:

* Iterate over the first ``n`` Fibonacci numbers.
```javascript
I000045(n) = FiboIterate(n)
```

* Iterate over the Fibonacci numbers which do not exceed ``n``.
```javascript
F000045(n) = takewhile(k -> k <= n, FiboIterate(n+1))
```

* Return the first ``n`` Fibonacci numbers in an array.
```javascript
L000045(n) = collect(FiboIterate(n))
```
Alternatively one can use a generating function if available:
```javascript
L000045(n) = coefficients(G000045, n)
```

* Return the ``n``-th Fibonacci number.
```javascript
function V000045(n)
   F = ZZ[1 1; 1 0]
   Fn = F^n
   Fn[2, 1]
end
```

* Fibonacci function for real values, returns a Float64.
```javascript
function R000045(x::Float64)
    (Base.MathConstants.golden^x - cos(x Base.MathConstants.pi)
        Base.MathConstants.golden^(-x)) / sqrt(5)
end
```

* Query if ``n`` is a Fibonacci number, returns a Bool.
```javascript
function is000045(n)
    d = 0
    for f in FiboIterate(n+2)
        d = n - f
        d <= 0 && break
    end
    d == 0
end
```

### Example 2: Abundant numbers

For the abundant numbers (i.e. numbers n where the sum of divisors exceeds 2n) we offer 5 functions:

   is005101, I005101, F005101, L005101, V005101

* Is ``n`` an abundant number, i.e. is ``σ(n) > 2 n `` ?
```javascript
is005101(n) = σ(n) > 2 n
```

* Iterate over the first ``n`` abundant numbers.
```javascript
I005101(n) = takefirst(isAbundant, n)
```

* Iterate over the abundant numbers which do not exceed ``n``.
```javascript
F005101(n) = filter(isAbundant, 1:n)
```

* Return the first ``n`` abundant numbers in an array.
```javascript
L005101(n) = collect(I005101(n))
```

* Return the value of the ``n``-th abundant number.
```javascript
V005101(n) = nth(I005101(n), n)
```

## Number triangles

#### Definition

To construct a number triangle one has to provide a function
t(n, k) defined for all integers n and k with n >= 0 and 0 <= k <= n.
Note that this corresponds to an infinite lower triangular matrix which is (0, 0)-based.
This deviates from the usual indexing of Julia matrices which are (1, 1)-based,
but the mother of all number triangles is Pascal's triangle which is (0, 0)-based
and in our application it is more convenient to follow the lead of Blaise than
that of Julia.

The matrix view of a number triangle of dimension dim has dim rows and the n-th row has length n.
Note that the rows are enumerated like the terms 0, 1, 2, ...

```javascript
    T(0,0)                          row 0
    T(1,0) T(1,1)                   row 1
    T(2,0) T(2,1) T(2,2)            row 2
    T(3,0) T(3,1) T(3,2) T(3,3)     row 3
```

However, our model is not that of a matrix, rather that of an iteration,
actually an iteration over lists. In this abstract view a triangle T is a
chain of lists. On the first level a triangle iterates over the rows of the
triangle and on the secondary level over the terms of the rows, which are
given by the user-supplied function t(n, k).

```javascript
    T = (row(0), row(1), ..., row(dim-1))
    Row(T, n) = [t(n, 0), t(n, 1), ..., t(n, n)]
```

#### Constructing

Sequence A097805 gives the number of ordered partitions of n into k parts.
The corresponding triangle can be constructed like this:
* Triangle T097805 based of explicite value.
```javascript
V097805(n, k) = k == 0 ? k^n : binomial(n-1, k-1)
T097805(dim) = Triangle(dim, V097805)
```

Many number triangles can be efficiently implemented by recurrence.
To support this the type RecTriangle has a buffer which saves the
previously computed row. This buffer can be accessed through a function 'prevrow'.  

* Triangle T097805 based on recurrence.
```javascript
R097805(n, k, prevrow) = k == 0 ? k^n : prevrow(k-1) + prevrow(k)
T097805(dim) = RecTriangle(dim, R097805)
```

This function is much more efficient than the version above. Note that you do not have
to provide the function prevrow as long as you use the function R097805 in the definition
of a triangle. The name 'prevrow' is not fixed but recommended as a convention.
A nice alternative for 'prevrow' is 'Tn_1' because Tn_1(k) = T(n-1, k) in matrix notation.

#### Triangle tools

The following functions are supplied:

* Return the row n (0 <= n < dim) of a triangle.
```javascript
Row(T::Triangle, n::Int, rev=true) = rev ? reversed(T(n)) : T(n)
```
If in the call the third -- optional -- parameter `rev` is true the
row is returned in reversed order.

* Return the triangle as a list of rows.
```javascript
TriangularArray(T::Triangle) = [row for row in T]
```

* Return the triangle as a list of integers.
```javascript
TriangleToList(T::Triangle) = [k for row in T for k in row]
```

Thus applying TriangleToList to a triangle of dimension dim
returns a list of integers of length dim(dim + 1)/2. Conversely, given
an integer list of length n(n + 1)/2 the function ListToTriangle returns a
triangle as a chain of iterators.
```javascript
ListToTriangle(A::Array{})
```

## Notebook

More examples can be found in this [Jupyter notebook](https://github.com/OpenLibMathSeq/IntegerSequences.jl/blob/master/demos/SequencesIntro.ipynb).

## Contribute!

Sequences are fun!  

* Start with cloning the module [NarayanaCows](https://github.com/OpenLibMathSeq/IntegerSequences.jl/blob/master/src/NarayanaCows.jl)
as a blueprint. Replace what is to be replaced.

* Execute the module 'BuildSequences' which will integrate your module into 'IntegerSequences.jl'.

* Send us a pull request.

We want to include only sequences which are of mathematical interest.
Please make sure that they are already documented in the Online Encyclopedia of
Integer Sequences, otherwise please submit them first to the OEIS.

We prefer parametrized sequences (family of sequences) over single ones and
triangles (family of polynomials) over straight sequences. Implementations of
sequence-to-sequence transformations are always welcome.
