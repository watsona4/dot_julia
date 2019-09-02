"""
    GrB_Descriptor_new(desc)

Initialize a descriptor with default field values.
"""
GrB_Descriptor_new(desc::Abstract_GrB_Descriptor) = _NI("GrB_Descriptor_new")

"""
    GrB_Descriptor_set(desc, field, val)

Set the content for a field for an existing descriptor.
"""
GrB_Descriptor_set(desc::Abstract_GrB_Descriptor, field::GrB_Desc_Field, val::GrB_Desc_Value) = _NI("GrB_Descriptor_set")
