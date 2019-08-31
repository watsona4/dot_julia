using BHAtp
using Test

#=
Compare formulas at:
http://www.awc.org/pdf/codes-standards/publications/design-aids/AWC-DA6-BeamFormulas-0710.pdf
=#

println("Test when editing in Atom\n")

N = 20
Np1 = N + 1
Nhp1 = Int(N/2) + 1

data = Dict(
  # Frame(nels, nn, ndim, nst, nip, finite_element(nod, nodof))
  :struc_el => Frame(N, Np1, 3, 1, 1, Line(2, 3)),
  :properties => [1.0e6 1.0e6 1.0e6 3.0e5;],
  :x_coords => range(0, stop=4, length=Np1),
  :y_coords => zeros(Np1),
  :z_coords => zeros(Np1),
  :g_num => [
    collect(1:N)';
    collect(2:Np1)'],
  :support => [
    (1, [1 0 0 0 0 0]),
    (Np1, [0 0 0 0 0 0]),
    ],
  :loaded_nodes => [
    (Nhp1, [0.0 -10000.0 0.0 0.0 0.0 0.0])]
)

@time m, dis_df, fm_df = p44_1(data)

# See figure 24 in above reference (Δmax):
@eval @test round.(m.displacements[2,Nhp1], digits=11) ≈ -0.00333333333

# See figure 24 in above reference (Mmax):
@eval @test m.actions[12,Nhp1] ≈ 3999.9999999975844
