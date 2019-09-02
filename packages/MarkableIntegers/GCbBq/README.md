# Markable&thinsp;Integers

### Signed and Unsigned Integers, individually [un]markable.

##### - all are introduced in the _unmarked_ state
-- elements are marked by attaching a _note_
-- elements are unmarked by removing that _note_


####  Two-state Integers (unmarked state, marked state)

#### Released under the MIT License. &nbsp; &nbsp; &nbsp; &nbsp;Copyright &copy; 2018 by Jeffrey Sarnoff.

> _this package requires Julia v0.7-_

----
## Purpose

MarkableIntegers allow elements (integer values) of a sequence, mesh, voxel image, or time series to be distinguished. Any one or more of the constituent numbers may be noted with a mark (a re-find-able tag).  Marking one value does not mean that all other occurances of that value become marked.  You may choose to mark some, all or none of the other occurances of that value.

You may be seeking to identify regions within the dataform or datastream that are of some greater interest.  Often this requires preliminary identification, contextual refinement, and revisiting.  There are well-know methods to manage this sort of incremental refinement.  All lean on ancillary data structures and dynamic update.

MarkableIntegers bring the ability to provide and refine algorithmic focus into the data per se.  For some applications, this suffices.  For others, intelligent use of ancillary data structures and dynamic update therewith in concert with markable integers is the right complement.

----

## Techniques (please add yours)

An easy way to find more lengthy runs of marked values is to run length encode the Bool sequence obtained with map(ismarked, seq).  A way to find more highly valued regions of marked values is to sum over each run.

One may mark values which are inconsistent with an underlying model or are otherwise suspect (e.g. values that appear to be "drop outs").  The unmarked values could then provide a neater view with which to begin exploration. Or, the marked values may be used as targets for simple fitting to provide a more digestable version of the info.

With evolutionary or swarm intellegence approaches (simulated annealing, ant colony, tabu search, ...) better solution spaces develop through process.  There may be an opportunity for speedup by using local markers to influence aspects of the process.




----
## Introduction

There are `Markable` versions of each `Signed` (`Int8`, `Int16`, `Int32`, `Int64`, `Int128`) and each `Unsigned` (`UInt8`, `UInt16`, `UInt32` ,`UInt64`, `UInt128`) type.  The `Markable` types are prefixed with `Mark` (`MarkInt32`, `MarkUInt64`).

For most uses, you do not need to be that specific.  Variables that hold markable integers are initialized with (constructed from) some `Signed` or `Unsigned` value (or with e.g. `zero(MarkInt)`, `one(MarkInt16)`).

You can use `Unmarked` or `Marked` with any legitimate initializer and forget about the specific type names. `ismarked` and `isunmarked` are provided to ascertain markedness during computation.  `allmarked` and `allunmarked` let you collect over markedness.

```julia
julia> an_unmarked_value = Unmarked(10)
10
julia> a_marked_value = Marked(16)
16

julia> isunmarked(an_unmarked_value), ismarked(an_unmarked_value)
true, false

julia> isunmarked(a_marked_value), ismarked(a_marked_value)
false, true
```

There are two ways of marking an unmarked value or unmarking a marked value.
The first way uses the same form as is used with initialization. The result must be assigned to some value to be of use. The second uses macros to change values in place.  The macros reassign the variable given.

```julia
julia> ten = Unmarked(10)
10
julia> sixteen = Marked(16)
16

julia> isunmarked(ten)
true
julia> ten = Marked(ten)
10
julia> isunmarked(ten)
false

julia> ismarked(sixteen)
true
julia> sixteen = Unmarked(sixteen)
16
julia> ismarked(sixteen)
false
```

```julia
julia> ten = Unmarked(10);
julia> sixteen = Marked(16);
julia> @mark!(ten)
10
julia> @unmark!(sixteen)
16
julia> ismarked(ten), isunmarked(sixteen)
true, true

julia> @unmark!(ten);
julia> @mark!(sixteen);
julia> isunmarked(ten), ismarked(sixteen)
true, true
```
MarkableSigned integers readily convert to Signed and MarkableUnsigned integers readily convert to Unsigned.  `Signed` and `Unsigned` provide these conversions.

```julia

julia> markable_two = Unmarked(Int64(2));
julia> markable_three = Marked(UInt16(3));

julia> typeof(markable_two), typeof(markable_three)
(MarkInt64, MarkUInt16)

julia> two = Signed(markable_two);
julia> three = Unsigned(markable_three);

julia> typeof(two), typeof(three)
(Int64, UInt16)
```

You can gather the marked values and the unmarked values.
```julia
julia> seq = [Marked(1), Unmarked(2), Unmarked(3), Marked(4), Unmarked(1)]
julia> allmarked(seq)
julia> allunmarked(seq)

```
----

## Exports

#### Constructors
- Unmarked, Marked
- Signed, Unsigned

#### Abstract and Collective Types
- `MarkableInteger`, `MarkableSigned`, `MarkableUnsigned`

#### Concrete Types
- `MarkInt`, `MarkInt8`, `MarkInt16`, `MarkInt32`, `MarkInt64`, `MarkInt128`
- `MarkUInt`, `MarkUInt8`, `MarkUInt16`, `MarkUInt32`, `MarkUInt64`, `MarkUInt128`

#### Predicates
 - `ismarked`, `isunmarked`
 - `allmarked`, `allunmarked`
 
#### Comparatives
  - `==`, `!=`, `<=`, `<`, `>=`, `>`
  - `isless`, `isequal`

#### Bitwise Primitives (wip)
  - `leading_zeros`, `trailing_zeros`, `leading_ones`, `trailing_ones`
  - `count_zeros`, `count_ones`

#### Bitwise Logic
- `~`, `&`, `|`, `⊻`
  
#### Math
  - `abs`, `signbit`, `sign`
  - `+`, `-`, `*`, `div`, `fld`, `cld`, `rem`, `mod`
  - `/`
  

