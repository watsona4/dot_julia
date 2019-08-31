
# This test is derived from test cmcompute_naifid.c in Calceph version 2.3.2
# the test data files are copied from calceph-2.3.2.tar.gz
function testFunction2(testFile,testFile2,ephFiles,pflag)

    eph = Ephem(ephFiles)
    if pflag
        prefetch(eph)
    end

    con = constants(eph)
    AU = con[:AU]

    f = open(testFile);
    f2 = open(testFile2);
    for (ln,ln2) in zip(eachline(f),eachline(f2))
        elts=split(ln)
        elts2=split(ln2)
        jd0=parse(Float64,elts[1])
        @test parse(Float64,elts2[1]) == jd0
        target=parse(Int,elts2[2])
        center=parse(Int,elts2[3])
        targetold=parse(Int,elts[2])
        centerold=parse(Int,elts[3])
        dt = jd0 - trunc(Int,jd0)
        jd0 = trunc(Int,jd0) + 2.4515450000000000000E+06
        ref = [parse(Float64, x) for x in elts[4:end]]
        @test [parse(Float64, x) for x in elts2[4:end]] == ref

        if (target != naifId.id[:ttmtdb] && target != 15)
            for (unitold,ϵ) in [ (unitAU+unitDay,0.0),
                                 (unitKM+unitDay,0.0),
                                 (unitAU+unitSec,0.0),
                                 (unitKM+unitSec,0.0)]
               unit = unitold + useNaifId
               val = compute(eph, jd0, dt, target, center, unit)
               ref = compute(eph, jd0, dt, targetold, centerold, unitold)
               [(@test ref[i] ≈ val[i] atol=ϵ) for i in 1:6]
           end
       elseif (target == 15)
            targetN = 301
            for (unitold,ϵ) in [ (unitRad+unitDay,0.0),
                                 (unitRad+unitSec,0.0)]
               unit = unitold + useNaifId
               val = orient(eph, jd0, dt, targetN, unit)
               ref = compute(eph, jd0, dt, targetold, centerold, unitold)
               [(@test ref[i] ≈ val[i] atol=ϵ) for i in 1:6]
               val2 = orient(eph, jd0, dt, targetN, unit,3)
               @test length(val2) == 12
               [(@test val2[i] ≈ val[i] atol=ϵ) for i in 1:6]
           end
       elseif (target == naifId.id[:ttmtdb])
           for (unitold,ϵ) in [ (unitDay,0.0),
                                (unitSec,0.0)]
               unit = unitold + useNaifId
               val = compute(eph, jd0, dt, target, center, unit)
               ref = compute(eph, jd0, dt, targetold, centerold, unitold)
               @test ref[1] ≈ val[1] atol=ϵ
           end
       end

    end
    close(f)
    close(f2)
end
