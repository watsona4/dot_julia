# RemoteSemaphores

[![Build Status](https://travis-ci.com/invenia/RemoteSemaphores.jl.svg?branch=master)](https://travis-ci.com/invenia/RemoteSemaphores.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/invenia/RemoteSemaphores.jl?svg=true)](https://ci.appveyor.com/project/invenia/RemoteSemaphores-jl)
[![CodeCov](https://codecov.io/gh/invenia/RemoteSemaphores.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/invenia/RemoteSemaphores.jl)

## Documentation

```julia
RemoteSemaphore(n::Int, pid=myid())
```

A `RemoteSemaphore` is a [counting semaphore](https://www.quora.com/What-is-a-counting-semaphore) that lives on a particular process in order to control access to a resource from multiple processes.
It is implemented using the unexported `Base.Semaphore` stored inside a `Future` which is only accessed on the process it was initialized on.
Like `Base.Semaphore`, it implements `acquire` and `release`, and is not thread-safe.
