using ERFA

using Test

@testset "ERFA" begin
    @testset "Calendar Tools" begin
        u1, u2 = ERFA.dtf2d("UTC", 2010, 7, 24, 11, 18, 7.318)
        a1, a2 = ERFA.utctai(u1, u2)
        t1, t2 = ERFA.taitt(a1, a2)
        @test ERFA.d2dtf("tt", 3, t1, t2) == (2010, 7, 24, 11, 19, 13, 502)

        iy = 2008; imo = 2; id = 29
        ihour = 23; imin = 59; sec = 59.9
        d1, d2 = ERFA.cal2jd(iy, imo, id)
        d = ERFA.tf2d('+', ihour, imin, sec)
        d2 += d
        @test d1 == 2400000.5
        @test isapprox(d2, 54525.999999, atol = 5e-7)
        iy, imo, id, fd = ERFA.jd2cal(d1, d2)
        @test (iy, imo, id) == (2008, 2, 29)
        @test isapprox(fd, 0.999999, atol = 5e-7)
        @test ERFA.jdcalf(3, d1, d2) == (2008, 3, 1, 0)

        d = 2457073.05631
        e = ERFA.epb(0., d)
        @test isapprox(e, 2015.1365941021, atol = 5e-11)
        d1, d2 = ERFA.epb2jd(e)
        d = d1 + d2
        @test isapprox(d, 2457073.056310000, atol = 5e-10)
        e = ERFA.epj(0., d)
        @test isapprox(e, 2015.1349933196, atol = 5e-11)
        d1, d2 = ERFA.epj2jd(e)
        d = d1 + d2
        @test isapprox(d, 2457073.056310000, atol = 5e-10)
    end

    ## test from t_erfa_c.c
    # ERFA.a2af
    @testset "a2af" begin
        @test ERFA.a2af(4, 2.345) == ('+', 134, 21, 30, 9706)
    end

    # ERFA.a2tf
    @testset "a2tf" begin
        @test ERFA.a2tf(4, -3.01234) == ('-', 11, 30, 22, 6484)
    end

    # ERFA.ab
    @testset "ab" begin
        pnat = [-0.76321968546737951,-0.60869453983060384,-0.21676408580639883]
        v = [2.1044018893653786e-5,-8.9108923304429319e-5,-3.8633714797716569e-5]
        s = 0.99980921395708788
        bm1 = 0.99999999506209258
        ppr = ERFA.ab(pnat, v, s, bm1)
        @test isapprox(ppr[1], -0.7631631094219556269, atol = 1e-12)
        @test isapprox(ppr[2], -0.6087553082505590832, atol = 1e-12)
        @test isapprox(ppr[3], -0.2167926269368471279, atol = 1e-12)
    end

    # ERFA.af2a
    @testset "af2a" begin
        r = ERFA.af2a('-', 45, 13, 27.2)
        @test isapprox(r, -0.7893115794313644842, atol = 1e-15)
        r = ERFA.af2a('+', 45, 13, 27.2)
        @test isapprox(r, 0.7893115794313644842, atol = 1e-15)
    end

    # ERFA.anp
    @testset "anp" begin
        r = ERFA.anp(-0.1)
        @test isapprox(r, 6.183185307179586477, atol = 1e-15)
    end

    # ERFA.anpm
    @testset "anpm" begin
        r = ERFA.anpm(-4.0)
        @test isapprox(r, 2.283185307179586477, atol = 1e-15)
    end

    # ERFA.apcg
    @testset "apcg" begin
        date1 = 2456165.5
        date2 = 0.401182685
        ebpv = [[0.901310875,-0.417402664,-0.180982288];
                [0.00742727954,0.0140507459,0.00609045792]]
        ehp = [0.903358544,-0.415395237,-0.180084014]
        astrom = ERFA.apcg(date1, date2, ebpv, ehp)
        @test isapprox(astrom.pmt, 12.65133794027378508, atol = 1e-11)
        @test isapprox(astrom.eb[1], 0.901310875, atol = 1e-12)
        @test isapprox(astrom.eb[2], -0.417402664, atol = 1e-12)
        @test isapprox(astrom.eb[3], -0.180982288, atol = 1e-12)
        @test isapprox(astrom.eh[1], 0.8940025429324143045, atol = 1e-12)
        @test isapprox(astrom.eh[2], -0.4110930268679817955, atol = 1e-12)
        @test isapprox(astrom.eh[3], -0.1782189004872870264, atol = 1e-12)
        @test isapprox(astrom.em, 1.010465295811013146, atol = 1e-12)
        @test isapprox(astrom.v[1], 0.4289638913597693554e-4, atol = 1e-16)
        @test isapprox(astrom.v[2], 0.8115034051581320575e-4, atol = 1e-16)
        @test isapprox(astrom.v[3], 0.3517555136380563427e-4, atol = 1e-16)
        @test isapprox(astrom.bm1, 0.9999999951686012981, atol = 1e-12)
        @test isapprox(astrom.bpn[1], 1.0, atol = 1e-10)
        @test isapprox(astrom.bpn[4], 0.0, atol = 1e-10)
        @test isapprox(astrom.bpn[7], 0.0, atol = 1e-10)
        @test isapprox(astrom.bpn[2], 0.0, atol = 1e-10)
        @test isapprox(astrom.bpn[5], 1.0, atol = 1e-10)
        @test isapprox(astrom.bpn[8], 0.0, atol = 1e-10)
        @test isapprox(astrom.bpn[3], 0.0, atol = 1e-10)
        @test isapprox(astrom.bpn[6], 0.0, atol = 1e-10)
        @test isapprox(astrom.bpn[9], 1.0, atol = 1e-10)
    end

    # ERFA.apcg13
    @testset "apcg13" begin
        date1 = 2456165.5
        date2 = 0.401182685
        astrom = ERFA.apcg13(date1, date2)
        @test isapprox(astrom.pmt, 12.65133794027378508, atol = 1e-12)
        @test isapprox(astrom.eb[1], 0.9013108747340644755, atol = 1e-12)
        @test isapprox(astrom.eb[2], -0.4174026640406119957, atol = 1e-12)
        @test isapprox(astrom.eb[3], -0.1809822877867817771, atol = 1e-12)
        @test isapprox(astrom.eh[1], 0.8940025429255499549, atol = 1e-12)
        @test isapprox(astrom.eh[2], -0.4110930268331896318, atol = 1e-12)
        @test isapprox(astrom.eh[3], -0.1782189006019749850, atol = 1e-12)
        @test isapprox(astrom.em, 1.010465295964664178, atol = 1e-12)
        @test isapprox(astrom.v[1], 0.4289638912941341125e-4, atol = 1e-16)
        @test isapprox(astrom.v[2], 0.8115034032405042132e-4, atol = 1e-16)
        @test isapprox(astrom.v[3], 0.3517555135536470279e-4, atol = 1e-16)
        @test isapprox(astrom.bm1, 0.9999999951686013142, atol = 1e-12)
        @test isapprox(astrom.bpn[1], 1.0, atol = 1e-10)
        @test isapprox(astrom.bpn[4], 0.0, atol = 1e-10)
        @test isapprox(astrom.bpn[7], 0.0, atol = 1e-10)
        @test isapprox(astrom.bpn[2], 0.0, atol = 1e-10)
        @test isapprox(astrom.bpn[5], 1.0, atol = 1e-10)
        @test isapprox(astrom.bpn[8], 0.0, atol = 1e-10)
        @test isapprox(astrom.bpn[3], 0.0, atol = 1e-10)
        @test isapprox(astrom.bpn[6], 0.0, atol = 1e-10)
        @test isapprox(astrom.bpn[9], 1.0, atol = 1e-10)
    end

    # ERFA.apci
    @testset "apci" begin
        date1 = 2456165.5
        date2 = 0.401182685
        ebpv = [[0.901310875,-0.417402664,-0.180982288];
                [0.00742727954,0.0140507459,0.00609045792]]
        ehp = [0.903358544,-0.415395237,-0.180084014]
        x =  0.0013122272
        y = -2.92808623e-5
        s =  3.05749468e-8
        astrom = ERFA.apci(date1, date2, ebpv, ehp, x, y, s)
        @test isapprox(astrom.pmt, 12.65133794027378508, atol = 1e-11)
        @test isapprox(astrom.eb[1], 0.901310875, atol = 1e-12)
        @test isapprox(astrom.eb[2], -0.417402664, atol = 1e-12)
        @test isapprox(astrom.eb[3], -0.180982288, atol = 1e-12)
        @test isapprox(astrom.eh[1], 0.8940025429324143045, atol = 1e-12)
        @test isapprox(astrom.eh[2], -0.4110930268679817955, atol = 1e-12)
        @test isapprox(astrom.eh[3], -0.1782189004872870264, atol = 1e-12)
        @test isapprox(astrom.em, 1.010465295811013146, atol = 1e-12)
        @test isapprox(astrom.v[1], 0.4289638913597693554e-4, atol = 1e-16)
        @test isapprox(astrom.v[2], 0.8115034051581320575e-4, atol = 1e-16)
        @test isapprox(astrom.v[3], 0.3517555136380563427e-4, atol = 1e-16)
        @test isapprox(astrom.bm1, 0.9999999951686012981, atol = 1e-12)
        @test isapprox(astrom.bpn[1], 0.9999991390295159156, atol = 1e-12)
        @test isapprox(astrom.bpn[4], 0.4978650072505016932e-7, atol = 1e-12)
        @test isapprox(astrom.bpn[7], 0.1312227200000000000e-2, atol = 1e-12)
        @test isapprox(astrom.bpn[2], -0.1136336653771609630e-7, atol = 1e-12)
        @test isapprox(astrom.bpn[5], 0.9999999995713154868, atol = 1e-12)
        @test isapprox(astrom.bpn[8], -0.2928086230000000000e-4, atol = 1e-12)
        @test isapprox(astrom.bpn[3], -0.1312227200895260194e-2, atol = 1e-12)
        @test isapprox(astrom.bpn[6], 0.2928082217872315680e-4, atol = 1e-12)
        @test isapprox(astrom.bpn[9], 0.9999991386008323373, atol = 1e-12)
    end

    # ERFA.apci13
    @testset "apci13" begin
        date1 = 2456165.5
        date2 = 0.401182685
        astrom, eo = ERFA.apci13(date1, date2)
        @test isapprox(astrom.pmt, 12.65133794027378508, atol = 1e-11)
        @test isapprox(astrom.eb[1], 0.9013108747340644755, atol = 1e-12)
        @test isapprox(astrom.eb[2], -0.4174026640406119957, atol = 1e-12)
        @test isapprox(astrom.eb[3], -0.1809822877867817771, atol = 1e-12)
        @test isapprox(astrom.eh[1], 0.8940025429255499549, atol = 1e-12)
        @test isapprox(astrom.eh[2], -0.4110930268331896318, atol = 1e-12)
        @test isapprox(astrom.eh[3], -0.1782189006019749850, atol = 1e-12)
        @test isapprox(astrom.em, 1.010465295964664178, atol = 1e-12)
        @test isapprox(astrom.v[1], 0.4289638912941341125e-4, atol = 1e-16)
        @test isapprox(astrom.v[2], 0.8115034032405042132e-4, atol = 1e-16)
        @test isapprox(astrom.v[3], 0.3517555135536470279e-4, atol = 1e-16)
        @test isapprox(astrom.bm1, 0.9999999951686013142, atol = 1e-12)
        @test isapprox(astrom.bpn[1], 0.9999992060376761710, atol = 1e-12)
        @test isapprox(astrom.bpn[4], 0.4124244860106037157e-7, atol = 1e-12)
        @test isapprox(astrom.bpn[7], 0.1260128571051709670e-2, atol = 1e-12)
        @test isapprox(astrom.bpn[2], -0.1282291987222130690e-7, atol = 1e-12)
        @test isapprox(astrom.bpn[5], 0.9999999997456835325, atol = 1e-12)
        @test isapprox(astrom.bpn[8], -0.2255288829420524935e-4, atol = 1e-12)
        @test isapprox(astrom.bpn[3], -0.1260128571661374559e-2, atol = 1e-12)
        @test isapprox(astrom.bpn[6], 0.2255285422953395494e-4, atol = 1e-12)
        @test isapprox(astrom.bpn[9], 0.9999992057833604343, atol = 1e-12)
        @test isapprox(eo, -0.2900618712657375647e-2, atol = 1e-12)
    end

    # ERFA.apco
    @testset "apco" begin
        date1 = 2456384.5
        date2 = 0.970031644
        ebpv = [[-0.974170438,-0.211520082,-0.0917583024];
                [0.00364365824,-0.0154287319,-0.00668922024]]
        ehp = [-0.973458265,-0.209215307,-0.0906996477]
        x = 0.0013122272
        y = -2.92808623e-5
        s = 3.05749468e-8
        theta = 3.14540971
        elong = -0.527800806
        phi = -1.2345856
        hm = 2738.0
        xp = 2.47230737e-7
        yp = 1.82640464e-6
        sp = -3.01974337e-11
        refa = 0.000201418779
        refb = -2.36140831e-7
        astrom = ERFA.apco(date1, date2, ebpv, ehp, x, y, s, theta, elong, phi, hm, xp, yp, sp, refa, refb)
        @test isapprox(astrom.pmt, 13.25248468622587269, atol = 1e-11)
        @test isapprox(astrom.eb[1], -0.9741827110630897003, atol = 1e-12)
        @test isapprox(astrom.eb[2], -0.2115130190135014340, atol = 1e-12)
        @test isapprox(astrom.eb[3], -0.09179840186968295686, atol = 1e-12)
        @test isapprox(astrom.eh[1], -0.9736425571689670428, atol = 1e-12)
        @test isapprox(astrom.eh[2], -0.2092452125848862201, atol = 1e-12)
        @test isapprox(astrom.eh[3], -0.09075578152261439954, atol = 1e-12)
        @test isapprox(astrom.em, 0.9998233241710617934, atol = 1e-12)
        @test isapprox(astrom.v[1], 0.2078704992916728762e-4, atol = 1e-16)
        @test isapprox(astrom.v[2], -0.8955360107151952319e-4, atol = 1e-16)
        @test isapprox(astrom.v[3], -0.3863338994288951082e-4, atol = 1e-16)
        @test isapprox(astrom.bm1, 0.9999999950277561236, atol = 1e-12)
        @test isapprox(astrom.bpn[1], 0.9999991390295159156, atol = 1e-12)
        @test isapprox(astrom.bpn[4], 0.4978650072505016932e-7, atol = 1e-12)
        @test isapprox(astrom.bpn[7], 0.1312227200000000000e-2, atol = 1e-12)
        @test isapprox(astrom.bpn[2], -0.1136336653771609630e-7, atol = 1e-12)
        @test isapprox(astrom.bpn[5], 0.9999999995713154868, atol = 1e-12)
        @test isapprox(astrom.bpn[8], -0.2928086230000000000e-4, atol = 1e-12)
        @test isapprox(astrom.bpn[3], -0.1312227200895260194e-2, atol = 1e-12)
        @test isapprox(astrom.bpn[6], 0.2928082217872315680e-4, atol = 1e-12)
        @test isapprox(astrom.bpn[9], 0.9999991386008323373, atol = 1e-12)
        @test isapprox(astrom.along, -0.5278008060301974337, atol = 1e-12)
        @test isapprox(astrom.xpl, 0.1133427418174939329e-5, atol = 1e-17)
        @test isapprox(astrom.ypl, 0.1453347595745898629e-5, atol = 1e-17)
        @test isapprox(astrom.sphi, -0.9440115679003211329, atol = 1e-12)
        @test isapprox(astrom.cphi, 0.3299123514971474711, atol = 1e-12)
        @test isapprox(astrom.diurab, 0, atol = 1e-10)
        @test isapprox(astrom.eral, 2.617608903969802566, atol = 1e-12)
        @test isapprox(astrom.refa, 0.2014187790000000000e-3, atol = 1e-15)
        @test isapprox(astrom.refb, -0.2361408310000000000e-6, atol = 1e-18)
    end

    # ERFA.apco13
    @testset "apco13" begin
        utc1 = 2456384.5
        utc2 = 0.969254051
        dut1 = 0.1550675
        elong = -0.527800806
        phi = -1.2345856
        hm = 2738.0
        p = 2.47230737e-7
        xp = 2.47230737e-7
        yp = 1.82640464e-6
        phpa = 731.0
        tc = 12.8
        rh = 0.59
        wl = 0.55
        astrom, eo = ERFA.apco13(utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tc, rh, wl)
        @test isapprox(astrom.pmt, 13.25248468622475727, atol = 1e-11)
        @test isapprox(astrom.eb[1], -0.9741827107321449445, atol = 1e-12)
        @test isapprox(astrom.eb[2], -0.2115130190489386190, atol = 1e-12)
        @test isapprox(astrom.eb[3], -0.09179840189515518726, atol = 1e-12)
        @test isapprox(astrom.eh[1], -0.9736425572586866640, atol = 1e-12)
        @test isapprox(astrom.eh[2], -0.2092452121602867431, atol = 1e-12)
        @test isapprox(astrom.eh[3], -0.09075578153903832650, atol = 1e-12)
        @test isapprox(astrom.em, 0.9998233240914558422, atol = 1e-12)
        @test isapprox(astrom.v[1], 0.2078704994520489246e-4, atol = 1e-16)
        @test isapprox(astrom.v[2], -0.8955360133238868938e-4, atol = 1e-16)
        @test isapprox(astrom.v[3], -0.3863338993055887398e-4, atol = 1e-16)
        @test isapprox(astrom.bm1, 0.9999999950277561004, atol = 1e-12)
        @test isapprox(astrom.bpn[1], 0.9999991390295147999, atol = 1e-12)
        @test isapprox(astrom.bpn[4], 0.4978650075315529277e-7, atol = 1e-12)
        @test isapprox(astrom.bpn[7], 0.001312227200850293372, atol = 1e-12)
        @test isapprox(astrom.bpn[2], -0.1136336652812486604e-7, atol = 1e-12)
        @test isapprox(astrom.bpn[5], 0.9999999995713154865, atol = 1e-12)
        @test isapprox(astrom.bpn[8], -0.2928086230975367296e-4, atol = 1e-12)
        @test isapprox(astrom.bpn[3], -0.001312227201745553566, atol = 1e-12)
        @test isapprox(astrom.bpn[6], 0.2928082218847679162e-4, atol = 1e-12)
        @test isapprox(astrom.bpn[9], 0.9999991386008312212, atol = 1e-12)
        @test isapprox(astrom.along, -0.5278008060301974337, atol = 1e-12)
        @test isapprox(astrom.xpl, 0.1133427418174939329e-5, atol = 1e-17)
        @test isapprox(astrom.ypl, 0.1453347595745898629e-5, atol = 1e-17)
        @test isapprox(astrom.sphi, -0.9440115679003211329, atol = 1e-12)
        @test isapprox(astrom.cphi, 0.3299123514971474711, atol = 1e-12)
        @test isapprox(astrom.diurab, 0, atol = 1e-10)
        @test isapprox(astrom.eral, 2.617608909189066140, atol = 1e-12)
        @test isapprox(astrom.refa, 0.2014187785940396921e-3, atol = 1e-15)
        @test isapprox(astrom.refb, -0.2361408314943696227e-6, atol = 1e-18)
        @test isapprox(eo, -0.003020548354802412839, atol = 1e-14)
    end

    # ERFA.apcs
    @testset "apcs" begin
        date1 = 2456384.5
        date2 = 0.970031644
        pv = [[-1836024.09,1056607.72,-5998795.26];
              [-77.0361767,-133.310856,0.0971855934]]
        ebpv = [[-0.974170438,-0.211520082,-0.0917583024];
                [0.00364365824,-0.0154287319,-0.00668922024]]
        ehp = [-0.973458265,-0.209215307,-0.0906996477]
        astrom = ERFA.apcs(date1, date2, pv, ebpv, ehp)
        @test isapprox(astrom.pmt, 13.25248468622587269, atol = 1e-11)
        @test isapprox(astrom.eb[1], -0.9741827110630456169, atol = 1e-12)
        @test isapprox(astrom.eb[2], -0.2115130190136085494, atol = 1e-12)
        @test isapprox(astrom.eb[3], -0.09179840186973175487, atol = 1e-12)
        @test isapprox(astrom.eh[1], -0.9736425571689386099, atol = 1e-12)
        @test isapprox(astrom.eh[2], -0.2092452125849967195, atol = 1e-12)
        @test isapprox(astrom.eh[3], -0.09075578152266466572, atol = 1e-12)
        @test isapprox(astrom.em, 0.9998233241710457140, atol = 1e-12)
        @test isapprox(astrom.v[1], 0.2078704993282685510e-4, atol = 1e-16)
        @test isapprox(astrom.v[2], -0.8955360106989405683e-4, atol = 1e-16)
        @test isapprox(astrom.v[3], -0.3863338994289409097e-4, atol = 1e-16)
        @test isapprox(astrom.bm1, 0.9999999950277561237, atol = 1e-12)
        @test isapprox(astrom.bpn[1], 1, atol = 1e-10)
        @test isapprox(astrom.bpn[4], 0, atol = 1e-10)
        @test isapprox(astrom.bpn[7], 0, atol = 1e-10)
        @test isapprox(astrom.bpn[2], 0, atol = 1e-10)
        @test isapprox(astrom.bpn[5], 1, atol = 1e-10)
        @test isapprox(astrom.bpn[8], 0, atol = 1e-10)
        @test isapprox(astrom.bpn[3], 0, atol = 1e-10)
        @test isapprox(astrom.bpn[6], 0, atol = 1e-10)
        @test isapprox(astrom.bpn[9], 1, atol = 1e-10)
    end

    # ERFA.apcs13
    @testset "apcs13" begin
        date1 = 2456165.5
        date2 = 0.401182685
        pv = [[-6241497.16,401346.896,-1251136.04];
              [-29.264597,-455.021831,0.0266151194]]
        astrom = ERFA.apcs13(date1, date2, pv)
        @test isapprox(astrom.pmt, 12.65133794027378508, atol = 1e-11)
        @test isapprox(astrom.eb[1], 0.9012691529023298391, atol = 1e-12)
        @test isapprox(astrom.eb[2], -0.4173999812023068781, atol = 1e-12)
        @test isapprox(astrom.eb[3], -0.1809906511146821008, atol = 1e-12)
        @test isapprox(astrom.eh[1], 0.8939939101759726824, atol = 1e-12)
        @test isapprox(astrom.eh[2], -0.4111053891734599955, atol = 1e-12)
        @test isapprox(astrom.eh[3], -0.1782336880637689334, atol = 1e-12)
        @test isapprox(astrom.em, 1.010428384373318379, atol = 1e-12)
        @test isapprox(astrom.v[1], 0.4279877294121697570e-4, atol = 1e-16)
        @test isapprox(astrom.v[2], 0.7963255087052120678e-4, atol = 1e-16)
        @test isapprox(astrom.v[3], 0.3517564013384691531e-4, atol = 1e-16)
        @test isapprox(astrom.bm1, 0.9999999952947980978, atol = 1e-12)
        @test isapprox(astrom.bpn[1], 1, atol = 1e-10)
        @test isapprox(astrom.bpn[4], 0, atol = 1e-10)
        @test isapprox(astrom.bpn[7], 0, atol = 1e-10)
        @test isapprox(astrom.bpn[2], 0, atol = 1e-10)
        @test isapprox(astrom.bpn[5], 1, atol = 1e-10)
        @test isapprox(astrom.bpn[8], 0, atol = 1e-10)
        @test isapprox(astrom.bpn[3], 0, atol = 1e-10)
        @test isapprox(astrom.bpn[6], 0, atol = 1e-10)
        @test isapprox(astrom.bpn[9], 1, atol = 1e-10)
    end

    # ERFA.aper
    @testset "aper" begin
        theta = 5.678
        pmt = 0.
        eb = zeros(3)
        eh = zeros(3)
        em = 0.
        v = zeros(3)
        bm1 = 0.
        bpn = zeros(9)
        along = 1.234
        phi, xpl, ypl, sphi, cphi, diurab, eral, refa, refb = 0., 0., 0., 0., 0., 0., 0., 0., 0.
        astrom = ERFA.ASTROM(pmt, eb, eh, em, v, bm1, bpn, along,
                             phi, xpl, ypl, sphi, cphi, diurab, eral, refa, refb)
        astrom = ERFA.aper(theta, astrom)
        @test isapprox(astrom.eral, 6.912000000000000000, atol = 1e-12)
    end

    # ERFA.aper13
    @testset "aper13" begin
        ut11 = 2456165.5
        ut12 = 0.401182685
        pmt = 0.
        eb = zeros(3)
        eh = zeros(3)
        em = 0.
        v = zeros(3)
        bm1 = 0.
        bpn = zeros(9)
        along = 1.234
        phi, xpl, ypl, sphi, cphi, diurab, eral, refa, refb = 0., 0., 0., 0., 0., 0., 0., 0., 0.
        astrom = ERFA.ASTROM(pmt, eb, eh, em, v, bm1, bpn, along,
                             phi, xpl, ypl, sphi, cphi, diurab, eral, refa, refb)
        astrom = ERFA.aper13(ut11, ut12, astrom)
        @test isapprox(astrom.eral, 3.316236661789694933, atol = 1e-12)
    end

    # ERFA.apio
    @testset "apio" begin
        sp = -3.01974337e-11
        theta = 3.14540971
        elong = -0.527800806
        phi = -1.2345856
        hm = 2738.0
        xp = 2.47230737e-7
        yp = 1.82640464e-6
        refa = 0.000201418779
        refb = -2.36140831e-7
        astrom = ERFA.apio(sp, theta, elong, phi, hm, xp, yp, refa, refb)
        @test isapprox(astrom.along, -0.5278008060301974337, atol = 1e-12)
        @test isapprox(astrom.xpl, 0.1133427418174939329e-5, atol = 1e-17)
        @test isapprox(astrom.ypl, 0.1453347595745898629e-5, atol = 1e-17)
        @test isapprox(astrom.sphi, -0.9440115679003211329, atol = 1e-12)
        @test isapprox(astrom.cphi, 0.3299123514971474711, atol = 1e-12)
        @test isapprox(astrom.diurab, 0.5135843661699913529e-6, atol = 1e-12)
        @test isapprox(astrom.eral, 2.617608903969802566, atol = 1e-12)
        @test isapprox(astrom.refa, 0.2014187790000000000e-3, atol = 1e-15)
        @test isapprox(astrom.refb, -0.2361408310000000000e-6, atol = 1e-18)
    end

    # ERFA.apio13
    @testset "apio13" begin
        utc1 = 2456384.5
        utc2 = 0.969254051
        dut1 = 0.1550675
        elong = -0.527800806
        phi = -1.2345856
        hm = 2738.0
        xp = 2.47230737e-7
        yp = 1.82640464e-6
        phpa = 731.0
        tc = 12.8
        rh = 0.59
        wl = 0.55
        astrom = ERFA.apio13(utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tc, rh, wl)
        @test isapprox(astrom.along, -0.5278008060301974337, atol = 1e-12)
        @test isapprox(astrom.xpl, 0.1133427418174939329e-5, atol = 1e-17)
        @test isapprox(astrom.ypl, 0.1453347595745898629e-5, atol = 1e-17)
        @test isapprox(astrom.sphi, -0.9440115679003211329, atol = 1e-12)
        @test isapprox(astrom.cphi, 0.3299123514971474711, atol = 1e-12)
        @test isapprox(astrom.diurab, 0.5135843661699913529e-6, atol = 1e-12)
        @test isapprox(astrom.eral, 2.617608909189066140, atol = 1e-12)
        @test isapprox(astrom.refa, 0.2014187785940396921e-3, atol = 1e-15)
        @test isapprox(astrom.refb, -0.2361408314943696227e-6, atol = 1e-18)
    end

    # ERFA.atci13
    @testset "atci13" begin
        rc = 2.71
        dc = 0.174
        pr = 1e-5
        pd = 5e-6
        px = 0.1
        rv = 55.0
        date1 = 2456165.5
        date2 = 0.401182685
        ri, di, eo = ERFA.atci13(rc, dc, pr, pd, px, rv, date1, date2)
        @test isapprox(ri, 2.710121572969038991, atol = 1e-12)
        @test isapprox(di, 0.1729371367218230438, atol = 1e-12)
        @test isapprox(eo, -0.002900618712657375647, atol = 1e-14)
    end

    # ERFA.atciq
    @testset "atciq" begin
        date1 = 2456165.5
        date2 = 0.401182685
        astrom, eo = ERFA.apci13(date1, date2)
        rc = 2.71
        dc = 0.174
        pr = 1e-5
        pd = 5e-6
        px = 0.1
        rv = 55.0
        ri, di = ERFA.atciq(rc, dc, pr, pd, px, rv, astrom)
        @test isapprox(ri, 2.710121572969038991, atol = 1e-12)
        @test isapprox(di, 0.1729371367218230438, atol = 1e-12)
    end

    # ERFA.atciqn
    @testset "atciqn" begin
        date1 = 2456165.5
        date2 = 0.401182685
        astrom, eo = ERFA.apci13(date1, date2)
        rc = 2.71
        dc = 0.174
        pr = 1e-5
        pd = 5e-6
        px = 0.1
        rv = 55.0
        b1 = ERFA.LDBODY(0.00028574, 3e-10,
                         [[-7.81014427,-5.60956681,-1.98079819];
                          [0.0030723249,-0.00406995477,-0.00181335842]])
        b2 = ERFA.LDBODY(0.00095435, 3e-9,
                         [[0.738098796, 4.63658692,1.9693136];
                          [-0.00755816922, 0.00126913722, 0.000727999001]])
        b3 = ERFA.LDBODY(1.0, 6e-6,
                         [[-0.000712174377, -0.00230478303, -0.00105865966];
                          [6.29235213e-6, -3.30888387e-7, -2.96486623e-7]])
        b = [b1; b2; b3]
        ri, di = ERFA.atciqn(rc, dc, pr, pd, px, rv, astrom, b)
        @test isapprox(ri, 2.710122008105325582, atol = 1e-12)
        @test isapprox(di, 0.1729371916491459122, atol = 1e-12)
    end

    # ERFA.atciqz
    @testset "atciqz" begin
        date1 = 2456165.5
        date2 = 0.401182685
        astrom, eo = ERFA.apci13(date1, date2)
        rc = 2.71
        dc = 0.174
        ri, di = ERFA.atciqz(rc, dc, astrom)
        @test isapprox(ri, 2.709994899247599271, atol = 1e-12)
        @test isapprox(di, 0.1728740720983623469, atol = 1e-12)
    end

    # ERFA.atco13
    @testset "atco13" begin
        rc = 2.71
        dc = 0.174
        pr = 1e-5
        pd = 5e-6
        px = 0.1
        rv = 55.0
        utc1 = 2456384.5
        utc2 = 0.969254051
        dut1 = 0.1550675
        elong = -0.527800806
        phi = -1.2345856
        hm = 2738.0
        xp = 2.47230737e-7
        yp = 1.82640464e-6
        phpa = 731.0
        tc = 12.8
        rh = 0.59
        wl = 0.55
        aob, zob, hob, dob, rob, eo = ERFA.atco13(rc, dc, pr, pd, px, rv,
                                                  utc1, utc2, dut1, elong, phi, hm, xp, yp,
                                                  phpa, tc, rh, wl)
        @test isapprox(aob, 0.09251774485358230653, atol = 1e-12)
        @test isapprox(zob, 1.407661405256767021, atol = 1e-12)
        @test isapprox(hob, -0.09265154431403157925, atol = 1e-12)
        @test isapprox(dob, 0.1716626560075591655, atol = 1e-12)
        @test isapprox(rob, 2.710260453503097719, atol = 1e-12)
        @test isapprox(eo, -0.003020548354802412839, atol = 1e-14)
    end

    # ERFA.atic13
    @testset "atic13" begin
        ri = 2.710121572969038991
        di = 0.1729371367218230438
        date1 = 2456165.5
        date2 = 0.401182685
        rc, dc, eo = ERFA.atic13(ri, di, date1, date2)
        @test isapprox(rc, 2.710126504531374930, atol = 1e-12)
        @test isapprox(dc, 0.1740632537628342320, atol = 1e-12)
        @test isapprox(eo, -0.002900618712657375647, atol = 1e-14)
    end

    # ERFA.aticq
    @testset "aticq" begin
        ri = 2.710121572969038991
        di = 0.1729371367218230438
        date1 = 2456165.5
        date2 = 0.401182685
        astrom, eo = ERFA.apci13(date1, date2)
        rc, dc = ERFA.aticq(ri, di, astrom)
        @test isapprox(rc, 2.710126504531374930, atol = 1e-12)
        @test isapprox(dc, 0.1740632537628342320, atol = 1e-12)
    end

    # ERFA.aticqn
    @testset "aticqn" begin
        date1 = 2456165.5
        date2 = 0.401182685
        astrom, eo = ERFA.apci13(date1, date2)
        ri = 2.709994899247599271
        di = 0.1728740720983623469
        b1 = ERFA.LDBODY(0.00028574, 3e-10,
                         [[-7.81014427,-5.60956681,-1.98079819];
                          [0.0030723249,-0.00406995477,-0.00181335842]])
        b2 = ERFA.LDBODY(0.00095435, 3e-9,
                         [[0.738098796, 4.63658692,1.9693136];
                          [-0.00755816922, 0.00126913722, 0.000727999001]])
        b3 = ERFA.LDBODY(1.0, 6e-6,
                         [[-0.000712174377, -0.00230478303, -0.00105865966];
                          [6.29235213e-6, -3.30888387e-7, -2.96486623e-7]])
        b = [b1; b2; b3]
        rc, dc = ERFA.aticqn(ri, di, astrom, b)
        @test isapprox(rc, 2.709999575032685412, atol = 1e-12)
        @test isapprox(dc, 0.1739999656317778034, atol = 1e-12)
    end

    # ERFA.atio13
    @testset "atio13" begin
        ri = 2.710121572969038991
        di = 0.1729371367218230438
        utc1 = 2456384.5
        utc2 = 0.969254051
        dut1 = 0.1550675
        elong = -0.527800806
        phi = -1.2345856
        hm = 2738.0
        xp = 2.47230737e-7
        yp = 1.82640464e-6
        phpa = 731.0
        tc = 12.8
        rh = 0.59
        wl = 0.55
        aob, zob, hob, dob, rob = ERFA.atio13(ri, di, utc1, utc2, dut1, elong, phi, hm, xp, yp, phpa, tc, rh, wl)
        @test isapprox(aob, 0.09233952224794989993, atol = 1e-12)
        @test isapprox(zob, 1.407758704513722461, atol = 1e-12)
        @test isapprox(hob, -0.09247619879782006106, atol = 1e-12)
        @test isapprox(dob, 0.1717653435758265198, atol = 1e-12)
        @test isapprox(rob, 2.710085107986886201, atol = 1e-12)
    end

    # ERFA.atioq
    @testset "atioq" begin
        utc1 = 2456384.5
        utc2 = 0.969254051
        dut1 = 0.1550675
        elong = -0.527800806
        phi = -1.2345856
        hm = 2738.0
        xp = 2.47230737e-7
        yp = 1.82640464e-6
        phpa = 731.0
        tc = 12.8
        rh = 0.59
        wl = 0.55
        astrom = ERFA.apio13(utc1, utc2, dut1, elong, phi, hm, xp, yp,
                             phpa, tc, rh, wl)
        ri = 2.710121572969038991
        di = 0.1729371367218230438
        aob, zob, hob, dob, rob = ERFA.atioq(ri, di, astrom)
        @test isapprox(aob, 0.09233952224794989993, atol = 1e-12)
        @test isapprox(zob, 1.407758704513722461, atol = 1e-12)
        @test isapprox(hob, -0.09247619879782006106, atol = 1e-12)
        @test isapprox(dob, 0.1717653435758265198, atol = 1e-12)
        @test isapprox(rob, 2.710085107986886201, atol = 1e-12)
    end

    # ERFA.atoc13
    @testset "atoc13" begin
        utc1 = 2456384.5
        utc2 = 0.969254051
        dut1 = 0.1550675
        elong = -0.527800806
        phi = -1.2345856
        hm = 2738.0
        xp = 2.47230737e-7
        yp = 1.82640464e-6
        phpa = 731.0
        tc = 12.8
        rh = 0.59
        wl = 0.55
        ob1 = 2.710085107986886201
        ob2 = 0.1717653435758265198
        rc, dc = ERFA.atoc13("r", ob1, ob2, utc1, utc2, dut1,
                             elong, phi, hm, xp, yp, phpa, tc, rh, wl)
        @test isapprox(rc, 2.709956744661000609, atol = 1e-12)
        @test isapprox(dc, 0.1741696500895398562, atol = 1e-12)
        ob1 = -0.09247619879782006106
        ob2 = 0.1717653435758265198
        rc, dc = ERFA.atoc13("h", ob1, ob2, utc1, utc2, dut1,
                             elong, phi, hm, xp, yp, phpa, tc, rh, wl)
        @test isapprox(rc, 2.709956744661000609, atol = 1e-12)
        @test isapprox(dc, 0.1741696500895398562, atol = 1e-12)
        ob1 = 0.09233952224794989993
        ob2 = 1.407758704513722461
        rc, dc = ERFA.atoc13("a", ob1, ob2, utc1, utc2, dut1,
                             elong, phi, hm, xp, yp, phpa, tc, rh, wl)
        @test isapprox(rc, 2.709956744661000609, atol = 1e-12)
        @test isapprox(dc, 0.1741696500895398562, atol = 1e-12)
    end

    # ERFA.atoi13
    @testset "atoi13" begin
        utc1 = 2456384.5
        utc2 = 0.969254051
        dut1 = 0.1550675
        elong = -0.527800806
        phi = -1.2345856
        hm = 2738.0
        xp = 2.47230737e-7
        yp = 1.82640464e-6
        phpa = 731.0
        tc = 12.8
        rh = 0.59
        wl = 0.55
        ob1 = 2.710085107986886201
        ob2 = 0.1717653435758265198
        ri, di = ERFA.atoi13("r", ob1, ob2, utc1, utc2, dut1,
                             elong, phi, hm, xp, yp, phpa, tc, rh, wl)
        @test isapprox(ri, 2.710121574449135955, atol = 1e-12)
        @test isapprox(di, 0.1729371839114567725, atol = 1e-12)
        ob1 = -0.09247619879782006106
        ob2 = 0.1717653435758265198
        ri, di = ERFA.atoi13("h", ob1, ob2, utc1, utc2, dut1,
                             elong, phi, hm, xp, yp, phpa, tc, rh, wl)
        @test isapprox(ri, 2.710121574449135955, atol = 1e-12)
        @test isapprox(di, 0.1729371839114567725, atol = 1e-12)
        ob1 = 0.09233952224794989993
        ob2 = 1.407758704513722461
        ri, di = ERFA.atoi13("a", ob1, ob2, utc1, utc2, dut1,
                             elong, phi, hm, xp, yp, phpa, tc, rh, wl)
        @test isapprox(ri, 2.710121574449135955, atol = 1e-12)
        @test isapprox(di, 0.1729371839114567728, atol = 1e-12)
    end

    # ERFA.atoiq
    @testset "atoiq" begin
        utc1 = 2456384.5
        utc2 = 0.969254051
        dut1 = 0.1550675
        elong = -0.527800806
        phi = -1.2345856
        hm = 2738.0
        xp = 2.47230737e-7
        yp = 1.82640464e-6
        phpa = 731.0
        tc = 12.8
        rh = 0.59
        wl = 0.55
        astrom = ERFA.apio13(utc1, utc2, dut1,
                             elong, phi, hm, xp, yp, phpa, tc, rh, wl)
        ob1 = 2.710085107986886201
        ob2 = 0.1717653435758265198
        ri, di = ERFA.atoiq("r", ob1, ob2, astrom)
        @test isapprox(ri, 2.710121574449135955, atol = 1e-12)
        @test isapprox(di, 0.1729371839114567725, atol = 1e-12)
        ob1 = -0.09247619879782006106
        ob2 = 0.1717653435758265198
        ri, di = ERFA.atoiq("h", ob1, ob2, astrom)
        @test isapprox(ri, 2.710121574449135955, atol = 1e-12)
        @test isapprox(di, 0.1729371839114567725, atol = 1e-12)
        ob1 = 0.09233952224794989993
        ob2 = 1.407758704513722461
        ri, di = ERFA.atoiq("a", ob1, ob2, astrom)
        @test isapprox(ri, 2.710121574449135955, atol = 1e-12)
        @test isapprox(di, 0.1729371839114567728, atol = 1e-12)
    end

    # ERFA.bi00
    @testset "bi00" begin
        dp, de, dr = ERFA.bi00()
        @test isapprox(dp, -0.2025309152835086613e-6, atol = 1e-15)
        @test isapprox(de, -0.3306041454222147847e-7, atol = 1e-15)
        @test isapprox(dr, -0.7078279744199225506e-7, atol = 1e-15)
    end

    # ERFA.bp00
    @testset "bp00" begin
        rb, rp, rbp = ERFA.bp00(2400000.5, 50123.9999)
        @test isapprox(rb[1], 0.9999999999999942498, atol = 1e-12)
        @test isapprox(rb[2], -0.7078279744199196626e-7, atol = 1e-16)
        @test isapprox(rb[3], 0.8056217146976134152e-7, atol = 1e-16)
        @test isapprox(rb[4], 0.7078279477857337206e-7, atol = 1e-16)
        @test isapprox(rb[5], 0.9999999999999969484, atol = 1e-12)
        @test isapprox(rb[6], 0.3306041454222136517e-7, atol = 1e-16)
        @test isapprox(rb[7], -0.8056217380986972157e-7, atol = 1e-16)
        @test isapprox(rb[8], -0.3306040883980552500e-7, atol = 1e-16)
        @test isapprox(rb[9], 0.9999999999999962084, atol = 1e-12)
        @test isapprox(rp[1], 0.9999995504864048241, atol = 1e-12)
        @test isapprox(rp[2], 0.8696113836207084411e-3, atol = 1e-14)
        @test isapprox(rp[3], 0.3778928813389333402e-3, atol = 1e-14)
        @test isapprox(rp[4], -0.8696113818227265968e-3, atol = 1e-14)
        @test isapprox(rp[5], 0.9999996218879365258, atol = 1e-12)
        @test isapprox(rp[6], -0.1690679263009242066e-6, atol = 1e-14)
        @test isapprox(rp[7], -0.3778928854764695214e-3, atol = 1e-14)
        @test isapprox(rp[8], -0.1595521004195286491e-6, atol = 1e-14)
        @test isapprox(rp[9], 0.9999999285984682756, atol = 1e-12)
        @test isapprox(rbp[1], 0.9999995505175087260, atol = 1e-12)
        @test isapprox(rbp[2], 0.8695405883617884705e-3, atol = 1e-14)
        @test isapprox(rbp[3], 0.3779734722239007105e-3, atol = 1e-14)
        @test isapprox(rbp[4], -0.8695405990410863719e-3, atol = 1e-14)
        @test isapprox(rbp[5], 0.9999996219494925900, atol = 1e-12)
        @test isapprox(rbp[6], -0.1360775820404982209e-6, atol = 1e-14)
        @test isapprox(rbp[7], -0.3779734476558184991e-3, atol = 1e-14)
        @test isapprox(rbp[8], -0.1925857585832024058e-6, atol = 1e-14)
        @test isapprox(rbp[9], 0.9999999285680153377, atol = 1e-12)
    end

    # ERFA.bp06
    @testset "bp06" begin
        rb, rp, rbp = ERFA.bp06(2400000.5, 50123.9999)
        @test isapprox(rb[1], 0.9999999999999942497, atol = 1e-12)
        @test isapprox(rb[2], -0.7078368960971557145e-7, atol = 1e-14)
        @test isapprox(rb[3], 0.8056213977613185606e-7, atol = 1e-14)
        @test isapprox(rb[4], 0.7078368694637674333e-7, atol = 1e-14)
        @test isapprox(rb[5], 0.9999999999999969484, atol = 1e-12)
        @test isapprox(rb[6], 0.3305943742989134124e-7, atol = 1e-14)
        @test isapprox(rb[7], -0.8056214211620056792e-7, atol = 1e-14)
        @test isapprox(rb[8], -0.3305943172740586950e-7, atol = 1e-14)
        @test isapprox(rb[9], 0.9999999999999962084, atol = 1e-12)
        @test isapprox(rp[1], 0.9999995504864960278, atol = 1e-12)
        @test isapprox(rp[2], 0.8696112578855404832e-3, atol = 1e-14)
        @test isapprox(rp[3], 0.3778929293341390127e-3, atol = 1e-14)
        @test isapprox(rp[4], -0.8696112560510186244e-3, atol = 1e-14)
        @test isapprox(rp[5], 0.9999996218880458820, atol = 1e-12)
        @test isapprox(rp[6], -0.1691646168941896285e-6, atol = 1e-14)
        @test isapprox(rp[7], -0.3778929335557603418e-3, atol = 1e-14)
        @test isapprox(rp[8], -0.1594554040786495076e-6, atol = 1e-14)
        @test isapprox(rp[9], 0.9999999285984501222, atol = 1e-12)
        @test isapprox(rbp[1], 0.9999995505176007047, atol = 1e-12)
        @test isapprox(rbp[2], 0.8695404617348208406e-3, atol = 1e-14)
        @test isapprox(rbp[3], 0.3779735201865589104e-3, atol = 1e-14)
        @test isapprox(rbp[4], -0.8695404723772031414e-3, atol = 1e-14)
        @test isapprox(rbp[5], 0.9999996219496027161, atol = 1e-12)
        @test isapprox(rbp[6], -0.1361752497080270143e-6, atol = 1e-14)
        @test isapprox(rbp[7], -0.3779734957034089490e-3, atol = 1e-14)
        @test isapprox(rbp[8], -0.1924880847894457113e-6, atol = 1e-14)
        @test isapprox(rbp[9], 0.9999999285679971958, atol = 1e-12)
    end

    # ERFA.bpn2xy
    @testset "bpn2xy" begin
        rbpn = [[9.999962358680738e-1,-2.516417057665452e-3,-1.093569785342370e-3];
                [2.516462370370876e-3,9.999968329010883e-1,4.006159587358310e-5];
        [1.093465510215479e-3,-4.281337229063151e-5,9.999994012499173e-1]]
        x, y = ERFA.bpn2xy(rbpn)
        @test isapprox(x, 1.093465510215479e-3, atol = 1e-12)
        @test isapprox(y, -4.281337229063151e-5, atol = 1e-12)
    end

    # ERFA.c2i00a
    @testset "c2i00a" begin
        rc2i = ERFA.c2i00a(2400000.5, 53736.0)
        @test isapprox(rc2i[1], 0.9999998323037165557, atol = 1e-12)
        @test isapprox(rc2i[2], 0.5581526348992140183e-9, atol = 1e-12)
        @test isapprox(rc2i[3], -0.5791308477073443415e-3, atol = 1e-12)
        @test isapprox(rc2i[4], -0.2384266227870752452e-7, atol = 1e-12)
        @test isapprox(rc2i[5], 0.9999999991917405258, atol = 1e-12)
        @test isapprox(rc2i[6], -0.4020594955028209745e-4, atol = 1e-12)
        @test isapprox(rc2i[7], 0.5791308472168152904e-3, atol = 1e-12)
        @test isapprox(rc2i[8], 0.4020595661591500259e-4, atol = 1e-12)
        @test isapprox(rc2i[9], 0.9999998314954572304, atol = 1e-12)
    end

    # ERFA.c2i00b
    @testset "c2i00b" begin
        rc2i = ERFA.c2i00b(2400000.5, 53736.0)
        @test isapprox(rc2i[1], 0.9999998323040954356, atol = 1e-12)
        @test isapprox(rc2i[2], 0.5581526349131823372e-9, atol = 1e-12)
        @test isapprox(rc2i[3], -0.5791301934855394005e-3, atol = 1e-12)
        @test isapprox(rc2i[4], -0.2384239285499175543e-7, atol = 1e-12)
        @test isapprox(rc2i[5], 0.9999999991917574043, atol = 1e-12)
        @test isapprox(rc2i[6], -0.4020552974819030066e-4, atol = 1e-12)
        @test isapprox(rc2i[7], 0.5791301929950208873e-3, atol = 1e-12)
        @test isapprox(rc2i[8], 0.4020553681373720832e-4, atol = 1e-12)
        @test isapprox(rc2i[9], 0.9999998314958529887, atol = 1e-12)
    end

    # ERFA.c2i06a
    @testset "c2i06a" begin
        rc2i = ERFA.c2i06a(2400000.5, 53736.0)
        @test isapprox(rc2i[1], 0.9999998323037159379, atol = 1e-12)
        @test isapprox(rc2i[2], 0.5581121329587613787e-9, atol = 1e-12)
        @test isapprox(rc2i[3], -0.5791308487740529749e-3, atol = 1e-12)
        @test isapprox(rc2i[4], -0.2384253169452306581e-7, atol = 1e-12)
        @test isapprox(rc2i[5], 0.9999999991917467827, atol = 1e-12)
        @test isapprox(rc2i[6], -0.4020579392895682558e-4, atol = 1e-12)
        @test isapprox(rc2i[7], 0.5791308482835292617e-3, atol = 1e-12)
        @test isapprox(rc2i[8], 0.4020580099454020310e-4, atol = 1e-12)
        @test isapprox(rc2i[9], 0.9999998314954628695, atol = 1e-12)
    end

    # ERFA.c2ibpn
    @testset "c2ibpn" begin
        rbpn = [[9.999962358680738e-1,-2.516417057665452e-3,-1.093569785342370e-3];
                [2.516462370370876e-3,9.999968329010883e-1,4.006159587358310e-5];
        [1.093465510215479e-3,-4.281337229063151e-5,9.999994012499173e-1]]
        rc2i = ERFA.c2ibpn(2400000.5, 50123.9999, rbpn)
        @test isapprox(rc2i[1], 0.9999994021664089977, atol = 1e-12)
        @test isapprox(rc2i[2], -0.3869195948017503664e-8, atol = 1e-12)
        @test isapprox(rc2i[3], -0.1093465511383285076e-2, atol = 1e-12)
        @test isapprox(rc2i[4], 0.5068413965715446111e-7, atol = 1e-12)
        @test isapprox(rc2i[5], 0.9999999990835075686, atol = 1e-12)
        @test isapprox(rc2i[6], 0.4281334246452708915e-4, atol = 1e-12)
        @test isapprox(rc2i[7], 0.1093465510215479000e-2, atol = 1e-12)
        @test isapprox(rc2i[8], -0.4281337229063151000e-4, atol = 1e-12)
        @test isapprox(rc2i[9], 0.9999994012499173103, atol = 1e-12)
    end

    # ERFA.c2s
    @testset "c2s" begin
        t, p = ERFA.c2s([100.,-50.,25.])
        @test isapprox(t, -0.4636476090008061162, atol = 1e-15)
        @test isapprox(p, 0.2199879773954594463, atol = 1e-15)
    end

    # ERFA.c2ixy
    @testset "c2ixy" begin
        x = 0.5791308486706011000e-3
        y = 0.4020579816732961219e-4
        rc2i = ERFA.c2ixy(2400000.5, 53736., x, y)
        @test isapprox(rc2i[1], 0.9999998323037157138, atol = 1e-12)
        @test isapprox(rc2i[2], 0.5581526349032241205e-9, atol = 1e-12)
        @test isapprox(rc2i[3], -0.5791308491611263745e-3, atol = 1e-12)
        @test isapprox(rc2i[4], -0.2384257057469842953e-7, atol = 1e-12)
        @test isapprox(rc2i[5], 0.9999999991917468964, atol = 1e-12)
        @test isapprox(rc2i[6], -0.4020579110172324363e-4, atol = 1e-12)
        @test isapprox(rc2i[7], 0.5791308486706011000e-3, atol = 1e-12)
        @test isapprox(rc2i[8], 0.4020579816732961219e-4, atol = 1e-12)
        @test isapprox(rc2i[9], 0.9999998314954627590, atol = 1e-12)
    end

    # ERFA.c2ixys
    @testset "c2ixys" begin
        x =  0.5791308486706011000e-3
        y =  0.4020579816732961219e-4
        s = -0.1220040848472271978e-7
        rc2i = ERFA.c2ixys(x, y, s)
        @test isapprox(rc2i[1], 0.9999998323037157138, atol = 1e-12)
        @test isapprox(rc2i[2], 0.5581984869168499149e-9, atol = 1e-12)
        @test isapprox(rc2i[3], -0.5791308491611282180e-3, atol = 1e-12)
        @test isapprox(rc2i[4], -0.2384261642670440317e-7, atol = 1e-12)
        @test isapprox(rc2i[5], 0.9999999991917468964, atol = 1e-12)
        @test isapprox(rc2i[6], -0.4020579110169668931e-4, atol = 1e-12)
        @test isapprox(rc2i[7], 0.5791308486706011000e-3, atol = 1e-12)
        @test isapprox(rc2i[8], 0.4020579816732961219e-4, atol = 1e-12)
        @test isapprox(rc2i[9], 0.9999998314954627590, atol = 1e-12)
    end

    # ERFA.c2t00a
    @testset "c2t00a" begin
        tta = 2400000.5
        uta = 2400000.5
        ttb = 53736.0
        utb = 53736.0
        xp = 2.55060238e-7
        yp = 1.860359247e-6
        rc2t = ERFA.c2t00a(tta, ttb, uta, utb, xp, yp)
        @test isapprox(rc2t[1], -0.1810332128307182668, atol = 1e-12)
        @test isapprox(rc2t[2], 0.9834769806938457836, atol = 1e-12)
        @test isapprox(rc2t[3], 0.6555535638688341725e-4, atol = 1e-12)
        @test isapprox(rc2t[4], -0.9834768134135984552, atol = 1e-12)
        @test isapprox(rc2t[5], -0.1810332203649520727, atol = 1e-12)
        @test isapprox(rc2t[6], 0.5749801116141056317e-3, atol = 1e-12)
        @test isapprox(rc2t[7], 0.5773474014081406921e-3, atol = 1e-12)
        @test isapprox(rc2t[8], 0.3961832391770163647e-4, atol = 1e-12)
        @test isapprox(rc2t[9], 0.9999998325501692289, atol = 1e-12)
    end

    # ERFA.c2t00b
    @testset "c2t00b" begin
        tta = 2400000.5
        uta = 2400000.5
        ttb = 53736.0
        utb = 53736.0
        xp = 2.55060238e-7
        yp = 1.860359247e-6
        rc2t = ERFA.c2t00b(tta, ttb, uta, utb, xp, yp)
        @test isapprox(rc2t[1], -0.1810332128439678965, atol = 1e-12)
        @test isapprox(rc2t[2], 0.9834769806913872359, atol = 1e-12)
        @test isapprox(rc2t[3], 0.6555565082458415611e-4, atol = 1e-12)
        @test isapprox(rc2t[4], -0.9834768134115435923, atol = 1e-12)
        @test isapprox(rc2t[5], -0.1810332203784001946, atol = 1e-12)
        @test isapprox(rc2t[6], 0.5749793922030017230e-3, atol = 1e-12)
        @test isapprox(rc2t[7], 0.5773467471863534901e-3, atol = 1e-12)
        @test isapprox(rc2t[8], 0.3961790411549945020e-4, atol = 1e-12)
        @test isapprox(rc2t[9], 0.9999998325505635738, atol = 1e-12)
    end

    # ERFA.c2t06a
    @testset "c2t06a" begin
        tta = 2400000.5
        uta = 2400000.5
        ttb = 53736.0
        utb = 53736.0
        xp = 2.55060238e-7
        yp = 1.860359247e-6
        rc2t = ERFA.c2t06a(tta, ttb, uta, utb, xp, yp)
        @test isapprox(rc2t[1], -0.1810332128305897282, atol = 1e-12)
        @test isapprox(rc2t[2], 0.9834769806938592296, atol = 1e-12)
        @test isapprox(rc2t[3], 0.6555550962998436505e-4, atol = 1e-12)
        @test isapprox(rc2t[4], -0.9834768134136214897, atol = 1e-12)
        @test isapprox(rc2t[5], -0.1810332203649130832, atol = 1e-12)
        @test isapprox(rc2t[6], 0.5749800844905594110e-3, atol = 1e-12)
        @test isapprox(rc2t[7], 0.5773474024748545878e-3, atol = 1e-12)
        @test isapprox(rc2t[8], 0.3961816829632690581e-4, atol = 1e-12)
        @test isapprox(rc2t[9], 0.9999998325501747785, atol = 1e-12)
    end

    # ERFA.c2tcio
    @testset "c2tcio" begin
        c = [[0.9999998323037164738,0.5581526271714303683e-9,-0.5791308477073443903e-3];
             [-0.2384266227524722273e-7,0.9999999991917404296,-0.4020594955030704125e-4];
        [0.5791308472168153320e-3,.4020595661593994396e-4,0.9999998314954572365]]
        era = 1.75283325530307
        p = [[0.9999999999999674705,-0.1367174580728847031e-10,0.2550602379999972723e-6];
             [0.1414624947957029721e-10,0.9999999999982694954,-0.1860359246998866338e-5];
        [-0.2550602379741215275e-6,0.1860359247002413923e-5,0.9999999999982369658]]
        rc2t = ERFA.c2tcio(c, era, p)
        @test isapprox(rc2t[1], -0.1810332128307110439, atol = 1e-12)
        @test isapprox(rc2t[2], 0.9834769806938470149, atol = 1e-12)
        @test isapprox(rc2t[3], 0.6555535638685466874e-4, atol = 1e-12)
        @test isapprox(rc2t[4], -0.9834768134135996657, atol = 1e-12)
        @test isapprox(rc2t[5], -0.1810332203649448367, atol = 1e-12)
        @test isapprox(rc2t[6], 0.5749801116141106528e-3, atol = 1e-12)
        @test isapprox(rc2t[7], 0.5773474014081407076e-3, atol = 1e-12)
        @test isapprox(rc2t[8], 0.3961832391772658944e-4, atol = 1e-12)
        @test isapprox(rc2t[9], 0.9999998325501691969, atol = 1e-12)
    end

    # ERFA.c2teqx
    @testset "c2teqx" begin
        c = [[0.9999989440476103608,-0.1332881761240011518e-2,-0.5790767434730085097e-3];
             [0.1332858254308954453e-2,0.9999991109044505944,-0.4097782710401555759e-4];
        [0.5791308472168153320e-3,0.4020595661593994396e-4,0.9999998314954572365]]
        gst = 1.754166138040730516
        p = [[0.9999999999999674705,-0.1367174580728847031e-10,0.2550602379999972723e-6];
             [0.1414624947957029721e-10,0.9999999999982694954,-0.1860359246998866338e-5];
        [-0.2550602379741215275e-6,0.1860359247002413923e-5,0.9999999999982369658]]
        rc2t = ERFA.c2teqx(c, gst, p)
        @test isapprox(rc2t[1], -0.1810332128528685730, atol = 1e-12)
        @test isapprox(rc2t[2], 0.9834769806897685071, atol = 1e-12)
        @test isapprox(rc2t[3], 0.6555535639982634449e-4, atol = 1e-12)
        @test isapprox(rc2t[4], -0.9834768134095211257, atol = 1e-12)
        @test isapprox(rc2t[5], -0.1810332203871023800, atol = 1e-12)
        @test isapprox(rc2t[6], 0.5749801116126438962e-3, atol = 1e-12)
        @test isapprox(rc2t[7], 0.5773474014081539467e-3, atol = 1e-12)
        @test isapprox(rc2t[8], 0.3961832391768640871e-4, atol = 1e-12)
        @test isapprox(rc2t[9], 0.9999998325501691969, atol = 1e-12)
    end

    # ERFA.c2tpe
    @testset "c2tpe" begin
        tta = 2400000.5
        uta = 2400000.5
        ttb = 53736.0
        utb = 53736.0
        deps =  0.4090789763356509900
        dpsi = -0.9630909107115582393e-5
        xp = 2.55060238e-7
        yp = 1.860359247e-6
        rc2t = ERFA.c2tpe(tta, ttb, uta, utb, dpsi, deps, xp, yp)
        @test isapprox(rc2t[1], -0.1813677995763029394, atol = 1e-12)
        @test isapprox(rc2t[2], 0.9023482206891683275, atol = 1e-12)
        @test isapprox(rc2t[3], -0.3909902938641085751, atol = 1e-12)
        @test isapprox(rc2t[4], -0.9834147641476804807, atol = 1e-12)
        @test isapprox(rc2t[5], -0.1659883635434995121, atol = 1e-12)
        @test isapprox(rc2t[6], 0.7309763898042819705e-1, atol = 1e-12)
        @test isapprox(rc2t[7], 0.1059685430673215247e-2, atol = 1e-12)
        @test isapprox(rc2t[8], 0.3977631855605078674, atol = 1e-12)
        @test isapprox(rc2t[9], 0.9174875068792735362, atol = 1e-12)
    end

    # ERFA.c2txy
    @testset "c2txy" begin
        tta = 2400000.5
        uta = 2400000.5
        ttb = 53736.0
        utb = 53736.0
        x = 0.5791308486706011000e-3
        y = 0.4020579816732961219e-4
        xp = 2.55060238e-7
        yp = 1.860359247e-6
        rc2t = ERFA.c2txy(tta, ttb, uta, utb, x, y, xp, yp)
        @test isapprox(rc2t[1], -0.1810332128306279253, atol = 1e-12)
        @test isapprox(rc2t[2], 0.9834769806938520084, atol = 1e-12)
        @test isapprox(rc2t[3], 0.6555551248057665829e-4, atol = 1e-12)
        @test isapprox(rc2t[4], -0.9834768134136142314, atol = 1e-12)
        @test isapprox(rc2t[5], -0.1810332203649529312, atol = 1e-12)
        @test isapprox(rc2t[6], 0.5749800843594139912e-3, atol = 1e-12)
        @test isapprox(rc2t[7], 0.5773474028619264494e-3, atol = 1e-12)
        @test isapprox(rc2t[8], 0.3961816546911624260e-4, atol = 1e-12)
        @test isapprox(rc2t[9], 0.9999998325501746670, atol = 1e-12)
    end

    # ERFA.cal2jd
    @testset "cal2jd" begin
        dmj0, dmj = ERFA.cal2jd(2003, 6, 1)
        @test isapprox(dmj0, 2400000.5, atol = 1e-9)
        @test isapprox(dmj, 52791.0, atol = 1e-9)
    end

    # ERFA.dat
    @testset "dat" begin
        d = ERFA.dat(2003, 6, 1, 0.0)
        @test isapprox(d, 32.0, atol = 1e-9)
        d = ERFA.dat(2008, 1, 17, 0.0)
        @test isapprox(d, 33.0, atol = 1e-9)
    end

    # ERFA.d2dtf
    @testset "d2dtf" begin
        y, m, d, H, M, S, F = ERFA.d2dtf("UTC", 5, 2400000.5, 49533.99999)
        @test (y, m, d, H, M, S, F) == (1994, 6, 30, 23, 59, 60, 13599)
    end

    # ERFA.d2tf
    @testset "d2tf" begin
        @test ERFA.d2tf(4, -0.987654321) == ('-', 23, 42, 13, 3333)
    end

    # ERFA.dtdb
    @testset "dtdb" begin
        d = ERFA.dtdb(2448939.5, 0.123, 0.76543, 5.0123, 5525.242, 3190.0)
        @test isapprox(d, -0.1280368005936998991e-2, atol = 1e-17)
    end

    # ERFA.dtf2d
    @testset "dtf2d" begin
        jd1, jd2 = ERFA.dtf2d("UTC", 1994, 6, 30, 23, 59, 60.13599)
        @test isapprox(jd1 + jd2, 2449534.49999, atol = 1e-6)
    end

    # ERFA.ee00
    @testset "ee00" begin
        epsa =  0.4090789763356509900
        dpsi = -0.9630909107115582393e-5
        ee = ERFA.ee00(2400000.5, 53736.0, epsa, dpsi)
        @test isapprox(ee, -0.8834193235367965479e-5, atol = 1e-18)
    end

    # ERFA.ee00a
    @testset "ee00a" begin
        ee = ERFA.ee00a(2400000.5, 53736.0)
        @test isapprox(ee, -0.8834192459222588227e-5, atol = 1e-18)
    end

    # ERFA.ee00b
    @testset "ee00b" begin
        ee = ERFA.ee00b(2400000.5, 53736.0)
        @test isapprox(ee, -0.8835700060003032831e-5, atol = 1e-18)
    end

    # ERFA.ee06a
    @testset "ee06a" begin
        ee = ERFA.ee06a(2400000.5, 53736.0)
        @test isapprox(ee, -0.8834195072043790156e-5, atol = 1e-15)
    end

    # ERFA.eect00
    @testset "eect00" begin
        ct = ERFA.eect00(2400000.5, 53736.0)
        @test isapprox(ct, 0.2046085004885125264e-8, atol = 1e-20)
    end

    # ERFA.eo06a
    @testset "eo06a" begin
        eo = ERFA.eo06a(2400000.5, 53736.0)
        @test isapprox(eo, -0.1332882371941833644e-2, atol = 1e-15)
    end

    # ERFA.eors
    @testset "eors" begin
        r = [[0.9999989440476103608,-0.1332881761240011518e-2,-0.5790767434730085097e-3];
             [0.1332858254308954453e-2,0.9999991109044505944,-0.4097782710401555759e-4];
        [0.5791308472168153320e-3,0.4020595661593994396e-4,0.9999998314954572365]]
        s = -0.1220040848472271978e-7
        eo = ERFA.eors(r, s)
        @test isapprox(eo, -0.1332882715130744606e-2, atol = 1e-15)
    end

    # ERFA.eform
    @testset "eform" begin
        a, f = ERFA.eform(ERFA.WGS84)
        @test isapprox(a, 6378137.0, atol = 1e-10)
        @test isapprox(f, 0.0033528106647474807, atol = 1e-18)
        a, f = ERFA.eform(ERFA.GRS80)
        @test isapprox(a, 6378137.0, atol = 1e-10)
        @test isapprox(f, 0.0033528106811823189, atol = 1e-18)
        a, f = ERFA.eform(ERFA.WGS72)
        @test isapprox(a, 6378135.0, atol = 1e-10)
        @test isapprox(f, 0.0033527794541675049, atol = 1e-18)
    end

    # ERFA.epb
    @testset "epb" begin
        b = ERFA.epb(2415019.8135, 30103.18648)
        @test isapprox(b, 1982.418424159278580, atol = 1e-12)
    end

    # ERFA.epb2jd
    @testset "epb2jd" begin
        dj0, dj1 = ERFA.epb2jd(1957.3)
        @test isapprox(dj0, 2400000.5, atol = 1e-9)
        @test isapprox(dj1, 35948.1915101513, atol = 1e-9)
    end

    # ERFA.epj
    @testset "epj" begin
        j = ERFA.epj(2451545, -7392.5)
        @test isapprox(j, 1979.760438056125941, atol = 1e-12)
    end

    # ERFA.epj2jd
    @testset "epj2jd" begin
        dj0, dj1 = ERFA.epj2jd(1996.8)
        @test isapprox(dj0, 2400000.5, atol = 1e-9)
        @test isapprox(dj1, 50375.7, atol = 1e-9)
    end

    # ERFA.epv00
    @testset "epv00" begin
        pvh, pvb = ERFA.epv00(2400000.5, 53411.52501161)
        @test isapprox(pvh[1], -0.7757238809297706813, atol = 1e-14)
        @test isapprox(pvh[2], 0.5598052241363340596, atol = 1e-14)
        @test isapprox(pvh[3], 0.2426998466481686993, atol = 1e-14)
        @test isapprox(pvh[4], -0.1091891824147313846e-1, atol = 1e-15)
        @test isapprox(pvh[5], -0.1247187268440845008e-1, atol = 1e-15)
        @test isapprox(pvh[6], -0.5407569418065039061e-2, atol = 1e-15)
        @test isapprox(pvb[1], -0.7714104440491111971, atol = 1e-14)
        @test isapprox(pvb[2], 0.5598412061824171323, atol = 1e-14)
        @test isapprox(pvb[3], 0.2425996277722452400, atol = 1e-14)
        @test isapprox(pvb[4], -0.1091874268116823295e-1, atol = 1e-15)
        @test isapprox(pvb[5], -0.1246525461732861538e-1, atol = 1e-15)
        @test isapprox(pvb[6], -0.5404773180966231279e-2, atol = 1e-15)
    end

    # ERFA.eqeq94
    @testset "eqeq94" begin
        ee = ERFA.eqeq94(2400000.5, 41234.0)
        @test isapprox(ee, 0.5357758254609256894e-4, atol = 1e-17)
    end

    # ERFA.era00
    @testset "era00" begin
        era = ERFA.era00(2400000.5, 54388.0)
        @test isapprox(era, 0.4022837240028158102, atol = 1e-12)
    end

    # ERFA.fad03
    @testset "fad03" begin
        d = ERFA.fad03(0.80)
        @test isapprox(d, 1.946709205396925672, atol = 1e-12)
    end

    # ERFA.fae03
    @testset "fae03" begin
        e = ERFA.fae03(0.80)
        @test isapprox(e, 1.744713738913081846, atol = 1e-12)
    end

    # ERFA.faf03
    @testset "faf03" begin
        f = ERFA.faf03(0.80)
        @test isapprox(f, 0.2597711366745499518, atol = 1e-12)
    end

    # ERFA.faju03
    @testset "faju03" begin
        l = ERFA.faju03(0.80)
        @test isapprox(l, 5.275711665202481138, atol = 1e-12)
    end

    # ERFA.fal03
    @testset "fal03" begin
        l = ERFA.fal03(0.80)
        @test isapprox(l, 5.132369751108684150, atol = 1e-12)
    end

    # ERFA.falp03
    @testset "falp03" begin
        lp = ERFA.falp03(0.80)
        @test isapprox(lp, 6.226797973505507345, atol = 1e-12)
    end

    # ERFA.fama03
    @testset "fama03" begin
        l = ERFA.fama03(0.80)
        @test isapprox(l, 3.275506840277781492, atol = 1e-12)
    end

    # ERFA.fame03
    @testset "fame03" begin
        l = ERFA.fame03(0.80)
        @test isapprox(l, 5.417338184297289661, atol = 1e-12)
    end

    # ERFA.fane03
    @testset "fane03" begin
        l = ERFA.fane03(0.80)
        @test isapprox(l, 2.079343830860413523, atol = 1e-12)
    end

    # ERFA.faom03
    @testset "faom03" begin
        l = ERFA.faom03(0.80)
        @test isapprox(l, -5.973618440951302183, atol = 1e-12)
    end

    # ERFA.fapa03
    @testset "fapa03" begin
        l = ERFA.fapa03(0.80)
        @test isapprox(l, 0.1950884762240000000e-1, atol = 1e-12)
    end

    # ERFA.fasa03
    @testset "fasa03" begin
        l = ERFA.fasa03(0.80)
        @test isapprox(l, 5.371574539440827046, atol = 1e-12)
    end

    # ERFA.faur03
    @testset "faur03" begin
        l = ERFA.faur03(0.80)
        @test isapprox(l, 5.180636450180413523, atol = 1e-12)
    end

    # ERFA.fave03
    @testset "fave03" begin
        l = ERFA.fave03(0.80)
        @test isapprox(l, 3.424900460533758000, atol = 1e-12)
    end

    # ERFA.fk52h
    @testset "fk52h" begin
        r5  =  1.76779433
        d5  = -0.2917517103
        dr5 = -1.91851572e-7
        dd5 = -5.8468475e-6
        px5 =  0.379210
        rv5 = -7.6
        rh, dh, drh, ddh, pxh, rvh = ERFA.fk52h(r5, d5, dr5, dd5, px5, rv5)
        @test isapprox(rh, 1.767794226299947632, atol = 1e-14)
        @test isapprox(dh, -0.2917516070530391757, atol = 1e-14)
        @test isapprox(drh, -0.19618741256057224e-6, atol = 1e-19)
        @test isapprox(ddh, -0.58459905176693911e-5, atol = 1e-19)
        @test isapprox(pxh, 0.37921, atol = 1e-14)
        @test isapprox(rvh, -7.6000000940000254, atol = 1e-11)
    end

    # ERFA.fk5hz
    @testset "fk5hz" begin
        r5 =  1.76779433
        d5 = -0.2917517103
        rh, dh = ERFA.fk5hz(r5, d5, 2400000.5, 54479.0)
        @test isapprox(rh, 1.767794191464423978, atol = 1e-12)
        @test isapprox(dh, -0.2917516001679884419, atol = 1e-12)
    end

    # ERFA.fw2m
    @testset "fw2m" begin
        gamb = -0.2243387670997992368e-5
        phib =  0.4091014602391312982
        psi  = -0.9501954178013015092e-3
        eps  =  0.4091014316587367472
        r = ERFA.fw2m(gamb, phib, psi, eps)
        @test isapprox(r[1], 0.9999995505176007047, atol = 1e-12)
        @test isapprox(r[2], 0.8695404617348192957e-3, atol = 1e-12)
        @test isapprox(r[3], 0.3779735201865582571e-3, atol = 1e-12)
        @test isapprox(r[4], -0.8695404723772016038e-3, atol = 1e-12)
        @test isapprox(r[5], 0.9999996219496027161, atol = 1e-12)
        @test isapprox(r[6], -0.1361752496887100026e-6, atol = 1e-12)
        @test isapprox(r[7], -0.3779734957034082790e-3, atol = 1e-12)
        @test isapprox(r[8], -0.1924880848087615651e-6, atol = 1e-12)
        @test isapprox(r[9], 0.9999999285679971958, atol = 1e-12)
    end

    # ERFA.fw2xy
    @testset "fw2xy" begin
        gamb = -0.2243387670997992368e-5
        phib =  0.4091014602391312982
        psi  = -0.9501954178013015092e-3
        eps  =  0.4091014316587367472
        x, y = ERFA.fw2xy(gamb, phib, psi, eps)
        @test isapprox(x, -0.3779734957034082790e-3, atol = 1e-14)
        @test isapprox(y, -0.1924880848087615651e-6, atol = 1e-14)
    end

    # ERFA.gc2gd
    @testset "gc2gd" begin
        xyz = [2.e6, 3.e6, 5.244e6]
        e, p, h = ERFA.gc2gd(1, xyz)
        @test isapprox(e, 0.98279372324732907, atol = 1e-14)
        @test isapprox(p, 0.97160184819075459, atol = 1e-14)
        @test isapprox(h, 331.41724614260599, atol = 1e-8)
        e, p, h = ERFA.gc2gd(2, xyz)
        @test isapprox(e, 0.98279372324732907, atol = 1e-14)
        @test isapprox(p, 0.97160184820607853, atol = 1e-14)
        @test isapprox(h, 331.41731754844348, atol = 1e-8)
        e, p, h = ERFA.gc2gd(3, xyz)
        @test isapprox(e, 0.98279372324732907, atol = 1e-14)
        @test isapprox(p, 0.97160181811015119, atol = 1e-14)
        @test isapprox(h, 333.27707261303181, atol = 1e-8)
    end

    # ERFA.gc2gde
    @testset "gc2gde" begin
        a = 6378136.0
        f = 0.0033528
        xyz = [2e6, 3e6, 5.244e6]
        e, p, h = ERFA.gc2gde(a, f, xyz)
        @test isapprox(e, 0.98279372324732907, atol = 1e-14)
        @test isapprox(p, 0.97160183775704115, atol = 1e-14)
        @test isapprox(h, 332.36862495764397, atol = 1e-8)
    end

    # ERFA.gd2gc
    @testset "gd2gc" begin
        e = 3.1
        p = -0.5
        h = 2500.0
        xyz = ERFA.gd2gc(1, e, p, h)
        @test isapprox(xyz[1], -5599000.5577049947, atol = 1e-7)
        @test isapprox(xyz[2], 233011.67223479203, atol = 1e-7)
        @test isapprox(xyz[3], -3040909.4706983363, atol = 1e-7)
        xyz = ERFA.gd2gc(2, e, p, h)
        @test isapprox(xyz[1], -5599000.5577260984, atol = 1e-7)
        @test isapprox(xyz[2], 233011.6722356703, atol = 1e-7)
        @test isapprox(xyz[3], -3040909.4706095476, atol = 1e-7)
        xyz = ERFA.gd2gc(3, e, p, h)
        @test isapprox(xyz[1], -5598998.7626301490, atol = 1e-7)
        @test isapprox(xyz[2], 233011.5975297822, atol = 1e-7)
        @test isapprox(xyz[3], -3040908.6861467111, atol = 1e-7)
    end

    # ERFA.gd2gce
    @testset "gd2gce" begin
        a = 6378136.0
        f = 0.0033528
        e = 3.1
        p = -0.5
        h = 2500.0
        xyz = ERFA.gd2gce(a, f, e, p, h)
        @test isapprox(xyz[1], -5598999.6665116328, atol = 1e-7)
        @test isapprox(xyz[2], 233011.63514630572, atol = 1e-7)
        @test isapprox(xyz[3], -3040909.0517314132, atol = 1e-7)
    end

    # ERFA.gmst00
    @testset "gmst00" begin
        g = ERFA.gmst00(2400000.5, 53736.0, 2400000.5, 53736.0)
        @test isapprox(g, 1.754174972210740592, atol = 1e-14)
    end

    # ERFA.gmst06
    @testset "gmst06" begin
        g = ERFA.gmst06(2400000.5, 53736.0, 2400000.5, 53736.0)
        @test isapprox(g, 1.754174971870091203, atol = 1e-14)
    end

    # ERFA.gmst82
    @testset "gmst82" begin
        g = ERFA.gmst82(2400000.5, 53736.0)
        @test isapprox(g, 1.754174981860675096, atol = 1e-14)
    end

    # ERFA.gst00a
    @testset "gst00a" begin
        g = ERFA.gst00a(2400000.5, 53736.0, 2400000.5, 53736.0)
        @test isapprox(g, 1.754166138018281369, atol = 1e-14)
    end

    # ERFA.gst00b
    @testset "gst00b" begin
        g = ERFA.gst00b(2400000.5, 53736.0)
        @test isapprox(g, 1.754166136510680589, atol = 1e-14)
    end

    # ERFA.gst06
    @testset "gst06" begin
        rnpb = [[0.9999989440476103608,-0.1332881761240011518e-2,-0.5790767434730085097e-3];
                [0.1332858254308954453e-2,0.9999991109044505944,-0.4097782710401555759e-4];
        [0.5791308472168153320e-3,0.4020595661593994396e-4,0.9999998314954572365]]
        g = ERFA.gst06(2400000.5, 53736.0, 2400000.5, 53736.0, rnpb)
        @test isapprox(g, 1.754166138018167568, atol = 1e-14)
    end

    # ERFA.gst06a
    @testset "gst06a" begin
        g = ERFA.gst06a(2400000.5, 53736.0, 2400000.5, 53736.0)
        @test isapprox(g, 1.754166137675019159, atol = 1e-14)
    end

    # ERFA.gst94
    @testset "gst94" begin
        g = ERFA.gst94(2400000.5, 53736.0)
        @test isapprox(g, 1.754166136020645203, atol = 1e-14)
    end

    # ERFA.h2fk5
    @testset "h2fk5" begin
        rh  =  1.767794352
        dh  = -0.2917512594
        drh = -2.76413026e-6
        ddh = -5.92994449e-6
        pxh =  0.379210
        rvh = -7.6
        r5, d5, dr5, dd5, px5, rv5 = ERFA.h2fk5(rh, dh, drh, ddh, pxh, rvh)
        @test isapprox(r5, 1.767794455700065506, atol = 1e-13)
        @test isapprox(d5, -0.2917513626469638890, atol = 1e-13)
        @test isapprox(dr5, -0.27597945024511204e-5, atol = 1e-18)
        @test isapprox(dd5, -0.59308014093262838e-5, atol = 1e-18)
        @test isapprox(px5, 0.37921, atol = 1e-13)
        @test isapprox(rv5, -7.6000001309071126, atol = 1e-10)
    end

    # ERFA.fk5hip
    @testset "fk5hip" begin
        r5h, s5h = ERFA.fk5hip()
        @test isapprox(r5h[1], 0.9999999999999928638, atol = 1e-14)
        @test isapprox(r5h[2], 0.1110223351022919694e-6, atol = 1e-17)
        @test isapprox(r5h[3], 0.4411803962536558154e-7, atol = 1e-17)
        @test isapprox(r5h[4], -0.1110223308458746430e-6, atol = 1e-17)
        @test isapprox(r5h[5], 0.9999999999999891830, atol = 1e-14)
        @test isapprox(r5h[6], -0.9647792498984142358e-7, atol = 1e-17)
        @test isapprox(r5h[7], -0.4411805033656962252e-7, atol = 1e-17)
        @test isapprox(r5h[8], 0.9647792009175314354e-7, atol = 1e-17)
        @test isapprox(r5h[9], 0.9999999999999943728, atol = 1e-14)
        @test isapprox(s5h[1], -0.1454441043328607981e-8, atol = 1e-17)
        @test isapprox(s5h[2], 0.2908882086657215962e-8, atol = 1e-17)
        @test isapprox(s5h[3], 0.3393695767766751955e-8, atol = 1e-17)
    end

    # ERFA.hfk5z
    @testset "hfk5z" begin
        rh =  1.767794352
        dh = -0.2917512594
        r5, d5, dr5, dd5 = ERFA.hfk5z(rh, dh, 2400000.5, 54479.0)
        @test isapprox(r5, 1.767794490535581026, atol = 1e-13)
        @test isapprox(d5, -0.2917513695320114258, atol = 1e-14)
        @test isapprox(dr5, 0.4335890983539243029e-8, atol = 1e-22)
        @test isapprox(dd5, -0.8569648841237745902e-9, atol = 1e-23)
    end

    # ERFA.jd2cal
    @testset "jd2cal" begin
        y, m, d, fd = ERFA.jd2cal(2400000.5, 50123.9999)
        @test (y, m, d) == (1996, 2, 10)
        @test isapprox(fd, 0.9999, atol = 1e-7)
    end

    # ERFA.jdcalf
    @testset "jdcalf" begin
        y, m, d, fd = ERFA.jdcalf(4, 2400000.5, 50123.9999)
        @test (y, m, d, fd) == (1996, 2, 10, 9999)
    end

    # ERFA.ld
    @testset "ld" begin
        bm = 0.00028574
        p = [-0.763276255, -0.608633767, -0.216735543]
        q = [-0.763276255, -0.608633767, -0.216735543]
        e = [0.76700421, 0.605629598, 0.211937094]
        em = 8.91276983
        dlim = 3e-10
        p1 = ERFA.ld(bm, p, q, e, em, dlim)
        @test isapprox(p1[1], -0.7632762548968159627, atol = 1e-12)
        @test isapprox(p1[2], -0.6086337670823762701, atol = 1e-12)
        @test isapprox(p1[3], -0.2167355431320546947, atol = 1e-12)
    end

    # ERFA.ldn
    @testset "ldn" begin
        sc = [-0.763276255, -0.608633767, -0.216735543]
        ob = [-0.974170437, -0.2115201, -0.0917583114]
        pv1 = [-7.81014427,-5.60956681,-1.98079819,
               0.0030723249,-0.00406995477,-0.00181335842]
        pv2 = [0.738098796, 4.63658692,1.9693136,
               -0.00755816922, 0.00126913722, 0.000727999001]
        pv3 = [-0.000712174377, -0.00230478303, -0.00105865966,
               6.29235213e-6, -3.30888387e-7, -2.96486623e-7]
        b1 = ERFA.LDBODY(0.00028574, 3e-10, pv1)
        b2 = ERFA.LDBODY(0.00095435, 3e-9, pv2)
        b3 = ERFA.LDBODY(1.0, 6e-6, pv3)
        l = [b1, b2, b3]
        sn = ERFA.ldn(l, ob, sc)
        @test isapprox(sn[1], -0.7632762579693333866, atol = 1e-12)
        @test isapprox(sn[2], -0.6086337636093002660, atol = 1e-12)
        @test isapprox(sn[3], -0.2167355420646328159, atol = 1e-12)
    end

    # ERFA.ldsun
    @testset "ldsun" begin
        p = [-0.763276255, -0.608633767, -0.216735543]
        e = [-0.973644023, -0.20925523, -0.0907169552]
        em = 0.999809214
        p1 = ERFA.ldsun(p, e, em)
        @test isapprox(p1[1], -0.7632762580731413169, atol = 1e-12)
        @test isapprox(p1[2], -0.6086337635262647900, atol = 1e-12)
        @test isapprox(p1[3], -0.2167355419322321302, atol = 1e-12)
    end

    # ERFA.num00a
    @testset "num00a" begin
        rmatn = ERFA.num00a(2400000.5, 53736.0)
        @test isapprox(rmatn[1], 0.9999999999536227949, atol = 1e-12)
        @test isapprox(rmatn[2], 0.8836238544090873336e-5, atol = 1e-12)
        @test isapprox(rmatn[3], 0.3830835237722400669e-5, atol = 1e-12)
        @test isapprox(rmatn[4], -0.8836082880798569274e-5, atol = 1e-12)
        @test isapprox(rmatn[5], 0.9999999991354655028, atol = 1e-12)
        @test isapprox(rmatn[6], -0.4063240865362499850e-4, atol = 1e-12)
        @test isapprox(rmatn[7], -0.3831194272065995866e-5, atol = 1e-12)
        @test isapprox(rmatn[8], 0.4063237480216291775e-4, atol = 1e-12)
        @test isapprox(rmatn[9], 0.9999999991671660338, atol = 1e-12)
    end

    # ERFA.num00b
    @testset "num00b" begin
        rmatn = ERFA.num00b(2400000.5, 53736.0)
        @test isapprox(rmatn[1], 0.9999999999536069682, atol = 1e-12)
        @test isapprox(rmatn[2], 0.8837746144871248011e-5, atol = 1e-12)
        @test isapprox(rmatn[3], 0.3831488838252202945e-5, atol = 1e-12)
        @test isapprox(rmatn[4], -0.8837590456632304720e-5, atol = 1e-12)
        @test isapprox(rmatn[5], 0.9999999991354692733, atol = 1e-12)
        @test isapprox(rmatn[6], -0.4063198798559591654e-4, atol = 1e-12)
        @test isapprox(rmatn[7], -0.3831847930134941271e-5, atol = 1e-12)
        @test isapprox(rmatn[8], 0.4063195412258168380e-4, atol = 1e-12)
        @test isapprox(rmatn[9], 0.9999999991671806225, atol = 1e-12)
    end

    # ERFA.num06a
    @testset "num06a" begin
        rmatn = ERFA.num06a(2400000.5, 53736.)
        @test isapprox(rmatn[1], 0.9999999999536227668, atol = 1e-12)
        @test isapprox(rmatn[2], 0.8836241998111535233e-5, atol = 1e-12)
        @test isapprox(rmatn[3], 0.3830834608415287707e-5, atol = 1e-12)
        @test isapprox(rmatn[4], -0.8836086334870740138e-5, atol = 1e-12)
        @test isapprox(rmatn[5], 0.9999999991354657474, atol = 1e-12)
        @test isapprox(rmatn[6], -0.4063240188248455065e-4, atol = 1e-12)
        @test isapprox(rmatn[7], -0.3831193642839398128e-5, atol = 1e-12)
        @test isapprox(rmatn[8], 0.4063236803101479770e-4, atol = 1e-12)
        @test isapprox(rmatn[9], 0.9999999991671663114, atol = 1e-12)
    end

    # ERFA.numat
    @testset "numat" begin
        epsa =  0.4090789763356509900
        dpsi = -0.9630909107115582393e-5
        deps =  0.4063239174001678826e-4
        rmatn = ERFA.numat(epsa, dpsi, deps)
        @test isapprox(rmatn[1], 0.9999999999536227949, atol = 1e-12)
        @test isapprox(rmatn[2], 0.8836239320236250577e-5, atol = 1e-12)
        @test isapprox(rmatn[3], 0.3830833447458251908e-5, atol = 1e-12)
        @test isapprox(rmatn[4], -0.8836083657016688588e-5, atol = 1e-12)
        @test isapprox(rmatn[5], 0.9999999991354654959, atol = 1e-12)
        @test isapprox(rmatn[6], -0.4063240865361857698e-4, atol = 1e-12)
        @test isapprox(rmatn[7], -0.3831192481833385226e-5, atol = 1e-12)
        @test isapprox(rmatn[8], 0.4063237480216934159e-4, atol = 1e-12)
        @test isapprox(rmatn[9], 0.9999999991671660407, atol = 1e-12)
    end

    # ERFA.nut00a
    @testset "nut00a" begin
        dpsi, deps = ERFA.nut00a(2400000.5, 53736.0)
        @test isapprox(dpsi, -0.9630909107115518431e-5, atol = 1e-13)
        @test isapprox(deps, 0.4063239174001678710e-4, atol = 1e-13)
    end

    # ERFA.nut00b
    @testset "nut00b" begin
        dpsi, deps = ERFA.nut00b(2400000.5, 53736.0)
        @test isapprox(dpsi, -0.9632552291148362783e-5, atol = 1e-13)
        @test isapprox(deps, 0.4063197106621159367e-4, atol = 1e-13)
    end

    # ERFA.nut06a
    @testset "nut06a" begin
        dpsi, deps = ERFA.nut06a(2400000.5, 53736.0)
        @test isapprox(dpsi, -0.9630912025820308797e-5, atol = 1e-13)
        @test isapprox(deps, 0.4063238496887249798e-4, atol = 1e-13)
    end

    # ERFA.nut80
    @testset "nut80" begin
        dpsi, deps = ERFA.nut80(2400000.5, 53736.0)
        @test isapprox(dpsi, -0.9643658353226563966e-5, atol = 1e-13)
        @test isapprox(deps, 0.4060051006879713322e-4, atol = 1e-13)
    end

    # ERFA.nutm80
    @testset "nutm80" begin
        rmatn = ERFA.nutm80(2400000.5, 53736.)
        @test isapprox(rmatn[1], 0.9999999999534999268, atol = 1e-12)
        @test isapprox(rmatn[2], 0.8847935789636432161e-5, atol = 1e-12)
        @test isapprox(rmatn[3], 0.3835906502164019142e-5, atol = 1e-12)
        @test isapprox(rmatn[4], -0.8847780042583435924e-5, atol = 1e-12)
        @test isapprox(rmatn[5], 0.9999999991366569963, atol = 1e-12)
        @test isapprox(rmatn[6], -0.4060052702727130809e-4, atol = 1e-12)
        @test isapprox(rmatn[7], -0.3836265729708478796e-5, atol = 1e-12)
        @test isapprox(rmatn[8], 0.4060049308612638555e-4, atol = 1e-12)
        @test isapprox(rmatn[9], 0.9999999991684415129, atol = 1e-12)
    end

    # ERFA.obl06
    @testset "obl06" begin
        obl = ERFA.obl06(2400000.5, 54388.0)
        @test isapprox(obl, 0.4090749229387258204, atol = 1e-16)
    end

    # ERFA.obl80
    @testset "obl80" begin
        obl = ERFA.obl80(2400000.5, 54388.0)
        @test isapprox(obl, 0.409075134764381621, atol = 1e-16)
    end

    # ERFA.p06e
    @testset "p06e" begin
        eps0, psia, oma, bpa, bqa, pia, bpia, epsa, chia, za, zetaa, thetaa, pa, gam, phi, psi = ERFA.p06e(2400000.5, 52541.0)
        @test isapprox(eps0, 0.4090926006005828715, atol = 1e-14)
        @test isapprox(psia, 0.6664369630191613431e-3, atol = 1e-14)
        @test isapprox(oma, 0.4090925973783255982, atol = 1e-14)
        @test isapprox(bpa, 0.5561149371265209445e-6, atol = 1e-14)
        @test isapprox(bqa, -0.6191517193290621270e-5, atol = 1e-14)
        @test isapprox(pia, 0.6216441751884382923e-5, atol = 1e-14)
        @test isapprox(bpia, 3.052014180023779882, atol = 1e-14)
        @test isapprox(epsa, 0.4090864054922431688, atol = 1e-14)
        @test isapprox(chia, 0.1387703379530915364e-5, atol = 1e-14)
        @test isapprox(za, 0.2921789846651790546e-3, atol = 1e-14)
        @test isapprox(zetaa, 0.3178773290332009310e-3, atol = 1e-14)
        @test isapprox(thetaa, 0.2650932701657497181e-3, atol = 1e-14)
        @test isapprox(pa, 0.6651637681381016344e-3, atol = 1e-14)
        @test isapprox(gam, 0.1398077115963754987e-5, atol = 1e-14)
        @test isapprox(phi, 0.4090864090837462602, atol = 1e-14)
        @test isapprox(psi, 0.6664464807480920325e-3, atol = 1e-14)
    end

    # ERFA.p2pv
    @testset "p2pv" begin
        pv = ERFA.p2pv([0.25,1.2,3.0])
        @test isapprox(pv[1], 0.25, atol = 1e-12)
        @test isapprox(pv[2], 1.2, atol = 1e-12)
        @test isapprox(pv[3], 3.0, atol = 1e-12)
        @test isapprox(pv[4], 0.0, atol = 1e-12)
        @test isapprox(pv[5], 0.0, atol = 1e-12)
        @test isapprox(pv[6], 0.0, atol = 1e-12)
    end

    # ERFA.p2s
    @testset "p2s" begin
        theta, phi, r = ERFA.p2s([100.,-50.,25.])
        @test isapprox(theta, -0.4636476090008061162, atol = 1e-12)
        @test isapprox(phi, 0.2199879773954594463, atol = 1e-12)
        @test isapprox(r, 114.5643923738960002, atol = 1e-12)
    end

    # ERFA.pap
    @testset "pap" begin
        a = [1.,0.1,0.2]
        b = [-3.,1e-3,0.2]
        theta = ERFA.pap(a, b)
        @test isapprox(theta, 0.3671514267841113674, atol = 1e-12)
    end

    # ERFA.pas
    @testset "pas" begin
        p = ERFA.pas(1.0, 0.1, 0.2, -1.0)
        @test isapprox(p, -2.724544922932270424, atol = 1e-12)
    end

    # ERFA.pb06
    @testset "pb06" begin
        bzeta, bz, btheta = ERFA.pb06(2400000.5, 50123.9999)
        @test isapprox(bzeta, -0.5092634016326478238e-3, atol = 1e-12)
        @test isapprox(bz, -0.3602772060566044413e-3, atol = 1e-12)
        @test isapprox(btheta, -0.3779735537167811177e-3, atol = 1e-12)
    end

    # ERFA.pfw06
    @testset "pfw06" begin
        gamb, phib, psib, epsa = ERFA.pfw06(2400000.5, 50123.9999)
        @test isapprox(gamb, -0.2243387670997995690e-5, atol = 1e-16)
        @test isapprox(phib, 0.4091014602391312808, atol = 1e-12)
        @test isapprox(psib, -0.9501954178013031895e-3, atol = 1e-14)
        @test isapprox(epsa, 0.4091014316587367491, atol = 1e-12)
    end

    # ERFA.pdp
    @testset "pdp" begin
        ab = ERFA.pdp([2.,2.,3.], [1.,3.,4.])
        @test isapprox(ab, 20, atol = 1e-12)
    end

    # ERFA.plan94
    @testset "plan94" begin
        @test_throws ERFAException ERFA.plan94(2400000.5, -320000., 10)
        p, v = ERFA.plan94(2400000.5, -320000., 3)
        @test isapprox(p[1], 0.9308038666832975759, atol = 1e-11)
        @test isapprox(p[2], 0.3258319040261346000, atol = 1e-11)
        @test isapprox(p[3], 0.1422794544481140560, atol = 1e-11)
        @test isapprox(v[1], -0.6429458958255170006e-2, atol = 1e-11)
        @test isapprox(v[2], 0.1468570657704237764e-1, atol = 1e-11)
        @test isapprox(v[3], 0.6406996426270981189e-2, atol = 1e-11)

        p, v = ERFA.plan94(2400000.5, 43999.9, 1)
        @test isapprox(p[1], 0.2945293959257430832, atol = 1e-11)
        @test isapprox(p[2], -0.2452204176601049596, atol = 1e-11)
        @test isapprox(p[3], -0.1615427700571978153, atol = 1e-11)
        @test isapprox(v[1], 0.1413867871404614441e-1, atol = 1e-11)
        @test isapprox(v[2], 0.1946548301104706582e-1, atol = 1e-11)
        @test isapprox(v[3], 0.8929809783898904786e-2, atol = 1e-11)
    end

    # ERFA.pm
    @testset "pm" begin
        m = ERFA.pm([0.3,1.2,-2.5])
        @test isapprox(m, 2.789265136196270604, atol = 1e-14)
    end

    # ERFA.pmp
    @testset "pmp" begin
        a = [2.0,2.0,3.0]
        b = [1.0,3.0,4.0]
        amb = ERFA.pmp(a, b)
        @test isapprox(amb[1], 1.0, atol = 1e-12)
        @test isapprox(amb[2], -1.0, atol = 1e-12)
        @test isapprox(amb[3], -1.0, atol = 1e-12)
    end

    # ERFA.pmpx
    @testset "pmpx" begin
        rc = 1.234
        dc = 0.789
        pr = 1e-5
        pd = -2e-5
        px = 1e-2
        rv = 10.0
        pmt = 8.75
        pob = [0.9, 0.4, 0.1]
        pco = ERFA.pmpx(rc, dc, pr, pd, px, rv, pmt, pob)
        @test isapprox(pco[1], 0.2328137623960308440, atol = 1e-12)
        @test isapprox(pco[2], 0.6651097085397855317, atol = 1e-12)
        @test isapprox(pco[3], 0.7095257765896359847, atol = 1e-12)
    end

    # ERFA.pmsafe
    @testset "pmsafe" begin
        ra1 = 1.234
        dec1 = 0.789
        pmr1 = 1e-5
        pmd1 = -2e-5
        px1 = 1e-2
        rv1 = 10.0
        ep1a = 2400000.5
        ep1b = 48348.5625
        ep2a = 2400000.5
        ep2b = 51544.5
        ra2, dec2, pmr2, pmd2, px2, rv2 = ERFA.pmsafe(ra1, dec1, pmr1, pmd1, px1, rv1, ep1a, ep1b, ep2a, ep2b)
        @test isapprox(ra2, 1.234087484501017061, atol = 1e-12)
        @test isapprox(dec2, 0.7888249982450468567, atol = 1e-12)
        @test isapprox(pmr2, 0.9996457663586073988e-5, atol = 1e-12)
        @test isapprox(pmd2, -0.2000040085106754565e-4, atol = 1e-16)
        @test isapprox(px2, 0.9999997295356830666e-2, atol = 1e-12)
        @test isapprox(rv2, 10.38468380293920069, atol = 1e-10)
    end

    # ERFA.pmat00
    @testset "pmat00" begin
        rbp = ERFA.pmat00(2400000.5, 50123.9999)
        @test isapprox(rbp[1], 0.9999995505175087260, atol = 1e-12)
        @test isapprox(rbp[2], 0.8695405883617884705e-3, atol = 1e-14)
        @test isapprox(rbp[3], 0.3779734722239007105e-3, atol = 1e-14)
        @test isapprox(rbp[4], -0.8695405990410863719e-3, atol = 1e-14)
        @test isapprox(rbp[5], 0.9999996219494925900, atol = 1e-12)
        @test isapprox(rbp[6], -0.1360775820404982209e-6, atol = 1e-14)
        @test isapprox(rbp[7], -0.3779734476558184991e-3, atol = 1e-14)
        @test isapprox(rbp[8], -0.1925857585832024058e-6, atol = 1e-14)
        @test isapprox(rbp[9], 0.9999999285680153377, atol = 1e-12)
    end

    # ERFA.pmat06
    @testset "pmat06" begin
        rbp = ERFA.pmat06(2400000.5, 50123.9999)
        @test isapprox(rbp[1], 0.9999995505176007047, atol = 1e-12)
        @test isapprox(rbp[2], 0.8695404617348208406e-3, atol = 1e-14)
        @test isapprox(rbp[3], 0.3779735201865589104e-3, atol = 1e-14)
        @test isapprox(rbp[4], -0.8695404723772031414e-3, atol = 1e-14)
        @test isapprox(rbp[5], 0.9999996219496027161, atol = 1e-12)
        @test isapprox(rbp[6], -0.1361752497080270143e-6, atol = 1e-14)
        @test isapprox(rbp[7], -0.3779734957034089490e-3, atol = 1e-14)
        @test isapprox(rbp[8], -0.1924880847894457113e-6, atol = 1e-14)
        @test isapprox(rbp[9], 0.9999999285679971958, atol = 1e-12)
    end

    # ERFA.pmat76
    @testset "pmat76" begin
        rmatp = ERFA.pmat76(2400000.5, 50123.9999)
        @test isapprox(rmatp[1], 0.9999995504328350733, atol = 1e-12)
        @test isapprox(rmatp[2], 0.8696632209480960785e-3, atol = 1e-14)
        @test isapprox(rmatp[3], 0.3779153474959888345e-3, atol = 1e-14)
        @test isapprox(rmatp[4], -0.8696632209485112192e-3, atol = 1e-14)
        @test isapprox(rmatp[5], 0.9999996218428560614, atol = 1e-12)
        @test isapprox(rmatp[6], -0.1643284776111886407e-6, atol = 1e-14)
        @test isapprox(rmatp[7], -0.3779153474950335077e-3, atol = 1e-14)
        @test isapprox(rmatp[8], -0.1643306746147366896e-6, atol = 1e-14)
        @test isapprox(rmatp[9], 0.9999999285899790119, atol = 1e-12)
    end

    # ERFA.pn
    @testset "pn" begin
        r, u = ERFA.pn([0.3,1.2,-2.5])
        @test isapprox(r, 2.789265136196270604, atol = 1e-12)
        @test isapprox(u[1], 0.1075552109073112058, atol = 1e-12)
        @test isapprox(u[2], 0.4302208436292448232, atol = 1e-12)
        @test isapprox(u[3], -0.8962934242275933816, atol = 1e-12)
    end

    # ERFA.pn00
    @testset "pn00" begin
        dpsi = -0.9632552291149335877e-5
        deps =  0.4063197106621141414e-4
        epsa, rb, rp, rbp, rn, rbpn = ERFA.pn00(2400000.5, 53736.0, dpsi, deps)
        @test isapprox(epsa, 0.4090791789404229916, atol = 1e-12)
        @test isapprox(rb[1], 0.9999999999999942498, atol = 1e-12)
        @test isapprox(rb[2], -0.7078279744199196626e-7, atol = 1e-18)
        @test isapprox(rb[3], 0.8056217146976134152e-7, atol = 1e-18)
        @test isapprox(rb[4], 0.7078279477857337206e-7, atol = 1e-18)
        @test isapprox(rb[5], 0.9999999999999969484, atol = 1e-12)
        @test isapprox(rb[6], 0.3306041454222136517e-7, atol = 1e-18)
        @test isapprox(rb[7], -0.8056217380986972157e-7, atol = 1e-18)
        @test isapprox(rb[8], -0.3306040883980552500e-7, atol = 1e-18)
        @test isapprox(rb[9], 0.9999999999999962084, atol = 1e-12)
        @test isapprox(rp[1], 0.9999989300532289018, atol = 1e-12)
        @test isapprox(rp[2], -0.1341647226791824349e-2, atol = 1e-14)
        @test isapprox(rp[3], -0.5829880927190296547e-3, atol = 1e-14)
        @test isapprox(rp[4], 0.1341647231069759008e-2, atol = 1e-14)
        @test isapprox(rp[5], 0.9999990999908750433, atol = 1e-12)
        @test isapprox(rp[6], -0.3837444441583715468e-6, atol = 1e-14)
        @test isapprox(rp[7], 0.5829880828740957684e-3, atol = 1e-14)
        @test isapprox(rp[8], -0.3984203267708834759e-6, atol = 1e-14)
        @test isapprox(rp[9], 0.9999998300623538046, atol = 1e-12)
        @test isapprox(rbp[1], 0.9999989300052243993, atol = 1e-12)
        @test isapprox(rbp[2], -0.1341717990239703727e-2, atol = 1e-14)
        @test isapprox(rbp[3], -0.5829075749891684053e-3, atol = 1e-14)
        @test isapprox(rbp[4], 0.1341718013831739992e-2, atol = 1e-14)
        @test isapprox(rbp[5], 0.9999990998959191343, atol = 1e-12)
        @test isapprox(rbp[6], -0.3505759733565421170e-6, atol = 1e-14)
        @test isapprox(rbp[7], 0.5829075206857717883e-3, atol = 1e-14)
        @test isapprox(rbp[8], -0.4315219955198608970e-6, atol = 1e-14)
        @test isapprox(rbp[9], 0.9999998301093036269, atol = 1e-12)
        @test isapprox(rn[1], 0.9999999999536069682, atol = 1e-12)
        @test isapprox(rn[2], 0.8837746144872140812e-5, atol = 1e-16)
        @test isapprox(rn[3], 0.3831488838252590008e-5, atol = 1e-16)
        @test isapprox(rn[4], -0.8837590456633197506e-5, atol = 1e-16)
        @test isapprox(rn[5], 0.9999999991354692733, atol = 1e-12)
        @test isapprox(rn[6], -0.4063198798559573702e-4, atol = 1e-16)
        @test isapprox(rn[7], -0.3831847930135328368e-5, atol = 1e-16)
        @test isapprox(rn[8], 0.4063195412258150427e-4, atol = 1e-16)
        @test isapprox(rn[9], 0.9999999991671806225, atol = 1e-12)
        @test isapprox(rbpn[1], 0.9999989440499982806, atol = 1e-12)
        @test isapprox(rbpn[2], -0.1332880253640848301e-2, atol = 1e-14)
        @test isapprox(rbpn[3], -0.5790760898731087295e-3, atol = 1e-14)
        @test isapprox(rbpn[4], 0.1332856746979948745e-2, atol = 1e-14)
        @test isapprox(rbpn[5], 0.9999991109064768883, atol = 1e-12)
        @test isapprox(rbpn[6], -0.4097740555723063806e-4, atol = 1e-14)
        @test isapprox(rbpn[7], 0.5791301929950205000e-3, atol = 1e-14)
        @test isapprox(rbpn[8], 0.4020553681373702931e-4, atol = 1e-14)
        @test isapprox(rbpn[9], 0.9999998314958529887, atol = 1e-12)
    end

    # ERFA.pn00a
    @testset "pn00a" begin
        dpsi, deps, epsa, rb, rp, rbp, rn, rbpn = ERFA.pn00a(2400000.5, 53736.0)
        @test isapprox(dpsi, -0.9630909107115518431e-5, atol = 1e-12)
        @test isapprox(deps, 0.4063239174001678710e-4, atol = 1e-12)
        @test isapprox(epsa, 0.4090791789404229916, atol = 1e-12)
        @test isapprox(rb[1], 0.9999999999999942498, atol = 1e-12)
        @test isapprox(rb[2], -0.7078279744199196626e-7, atol = 1e-16)
        @test isapprox(rb[3], 0.8056217146976134152e-7, atol = 1e-16)
        @test isapprox(rb[4], 0.7078279477857337206e-7, atol = 1e-16)
        @test isapprox(rb[5], 0.9999999999999969484, atol = 1e-12)
        @test isapprox(rb[6], 0.3306041454222136517e-7, atol = 1e-16)
        @test isapprox(rb[7], -0.8056217380986972157e-7, atol = 1e-16)
        @test isapprox(rb[8], -0.3306040883980552500e-7, atol = 1e-16)
        @test isapprox(rb[9], 0.9999999999999962084, atol = 1e-12)
        @test isapprox(rp[1], 0.9999989300532289018, atol = 1e-12)
        @test isapprox(rp[2], -0.1341647226791824349e-2, atol = 1e-14)
        @test isapprox(rp[3], -0.5829880927190296547e-3, atol = 1e-14)
        @test isapprox(rp[4], 0.1341647231069759008e-2, atol = 1e-14)
        @test isapprox(rp[5], 0.9999990999908750433, atol = 1e-12)
        @test isapprox(rp[6], -0.3837444441583715468e-6, atol = 1e-14)
        @test isapprox(rp[7], 0.5829880828740957684e-3, atol = 1e-14)
        @test isapprox(rp[8], -0.3984203267708834759e-6, atol = 1e-14)
        @test isapprox(rp[9], 0.9999998300623538046, atol = 1e-12)
        @test isapprox(rbp[1], 0.9999989300052243993, atol = 1e-12)
        @test isapprox(rbp[2], -0.1341717990239703727e-2, atol = 1e-14)
        @test isapprox(rbp[3], -0.5829075749891684053e-3, atol = 1e-14)
        @test isapprox(rbp[4], 0.1341718013831739992e-2, atol = 1e-14)
        @test isapprox(rbp[5], 0.9999990998959191343, atol = 1e-12)
        @test isapprox(rbp[6], -0.3505759733565421170e-6, atol = 1e-14)
        @test isapprox(rbp[7], 0.5829075206857717883e-3, atol = 1e-14)
        @test isapprox(rbp[8], -0.4315219955198608970e-6, atol = 1e-14)
        @test isapprox(rbp[9], 0.9999998301093036269, atol = 1e-12)
        @test isapprox(rn[1], 0.9999999999536227949, atol = 1e-12)
        @test isapprox(rn[2], 0.8836238544090873336e-5, atol = 1e-14)
        @test isapprox(rn[3], 0.3830835237722400669e-5, atol = 1e-14)
        @test isapprox(rn[4], -0.8836082880798569274e-5, atol = 1e-14)
        @test isapprox(rn[5], 0.9999999991354655028, atol = 1e-12)
        @test isapprox(rn[6], -0.4063240865362499850e-4, atol = 1e-14)
        @test isapprox(rn[7], -0.3831194272065995866e-5, atol = 1e-14)
        @test isapprox(rn[8], 0.4063237480216291775e-4, atol = 1e-14)
        @test isapprox(rn[9], 0.9999999991671660338, atol = 1e-12)
        @test isapprox(rbpn[1], 0.9999989440476103435, atol = 1e-12)
        @test isapprox(rbpn[2], -0.1332881761240011763e-2, atol = 1e-14)
        @test isapprox(rbpn[3], -0.5790767434730085751e-3, atol = 1e-14)
        @test isapprox(rbpn[4], 0.1332858254308954658e-2, atol = 1e-14)
        @test isapprox(rbpn[5], 0.9999991109044505577, atol = 1e-12)
        @test isapprox(rbpn[6], -0.4097782710396580452e-4, atol = 1e-14)
        @test isapprox(rbpn[7], 0.5791308472168152904e-3, atol = 1e-14)
        @test isapprox(rbpn[8], 0.4020595661591500259e-4, atol = 1e-14)
        @test isapprox(rbpn[9], 0.9999998314954572304, atol = 1e-12)
    end

    # ERFA.pn06
    @testset "pn06" begin
        dpsi = -0.9632552291149335877e-5
        deps =  0.4063197106621141414e-4
        epsa, rb, rp, rbp, rn, rbpn = ERFA.pn06(2400000.5, 53736.0, dpsi, deps)
        @test isapprox(epsa, 0.4090789763356509926, atol = 1e-12)
        @test isapprox(rb[1], 0.9999999999999942497, atol = 1e-12)
        @test isapprox(rb[2], -0.7078368960971557145e-7, atol = 1e-14)
        @test isapprox(rb[3], 0.8056213977613185606e-7, atol = 1e-14)
        @test isapprox(rb[4], 0.7078368694637674333e-7, atol = 1e-14)
        @test isapprox(rb[5], 0.9999999999999969484, atol = 1e-12)
        @test isapprox(rb[6], 0.3305943742989134124e-7, atol = 1e-14)
        @test isapprox(rb[7], -0.8056214211620056792e-7, atol = 1e-14)
        @test isapprox(rb[8], -0.3305943172740586950e-7, atol = 1e-14)
        @test isapprox(rb[9], 0.9999999999999962084, atol = 1e-12)
        @test isapprox(rp[1], 0.9999989300536854831, atol = 1e-12)
        @test isapprox(rp[2], -0.1341646886204443795e-2, atol = 1e-14)
        @test isapprox(rp[3], -0.5829880933488627759e-3, atol = 1e-14)
        @test isapprox(rp[4], 0.1341646890569782183e-2, atol = 1e-14)
        @test isapprox(rp[5], 0.9999990999913319321, atol = 1e-12)
        @test isapprox(rp[6], -0.3835944216374477457e-6, atol = 1e-14)
        @test isapprox(rp[7], 0.5829880833027867368e-3, atol = 1e-14)
        @test isapprox(rp[8], -0.3985701514686976112e-6, atol = 1e-14)
        @test isapprox(rp[9], 0.9999998300623534950, atol = 1e-12)
        @test isapprox(rbp[1], 0.9999989300056797893, atol = 1e-12)
        @test isapprox(rbp[2], -0.1341717650545059598e-2, atol = 1e-14)
        @test isapprox(rbp[3], -0.5829075756493728856e-3, atol = 1e-14)
        @test isapprox(rbp[4], 0.1341717674223918101e-2, atol = 1e-14)
        @test isapprox(rbp[5], 0.9999990998963748448, atol = 1e-12)
        @test isapprox(rbp[6], -0.3504269280170069029e-6, atol = 1e-14)
        @test isapprox(rbp[7], 0.5829075211461454599e-3, atol = 1e-14)
        @test isapprox(rbp[8], -0.4316708436255949093e-6, atol = 1e-14)
        @test isapprox(rbp[9], 0.9999998301093032943, atol = 1e-12)
        @test isapprox(rn[1], 0.9999999999536069682, atol = 1e-12)
        @test isapprox(rn[2], 0.8837746921149881914e-5, atol = 1e-14)
        @test isapprox(rn[3], 0.3831487047682968703e-5, atol = 1e-14)
        @test isapprox(rn[4], -0.8837591232983692340e-5, atol = 1e-14)
        @test isapprox(rn[5], 0.9999999991354692664, atol = 1e-12)
        @test isapprox(rn[6], -0.4063198798558931215e-4, atol = 1e-14)
        @test isapprox(rn[7], -0.3831846139597250235e-5, atol = 1e-14)
        @test isapprox(rn[8], 0.4063195412258792914e-4, atol = 1e-14)
        @test isapprox(rn[9], 0.9999999991671806293, atol = 1e-12)
        @test isapprox(rbpn[1], 0.9999989440504506688, atol = 1e-12)
        @test isapprox(rbpn[2], -0.1332879913170492655e-2, atol = 1e-14)
        @test isapprox(rbpn[3], -0.5790760923225655753e-3, atol = 1e-14)
        @test isapprox(rbpn[4], 0.1332856406595754748e-2, atol = 1e-14)
        @test isapprox(rbpn[5], 0.9999991109069366795, atol = 1e-12)
        @test isapprox(rbpn[6], -0.4097725651142641812e-4, atol = 1e-14)
        @test isapprox(rbpn[7], 0.5791301952321296716e-3, atol = 1e-14)
        @test isapprox(rbpn[8], 0.4020538796195230577e-4, atol = 1e-14)
        @test isapprox(rbpn[9], 0.9999998314958576778, atol = 1e-12)
    end

    # ERFA.pn06a
    @testset "pn06a" begin
        dpsi, deps, epsa, rb, rp, rbp, rn, rbpn = ERFA.pn06a(2400000.5, 53736.0)
        @test isapprox(dpsi, -0.9630912025820308797e-5, atol = 1e-12)
        @test isapprox(deps, 0.4063238496887249798e-4, atol = 1e-12)
        @test isapprox(epsa, 0.4090789763356509926, atol = 1e-12)
        @test isapprox(rb[1], 0.9999999999999942497, atol = 1e-12)
        @test isapprox(rb[2], -0.7078368960971557145e-7, atol = 1e-14)
        @test isapprox(rb[3], 0.8056213977613185606e-7, atol = 1e-14)
        @test isapprox(rb[4], 0.7078368694637674333e-7, atol = 1e-14)
        @test isapprox(rb[5], 0.9999999999999969484, atol = 1e-12)
        @test isapprox(rb[6], 0.3305943742989134124e-7, atol = 1e-14)
        @test isapprox(rb[7], -0.8056214211620056792e-7, atol = 1e-14)
        @test isapprox(rb[8], -0.3305943172740586950e-7, atol = 1e-14)
        @test isapprox(rb[9], 0.9999999999999962084, atol = 1e-12)
        @test isapprox(rp[1], 0.9999989300536854831, atol = 1e-12)
        @test isapprox(rp[2], -0.1341646886204443795e-2, atol = 1e-14)
        @test isapprox(rp[3], -0.5829880933488627759e-3, atol = 1e-14)
        @test isapprox(rp[4], 0.1341646890569782183e-2, atol = 1e-14)
        @test isapprox(rp[5], 0.9999990999913319321, atol = 1e-12)
        @test isapprox(rp[6], -0.3835944216374477457e-6, atol = 1e-14)
        @test isapprox(rp[7], 0.5829880833027867368e-3, atol = 1e-14)
        @test isapprox(rp[8], -0.3985701514686976112e-6, atol = 1e-14)
        @test isapprox(rp[9], 0.9999998300623534950, atol = 1e-12)
        @test isapprox(rbp[1], 0.9999989300056797893, atol = 1e-12)
        @test isapprox(rbp[2], -0.1341717650545059598e-2, atol = 1e-14)
        @test isapprox(rbp[3], -0.5829075756493728856e-3, atol = 1e-14)
        @test isapprox(rbp[4], 0.1341717674223918101e-2, atol = 1e-14)
        @test isapprox(rbp[5], 0.9999990998963748448, atol = 1e-12)
        @test isapprox(rbp[6], -0.3504269280170069029e-6, atol = 1e-14)
        @test isapprox(rbp[7], 0.5829075211461454599e-3, atol = 1e-14)
        @test isapprox(rbp[8], -0.4316708436255949093e-6, atol = 1e-14)
        @test isapprox(rbp[9], 0.9999998301093032943, atol = 1e-12)
        @test isapprox(rn[1], 0.9999999999536227668, atol = 1e-12)
        @test isapprox(rn[2], 0.8836241998111535233e-5, atol = 1e-14)
        @test isapprox(rn[3], 0.3830834608415287707e-5, atol = 1e-14)
        @test isapprox(rn[4], -0.8836086334870740138e-5, atol = 1e-14)
        @test isapprox(rn[5], 0.9999999991354657474, atol = 1e-12)
        @test isapprox(rn[6], -0.4063240188248455065e-4, atol = 1e-14)
        @test isapprox(rn[7], -0.3831193642839398128e-5, atol = 1e-14)
        @test isapprox(rn[8], 0.4063236803101479770e-4, atol = 1e-14)
        @test isapprox(rn[9], 0.9999999991671663114, atol = 1e-12)
        @test isapprox(rbpn[1], 0.9999989440480669738, atol = 1e-12)
        @test isapprox(rbpn[2], -0.1332881418091915973e-2, atol = 1e-14)
        @test isapprox(rbpn[3], -0.5790767447612042565e-3, atol = 1e-14)
        @test isapprox(rbpn[4], 0.1332857911250989133e-2, atol = 1e-14)
        @test isapprox(rbpn[5], 0.9999991109049141908, atol = 1e-12)
        @test isapprox(rbpn[6], -0.4097767128546784878e-4, atol = 1e-14)
        @test isapprox(rbpn[7], 0.5791308482835292617e-3, atol = 1e-14)
        @test isapprox(rbpn[8], 0.4020580099454020310e-4, atol = 1e-14)
        @test isapprox(rbpn[9], 0.9999998314954628695, atol = 1e-12)
    end

    # ERFA.pnm00a
    @testset "pnm00a" begin
        rbpn = ERFA.pnm00a(2400000.5, 50123.9999)
        @test isapprox(rbpn[1], 0.9999995832793134257, atol = 1e-12)
        @test isapprox(rbpn[2], 0.8372384254137809439e-3, atol = 1e-14)
        @test isapprox(rbpn[3], 0.3639684306407150645e-3, atol = 1e-14)
        @test isapprox(rbpn[4], -0.8372535226570394543e-3, atol = 1e-14)
        @test isapprox(rbpn[5], 0.9999996486491582471, atol = 1e-12)
        @test isapprox(rbpn[6], 0.4132915262664072381e-4, atol = 1e-14)
        @test isapprox(rbpn[7], -0.3639337004054317729e-3, atol = 1e-14)
        @test isapprox(rbpn[8], -0.4163386925461775873e-4, atol = 1e-14)
        @test isapprox(rbpn[9], 0.9999999329094390695, atol = 1e-12)
    end

    # ERFA.pn00b
    @testset "pn00b" begin
        dpsi, deps, epsa, rb, rp, rbp, rn, rbpn = ERFA.pn00b(2400000.5, 53736.0)
        @test isapprox(dpsi, -0.9632552291148362783e-5, atol = 1e-12)
        @test isapprox(deps, 0.4063197106621159367e-4, atol = 1e-12)
        @test isapprox(epsa, 0.4090791789404229916, atol = 1e-12)
        @test isapprox(rb[1], 0.9999999999999942498, atol = 1e-12)
        @test isapprox(rb[2], -0.7078279744199196626e-7, atol = 1e-16)
        @test isapprox(rb[3], 0.8056217146976134152e-7, atol = 1e-16)
        @test isapprox(rb[4], 0.7078279477857337206e-7, atol = 1e-16)
        @test isapprox(rb[5], 0.9999999999999969484, atol = 1e-12)
        @test isapprox(rb[6], 0.3306041454222136517e-7, atol = 1e-16)
        @test isapprox(rb[7], -0.8056217380986972157e-7, atol = 1e-16)
        @test isapprox(rb[8], -0.3306040883980552500e-7, atol = 1e-16)
        @test isapprox(rb[9], 0.9999999999999962084, atol = 1e-12)
        @test isapprox(rp[1], 0.9999989300532289018, atol = 1e-12)
        @test isapprox(rp[2], -0.1341647226791824349e-2, atol = 1e-14)
        @test isapprox(rp[3], -0.5829880927190296547e-3, atol = 1e-14)
        @test isapprox(rp[4], 0.1341647231069759008e-2, atol = 1e-14)
        @test isapprox(rp[5], 0.9999990999908750433, atol = 1e-12)
        @test isapprox(rp[6], -0.3837444441583715468e-6, atol = 1e-14)
        @test isapprox(rp[7], 0.5829880828740957684e-3, atol = 1e-14)
        @test isapprox(rp[8], -0.3984203267708834759e-6, atol = 1e-14)
        @test isapprox(rp[9], 0.9999998300623538046, atol = 1e-12)
        @test isapprox(rbp[1], 0.9999989300052243993, atol = 1e-12)
        @test isapprox(rbp[2], -0.1341717990239703727e-2, atol = 1e-14)
        @test isapprox(rbp[3], -0.5829075749891684053e-3, atol = 1e-14)
        @test isapprox(rbp[4], 0.1341718013831739992e-2, atol = 1e-14)
        @test isapprox(rbp[5], 0.9999990998959191343, atol = 1e-12)
        @test isapprox(rbp[6], -0.3505759733565421170e-6, atol = 1e-14)
        @test isapprox(rbp[7], 0.5829075206857717883e-3, atol = 1e-14)
        @test isapprox(rbp[8], -0.4315219955198608970e-6, atol = 1e-14)
        @test isapprox(rbp[9], 0.9999998301093036269, atol = 1e-12)
        @test isapprox(rn[1], 0.9999999999536069682, atol = 1e-12)
        @test isapprox(rn[2], 0.8837746144871248011e-5, atol = 1e-14)
        @test isapprox(rn[3], 0.3831488838252202945e-5, atol = 1e-14)
        @test isapprox(rn[4], -0.8837590456632304720e-5, atol = 1e-14)
        @test isapprox(rn[5], 0.9999999991354692733, atol = 1e-12)
        @test isapprox(rn[6], -0.4063198798559591654e-4, atol = 1e-14)
        @test isapprox(rn[7], -0.3831847930134941271e-5, atol = 1e-14)
        @test isapprox(rn[8], 0.4063195412258168380e-4, atol = 1e-14)
        @test isapprox(rn[9], 0.9999999991671806225, atol = 1e-12)
        @test isapprox(rbpn[1], 0.9999989440499982806, atol = 1e-12)
        @test isapprox(rbpn[2], -0.1332880253640849194e-2, atol = 1e-14)
        @test isapprox(rbpn[3], -0.5790760898731091166e-3, atol = 1e-14)
        @test isapprox(rbpn[4], 0.1332856746979949638e-2, atol = 1e-14)
        @test isapprox(rbpn[5], 0.9999991109064768883, atol = 1e-12)
        @test isapprox(rbpn[6], -0.4097740555723081811e-4, atol = 1e-14)
        @test isapprox(rbpn[7], 0.5791301929950208873e-3, atol = 1e-14)
        @test isapprox(rbpn[8], 0.4020553681373720832e-4, atol = 1e-14)
        @test isapprox(rbpn[9], 0.9999998314958529887, atol = 1e-12)
    end

    # ERFA.pnm00b
    @testset "pnm00b" begin
        rbpn = ERFA.pnm00b(2400000.5, 50123.9999)
        @test isapprox(rbpn[1], 0.9999995832776208280, atol = 1e-12)
        @test isapprox(rbpn[2], 0.8372401264429654837e-3, atol = 1e-14)
        @test isapprox(rbpn[3], 0.3639691681450271771e-3, atol = 1e-14)
        @test isapprox(rbpn[4], -0.8372552234147137424e-3, atol = 1e-14)
        @test isapprox(rbpn[5], 0.9999996486477686123, atol = 1e-12)
        @test isapprox(rbpn[6], 0.4132832190946052890e-4, atol = 1e-14)
        @test isapprox(rbpn[7], -0.3639344385341866407e-3, atol = 1e-14)
        @test isapprox(rbpn[8], -0.4163303977421522785e-4, atol = 1e-14)
        @test isapprox(rbpn[9], 0.9999999329092049734, atol = 1e-12)
    end

    # ERFA.pnm06a
    @testset "pnm06a" begin
        rbpn = ERFA.pnm06a(2400000.5, 50123.9999)
        @test isapprox(rbpn[1], 0.9999995832794205484, atol = 1e-12)
        @test isapprox(rbpn[2], 0.8372382772630962111e-3, atol = 1e-14)
        @test isapprox(rbpn[3], 0.3639684771140623099e-3, atol = 1e-14)
        @test isapprox(rbpn[4], -0.8372533744743683605e-3, atol = 1e-14)
        @test isapprox(rbpn[5], 0.9999996486492861646, atol = 1e-12)
        @test isapprox(rbpn[6], 0.4132905944611019498e-4, atol = 1e-14)
        @test isapprox(rbpn[7], -0.3639337469629464969e-3, atol = 1e-14)
        @test isapprox(rbpn[8], -0.4163377605910663999e-4, atol = 1e-14)
        @test isapprox(rbpn[9], 0.9999999329094260057, atol = 1e-12)
    end

    # ERFA.pnm80
    @testset "pnm80" begin
        rmatpn = ERFA.pnm80(2400000.5, 50123.9999)
        @test isapprox(rmatpn[1], 0.9999995831934611169, atol = 1e-12)
        @test isapprox(rmatpn[2], 0.8373654045728124011e-3, atol = 1e-14)
        @test isapprox(rmatpn[3], 0.3639121916933106191e-3, atol = 1e-14)
        @test isapprox(rmatpn[4], -0.8373804896118301316e-3, atol = 1e-14)
        @test isapprox(rmatpn[5], 0.9999996485439674092, atol = 1e-12)
        @test isapprox(rmatpn[6], 0.4130202510421549752e-4, atol = 1e-14)
        @test isapprox(rmatpn[7], -0.3638774789072144473e-3, atol = 1e-14)
        @test isapprox(rmatpn[8], -0.4160674085851722359e-4, atol = 1e-14)
        @test isapprox(rmatpn[9], 0.9999999329310274805, atol = 1e-12)
    end

    # ERFA.pom00
    @testset "pom00" begin
        xp =  2.55060238e-7
        yp =  1.860359247e-6
        sp = -0.1367174580728891460e-10
        rpom = ERFA.pom00(xp, yp, sp)
        @test isapprox(rpom[1], 0.9999999999999674721, atol = 1e-12)
        @test isapprox(rpom[2], -0.1367174580728846989e-10, atol = 1e-16)
        @test isapprox(rpom[3], 0.2550602379999972345e-6, atol = 1e-16)
        @test isapprox(rpom[4], 0.1414624947957029801e-10, atol = 1e-16)
        @test isapprox(rpom[5], 0.9999999999982695317, atol = 1e-12)
        @test isapprox(rpom[6], -0.1860359246998866389e-5, atol = 1e-16)
        @test isapprox(rpom[7], -0.2550602379741215021e-6, atol = 1e-16)
        @test isapprox(rpom[8], 0.1860359247002414021e-5, atol = 1e-16)
        @test isapprox(rpom[9], 0.9999999999982370039, atol = 1e-12)
    end

    # ERFA.ppp
    @testset "ppp" begin
        apb = ERFA.ppp([2.0,2.0,3.0], [1.0,3.0,4.0])
        @test isapprox(apb[1], 3.0, atol = 1e-12)
        @test isapprox(apb[2], 5.0, atol = 1e-12)
        @test isapprox(apb[3], 7.0, atol = 1e-12)
    end

    # ERFA.ppsp
    @testset "ppsp" begin
        apsb = ERFA.ppsp([2.0,2.0,3.0], 5.0, [1.0,3.0,4.0])
        @test isapprox(apsb[1], 7.0, atol = 1e-12)
        @test isapprox(apsb[2], 17.0, atol = 1e-12)
        @test isapprox(apsb[3], 23.0, atol = 1e-12)
    end

    # ERFA.pr00
    @testset "pr00" begin
        dpsipr, depspr = ERFA.pr00(2400000.5, 53736.)
        @test isapprox(dpsipr, -0.8716465172668347629e-7, atol = 1e-22)
        @test isapprox(depspr, -0.7342018386722813087e-8, atol = 1e-22)
    end

    # ERFA.prec76
    @testset "prec76" begin
        ep01 = 2400000.5
        ep02 = 33282.0
        ep11 = 2400000.5
        ep12 = 51544.0
        zeta, z, theta = ERFA.prec76(ep01, ep02, ep11, ep12)
        @test isapprox(zeta, 0.5588961642000161243e-2, atol = 1e-12)
        @test isapprox(z, 0.5589922365870680624e-2, atol = 1e-12)
        @test isapprox(theta, 0.4858945471687296760e-2, atol = 1e-12)
    end

    # ERFA.pv2p
    @testset "pv2p" begin
        p = ERFA.pv2p([[0.3,1.2,-2.5];[-0.5,3.1,0.9]])
        @test isapprox(p[1], 0.3, atol = 0.0)
        @test isapprox(p[2], 1.2, atol = 0.0)
        @test isapprox(p[3], -2.5, atol = 0.0)
    end

    # ERFA.pv2s
    @testset "pv2s" begin
        pv = [[-0.4514964673880165,0.03093394277342585,0.05594668105108779];
              [1.292270850663260e-5,2.652814182060692e-6,2.568431853930293e-6]]
        theta, phi, r, td, pd, rd = ERFA.pv2s(pv)
        @test isapprox(theta, 3.073185307179586515, atol = 1e-12)
        @test isapprox(phi, 0.1229999999999999992, atol = 1e-12)
        @test isapprox(r, 0.4559999999999999757, atol = 1e-12)
        @test isapprox(td, -0.7800000000000000364e-5, atol = 1e-16)
        @test isapprox(pd, 0.9010000000000001639e-5, atol = 1e-16)
        @test isapprox(rd, -0.1229999999999999832e-4, atol = 1e-16)
    end

    # ERFA.pvdpv
    @testset "pvdpv" begin
        a = [[2.,2.,3.];[6.,0.,4.]]
        b = [[1.,3.,4.];[0.,2.,8.]]
        adb = ERFA.pvdpv(a, b)
        @test isapprox(adb[1], 20.0, atol = 1e-12)
        @test isapprox(adb[2], 50.0, atol = 1e-12)
    end

    # ERFA.pvm
    @testset "pvm" begin
        pv = [[0.3,1.2,-2.5];[0.45,-0.25,1.1]]
        r, s = ERFA.pvm(pv)
        @test isapprox(r, 2.789265136196270604, atol = 1e-12)
        @test isapprox(s, 1.214495780149111922, atol = 1e-12)
    end

    # ERFA.pvmpv
    @testset "pvmpv" begin
        a = [[2.0,2.0,3.0];[5.0,6.0,3.0]]
        b = [[1.0,3.0,4.0];[3.0,2.0,1.0]]
        amb = ERFA.pvmpv(a, b)
        @test isapprox(amb[1], 1.0, atol = 1e-12)
        @test isapprox(amb[2], -1.0, atol = 1e-12)
        @test isapprox(amb[3], -1.0, atol = 1e-12)
        @test isapprox(amb[4], 2.0, atol = 1e-12)
        @test isapprox(amb[5], 4.0, atol = 1e-12)
        @test isapprox(amb[6], 2.0, atol = 1e-12)
    end

    # ERFA.pvppv
    @testset "pvppv" begin
        a = [[2.0,2.0,3.0];[5.0,6.0,3.0]]
        b = [[1.0,3.0,4.0];[3.0,2.0,1.0]]
        apb = ERFA.pvppv(a, b)
        @test isapprox(apb[1], 3.0, atol = 1e-12)
        @test isapprox(apb[2], 5.0, atol = 1e-12)
        @test isapprox(apb[3], 7.0, atol = 1e-12)
        @test isapprox(apb[4], 8.0, atol = 1e-12)
        @test isapprox(apb[5], 8.0, atol = 1e-12)
        @test isapprox(apb[6], 4.0, atol = 1e-12)
    end

    # ERFA.pvxpv
    @testset "pvxpv" begin
        a = [[2.0,2.0,3.0];[6.0,0.0,4.0]]
        b = [[1.0,3.0,4.0];[0.0,2.0,8.0]]
        axb = ERFA.pvxpv(a, b)
        @test isapprox(axb[1], -1.0, atol = 1e-12)
        @test isapprox(axb[2], -5.0, atol = 1e-12)
        @test isapprox(axb[3], 4.0, atol = 1e-12)
        @test isapprox(axb[4], -2.0, atol = 1e-12)
        @test isapprox(axb[5], -36.0, atol = 1e-12)
        @test isapprox(axb[6], 22.0, atol = 1e-12)
    end

    # ERFA.pvstar
    @testset "pvstar" begin
        pv = [[126668.5912743160601,2136.792716839935195,-245251.2339876830091];
              [-0.4051854035740712739e-2,-0.6253919754866173866e-2,0.1189353719774107189e-1]]
        ra, dec, pmr, pmd, px, rv = ERFA.pvstar(pv)
        @test isapprox(ra, 0.1686756e-1, atol = 1e-12)
        @test isapprox(dec, -1.093989828, atol = 1e-12)
        @test isapprox(pmr, -0.1783235160000472788e-4, atol = 1e-16)
        @test isapprox(pmd, 0.2336024047000619347e-5, atol = 1e-16)
        @test isapprox(px, 0.74723, atol = 1e-12)
        @test isapprox(rv, -21.60000010107306010, atol = 1e-11)
    end

    # ERFA.pvtob
    @testset "pvtob" begin
        elong = 2.0
        phi = 0.5
        hm = 3000.0
        xp = 1e-6
        yp = -0.5e-6
        sp = 1e-8
        theta = 5.0
        pv = ERFA.pvtob(elong, phi, hm, xp, yp, sp, theta)
        @test isapprox(pv[1], 4225081.367071159207, atol = 1e-5)
        @test isapprox(pv[2], 3681943.215856198144, atol = 1e-5)
        @test isapprox(pv[3], 3041149.399241260785, atol = 1e-5)
        @test isapprox(pv[4], -268.4915389365998787, atol = 1e-9)
        @test isapprox(pv[5], 308.0977983288903123, atol = 1e-9)
        @test isapprox(pv[6], 0, atol = 1e-0)
    end

    # ERFA.pvu
    @testset "pvu" begin
        dt = 2920.0
        pv = [[126668.5912743160734,2136.792716839935565,-245251.2339876830229];
              [-0.4051854035740713039e-2,-0.6253919754866175788e-2,0.1189353719774107615e-1]]
        upv = ERFA.pvu(dt, pv)
        @test isapprox(upv[1], 126656.7598605317105, atol = 1e-12)
        @test isapprox(upv[2], 2118.531271155726332, atol = 1e-12)
        @test isapprox(upv[3], -245216.5048590656190, atol = 1e-12)
        @test isapprox(upv[4], -0.4051854035740713039e-2, atol = 1e-12)
        @test isapprox(upv[5], -0.6253919754866175788e-2, atol = 1e-12)
        @test isapprox(upv[6], 0.1189353719774107615e-1, atol = 1e-12)
    end

    # ERFA.pvup
    @testset "pvup" begin
        dt = 2920.0
        pv = [[126668.5912743160734,2136.792716839935565,-245251.2339876830229];
              [-0.4051854035740713039e-2,-0.6253919754866175788e-2,0.1189353719774107615e-1]]
        p = ERFA.pvup(dt, pv)
        @test isapprox(p[1], 126656.7598605317105, atol = 1e-12)
        @test isapprox(p[2], 2118.531271155726332, atol = 1e-12)
        @test isapprox(p[3], -245216.5048590656190, atol = 1e-12)
    end

    # ERFA.pxp
    @testset "pxp" begin
        axb = ERFA.pxp([2.0,2.0,3.0], [1.0,3.0,4.0])
        @test isapprox(axb[1], -1.0, atol = 1e-12)
        @test isapprox(axb[2], -5.0, atol = 1e-12)
        @test isapprox(axb[3], 4.0, atol = 1e-12)
    end

    # ERFA.refco
    @testset "refco" begin
        phpa = 800.0
        tc = 10.0
        rh = 0.9
        wl = 0.4
        refa, refb = ERFA.refco(phpa, tc, rh, wl)
        @test isapprox(refa, 0.2264949956241415009e-3, atol = 1e-15)
        @test isapprox(refb, -0.2598658261729343970e-6, atol = 1e-18)
    end

    # ERFA.rm2v
    @testset "rm2v" begin
        w = ERFA.rm2v([[0.0,-0.8,-0.6];
                       [0.8,-0.36,0.48];
                       [0.6,0.48,-0.64]])
        @test isapprox(w[1], 0.0, atol = 1e-12)
        @test isapprox(w[2], 1.413716694115406957, atol = 1e-12)
        @test isapprox(w[3], -1.884955592153875943, atol = 1e-12)
    end

    # ERFA.rv2m
    @testset "rv2m" begin
        r = ERFA.rv2m([0.0, 1.41371669, -1.88495559])
        @test isapprox(r[1], -0.7071067782221119905, atol = 1e-14)
        @test isapprox(r[2], -0.5656854276809129651, atol = 1e-14)
        @test isapprox(r[3], -0.4242640700104211225, atol = 1e-14)
        @test isapprox(r[4], 0.5656854276809129651, atol = 1e-14)
        @test isapprox(r[5], -0.0925483394532274246, atol = 1e-14)
        @test isapprox(r[6], -0.8194112531408833269, atol = 1e-14)
        @test isapprox(r[7], 0.4242640700104211225, atol = 1e-14)
        @test isapprox(r[8], -0.8194112531408833269, atol = 1e-14)
        @test isapprox(r[9], 0.3854415612311154341, atol = 1e-14)
    end

    # ERFA.rx
    @testset "rx" begin
        phi = 0.3456789
        r = [[2.0,3.0,2.0];
             [3.0,2.0,3.0];
        [3.0,4.0,5.0]]
        r = ERFA.rx(phi, r)
        @test isapprox(r[1], 2.0, atol = 0.0)
        @test isapprox(r[2], 3.0, atol = 0.0)
        @test isapprox(r[3], 2.0, atol = 0.0)
        @test isapprox(r[4], 3.839043388235612460, atol = 1e-12)
        @test isapprox(r[5], 3.237033249594111899, atol = 1e-12)
        @test isapprox(r[6], 4.516714379005982719, atol = 1e-12)
        @test isapprox(r[7], 1.806030415924501684, atol = 1e-12)
        @test isapprox(r[8], 3.085711545336372503, atol = 1e-12)
        @test isapprox(r[9], 3.687721683977873065, atol = 1e-12)
    end

    # ERFA.rxp
    @testset "rxp" begin
        r = [[2.0,3.0,2.0];
             [3.0,2.0,3.0];
        [3.0,4.0,5.0]]
        p = [0.2,1.5,0.1]
        rp = ERFA.rxp(r, p)
        @test isapprox(rp[1], 5.1, atol = 1e-12)
        @test isapprox(rp[2], 3.9, atol = 1e-12)
        @test isapprox(rp[3], 7.1, atol = 1e-12)
    end

    # ERFA.rxpv
    @testset "rxpv" begin
        r = [[2.0,3.0,2.0];
             [3.0,2.0,3.0];
        [3.0,4.0,5.0]]
        pv = [[0.2,1.5,0.1];
              [1.5,0.2,0.1]]
        rpv = ERFA.rxpv(r, pv)
        @test isapprox(rpv[1], 5.1, atol = 1e-12)
        @test isapprox(rpv[4], 3.8, atol = 1e-12)
        @test isapprox(rpv[2], 3.9, atol = 1e-12)
        @test isapprox(rpv[5], 5.2, atol = 1e-12)
        @test isapprox(rpv[3], 7.1, atol = 1e-12)
        @test isapprox(rpv[6], 5.8, atol = 1e-12)
    end

    # ERFA.rxr
    @testset "rxr" begin
        a = [[2.0,3.0,2.0];
             [3.0,2.0,3.0];
        [3.0,4.0,5.0]]
        b = [[1.0,2.0,2.0];
             [4.0,1.0,1.0];
        [3.0,0.0,1.0]]
        atb = ERFA.rxr(a, b)
        @test isapprox(atb[1], 20.0, atol = 1e-12)
        @test isapprox(atb[2], 7.0, atol = 1e-12)
        @test isapprox(atb[3], 9.0, atol = 1e-12)
        @test isapprox(atb[4], 20.0, atol = 1e-12)
        @test isapprox(atb[5], 8.0, atol = 1e-12)
        @test isapprox(atb[6], 11.0, atol = 1e-12)
        @test isapprox(atb[7], 34.0, atol = 1e-12)
        @test isapprox(atb[8], 10.0, atol = 1e-12)
        @test isapprox(atb[9], 15.0, atol = 1e-12)
    end

    # ERFA.ry
    @testset "ry" begin
        theta = 0.3456789
        r = [[2.0,3.0,2.0];
             [3.0,2.0,3.0];
        [3.0,4.0,5.0]]
        r = ERFA.ry(theta, r)
        @test isapprox(r[1], 0.8651847818978159930, atol = 1e-12)
        @test isapprox(r[2], 1.467194920539316554, atol = 1e-12)
        @test isapprox(r[3], 0.1875137911274457342, atol = 1e-12)
        @test isapprox(r[4], 3, atol = 1e-12)
        @test isapprox(r[5], 2, atol = 1e-12)
        @test isapprox(r[6], 3, atol = 1e-12)
        @test isapprox(r[7], 3.500207892850427330, atol = 1e-12)
        @test isapprox(r[8], 4.779889022262298150, atol = 1e-12)
        @test isapprox(r[9], 5.381899160903798712, atol = 1e-12)
    end

    # ERFA.rz
    @testset "rz" begin
        psi = 0.3456789
        r = [[2.0,3.0,2.0];
             [3.0,2.0,3.0];
        [3.0,4.0,5.0]]
        r = ERFA.rz(psi, r)
        @test isapprox(r[1], 2.898197754208926769, atol = 1e-12)
        @test isapprox(r[2], 3.500207892850427330, atol = 1e-12)
        @test isapprox(r[3], 2.898197754208926769, atol = 1e-12)
        @test isapprox(r[4], 2.144865911309686813, atol = 1e-12)
        @test isapprox(r[5], 0.865184781897815993, atol = 1e-12)
        @test isapprox(r[6], 2.144865911309686813, atol = 1e-12)
        @test isapprox(r[7], 3.0, atol = 1e-12)
        @test isapprox(r[8], 4.0, atol = 1e-12)
        @test isapprox(r[9], 5.0, atol = 1e-12)
    end

    # ERFA.s00
    @testset "s00" begin
        x = 0.5791308486706011000e-3
        y = 0.4020579816732961219e-4
        s = ERFA.s00(2400000.5, 53736.0, x, y)
        @test isapprox(s, -0.1220036263270905693e-7, atol = 1e-18)
    end

    # ERFA.s00a
    @testset "s00a" begin
        s = ERFA.s00a(2400000.5, 52541.0)
        @test isapprox(s, -0.1340684448919163584e-7, atol = 1e-18)
    end

    # ERFA.s00b
    @testset "s00b" begin
        s = ERFA.s00b(2400000.5, 52541.0)
        @test isapprox(s, -0.1340695782951026584e-7, atol = 1e-18)
    end

    # ERFA.s06
    @testset "s06" begin
        x = 0.5791308486706011000e-3
        y = 0.4020579816732961219e-4
        s = ERFA.s06(2400000.5, 53736.0, x, y)
        @test isapprox(s, -0.1220032213076463117e-7, atol = 1e-18)
    end

    # ERFA.s06a
    @testset "s06a" begin
        s = ERFA.s06a(2400000.5, 52541.0)
        @test isapprox(s, -0.1340680437291812383e-7, atol = 1e-18)
    end

    # ERFA.s2c
    @testset "s2c" begin
        c = ERFA.s2c(3.0123, -0.999)
        @test isapprox(c[1], -0.5366267667260523906, atol = 1e-12)
        @test isapprox(c[2], 0.0697711109765145365, atol = 1e-12)
        @test isapprox(c[3], -0.8409302618566214041, atol = 1e-12)
    end

    # ERFA.s2p
    @testset "s2p" begin
        p = ERFA.s2p(-3.21, 0.123, 0.456)
        @test isapprox(p[1], -0.4514964673880165228, atol = 1e-12)
        @test isapprox(p[2], 0.0309339427734258688, atol = 1e-12)
        @test isapprox(p[3], 0.0559466810510877933, atol = 1e-12)
    end

    # ERFA.s2pv
    @testset "s2pv" begin
        pv = ERFA.s2pv(-3.21, 0.123, 0.456, -7.8e-6, 9.01e-6, -1.23e-5)
        @test isapprox(pv[1], -0.4514964673880165228, atol = 1e-12)
        @test isapprox(pv[2], 0.0309339427734258688, atol = 1e-12)
        @test isapprox(pv[3], 0.0559466810510877933, atol = 1e-12)
        @test isapprox(pv[4], 0.1292270850663260170e-4, atol = 1e-16)
        @test isapprox(pv[5], 0.2652814182060691422e-5, atol = 1e-16)
        @test isapprox(pv[6], 0.2568431853930292259e-5, atol = 1e-16)
    end

    # ERFA.s2xpv
    @testset "s2xpv" begin
        s1 = 2.0
        s2 = 3.0
        pv = [[0.3,1.2,-2.5];
              [0.5,2.3,-0.4]]
        spv = ERFA.s2xpv(s1, s2, pv)
        @test isapprox(spv[1], 0.6, atol = 1e-12)
        @test isapprox(spv[2], 2.4, atol = 1e-12)
        @test isapprox(spv[3], -5.0, atol = 1e-12)
        @test isapprox(spv[4], 1.5, atol = 1e-12)
        @test isapprox(spv[5], 6.9, atol = 1e-12)
        @test isapprox(spv[6], -1.2, atol = 1e-12)
    end

    # ERFA.sepp
    @testset "sepp" begin
        a = [1.,0.1,0.2]
        b = [-3.,1e-3,0.2]
        s = ERFA.sepp(a, b)
        @test isapprox(s, 2.860391919024660768, atol = 1e-12)
    end

    # ERFA.seps
    @testset "seps" begin
        s = ERFA.seps(1., .1, .2, -3.)
        @test isapprox(s, 2.346722016996998842, atol = 1e-14)
    end

    # ERFA.sp00
    @testset "sp00" begin
        s = ERFA.sp00(2400000.5, 52541.0)
        @test isapprox(s, -0.6216698469981019309e-11, atol = 1e-12)
    end

    # ERFA.starpm
    @testset "starpm" begin
        ra1 =   0.01686756
        dec1 = -1.093989828
        pmr1 = -1.78323516e-5
        pmd1 =  2.336024047e-6
        px1 =   0.74723
        rv1 = -21.6
        ra2, dec2, pmr2, pmd2, px2, rv2 = ERFA.starpm(ra1, dec1, pmr1, pmd1, px1, rv1,
                                                      2400000.5, 50083.0, 2400000.5, 53736.0)
        @test isapprox(ra2, 0.01668919069414256149, atol = 1e-13)
        @test isapprox(dec2, -1.093966454217127897, atol = 1e-13)
        @test isapprox(pmr2, -0.1783662682153176524e-4, atol = 1e-17)
        @test isapprox(pmd2, 0.2338092915983989595e-5, atol = 1e-17)
        @test isapprox(px2, 0.7473533835317719243, atol = 1e-13)
        @test isapprox(rv2, -21.59905170476417175, atol = 1e-11)
    end

    # ERFA.starpv
    @testset "starpv" begin
        ra =   0.01686756
        dec = -1.093989828
        pmr = -1.78323516e-5
        pmd =  2.336024047e-6
        px =   0.74723
        rv = -21.6
        pv = ERFA.starpv(ra, dec, pmr, pmd, px, rv)
        @test isapprox(pv[1], 126668.5912743160601, atol = 1e-10)
        @test isapprox(pv[2], 2136.792716839935195, atol = 1e-12)
        @test isapprox(pv[3], -245251.2339876830091, atol = 1e-10)
        @test isapprox(pv[4], -0.4051854008955659551e-2, atol = 1e-13)
        @test isapprox(pv[5], -0.6253919754414777970e-2, atol = 1e-15)
        @test isapprox(pv[6], 0.1189353714588109341e-1, atol = 1e-13)
    end

    # ERFA.sxp
    @testset "sxp" begin
        s = 2.0
        p = [0.3,1.2,-2.5]
        sp = ERFA.sxp(s, p)
        @test isapprox(sp[1], 0.6, atol = 0.0)
        @test isapprox(sp[2], 2.4, atol = 0.0)
        @test isapprox(sp[3], -5.0, atol = 0.0)
    end

    # ERFA.sxpv
    @testset "sxpv" begin
        s = 2.0
        pv = [[0.3,1.2,-2.5];[0.5,3.2,-0.7]]
        spv = ERFA.sxpv(s, pv)
        @test isapprox(spv[1], 0.6, atol = 0.0)
        @test isapprox(spv[2], 2.4, atol = 0.0)
        @test isapprox(spv[3], -5.0, atol = 0.0)
        @test isapprox(spv[4], 1.0, atol = 0.0)
        @test isapprox(spv[5], 6.4, atol = 0.0)
        @test isapprox(spv[6], -1.4, atol = 0.0)
    end

    # ERFA.taitt
    @testset "taitt" begin
        t1, t2 = ERFA.taitt(2453750.5, 0.892482639)
        @test isapprox(t1, 2453750.5, atol = 1e-6)
        @test isapprox(t2, 0.892855139, atol = 1e-12)
    end

    # ERFA.taiut1
    @testset "taiut1" begin
        u1, u2 = ERFA.taiut1(2453750.5, 0.892482639, -32.6659)
        @test isapprox(u1, 2453750.5, atol = 1e-6)
        @test isapprox(u2, 0.8921045614537037037, atol = 1e-12)
    end

    # ERFA.taiutc
    @testset "taiutc" begin
        u1, u2 = ERFA.taiutc(2453750.5, 0.892482639)
        @test isapprox(u1, 2453750.5, atol = 1e-6)
        @test isapprox(u2, 0.8921006945555555556, atol = 1e-12)
    end

    # ERFA.tcbtdb
    @testset "tcbtdb" begin
        b1, b2 = ERFA.tcbtdb(2453750.5, 0.893019599)
        @test isapprox(b1, 2453750.5, atol = 1e-6)
        @test isapprox(b2, 0.8928551362746343397, atol = 1e-12)
    end

    # ERFA.tcgtt
    @testset "tcgtt" begin
        t1, t2 = ERFA.tcgtt(2453750.5,  0.892862531)
        @test isapprox(t1, 2453750.5, atol = 1e-6)
        @test isapprox(t2, 0.8928551387488816828, atol = 1e-12)
    end

    # ERFA.tdbtcb
    @testset "tdbtcb" begin
        b1, b2 = ERFA.tdbtcb(2453750.5, 0.892855137)
        @test isapprox(b1, 2453750.5, atol = 1e-6)
        @test isapprox(b2, 0.8930195997253656716, atol = 1e-12)
    end

    # ERFA.tdbtt
    @testset "tdbtt" begin
        t1, t2 = ERFA.tdbtt(2453750.5,  0.892855137, -0.000201)
        @test isapprox(t1, 2453750.5, atol = 1e-6)
        @test isapprox(t2, 0.8928551393263888889, atol = 1e-12)
    end

    # ERFA.tf2a
    @testset "tf2a" begin
        a = ERFA.tf2a('+', 4, 58, 20.2)
        @test isapprox(a, 1.301739278189537429, atol = 1e-12)
    end

    # ERFA.tf2d
    @testset "tf2d" begin
        d = ERFA.tf2d('+', 23, 55, 10.9)
        @test isapprox(d, 0.9966539351851851852, atol = 1e-12)
    end

    # ERFA.tr
    @testset "tr" begin
        r = [[2.0,3.0,2.0];
             [3.0,2.0,3.0];
        [3.0,4.0,5.0]]
        rt = ERFA.tr(r)
        @test isapprox(rt[1], 2.0, atol = 0.0)
        @test isapprox(rt[2], 3.0, atol = 0.0)
        @test isapprox(rt[3], 3.0, atol = 0.0)
        @test isapprox(rt[4], 3.0, atol = 0.0)
        @test isapprox(rt[5], 2.0, atol = 0.0)
        @test isapprox(rt[6], 4.0, atol = 0.0)
        @test isapprox(rt[7], 2.0, atol = 0.0)
        @test isapprox(rt[8], 3.0, atol = 0.0)
        @test isapprox(rt[9], 5.0, atol = 0.0)
    end

    # ERFA.trxp
    @testset "trxp" begin
        r = [[2.0,3.0,2.0];
             [3.0,2.0,3.0];
        [3.0,4.0,5.0]]
        p = [0.2,1.5,0.1]
        trp = ERFA.trxp(r, p)
        @test isapprox(trp[1], 5.2, atol = 1e-12)
        @test isapprox(trp[2], 4.0, atol = 1e-12)
        @test isapprox(trp[3], 5.4, atol = 1e-12)
    end

    # ERFA.trxpv
    @testset "trxpv" begin
        r = [[2.0,3.0,2.0];
             [3.0,2.0,3.0];
        [3.0,4.0,5.0]]
        pv = [[0.2,1.5,0.1];
              [1.5,0.2,0.1]]
        trpv = ERFA.trxpv(r, pv)
        @test isapprox(trpv[1], 5.2, atol = 1e-12)
        @test isapprox(trpv[2], 4.0, atol = 1e-12)
        @test isapprox(trpv[3], 5.4, atol = 1e-12)
        @test isapprox(trpv[4], 3.9, atol = 1e-12)
        @test isapprox(trpv[5], 5.3, atol = 1e-12)
        @test isapprox(trpv[6], 4.1, atol = 1e-12)
    end

    # ERFA.tttai
    @testset "tttai" begin
        t1, t2 = ERFA.tttai(2453750.5, 0.892482639)
        @test isapprox(t1, 2453750.5, atol = 1e-6)
        @test isapprox(t2, 0.892110139, atol = 1e-12)
    end

    # ERFA.tttcg
    @testset "tttcg" begin
        t1, t2 = ERFA.tttcg(2453750.5, 0.892482639)
        @test isapprox(t1, 2453750.5, atol = 1e-6)
        @test isapprox(t2, 0.8924900312508587113, atol = 1e-12)
    end

    # ERFA.tttdb
    @testset "tttdb" begin
        t1, t2 = ERFA.tttdb(2453750.5, 0.892855139, -0.000201)
        @test isapprox(t1, 2453750.5, atol = 1e-6)
        @test isapprox(t2, 0.8928551366736111111, atol = 1e-12)
    end

    # ERFA.ttut1
    @testset "ttut1" begin
        t1, t2 = ERFA.ttut1(2453750.5, 0.892855139, 64.8499)
        @test isapprox(t1, 2453750.5, atol = 1e-6)
        @test isapprox(t2, 0.8921045614537037037, atol = 1e-12)
    end

    # ERFA.ut1tai
    @testset "ut1tai" begin
        a1, a2 = ERFA.ut1tai(2453750.5, 0.892104561, -32.6659)
        @test isapprox(a1, 2453750.5, atol = 1e-6)
        @test isapprox(a2, 0.8924826385462962963, atol = 1e-12)
    end

    # ERFA.ut1tt
    @testset "ut1tt" begin
        a1, a2 = ERFA.ut1tt(2453750.5, 0.892104561, 64.8499)
        @test isapprox(a1, 2453750.5, atol = 1e-6)
        @test isapprox(a2, 0.8928551385462962963, atol = 1e-15)
    end

    # ERFA.ut1utc
    @testset "ut1utc" begin
        a1, a2 = ERFA.ut1utc(2453750.5, 0.892104561, 0.3341)
        @test isapprox(a1, 2453750.5, atol = 1e-6)
        @test isapprox(a2, 0.8921006941018518519, atol = 1e-13)
    end

    # ERFA.utctai
    @testset "utctai" begin
        u1, u2 = ERFA.utctai(2453750.5, 0.892100694)
        @test isapprox(u1, 2453750.5, atol = 1e-6)
        @test isapprox(u2, 0.8924826384444444444, atol = 1e-13)
    end

    # ERFA.utcut1
    @testset "utcut1" begin
        u1, u2 = ERFA.utcut1(2453750.5, 0.892100694, 0.3341)
        @test isapprox(u1, 2453750.5, atol = 1e-6)
        @test isapprox(u2, 0.8921045608981481481, atol = 1e-13)
    end

    # ERFA.xy06
    @testset "xy06" begin
        x, y = ERFA.xy06(2400000.5, 53736.0)
        @test isapprox(x, 0.5791308486706010975e-3, atol = 1e-16)
        @test isapprox(y, 0.4020579816732958141e-4, atol = 1e-17)
    end

    # ERFA.xys00a
    @testset "xys00a" begin
        x, y, s = ERFA.xys00a(2400000.5, 53736.0)
        @test isapprox(x, 0.5791308472168152904e-3, atol = 1e-16)
        @test isapprox(y, 0.4020595661591500259e-4, atol = 3e-17)  # originally eps=1e-17; relaxed for 32-bit windows
        @test isapprox(s, -0.1220040848471549623e-7, atol = 1e-20)
    end

    # ERFA.xys00b
    @testset "xys00b" begin
        x, y, s = ERFA.xys00b(2400000.5, 53736.0)
        @test isapprox(x, 0.5791301929950208873e-3, atol = 1e-16)
        @test isapprox(y, 0.4020553681373720832e-4, atol = 1e-16)
        @test isapprox(s, -0.1220027377285083189e-7, atol = 1e-19)
    end

    # ERFA.xys06a
    @testset "xys06a" begin
        x, y, s = ERFA.xys06a(2400000.5, 53736.0)
        @test isapprox(x, 0.5791308482835292617e-3, atol = 1e-16)
        @test isapprox(y, 0.4020580099454020310e-4, atol = 1e-15)
        @test isapprox(s, -0.1220032294164579896e-7, atol = 1e-19)
    end

    # ERFA.icrs2g
    @testset "icrs2g" begin
        dl, db = ERFA.icrs2g(5.9338074302227188048671087, -1.1784870613579944551540570)
        @test isapprox(dl, 5.5850536063818546461558, atol = 1e-14)
        @test isapprox(db, -0.7853981633974483096157, atol = 1e14)
    end

    # ERFA.g2icrs
    @testset "g2icrs" begin
        dr, dd = ERFA.g2icrs(5.5850536063818546461558105, -0.7853981633974483096156608)
        @test isapprox(dr, 5.9338074302227188048671, atol = 1e-14)
        @test isapprox(dd, -1.1784870613579944551541, atol = 1e14)
    end

    # ERFA.ltp
    @testset "ltp" begin
        rp = ERFA.ltp(1666.666)
        @test isapprox(rp[1], 0.9967044141159213819, atol = 1e-14)
        @test isapprox(rp[2], 0.7437801893193210840e-1, atol = 1e-14)
        @test isapprox(rp[3], 0.3237624409345603401e-1, atol = 1e-14)
        @test isapprox(rp[4], -0.7437802731819618167e-1, atol = 1e-14)
        @test isapprox(rp[5], 0.9972293894454533070, atol = 1e-14)
        @test isapprox(rp[6], -0.1205768842723593346e-2, atol = 1e-14)
        @test isapprox(rp[7], -0.3237622482766575399e-1, atol = 1e-14)
        @test isapprox(rp[8], -0.1206286039697609008e-2, atol = 1e-14)
        @test isapprox(rp[9], 0.9994750246704010914, atol = 1e-14)
    end

    # ERFA.ltpb
    @testset "ltpb" begin
        rp = ERFA.ltpb(1666.666)
        @test isapprox(rp[1], 0.9967044167723271851, atol = 1e-14)
        @test isapprox(rp[2], 0.7437794731203340345e-1, atol = 1e-14)
        @test isapprox(rp[3], 0.3237632684841625547e-1, atol = 1e-14)
        @test isapprox(rp[4], -0.7437795663437177152e-1, atol = 1e-14)
        @test isapprox(rp[5], 0.9972293947500013666, atol = 1e-14)
        @test isapprox(rp[6], -0.1205741865911243235e-2, atol = 1e-14)
        @test isapprox(rp[7], -0.3237630543224664992e-1, atol = 1e-14)
        @test isapprox(rp[8], -0.1206316791076485295e-2, atol = 1e-14)
        @test isapprox(rp[9], 0.9994750220222438819, atol = 1e-14)
    end

    # ERFA.ltpecl
    @testset "ltpecl" begin
        vec = ERFA.ltpecl(-1500.0)
        @test isapprox(vec[1], 0.4768625676477096525e-3, atol = 1e-14)
        @test isapprox(vec[2], -0.4052259533091875112, atol = 1e-14)
        @test isapprox(vec[3], 0.9142164401096448012, atol = 1e-14)
    end

    # ERFA.ltpequ
    @testset "ltpequ" begin
        vec = ERFA.ltpequ(-2500.0)
        @test isapprox(vec[1], -0.3586652560237326659, atol = 1e-14)
        @test isapprox(vec[2], -0.1996978910771128475, atol = 1e-14)
        @test isapprox(vec[3], 0.9118552442250819624, atol = 1e-14)
    end

    # ERFA.eceq06
    @testset "eceq06" begin
        dr, dd = ERFA.eceq06(2456165.5, 0.401182685, 5.1, -0.9)
        @test isapprox(dr, 5.533459733613627767, atol = 1e-14)
        @test isapprox(dd, -1.246542932554480576, atol = 1e-14)
    end

    # ERFA.eqec06
    @testset "eqec06" begin
        dl, db = ERFA.eqec06(1234.5, 2440000.5, 1.234, 0.987)
        @test isapprox(dl, 1.342509918994654619, atol = 1e-14)
        @test isapprox(db, 0.5926215259704608132, atol = 1e-14)
    end

    # ERFA.ecm06
    @testset "ecm06" begin
        rm = ERFA.ecm06(2456165.5, 0.401182685)
        @test isapprox(rm[1], 0.9999952427708701137, atol = 1e-14)
        @test isapprox(rm[2], -0.2829062057663042347e-2, atol = 1e-14)
        @test isapprox(rm[3], -0.1229163741100017629e-2, atol = 1e-14)
        @test isapprox(rm[4], 0.3084546876908653562e-2, atol = 1e-14)
        @test isapprox(rm[5], 0.9174891871550392514, atol = 1e-14)
        @test isapprox(rm[6], 0.3977487611849338124, atol = 1e-14)
        @test isapprox(rm[7], 0.2488512951527405928e-5, atol = 1e-14)
        @test isapprox(rm[8], -0.3977506604161195467, atol = 1e-14)
        @test isapprox(rm[9], 0.9174935488232863071, atol = 1e-14)
    end

    # ERFA.ltecm
    @testset "ltecm" begin
        rm = ERFA.ltecm(-3000.0)
        @test isapprox(rm[1], 0.3564105644859788825, atol = 1e-14)
        @test isapprox(rm[2], 0.8530575738617682284, atol = 1e-14)
        @test isapprox(rm[3], 0.3811355207795060435, atol = 1e-14)
        @test isapprox(rm[4], -0.9343283469640709942, atol = 1e-14)
        @test isapprox(rm[5], 0.3247830597681745976, atol = 1e-14)
        @test isapprox(rm[6], 0.1467872751535940865, atol = 1e-14)
        @test isapprox(rm[7], 0.1431636191201167793e-2, atol = 1e-14)
        @test isapprox(rm[8], -0.4084222566960599342, atol = 1e-14)
        @test isapprox(rm[9], 0.9127919865189030899, atol = 1e-14)
    end

    # ERFA.lteceq
    @testset "lteceq" begin
        dr, dd = ERFA.lteceq(2500.0, 1.5, 0.6)
        @test isapprox(dr, 1.275156021861921167, atol = 1e-14)
        @test isapprox(dd, 0.9966573543519204791, atol = 1e-14)
    end

    # ERFA.lteqec
    @testset "lteqec" begin
        dl, db = ERFA.lteqec(-1500.0, 1.234, 0.987)
        @test isapprox(dl, 0.5039483649047114859, atol = 1e-14)
        @test isapprox(db, 0.5848534459726224882, atol = 1e-14)
    end
end
