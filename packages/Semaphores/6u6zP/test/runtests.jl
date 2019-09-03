using Semaphores
using Test

function test_named_semaphore()
    @info("testing posix named semaphores")
    sem = NamedSemaphore("/testsem")
    close(sem)
    delete!(sem)
    sem = NamedSemaphore("/testsem", true, true)

    Sys.isapple() || (@test count(sem) == 1)

    lock(sem)
    Sys.isapple() || (@test count(sem) == 0)
    @test !trylock(sem)
    unlock(sem)
    Sys.isapple() || (@test count(sem) == 1)
    @test trylock(sem)
    Sys.isapple() || (@test count(sem) == 0)

    N = 10
    for idx in 1:N
        unlock(sem)
    end
    Sys.isapple() || (@test count(sem) == N)
    for idx in 1:N
        lock(sem)
    end
    Sys.isapple() || (@test count(sem) == 0)

    close(sem)
    delete!(sem)
end

function test_sysv_semaphore()
    @info("testing system v semaphores")
    tok = Semaphores.ftok(pwd(), 0)
    sem = Semaphores.semcreate(tok, 2)
    @test sem >= 0
    try
        @test 0 == Semaphores.semget(sem)

        a = Cushort[0,0]
        Semaphores.semset(sem, a)
        Semaphores.semget(sem, a)
        @test sum(a) == 0

        Semaphores.semset(sem, Cint(10))
        Semaphores.semset(sem, Cint(5), 1)
        Semaphores.semget(sem, a)
        @test a[1] == 10
        @test a[2] == 5

        a = Cushort[5,10]
        Semaphores.semset(sem, a)
        a = Cushort[0,0]
        Semaphores.semget(sem, a)
        @test a == Cushort[5,10]

        o = [Semaphores.SemBuf(0,1),Semaphores.SemBuf(1,1)]
        Semaphores.semop(sem, o)
        a = Cushort[0,0]
        Semaphores.semget(sem, a)
        @test a == Cushort[6,11]

        o = [Semaphores.SemBuf(0,-1),Semaphores.SemBuf(1,1)]
        Semaphores.semop(sem, o)
        a = Cushort[0,0]
        Semaphores.semget(sem, a)
        @test a == Cushort[5,12]
    finally
        Semaphores.semrm(sem)
    end
end

function test_resource_counter()
    @info("testing single resource counter")
    rescounter = ResourceCounter(pwd())
    try
        reset(rescounter, 1)
        @test count(rescounter,0) == 1
        reset(rescounter, [2])
        @test count(rescounter) == [2]
        change(rescounter, -1)
        @test count(rescounter,0) == 1
        change(rescounter, 2)
        @test count(rescounter) == [3]
        close(rescounter)
    finally
        delete!(rescounter)
    end

    @info("testing multiple resource counter")
    rescounter = ResourceCounter((pwd(),2), 2)
    try
        reset(rescounter, [1,2])
        @test count(rescounter,0) == 1
        @test count(rescounter,1) == 2
        reset(rescounter, [2,3])
        @test count(rescounter) == [2,3]
        change(rescounter, -1, 0)
        @test count(rescounter,0) == 1
        @test count(rescounter,1) == 3
        change(rescounter, 2, 1)
        @test count(rescounter) == [1,5]
        change(rescounter, [SemBuf(0,1),SemBuf(1,-3)])
        @test count(rescounter) == [2,2]
        close(rescounter)
    finally
        delete!(rescounter)
    end
end

test_named_semaphore()
test_sysv_semaphore()
test_resource_counter()
