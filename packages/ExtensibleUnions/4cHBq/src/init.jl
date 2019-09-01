function __init__()
    global _registry_extensibleunion_to_genericfunctions
    global _registry_extensibleunion_to_members
    global _registry_genericfunctions_to_extensibleunions
    empty!(_registry_extensibleunion_to_genericfunctions)
    empty!(_registry_extensibleunion_to_members)
    empty!(_registry_genericfunctions_to_extensibleunions)
    return nothing
end
