# GeoEfficiency Package Release Notes

### Version 0.9.3
*  a customized error system has been add to the package.
*  the unexported function `getfloat` now accepts two more KW arguments, `lower=true` and `upper=false` to encloud the lower and upper limits.
*  the unexported function `getfloat` now throw an error 'ArgumentError' for invalid acceptance interval. this will impact almost all input-from-the-console dependent functions. 

### Version 0.9.2
*  the unexported function `getfloat` change behavior to by default accept all numerical value not just the positive.

### Version 0.9.1
 *  use of `Point` in place of `setRHo!` and `SetHight!`, so now the behavior of both is exported.
 *  fix an error in `source` in this release make it consider all sources as point-source.
 *  remove the function `CONFIG`.
 *  new convert definition allow `Vector{RadiationDetector}` to convert any array of type `Vector{<:RadiationDetector}`.
 *  now `getDetectors` methods can accept a `detectors_array::Vector{<:RadiationDetector}` as input to append new detector to it. It return a sorted array of all the detectors. 
 *  now `batch` methods return an array of paths where results are stored. 
 *  now `batch` methods when encounter an error in calculation assume `NaN` value and proceeds to the next calculation.
 *  new `@enum SrcType` where add to describe the source type
	  -  srcUnknown = -1, 
	  -  srcPoint = 0, 
	  -  srcLine = 1, 
	  -  srcDisk = 2, 
	  -  srcVolume = 3, 
	  -  srcNotPoint = 4.
  
 *  new `typeofSrc()` method to return the current source type. 
 *  new `typeofSrc(::Int)` method to convert `Int` and modify the current source type. 
 *  now `setSrcToPoint()` only return whether the source type is point or not.
 *  `setSrcToPoint(false)` set the source to `srcNotPoint`. the source type is leaved as it if  it were `srcLine`, `srcDisk`, or `srcVolume`.

 
### Version 0.9.0
 *  now the function `calcN` will not terminate when a calculation error happened.
 *  create the special function `CONFIG` to configure the package.
 *  label the function `CONFIG` as experimental and should not used interactively.
 *  unexport the function `CONFIG`. 
 *  support for julia 0.4 and julia 0.5 dropped.
 
 
### Version 0.8.7
 *  new function `about()` give information about the software Package.
 *  new function `SetSrcToPoint()` to set source type.
 *  function `source()`, now did not take keyword argument instead it depend on the global variable `isPoint`. 
 *  function `source()`, now can take a point as its anchor point and if missing ask for one from the console.
 *  `RadiationDetector()` is unexported now. still `Detector()` is available. 


### Version 0.8.6
 *  When `batch` taking arguments, all the arrays `srcHeights_array`, `srcRhos_array`, `srcRadii_array`, `srcLengths_array` element type should be float64. If any of them have Real element type it should be converted to `float64` using `float` before passing it to the `batch` function.

### Version 0.8.5
 *  `Detector()` can be used to construct a new detector.
