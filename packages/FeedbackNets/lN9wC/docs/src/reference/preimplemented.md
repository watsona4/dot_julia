# Preimplemented Models

```@docs
ModelFactory
```

## LeNet5

```@docs
LeNet5
```

`ModelFactory.jl` contains a modified version of the LeNet5 architecture from

    LeCun, Bottou, Bengio & Haffner (1998),
    Gradient-based learning applied to document recognition.
    Procedings of the IEEE 86(11), 2278-2324.

as well as a version with feedback connections.

```@docs
lenet5
```

```@docs
lenet5_fb
```

In addition, there is a wrapper to more easily generate a Flux.Recur for the
feedback model.

```@docs
wrapfb_lenet5
```

## Networks by Spoerer et al.

```@docs
Spoerer2017
```

The paper contains six network architectures:

```@docs
spoerer_model_b
```

```@docs
spoerer_model_bk
```

```@docs
spoerer_model_bf
```

```@docs
spoerer_model_bl
```

```@docs
spoerer_model_bt
```

```@docs
spoerer_model_blt
```

The first three architectures (B, BK, BF) are feedforward and are internally
implemented with one function:

```@docs
ModelFactory.Spoerer2017.spoerer_model_fw
```
