sstr = ScanningStrategy(spinsunang_rad = 0.0,
    borespinang_rad = 0.0,
    spin_rpm = 0.0,
    prec_rpm = 0.0,
    hwp_rpm = 0.0)

dirs = genpointings(sstr, 0.:3600.:86400., Float64[0, 0, 1], 0.0)

# Check the colatitudes
for idx in 1:size(dirs, 1)
    # Check that we're on the Ecliptic plane (colatitude = 90°)
    @test dirs[idx, 1] ≈ π / 2

    # Check that the polarization angle is always the same
    @test dirs[idx, 3] ≈ -π / 2
end

# Check that the longitude increases as expected
@test dirs[end, 2] - dirs[1, 2] ≈ 2π / DAYS_PER_YEAR

#######################################################################

sstr = ScanningStrategy(spinsunang_rad = 0.0,
    borespinang_rad = 0.0,
    spin_rpm = 1.0,
    prec_rpm = 0.0,
    hwp_rpm = 1.0)

dirs = genpointings(sstr, 0.:0.1:120., Float64[0, 0, 1], 0.0)

@test maximum(dirs[:, 3]) ≈ π / 2
@test minimum(dirs[:, 3]) ≈ -π / 2

#######################################################################

sstr = ScanningStrategy(spinsunang_rad = 0.0,
    borespinang_rad = deg2rad(15.),
    spin_rpm = 1.0,
    prec_rpm = 0.0,
    hwp_rpm = 1.0,
    yearly_rpm = 0.0)

dirs = genpointings(sstr, 0.:1.:60., Float64[0, 0, 1], 0.0)

# Colatitudes should depart no more than ±15° from the Ecliptic 
@test rad2deg(minimum(dirs[:, 1])) ≈ 90 - 15
@test rad2deg(maximum(dirs[:, 1])) ≈ 90 + 15

@test dirs[1, 2] ≈ 0.0
@test rad2deg(dirs[end, 2]) ≈ 360.0

#######################################################################

sstr = ScanningStrategy(spinsunang_rad = deg2rad(15.),
    borespinang_rad = 0.0,
    spin_rpm = 1.0,
    prec_rpm = 0.0,
    hwp_rpm = 1.0,
    yearly_rpm = 0.0)

dirs = genpointings(sstr, 0.:1.:60., Float64[0, 0, 1], 0.0)

for idx in 1:size(dirs, 1)
    @test rad2deg(dirs[idx, 1]) ≈ 90 - 15
end
