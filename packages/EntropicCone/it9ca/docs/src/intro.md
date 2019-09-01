# Introduction

## The definition of entropy

In 1948, Shannon published "A Mathematical Theory of Communication" [Sha48].
In this paper, Shannon introduces the entropy of a random variable.
Suppose we have a random variable ``X`` of alphabet ``\mathcal{X}``, he defines the entropy of ``X`` as
```math
H_b(X) = \sum_{x \in \mathcal{X}} \Pr[X = x] \log_b \frac{1}{\Pr[X = x]}
```
where the basis ``b`` is positive.
If ``b`` is 2 (resp. ``e``), the unit is the bits (resp. nats).
Note that ``H_b(X) = H_a(X) \log_b(a)`` so the entropies using different basis are equivalent up to a positive constant factor.

The entropy of several random variables in simply the entropy of their cartesian product:
```math
\begin{align*}
  H_b(\{X_1, \ldots, X_n\})
  & = \sum_{(x_1,\ldots,x_n) \in \mathcal{X}_1 \times \cdots \times \mathcal{X}_n} \Pr[(X_1, \ldots, X_n) = (x_1,\ldots,x_n)] \log_b \frac{1}{\Pr[(X_1, \ldots, X_n) = (x_1,\ldots,x_n)]}.
\end{align*}
```
By convention, we say that the entropy of an empty set of random variables is 0.

Given a ``n`` random variables, we can compute the entropy of any of the ``2^n`` subset of those ``n`` variables.
The entropic vector of a set of ``n`` random variables is a vector ``h``, indexed by the subsets of ``[n] = \{1, \ldots, n\}``,
such that ``h_S = H_b(\{\, X_i \mid i \in S\,\})``.

## The entropic cone

The *entropic cone* of ``n`` variables is the set of vectors of ``\mathbb{R}^{2^n-1}`` that are entropic:
```math
\mathcal{H}_n = \{\, h \in \mathbb{R}^{2^n-1} \mid \exists X_1, \ldots, X_n, \forall \emptyset \neq S \subseteq [n], h_S = H_b(\{\, X_i \mid i \in S\,\}) \,\}.
```
We do not include the dimension corresponding to the entropy of the empty set as it is zero to make the cone ``\mathcal{H}_n`` solid, i.e. full-dimensional.

[Sha48] Claude Elwood Shannon.
*A mathematical theory of communication*.
Bell System Technical Journal, 27:379–423 and 623–656, July and October 1948.
