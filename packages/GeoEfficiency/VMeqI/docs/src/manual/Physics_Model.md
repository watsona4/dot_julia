# Physics Model
Geometrical efficiency of radioactive source measurement is a type of detection efficiency. A fully describe a radioactive source measurement at the most basic level three component should be provided. 
*  radioactive detector description
*  radiation source description 
*  relative position of the source to detector.
this section will discus how to instruct the program to construct each of the aforementioned component.

# Detector
Currently, only cylindrical-like types of detectors are supported.  

## Cylindrical Detector

```@docs
GeoEfficiency.CylDetector
```

```@docs
GeoEfficiency.CylDetector(CryRadius::Real)
```

```@docs
GeoEfficiency.CylDetector()
```
!!!  note
    the positon of the source is reported relative to the detector anchoring point, 
    for a cylinder detector it is taking as a point in the plain surface nearest to the source 
    which lies on the detector axis of symmetry.

## Bore-hole Detector

```@docs
GeoEfficiency.BoreDetector
```

```@docs
GeoEfficiency.BoreDetector()
```

!!! note
    the positon of the source is reported relative to the detector anchoring point, 
    for a bore-hole detector it is taking as the middle point of its axis of symmetry.


## Well-type Detector

```@docs
GeoEfficiency.WellDetector
```

```@docs
GeoEfficiency.WellDetector()
```
!!! note
    the positon of the source is reported relative to the detector anchoring point, 
    for well-type detector it is taking as the point detector hole surface that 
    lies on the detector axis of symmetry.

# Source

```@docs
GeoEfficiency.source
```

# Source Anchoring Point

```@docs
GeoEfficiency.Point
```


```@docs
GeoEfficiency.Point(Height::Real)
```

```@docs
GeoEfficiency.Point()
GeoEfficiency.Point(xHeight::Real, aPnt::Point)
```

```@docs
GeoEfficiency.Point(aPnt::Point, xRho::Real)
```
