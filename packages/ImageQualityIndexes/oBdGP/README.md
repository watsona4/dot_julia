# ImageQualityIndexes

[![Build Status](https://travis-ci.org/JuliaImages/ImageQualityIndexes.jl.svg?branch=master)](https://travis-ci.org/JuliaImages/ImageQualityIndexes.jl)
[![Codecov](https://codecov.io/gh/JuliaImages/ImageQualityIndexes.jl/badge.svg?branch=master)](https://codecov.io/gh/JuliaImages/ImageQualityIndexes.jl)

ImageQualityIndexes provides the basic image quality assessment methods.

## Supported indexes

### Full reference indexes

* `PSNR`/`psnr` -- Peak signal-to-noise ratio
* `SSIM`/`ssim` -- Structural similarity

### No-reference indexes

* `HASLER_AND_SUSSTRUNK_M3`/`hasler_and_susstrunk_m3` -- Colorfulness

## Basic usage

The root type is `ImageQualityIndex`, each concrete index is supposed to be one of `FullReferenceIQI`, `ReducedReferenceIQI` and `NoReferenceIQI`.

There are three ways to assess the image quality:

* use the general protocol, e.g., `assess(PSNR(), x, ref)`. This reads as "**assess** the image quality of **x** using method **PSNR** with information **ref**"
* each index instance is itself a function, e.g., `PSNR()(x, ref)`
* for well-known indexes, there are also convenient name for it for benchmark purpose.

For detailed usage of particular index, please check the docstring (e.g., `?PSNR`)

## Examples

```julia
using Images, TestImages
using ImageQualityIndexes

img = testimage("lena_gray_256") .|> float64
noisy_img = img .+ 0.1 .* randn(size(img))
ssim(noisy_img, img) # 0.3577
psnr(noisy_img, img) # 19.9941

kernel = ones(3, 3)./9 # mean filter
denoised_img = imfilter(noisy_img, kernel)
ssim(denoised_img, img) # 0.6529
psnr(denoised_img, img) # 26.0350

img = testimage("lena_color_256");
colorfulness(img) # 64.1495

```
