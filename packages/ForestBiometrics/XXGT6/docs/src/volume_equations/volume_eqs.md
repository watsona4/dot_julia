# Volume Equations
## Calculating the volume of an individual tree

**This functionality is under active development and may change, I haven't fully fleshed out what a Julia-esque volume equations API looks like. Suggestions and issues are welcome.**

ForestBiometrics has functions to calculate log volumes using a variety of scaling rules


## Doyle Rule

      doyle_volume(small end diameter, log length)

calculates the doyle volume

## Scribner

      scribner_volume(small end diameter, log length; decimal_C=false)

calculates the scribner volume calculated using the formula

```math
V = (0.79D^2 - 2D - 4)\frac{L}{16}
```

where V is the Scribner board foot volume, D is the small end diameter in inches and L is the log length in feet.

 `decimal_C=true` will return the board feet in the standard Scribner Decimal C lookup table for trees dib >5" and log lengths <20'. Oversize logs are calculated using the formula above.


## International

      international_volume(small end diameter, log length)

calculates the volume using international rule

## Types

In addition, we introduce two abstract types, `VolumeEquation`, and `MerchSpecs`.

MerchSpecs is a super type to allow for merchandizing specifications to be stored and referenced by product and some common ones have been predefined.

      type Sawtimber<:MerchSpecs
      std_length
      trim
      min_length
      max_length
      min_dib
      end
      Sawtimber(16.0,0.5,8.0,20.0,6.0)


There are also other types including Log and LogSegment where `LogSegment<:Log` .
I have created a few base types based on the possible geometric shapes a log segment can be and use a `volume` equation that dispatches on that type.

    type Cone
    length
    large_end_diam
    end

    type Cylinder
    length
    large_end_diam
    end

    type Paraboloid
    length
    large_end_diam
    end

    type Neiloid
    length
    large_end_diam
    end

    type ParaboloidFrustrum
    length
    large_end_diam
    mid_point_diam #can set to nothing ( or missing in 0.7.0+?)
    small_end_diam
    end

some shapes have additonal kwargs to modify the formula used such as:

    function volume(solid::ParaboloidFrustrum; huber=false, newton = false)
    function volume(solid::ConeFrustrum; newton=false)`

where `huber = true` uses the form ``V=A_mL`` and `newton=true` uses the form ``V=L/6(A_l + 4A_m + A_s)`` otherwise smalian's form ``V=L/2(A_l + A_s)``  is used for ParaboloidFrustrum and ``V=L/3(A_l + \sqrt{A_l*A_s} + A_s`` for ConeFrustrum.






    type ConeFrustrum
    length
    large_end_diam
    mid_point_diam #can set to nothing
    small_end_diam
    end

    type NeiloidFrustrum
    length
    large_end_diam
    mid_point_diam #can set to nothing
    small_end_diam
    end


`area()` is a helper function to convert between diameter and area using the exported constant `K`
