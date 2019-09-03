@reexport module CaretLearners

export CaretLearner,fit!,transform!

using TSML

import TSML.TSMLTypes.fit!   # importing to overload
import TSML.TSMLTypes.transform! # importing to overload

using RCall

function initlibs()
    #packages = ["caret","e1071","gam","randomForest","nnet","kernlab","grid","MASS","pls"]
    packages = ["caret","randomForest"]
    for pk in packages
        rcall(:library,pk,"lib=.libPaths()")
    end
end

mutable struct CaretLearner <: TSLearner
    model
    args

    function CaretLearner(args=Dict())
        #fitControl=:(R"trainControl(method = 'repeatedcv',number = 5)")
        fitControl="trainControl(method = 'none')"
        default_args = Dict(
            :output => :class,
            :learner => "rf",
            :fitControl=>fitControl,
            :impl_args => Dict()
        )
        initlibs()
        new(nothing,mergedict(default_args,args))
    end
end

function fit!(crt::CaretLearner,x::T,y::Vector) where  {T<:Union{Vector,Matrix,DataFrame}}
    xx = x |> DataFrame
    yy = y |> Vector
    rres = rcall(:train,xx,yy,method=crt.args[:learner],trControl = reval(crt.args[:fitControl]))
    #crt.model = R"$rres$finalModel"
    crt.model = rres
end

function transform!(crt::CaretLearner,x::T) where  {T<:Union{Vector,Matrix,DataFrame}}
    xx = x |> DataFrame
    res = rcall(:predict,crt.model,xx) #in robj
    return rcopy(res) # return extracted robj
end

function caretrun()
    crt = CaretLearner(Dict(:learner=>"rf") )
    iris=getiris()
    x=iris[:,1:4]  |> Matrix
    y=iris[:,5] |> Vector
    fit!(crt,x,y)
    print(crt.model)
    transform!(crt,x) |> collect
end

end
