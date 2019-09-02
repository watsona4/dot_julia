### Dev Build Instructions

ITK.jl makes use of a shared library (.so) and header file based from ITK.

If you want to install the base ITK C++ library, see [here](https://itk.org/Wiki/Getting_Started_Build/Linux).

Once ITK is build and you have written a C++ file, you can build a shared library to load with the CMakeLists.txt configuration below. 

```
cmake_minimum_required(VERSION 2.8)

project(ITKLib)

set(USE_ITK_MODULES ITKCommon ITKIOImageBase ITKOptimizers ITKRegistrationCommon ITKTransform ITKImageIO )

# Find ITK.
find_package(ITK COMPONENTS ${USE_ITK_MODULES})
include(${ITK_USE_FILE})

# Replace with desired library name and your own C++ file name
add_library(itk SHARED JuliaCxx.cxx)
target_link_libraries(itk ${ITK_LIBRARIES})
```

Once you have built your shared library file, you can load it into Julia as done in the function 'loadcxx' in src/ITK.jl.