export Quaternion, rotationmatrix_normalized, qrotation_x, qrotation_y, qrotation_z

import Base: *, ≈

@doc raw"""
A structure representing a quaternion.

Stripeline uses quaternions to encode rotations when generating pointings. The
fields of `Quaternion` are:

- `s`
- `v1`
- `v2`
- `v3`

It is possible to multiply quaternions using the `*` operator. Constructors for
rotation quaternions are provided by `qrotation_x`, `qrotation_y`, and
`qrotation_z`.

`Quaternion` implements the `≈` binary relationship, in order to ease the
implementation of tests.
"""
struct Quaternion
    s::Float64
    v1::Float64
    v2::Float64
    v3::Float64
end

(*)(q::Quaternion, w::Quaternion) = Quaternion(q.s * w.s - q.v1 * w.v1 - q.v2 * w.v2 - q.v3 * w.v3,
                                               q.s * w.v1 + q.v1 * w.s + q.v2 * w.v3 - q.v3 * w.v2,
                                               q.s * w.v2 - q.v1 * w.v3 + q.v2 * w.s + q.v3 * w.v1,
                                               q.s * w.v3 + q.v1 * w.v2 - q.v2 * w.v1 + q.v3 * w.s)

(≈)(q::Quaternion, w::Quaternion) = (q.s ≈ w.s) && (q.v1 ≈ w.v1) && (q.v2 ≈ w.v2) && (q.v3 ≈ w.v3)

@doc raw"""

    rotationmatrix_normalized(q::Quaternion)

Return a 3×3 matrix representing the rotation encoded by quaternion `q`.
The function assumes that the quaternion is normalized. This is the
case if `q` is a composition of rotations built using the functions
`qrotation_x`, `qrotation_y`, and `qrotation_z`.
"""
function rotationmatrix_normalized(q::Quaternion)
    sx, sy, sz = 2q.s * q.v1, 2q.s * q.v2, 2q.s * q.v3
    xx, xy, xz = 2q.v1^2, 2q.v1 * q.v2, 2q.v1 * q.v3
    yy, yz, zz = 2q.v2^2, 2q.v2 * q.v3, 2q.v3^2
    Float64[(1 - (yy + zz))  (xy - sz)        (xz + sy);
            (xy + sz)        (1 - (xx + zz))  (yz - sx);
            (xz - sy)        (yz + sx)        (1 - (xx + yy))]
end
    
qrotation_x(theta) = Quaternion(cos(theta / 2), sin(theta / 2), 0.0, 0.0)
qrotation_y(theta) = Quaternion(cos(theta / 2), 0.0, sin(theta / 2), 0.0)
qrotation_z(theta) = Quaternion(cos(theta / 2), 0.0, 0.0, sin(theta / 2))

"""
    qrotation_x(theta)
    qrotation_y(theta)
    qrotation_z(theta)

Return a `Quaternion` object representing a rotation around the ``e_x``,
``e_y``, or ``e_z`` axis by an angle `theta` (in radians). The quaternions
returned by these functions are already normalized and can be used with the
function `rotationmatrix_normalized`.
"""
qrotation_x, qrotation_y, qrotation_z
