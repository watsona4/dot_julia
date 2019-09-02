@LinearAdjoints.assemblevector (a, c) b function f(a, c)
	@assert length(a) == length(c)
	b = Array{Float64}(undef, length(a))
	for i = 1:length(b)
		b[i] = a[i] ^ 2 + exp(c[end - i + 1])
	end
	return b
end

n = 10
a = randn(n)
c = randn(n)
b = f(a, c)
@test b == a .^ 2 + exp.(reverse(c))
b_p = f_p(a, c)
trueb_p = zeros(2 * n, n)
for i = 1:n
	trueb_p[i, i] = 2 * a[i]
	trueb_p[n + i, n - i + 1] = exp(c[i])
end
@test Matrix(b_p) == trueb_p
