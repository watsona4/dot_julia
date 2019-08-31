## IEEE Standard 754-2008, and the 754-2018 revision

![Standard Float64 bitfields](https://github.com/JeffreySarnoff/BitsFields.jl/blob/master/docs/assets/IEEE754/figure3_1.png)


### the representation
> 2.1.26 floating-point representation: An unencoded member of a floating-point format, representing a
finite number, a signed infinity, a quiet NaN, or a signaling NaN. A representation of a finite number has
three components: a sign, an exponent, and a significand; its numerical value is the signed product of its
significand and its radix raised to the power of its exponent.

![Standard Floating Point Specifications](https://github.com/JeffreySarnoff/BitsFields.jl/blob/master/docs/assets/IEEE754/table3.2.png)


This view of the significand as an integer c, with its corresponding exponent q, describes exactly the same
set of zero and non-zero floating-point numbers as the view in scientific form. [&sect;3.3]

### the sign
> 

### the significand
> 2.1.49 significand: A component of a finite floating-point number containing its significant digits. The
significand can be thought of as an integer, a fraction, or some other fixed-point form, by choosing an
appropriate exponent offset. A decimal or subnormal binary significand can also contain leading zeros.

### the exponent
> 2.1.19 exponent: The component of a finite floating-point representation that signifies the integer power to
which the radix is raised in determining the value of that floating-point representation. The exponent e is
used when the significand is regarded as an integer digit and fraction field, and the exponent q is used when
the significand is regarded as an integer; e = q + p − 1 where p is the precision of the format in digits.


