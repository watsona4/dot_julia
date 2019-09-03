# based on https://dlmf.nist.gov/11.2.i
# for |z| << 1

const order_small = 10

_inner_small(n, ν, z) = (0.5z)^(2n) / (gamma(n + 1.5) * gamma(n + ν + 1.5))

_H_small(ν, z) = (0.5z)^(ν + 1) * sum((-1)^n * _inner_small(n, ν, z) for n in 0:order_small)

_L_small(ν, z) = (0.5z)^(ν + 1) * sum(_inner_small(n, ν, z) for n in 0:order_small)

