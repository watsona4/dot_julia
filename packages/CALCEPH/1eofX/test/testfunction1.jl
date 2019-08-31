
# This test is derived from test cmcompute.c in Calceph version 2.3.2
# the test data files are copied from calceph-2.3.2.tar.gz
function testFunction1(testFile,ephFiles,pflag)

    eph = Ephem(ephFiles)
    if pflag
        prefetch(eph)
    end

    con = constants(eph)
    AU = con[:AU]

    f = open(testFile);
    for ln in eachline(f)
        elts=split(ln)
        jd0=parse(Float64,elts[1])
        target=parse(Int,elts[2])
        center=parse(Int,elts[3])
        dt = jd0 - trunc(Int,jd0);
        jd0 = trunc(Int,jd0) + 2.4515450000000000000E+06
        ref = [parse(Float64, x) for x in elts[4:end]]
        val = compute(eph,jd0,dt,target,center)

        ϵ = 1.0e-8
        val0 = val[:]
        if (target==15)
            ϵ = 1.0e-7
            while val[3]>2π
                val[3]-=2π
            end
            while val[3]<=0
                val[3]+=2π
            end
        end
        for i in 1:6
            @test abs(ref[i]-val[i]) < ϵ
        end
        ref = val0
        ϵ = 3.0e-15
        if target ∉ [15,16,17]
            val = compute(eph,jd0,dt,target,center,unitAU+unitDay)
            for i in 1:6
                @test abs(ref[i]-val[i]) < ϵ
            end
            val = compute(eph,jd0,dt,target,center,unitAU+unitSec)
            for i in 1:6
                if i>3
                    val[i]*=86400
                end
                @test abs(ref[i]-val[i]) < ϵ
            end
            ϵ = 3.0e-14;
            val = compute(eph,jd0,dt,target,center,unitKM+unitDay)
            for i in 1:6
                @test abs(ref[i]-val[i]/AU) < ϵ
            end

            val = compute(eph,jd0,dt,target,center,unitKM+unitSec)
            for i in 1:6
                if i>3
                    val[i]*=86400
                end
                @test abs(ref[i]-val[i]/AU) < ϵ
            end

            ϵ = 3.0e-15
            val = compute(eph,jd0,dt,target,center,unitDay+unitAU,3)
            @test length(val)==12
            for i in 1:6
                @test abs(ref[i]-val[i]) < ϵ
            end

            ref = val
            val = compute(eph,jd0,dt,target,center,unitDay+unitAU,2)
            @test length(val)==9
            for i in 1:9
                @test abs(ref[i]-val[i]) < ϵ
            end
            val = compute(eph,jd0,dt,target,center,unitDay+unitAU,1)
            @test length(val)==6
            for i in 1:6
                @test abs(ref[i]-val[i]) < ϵ
            end
            val = compute(eph,jd0,dt,target,center,unitDay+unitAU,0)
            @test length(val)==3
            for i in 1:3
                @test abs(ref[i]-val[i]) < ϵ
            end

            ϵ = 3.0e-14
            val = compute(eph,jd0,dt,target,center,unitSec+unitKM,3)
            @test length(val)==12
            for i in 1:12
                if i>3
                    val[i]*=86400
                end
                if i>6
                    val[i]*=86400
                end
                if i>9
                    val[i]*=86400
                end
                @test abs(ref[i]-val[i]/AU) < ϵ
            end



        elseif target == 15
            val = compute(eph,jd0,dt,target,center,unitRad+unitDay)
            for i in 1:6
                @test abs(ref[i]-val[i]) < ϵ
            end
            val = compute(eph,jd0,dt,target,center,unitRad+unitSec)
            for i in 1:6
                if i>3
                    val[i]*=86400
                end
                @test abs(ref[i]-val[i]) < ϵ
            end
        elseif target ∈ [16,17]
            ϵ = 1e-18
            val = compute(eph,jd0,dt,target,center,unitSec)
            @test abs(ref[1]-val[1]) < ϵ
            val = compute(eph,jd0,dt,target,center,unitDay)
            @test abs(ref[1]-val[1]*86400) < ϵ*86400
        end

    end
    close(f)



end
