# field[s] offset (shift by)

@inline sign_field_offset(::Type{T}) where T<:Unsigned = bitwidth(T) - one(T)
@inline exponent_field_offset(::Type{T}) where T<:Unsigned = sign_field_offset(T) - exponent_bits(T)
@inline significand_field_offset(::Type{T}) where T<:Unsigned = zero(T)
@inline sign_and_exponent_fields_offset(::Type{T}) where T<:Unsigned = exponent_field_offset(T)
@inline exponent_and_significand_fields_offset(::Type{T}) where T<:Unsigned = significand_field_offset(T)
@inline sign_and_significand_fields_offset(::Type{T}) where T<:Unsigned = significand_field_offset(T)

# field[s] filter and mask

@inline sign_field_filter(::Type{T}) where T<:Unsigned = ~(zero(T)) >>> 1
@inline sign_and_exponent_fields_filter(::Type{T}) where T<:Unsigned = ~(zero(T)) >>> (exponent_bits(T) + 1)
@inline exponent_field_filter(::Type{T}) where T<:Unsigned = sign_and_exponent_fields_filter(T) | sign_field_mask(T)
@inline significand_field_filter(::Type{T}) where T<:Unsigned = ~sign_and_exponent_fields_filter(T)
@inline exponent_and_significand_fields_filter(::Type{T}) where T<:Unsigned = ~(sign_field_filter(T))

@inline sign_field_mask(::Type{T}) where T<:Unsigned = ~sign_field_filter(T)
@inline sign_and_exponent_fields_mask(::Type{T}) where T<:Unsigned = ~sign_and_exponent_fields_filter(T)
@inline exponent_field_mask(::Type{T}) where T<:Unsigned = ~exponent_field_filter(T)
@inline significand_field_mask(::Type{T}) where T<:Unsigned = ~sign_and_exponent_fields_mask(T)
@inline exponent_and_significand_fields_mask(::Type{T}) where T<:Unsigned = ~exponent_and_significand_fields_mask(T)

@inline sign_field_mask_lsbs(::Type{T}) where T<:Unsigned = sign_field_mask(T) >> sign_field_offset(T)
@inline exponent_field_mask_lsbs(::Type{T}) where T<:Unsigned = exponent_field_mask(T) >> exponent_field_offset(T)
@inline significand_field_mask_lsbs(::Type{T}) where T<:Unsigned = significand_field_mask(T) >> significand_field_offset(T)
@inline sign_and_exponent_fields_mask_lsbs(::Type{T}) where T<:Unsigned = sign_and_exponent_fields_mask(T) >> exponent_field_offset(T)
@inline exponent_and_significand_fields_mask_lsbs(::Type{T}) where T<:Unsigned = exponent_and_significand_fields_mask(T) >> significand_field_offset(T)

# isolate the field[s] from other bits and yield the field value, as Unsigned bits in place

@inline isolate_sign_field(x::T) where T<:Unsigned = x & sign_field_mask(T)
@inline isolate_exponent_field(x::T) where T<:Unsigned = x & exponent_field_mask(T)
@inline isolate_significand_field(x::T) where T<:Unsigned = x & significand_field_mask(T)
@inline isolate_sign_and_exponent_fields(x::T) where T<:Unsigned = x & sign_and_exponent_field_mask(T)
@inline isolate_exponent_and_significand_fields(x::T) where T<:Unsigned = x & sign_field_filter(T)
@inline isolate_sign_and_significand_fields(x::T) where T<:Unsigned = x & exponent_field_mask(T)
