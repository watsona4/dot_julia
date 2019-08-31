@test RectangularBinning(2) isa RectangularBinning
@test RectangularBinning(2.0) isa RectangularBinning
@test RectangularBinning([2.0, 1.0]) isa RectangularBinning
@test RectangularBinning([3, 5]) isa RectangularBinning
@test RectangularBinning(([(1.0, 2.0), (2.0, 3.0)], 2)) isa RectangularBinning
@test RectangularBinning([(-1, 2), (2, 3)], 3) isa RectangularBinning
@test RectangularBinning([-1.0:2.0, 2:3, 5:10.0], 3) isa RectangularBinning
@test RectangularBinning(-5:5, -2:2, n_intervals = 10) isa RectangularBinning