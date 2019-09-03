# based on https://dlmf.nist.gov/11.6.i
# not valid for real z < 0

const order_large = 10

_K_large(ν, z) = (1 / pi) * sum(gamma(k + 0.5) * (0.5z)^(ν - 2k - 1) / gamma(ν + 0.5 - k) for k in 0:order_large)

_K0_large(z) = _K_large(0, z)

_M_large(ν, z) = (1 / pi) * sum((-1)^(k + 1) * gamma(k + 0.5) * (0.5z)^(ν - 2k - 1) / gamma(ν + 0.5 - k) for k in 0:order_large)

_M0_large(z) = _M_large(0, z)
