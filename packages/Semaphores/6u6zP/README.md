# Semaphores

[![Build Status](https://travis-ci.org/tanmaykm/Semaphores.jl.svg?branch=master)](https://travis-ci.org/tanmaykm/Semaphores.jl)
[![Coverage Status](https://coveralls.io/repos/tanmaykm/Semaphores.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/tanmaykm/Semaphores.jl?branch=master)

Semaphores for inter process locking and resource counting. POSIX named semaphores and SysV semaphores are supported. Tested on Linux and MacOS.

## Posix Named Semaphores

### Creation and deletion
```
# create a semaphore (or attach to an existing one)
sem = NamedSemaphore("/testsem") 

# close / detach
close(sem)

# delete
delete!(sem)

# create (exclusive)
sem = NamedSemaphore("/testsem", true, true)
```

### Operations
```
# get current value (Not supported on OSX)
count(sem)

# lock / decrement value / reserve resource (blocking call)
lock(sem)
@test count(sem) == 0

# try to lock / decrement / reserve (non blocking, returns true on success)
trylock(sem)

# unlock / increment value / return resource (blocking call)
unlock(sem)
```

## SysV Semaphores

### Creation and deletion
```
# create an array of 2 semaphores
tok = Semaphores.ftok(pwd(), 0)
sem = Semaphores.semcreate(tok, 2)

# delete
Semaphores.semrm(sem)
```

### Operations
```
# set values of semaphores
a = Cushort[0,0]
Semaphores.semset(sem, a)
Semaphores.semget(sem, a)
@test sum(a) == 0

# atomic operations on semaphore sets
o = [Semaphores.SemBuf(0,1),Semaphores.SemBuf(1,1)]
Semaphores.semop(sem, o)
```

## Resource Counter (based on SysV Semaphores)

### Counting single resources
```
# create a resoruce counter for a single resource
rescounter = ResourceCounter(pwd())

# set counter value
reset(rescounter, 1)
@test count(rescounter,0) == 1

# change value by amount
change(rescounter, 2)
@test count(rescounter,0) == 3
```

### Counting multiple resources
```
# create a resource counter for 2 resources
rescounter = ResourceCounter((pwd(),2), 2)

# set counter values
reset(rescounter, [1,2])
@test count(rescounter,0) == 1
@test count(rescounter,1) == 2

# change values by amount
change(rescounter, -1, 0)
@test count(rescounter,0) == 0
@test count(rescounter,1) == 2
```
