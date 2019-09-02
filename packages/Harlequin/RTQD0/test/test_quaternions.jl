# Check of handedness
@test rotationmatrix_normalized(qrotation_x(π/2)) * [0, 1, 0] ≈ [0, 0, 1]
@test rotationmatrix_normalized(qrotation_y(π/2)) * [1, 0, 0] ≈ [0, 0, -1]
@test rotationmatrix_normalized(qrotation_z(π/2)) * [1, 0, 0] ≈ [0, 1, 0]

# Simple composition of rotations
@test qrotation_x(π/3) * qrotation_x(π/3) ≈ qrotation_x(2π/3)
@test qrotation_y(π/3) * qrotation_y(π/3) ≈ qrotation_y(2π/3)
@test qrotation_z(π/3) * qrotation_z(π/3) ≈ qrotation_z(2π/3)

# More complex compositions
comp = qrotation_y(π/2) * qrotation_x(π/2)
@test rotationmatrix_normalized(comp) * [0, 1, 0] ≈ [1, 0, 0]

comp = qrotation_z(π/2) * qrotation_y(π/2)
@test rotationmatrix_normalized(comp) * [0, 0, 1] ≈ [0, 1, 0]
