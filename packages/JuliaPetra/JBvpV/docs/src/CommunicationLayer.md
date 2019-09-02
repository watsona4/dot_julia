# Communications Layer

```@meta
CurrentModule = JuliaPetra
```

JuliaPetra abstracts communication with the [`Comm`](@ref) and [`Distributor`](@ref) interfaces.
There are two communication implementations with JuliaPetra [`SerialComm`](@ref) and [`MPIComm`](@ref).
Note that most objects dependent on inter-process communication support the [`getComm`](@ref) method.

## Interface

```@docs
Comm
Distributor
```

### Functions

```@docs
getComm
barrier
broadcastAll
gatherAll
sumAll
maxAll
minAll
scanSum
myPid
numProc
createDistributor
createFromSends
createFromRecvs
resolve
resolvePosts
resolveWaits
resolveReverse
resolveReversePosts
resolveReverseWaits
```

## Implementations

```@docs
LocalComm
SerialComm
SerialDistributor
MPIComm
MPIDistributor
```
