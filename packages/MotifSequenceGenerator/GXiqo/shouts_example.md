# Simple Motif Sequence
This example illustrates how the module [`MotifSequenceGenerator`](@ref) works using
a simple `struct`. For a more realistic, and much more complex example, see the
[example using music notes](link).

---

Let's say that we want to create a random sequence of "shouts", which
are described by the `struct`
```@example shout
struct Shout
  shout::String
  start::Int
end
```

Let's now create a vector of shouts that will be used as the pool of
possible motifs that will create the random sequence:
```@example shout
using Random
shouts = [Shout(uppercase(randstring(rand(3:5))), rand(1:100)) for k in 1:5]
```
Notice that at the moment the values of the `.start` field of `Shout` are irrelevant. `MotifSequenceGenerator` will translate all motifs to start point 0 while operating.

Now, to create a random sequence, we need to define two concepts:
```@example shout
shoutlimits(s::Shout) = (s.start, s.start + length(s.shout) + 1);

shouttranslate(s::Shout, n) = Shout(s.shout, s.start + n);
```
This means that we accept that the temporal length of a `Shout` is `length(s.shout) + 1` (so that the dude that shouts can rest a bit...).

We can now create random sequences of shouts that have total length of
*exactly* `q`:
```@example shout
using MotifSequenceGenerator
q = 30
random_sequence(shouts, q, shoutlimits, shouttranslate)
```
```@example shout
random_sequence(shouts, q, shoutlimits, shouttranslate)
```
Notice that it is impossible to create a sequence of length e.g. `7` with the above pool
```@example shout
random_sequence(shouts, 7, shoutlimits, shouttranslate)
```
