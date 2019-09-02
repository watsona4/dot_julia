# Use of the OEIS

We emphasize that references to the Online Encyclopedia of Integer Sequences always mean only that information about the sequence can be found in this database, never that we necessarily implement the definition used there.

There is a variety of reasons to deviate occasionally from the definitions used in the OEIS.

* Many sequences there are frozen by the editor in chief for so-called 'historical reasons' (for example because they were published in this form in printed versions of the encyclopedia or referenced in scientific papers).

* Conventions in the OEIS are used that made more sense in times of punch cards than today, for example the suppression of 0's in many series expansions.

* If there exists a natural generalization with which the given sequence can be expressed more systematically then we will use it. In particular we give preference to the formal definition over an interpretation of a sequence.

* We always try to specify the full extension of a sequence to the domain ℕ = {0, 1, 2, 3, ...} or to ℕ X ℕ. In practice this often means that we use a different offset than the one in the OEIS, for example by prepending s(0) to a sequence or a first column on the left hand side of a triangle which is (1, 1)-based in the OEIS.

#### Example: an arithmetic function

For instance the Möbius function has the simple definition μ(1) = 1 and for all other n ∈ ℕ is

    μ(n) = − ∑ d ∈ δ(n) : μ(d)  where  δ(n) = {1 < d < n: d|n}

are the proper divisors of n. We see that the special case n = 0 is covered by the formula: since δ(0) is empty the sum is zero and thus μ(0) = 0. (As a side note: Mathematica's Möbius function behaves exactly this way.)

So we do not take the (meta-) point of view: "This is an arithmetical function and thus not defined for n = 0."; rather we say: "This is the nice definition of a nice sequence and if someone wants to use only parts of this sequence for whatever reason we leave that restriction to him or her.".

_We always defend the sequence against the interpretation_.

#### Example: a triangle with left column cut off

There are many such examples in the OEIS, for instance the nice triangle of tangent numbers (A059419). However the author chose to define it only for (1 ≤ k ≤ n). Thus the natural representation of the triangle by Bell polynomials was prevented and in innumerable small formulas, which refer to these numbers, special cases or restrictions had to be added. Not even the sequence of the row sums (A006229) matches the offset. Such unfortunate inconsistencies must always be taken into account (but not reproduced) when checking the correctness of our implementations.
