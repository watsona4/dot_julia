function numquad(integrand, test_local_space, trial_local_space,
    test_chart, trial_chart, out)

    outer_qps = quadpoints(test_chart, 10)
    inner_qps = quadpoints(trial_chart, 11)

    M = numfunctions(test_local_space)
    N = numfunctions(trial_local_space)

    for (x,wx) in outer_qps
        f = test_local_space(x)
        for (y,wy) in inner_qps
            g = trial_local_space(y)
            G = integrand(x,y)
            ds = wx * wy
            out += SMatrix{M,N}([dot(f[i][1], G*g[j][1]) for i ∈ 1:M, j ∈ 1:N])*ds
        end
    end

    out
end

function numquad_cf(integrand, test_local_space, trial_local_space,
    test_chart, trial_chart, out)

    outer_qps = quadpoints(test_chart, 10)

    inner_ksi = quadpoints(simplex(point(0),point(1)), 13)
    inner_eta = quadpoints(simplex(point(0),point(1)), 13)

    @assert sum(w for (x,w) in inner_ksi) ≈ 1
    @assert sum(w for (x,w) in inner_eta) ≈ 1

    @assert sum(w for (p,w) in outer_qps) ≈ volume(test_chart)
    @assert sum(w1*w2*(1-cartesian(p2)[1]) for (p1,w1) in inner_ksi for (p2,w2) in inner_eta) ≈ 0.5

    p1, p2, p3 = trial_chart.vertices

    M = numfunctions(test_local_space)
    N = numfunctions(trial_local_space)

    @assert volume(trial_chart) ≈ volume(test_chart)

    @assert M == N == 3

    check = 0.0

    for (x,wx) in outer_qps
        s1 = simplex(p3,cartesian(x),p2)
        s2 = simplex(p1,cartesian(x),p3)
        s3 = simplex(p2,cartesian(x),p1)

        @assert volume(s1) + volume(s2) + volume(s3) ≈ volume(trial_chart)

        qq = carttobary(trial_chart, cartesian(x))
        @assert 0 <= qq[1] <= 1
        @assert 0 <= qq[2] <= 1
        @assert 0 <= 1-qq[1]-qq[2] <= 1

        f = test_local_space(x)
        @assert length(f) == 3
        @assert f[1][1] isa SVector
        inner_check = 0.0
        for (ksi,wksi) in inner_ksi
            for (eta,weta) in inner_eta

                p = cartesian(ksi)[1]
                q = cartesian(eta)[1]

                @assert p isa Float64
                @assert q isa Float64

                u = p*(1-q)
                v = q
                wuv = wksi*weta*(1-cartesian(eta)[1])

                @assert 0 <= u <= 1
                @assert 0 <= v <= 1
                @assert 0 <= 1-u-v <= 1

                y1 = neighborhood(s1,(u,v))
                y2 = neighborhood(s2,(u,v))
                y3 = neighborhood(s3,(u,v))

                u1 = carttobary(s1, cartesian(y1))
                u2 = carttobary(s2, cartesian(y2))
                u3 = carttobary(s3, cartesian(y3))
                @assert 0 <= u1[1] <= 1
                @assert 0 <= u1[2] <= 1
                @assert 0 <= u2[1] <= 1
                @assert 0 <= u2[2] <= 1
                @assert 0 <= u3[1] <= 1
                @assert 0 <= u3[2] <= 1

                g1 = trial_local_space(neighborhood(trial_chart,carttobary(trial_chart,cartesian(y1))))
                g2 = trial_local_space(neighborhood(trial_chart,carttobary(trial_chart,cartesian(y2))))
                g3 = trial_local_space(neighborhood(trial_chart,carttobary(trial_chart,cartesian(y3))))

                @assert length(g1) == 3
                @assert length(g2) == 3
                @assert length(g3) == 3

                @assert g1[1][1] isa SVector
                @assert g2[1][1] isa SVector
                @assert g3[1][1] isa SVector

                @assert jacobian(y1) >= 0
                @assert jacobian(y2) >= 0
                @assert jacobian(y3) >= 0
                @assert jacobian(y1)+jacobian(y2)+jacobian(y3) ≈ 2*volume(test_chart)

                G1 = integrand(x,y1)*jacobian(y1)
                G2 = integrand(x,y2)*jacobian(y2)
                G3 = integrand(x,y3)*jacobian(y3)

                @assert wksi > 0
                @assert weta > 0
                @assert wx*wuv > 0

                check += wx*wuv
                inner_check += wuv

                out += wx*wuv*(SMatrix{M,N}([dot(f[i][1], (G1*g1[j][1]+G2*g2[j][1]+G3*g3[j][1])) for i=1:M, j=1:N]))
            end
        end
        @assert inner_check ≈ 0.5
    end

    @assert check ≈ volume(test_chart)*0.5
    out
end
