dipparams = DipoleParameters(theta_rad = deg2rad(15),
    phi_rad = deg2rad(30),
    speed_m_s = 1e7,
    t_k = 10.0,
)

@test dipole_temperature([0, 0, 1], params = dipparams) ≈ 0.32717489089672647
@test dipole_temperature([0, 0, 1], 1e12, params = dipparams) ≈ 0.3475227551239395
@test dipole_temperature([0, 0, 1], 1e13, params = dipparams) ≈ 0.5713065804441115
@test dipole_temperature([0, 1, 0], params = dipparams) ≈ 0.03776458768801616
@test dipole_temperature([0, 1, 0], 1e12, params = dipparams) ≈ 0.0436209260747376
@test dipole_temperature([0, 1, 0], 1e13, params = dipparams) ≈ 0.047637665018382125
