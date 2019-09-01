# API

```@docs
World
```
```@docs
ECSComponent
```
```@docs
EntityKey
```
```@docs
register!(world::World,::Type{C}) where C <: ECSComponent
```
```@docs
createentity!(world::World)
```
```@docs
getentity(world::World,key::EntityKey)
```
```@docs
destroyentity!(world::World,entity::EntityKey)
```
```@docs
addcomponent!(world::World,entity::EntityKey,component::C) where C <: ECSComponent
```
```@docs
removecomponent!(world::World,entity::EntityKey,::Type{C}) where C <: ECSComponent
```
```@docs
getcomponent(world::World,entity::EntityKey,::Type{C}) where C <: ECSComponent
```
```@docs
runsystem!(f,world::World,types::Array{DataType,1})
```
