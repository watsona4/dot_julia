# Ideas for future development

## Maintaining performance via sortedness and views

The classes in this package serve dual roles: they server as annotation of arbitrary collections of genomic
positions, but they also as indices into that annotation. By allowing an arbitrary ordering of features
(genome positions, ranges etc.) these classes can represent an ordering of their associated data (e.g. sorting
by significance). Additionally, by not breaking data up into chunks by chromosome, we enable many conveniences.

These ordering decisions have performance implications. The current strategy is to support faster searching of
genome positions when data are arranged in genome order. For example, looking up the relevant chromosome for
`n` data points in `k` chromosomes is is `O(n)` for sorted positions and `O(n * log(k))` for unordered
data. (A single genome -> chromosome lookup is always `O(log(k))` as the chromosome boundary data are
maintained in sorted order).

In the future we may attempt to maintain the benefits arbitrary ordering and also of fast searching by
maintaining position data in an efficient representation (ordered, IntervalTree, NC list, etc.) in addition to a `View`
representing the arbitrary ordering.
