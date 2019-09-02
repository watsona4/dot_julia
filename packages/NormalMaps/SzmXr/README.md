# NormalsMaps.jl
Package for generating and manipulating normal maps from images, using Julia.

Simple Example
```python
brick = load("brick_input.png")
res   = NormalGen(brick)`
```

Input             |  Output
:-------------------------:|:-------------------------:
![alt text](https://github.com/NTimmons/Normals.jl/blob/master/test/brick_input.png?raw=true)  |  ![alt text](https://github.com/NTimmons/Normals.jl/blob/master/test/brick_output.png?raw=true)

```python
base   = load("normal_base.png")
overlay= load("normal_overlay.png")
res    = BlendNormalsRNM(base,overlay)
```
Base                       |  Overlay                  | Result
:-------------------------:|:-------------------------:|:-------------------------:
![alt text](https://github.com/NTimmons/Normals.jl/blob/master/test/normal_base.png?raw=true)  |  ![alt text](https://github.com/NTimmons/Normals.jl/blob/master/test/normal_overlay.png?raw=true) | ![alt text](https://github.com/NTimmons/Normals.jl/blob/master/test/normal_combined.png?raw=true)
