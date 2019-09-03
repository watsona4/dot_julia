
x = range(0, stop=0.2, length=10)
y = zeros(size(x))
z = zeros(size(x))
r = [x'; y'; z']
a = randn(10).^2  # squared to make sure the're all positive

# Different types to check promotion
h = 1.02 * ones(Float32, length(a))
g = 1.04 * ones(Float16, length(a))

weird_zoop = Scatterer(r, a, h, g)
werid_zoop = Scatterer(r, a, 1.02, 1.04)
werid_zoop = Scatterer(r, a, 1.02, 1)


# Make sure all models load
krill1 = Models.krill_mcgeehee
krill2 = Models.krill_conti
cope = Models.calanoid_copepod
sandeel = Models.sandeel
daphnia = Models.daphnia


@assert length(rotate(krill1, roll=90, tilt=30, yaw=12)) ≈ length(krill1)
@assert length(resize(krill1, 0.03)) == 0.03
