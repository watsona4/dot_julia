# jInv Documentation

The documentation of jInv is hosted on readthedocs. To create the documentation we use [```Documenter.jl```](https://juliadocs.github.io/Documenter.jl). Using Travis the documentation is updated with each commit to the main branch. 

## Ways to contribute

Your help is definitely appreciated. There are two ways to contribute to the documentation:

1. Help make sure that the docstrings in the code are updated. They are used to generate the documentation and are also available in your Julia session. Methods should describe their inputs and outputs as well as describe clearly what they are doing. Also there should be some info if input arguments are changed on the fly.
1. To edit the overall description in the documentation, edit the Markdown (*.md) files in the src folder. Here, also images can be provided. To learn more about this, look at the online description of ```Documenter.jl```.