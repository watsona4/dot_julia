# bias/unbias
biased_exponent(x::T) where T<:Union{SysFloat, Unsigned} = Int(biased_exponent_field(x))
unbias_exponent(x::T) where T<:Union{SysFloat, Unsigned} = Int(x - exponent_bias(T))
bias_exponent(x::T) where T<:Union{SysFloat, Unsigned} = Int(x + exponent_bias(T))

# fetch the field[s] into the low order bits of an Unsigned

@inline sign_field(x::T) where T<:Unsigned = isolate_sign_field(x) >> sign_field_offset(T)
@inline exponent_field(x::T) where T<:Unsigned = isolate_exponent_field(x) >> exponent_field_offset(T)
@inline significand_field(x::T) where T<:Unsigned = isolate_significand_field(x) >> significand_field_offset(T)
@inline sign_and_exponent_fields(x::T) where T<:Unsigned = isolate_sign_and_exponent_fields(x) >> exponent_field_offset(T)
@inline exponent_and_significand_fields(x::T) where T<:Unsigned = isolate_exponent_and_significand_fields(x) >> significand_field_offset(T)

@inline biased_exponent_field(x::T) where T<:Unsigned = exponent_field(x)
@inline unbiased_exponent_field(x::T) where T<:Unsigned = exponent_field(x) - exponent_bias(T)

for F in (:sign_field, :exponent_field, :significand_field,
          :biased_exponent_field,
          :sign_and_exponent_fields, :exponent_and_significand_fields)
  @eval begin
    @inline $F(x::T) where T<:SysFloat = $F(convert(Unsigned,x))
  end
end

@inline unbiased_exponent_field(x::Float64) = convert(UInt64, exponent_field(x) - exponent_bias(Float64))
@inline unbiased_exponent_field(x::Float32) = convert(UInt32, exponent_field(x) - exponent_bias(Float32))
@inline unbiased_exponent_field(x::Float16) = convert(UInt16, exponent_field(x) - exponent_bias(Float16))


# set field[s]: sign_field(1.0, 1%UInt64) == -1.0

for (F,C,P) in ((:sign_field, :clear_sign_field, :prepare_sign_field),
                (:exponent_field, :clear_exponent_field, :prepare_exponent_field),
                (:significand_field, :clear_significand_field, :prepare_significand_field),
                (:sign_and_exponent_fields, :clear_sign_and_exponent_fields, :prepare_sign_and_exponent_fields),
                (:exponent_and_significand_fields, :clear_exponent_and_significand_fields, :prepare_exponent_and_significand_fields),
                (:biased_exponent_field, :clear_exponent_field, :prepare_exponent_field))
  for (T,U,S) in ((:Float64, :UInt64, :Int64), (:Float32, :UInt32, :Int32), (:Float16, :UInt16, :Int32))
    @eval begin
        @inline $F(x::$T, y::$U) = reinterpret($T, $C(x) | $P(y))
        @inline $F(x::$T, y::U) where U<:Unsigned = convert($T, $C(x) | $P(convert($U, y)))
    end
  end
end

@inline unbiased_exponent_field(x::U, y::U) where U<:Unsigned = clear_exponent_field(x) | prepare_unbiased_exponent_field(y)
@inline unbiased_exponent_field(x::Float64, y::UInt64) = reinterpret(Float64, unbiased_exponent_field(reinterpret(UInt64, x), y))
@inline unbiased_exponent_field(x::Float32, y::UInt32) = reinterpret(Float32, unbiased_exponent_field(reinterpret(UInt32, x), y))
@inline unbiased_exponent_field(x::Float16, y::UInt16) = reinterpret(Float16, unbiased_exponent_field(reinterpret(UInt16, x), y))


# clear the field[s] and yield the value, as Unsigned bits in place

@inline clear_sign_field(x::T) where T<:Unsigned = x & sign_field_filter(T)
@inline clear_exponent_field(x::T) where T<:Unsigned = x & exponent_field_filter(T)
@inline clear_significand_field(x::T) where T<:Unsigned = x & significand_field_filter(T)
@inline clear_sign_and_exponent_fields(x::T) where T<:Unsigned = x & sign_and_exponent_fields_filter(T)
@inline clear_exponent_and_significand_fields(x::T) where T<:Unsigned = x & exponent_and_significand_fields_filter(T)

for F in (:clear_sign_field, :clear_exponent_field, :clear_significand_field,
          :clear_sign_and_exponent_fields, :clear_exponent_and_significand_fields)
  @eval begin
    @inline $F(x::T) where T<:SysFloat = $F(convert(Unsigned,x))
  end
end

# prepare Unsigned low order bits to occupy field[s]

@inline prepare_sign_field(x::T) where T<:Unsigned = (x & sign_field_mask_lsbs(T)) << sign_field_offset(T)
@inline prepare_exponent_field(x::T) where T<:Unsigned = (x & exponent_field_mask_lsbs(T)) << exponent_field_offset(T)
@inline prepare_significand_field(x::T) where T<:Unsigned = (x & significand_field_mask_lsbs(T)) << significand_field_offset(T)
@inline prepare_sign_and_exponent_fields(x::T) where T<:Unsigned = (x & sign_and_exponent_fields_mask_lsbs(T)) << exponent_field_offset(T)
@inline prepare_exponent_and_significand_fields(x::T) where T<:Unsigned = (x & exponent_and_significand_fields_mask_lsbs(T)) << exponent_and_significand_fields_offset(T)
@inline prepare_biased_exponent_field(x::T) where T<:Unsigned = prepare_exponent_field(x)
@inline prepare_unbiased_exponent_field(x::T) where T<:Unsigned = prepare_exponent_field(x + exponent_bias(T))
