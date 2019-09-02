# Problem Distribution Layer

```@meta
CurrentModule = JuliaPetra
```

The Problem Distribution Layer managers how the problem is distributed across processes.
The main type is [`BlockMap`](@ref) which represents a problem distribution.

## BlockMap

```@docs
BlockMap
lid
gid
myLID
myGID
remoteIDList
minAllGID
maxAllGID
minMyGID
maxMyGID
minLID
maxLID
numGlobalElements
numMyElements
myGlobalElements
myGlobalElementIDs
uniqueGIDs
sameBlockMapDataAs
sameAs
globalIndicesType
linearMap
distributedGlobal
```

## Directory

```@docs
Directory
BasicDirectory
getDirectoryEntries
gidsAllUniquelyOwned
createDirectory
```

## Converting IDs Between Maps

```@docs
Export
Import
sourceMap
targetMap
distributor
isLocallyComplete
permuteToLIDs
permuteFromLIDs
exportLIDs
remoteLIDs
remotePIDs
numSameIDs
```

## Converting Data Structures Between Maps

Converting data structures between maps is built on the [`DistObject`](@ref) and [`SrcDistObject`](@ref) interfaces.

```@docs
DistObject
SrcDistObject
CombineMode
getMap
checkSizes
copyAndPermute
packAndPrepare
unpackAndCombine
```
