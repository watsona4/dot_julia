module EntityComponentSystem

"""
    ECSComponent

A representation of an entity component system component.
"""
abstract type ECSComponent end

"""
    EntityKey

A generational index to an entity that will fail in usage if the entity has been destroyed.
"""
mutable struct EntityKey
    index::Int64
    generation::Int64
end

"""
    World

A collection of entities and their components.
"""
mutable struct World
    entity_keys::Array{Union{EntityKey,Nothing}}
    max_entity::Int64
    free_entities::Array{Int64,1}
    components::Dict{DataType,Any}
end

"""
    World()

Returns a new World instance with defaults.
"""
function World()
    World(Array{Union{Int64,Nothing}}(undef,100),0,[],Dict())
end

"""
    getentity(world::World,key::EntityKey)

Returns entity index if entity key is still valid.
"""
function getentity(world::World,key::EntityKey)
    entity = world.entity_keys[key.index]
    if entity == nothing || entity.generation != key.generation
        return nothing
    end
    key.index
end

"""
    register!(world::World,::Type{C}) where C <: ECSComponent

Registers storage space for a component type.
"""
function register!(world::World,::Type{C}) where C <: ECSComponent
    world.components[C] = Array{Union{C,Nothing}}(undef,1000)
    nothing
end

"""
    destroyentity!(world::World,entity::EntityKey)

Deallocates entity and memory if entity key is valid.
"""
function destroyentity!(world::World,entity::EntityKey)
    if getentity(world,entity) == nothing
        println("tried to destroy non existant entity")
        return
    end
    for x in keys(world.components)
        world.components[x][entity.index] = nothing
    end
    push!(world.free_entities,entity.index)
    # makes sure entity cant be retrieved again
    world.entity_keys[entity.index] = EntityKey(entity.index,world.entity_keys[entity.index].generation + 1)
    nothing
end

"""
    createentity!(world::World)

Allocates an entity and returns an entity key.
"""
function createentity!(world::World)
    i = if length(world.free_entities) > 0
        # If there's a free entity, use it
        pop!(world.free_entities)
    else
        # Otherwise add a new one
        world.max_entity += 1
    end
    
    entity_key = world.entity_keys[i]
    if entity_key == nothing 
        entity_key = EntityKey(i,1)
        world.entity_keys[i] = entity_key
    else
        world.entity_keys[i] = EntityKey(i,world.entity_keys[i].generation + 1)
    end
    
    # clear out components for the new entity
    for x in keys(world.components)
        componentList = world.components[x]
        if i > length(componentList)
            resize!(componentList,2*length(componentList))
        end
        componentList[i] = nothing
    end
    entity_key
end

"""
    addcomponent!(world::World,entity::EntityKey,component::C) where C <: ECSComponent

Associate a component with an entity key.
"""
function addcomponent!(world::World,entity::EntityKey,component::C) where C <: ECSComponent
    if getentity(world,entity) == nothing
        println("tried to add component to non existant entity")
        return
    end
    world.components[C][entity.index] = component
    nothing
end

"""
    removecomponent!(world::World,entity::EntityKey,::Type{C}) where C <: ECSComponent

Dissociate a component of a specific type with an entity key.
"""
function removecomponent!(world::World,entity::EntityKey,::Type{C}) where C <: ECSComponent
    if getentity(world,entity) == nothing
        println("tried to remove component to non existant entity")
        return
    end
    world.components[C][entity.index] = nothing
    nothing
end

"""
    getcomponent(world::World,entity::EntityKey,::Type{C}) where C <: ECSComponent

Get a component of a specific type of an entity key.
"""
function getcomponent(world::World,entity::EntityKey,::Type{C}) where C <: ECSComponent
    if getentity(world,entity) == nothing
        println("tried to remove component to non existant entity")
        return
    end
    world.components[C][entity.index]
end

"""
    runsystem!(f,world::World,types::Array{DataType,1})

For each entity with components of passed in types, call provided function with that entity and components.
"""
function runsystem!(f,world::World,types::Array{DataType,1})
    num_types = length(types)
    for e = 1:world.max_entity
        components = []
        for t in types
            component_list = world.components[t]
            if e<=length(component_list) && component_list[e] != nothing
                # if we found a component, store it
                push!(components,component_list[e])
            else
                # if we find nothing we can stop right now
                break
            end
        end
        # if entity has all components call function
        if length(components) == num_types
            f(world.entity_keys[e],components)
        end
    end
    nothing
end

export ECSComponent,World,EntityKey,getentity,createentity!,register!,destroyentity!,
runsystem!,addcomponent!,removecomponent!,getcomponent
end
