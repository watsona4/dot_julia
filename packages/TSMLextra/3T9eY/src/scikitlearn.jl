@reexport module SKLearners

export SKLearner,transform!,fit!

using TSML
import TSML.TSMLTypes.fit! # to overload
import TSML.TSMLTypes.transform! # to overload

using PyCall

function initlibs()
  global ENS=pyimport("sklearn.ensemble") 
  global LM=pyimport("sklearn.linear_model")
  global DA=pyimport("sklearn.discriminant_analysis")
  global NN=pyimport("sklearn.neighbors")
  global SVM=pyimport("sklearn.svm")
  global TREE=pyimport("sklearn.tree")
  global ANN=pyimport("sklearn.neural_network")
  global GP=pyimport("sklearn.gaussian_process")
  global KR=pyimport("sklearn.kernel_ridge")
  global NB=pyimport("sklearn.naive_bayes")
  global ISO=pyimport("sklearn.isotonic")

  # Available scikit-learn learners.
  global learner_dict = Dict(
                      "AdaBoostClassifier" => ENS.AdaBoostClassifier,
                      "BaggingClassifier" => ENS.BaggingClassifier,
                      "ExtraTreesClassifier" => ENS.ExtraTreesClassifier,
                      "VotingClassifier" => ENS.VotingClassifier,
                      "GradientBoostingClassifier" => ENS.GradientBoostingClassifier,
                      "RandomForestClassifier" => ENS.RandomForestClassifier,
                      "LDA" => DA.LinearDiscriminantAnalysis,
                      "QDA" => DA.QuadraticDiscriminantAnalysis,
                      "LogisticRegression" => LM.LogisticRegression,
                      "PassiveAggressiveClassifier" => LM.PassiveAggressiveClassifier,
                      "RidgeClassifier" => LM.RidgeClassifier,
                      "RidgeClassifierCV" => LM.RidgeClassifierCV,
                      "SGDClassifier" => LM.SGDClassifier,
                      "KNeighborsClassifier" => NN.KNeighborsClassifier,
                      "RadiusNeighborsClassifier" => NN.RadiusNeighborsClassifier,
                      "NearestCentroid" => NN.NearestCentroid,
                      "SVC" => SVM.SVC,
                      "LinearSVC" => SVM.LinearSVC,
                      "NuSVC" => SVM.NuSVC,
                      "MLPClassifier" => ANN.MLPClassifier,
                      "GaussianProcessClassifier" => GP.GaussianProcessClassifier,
                      "DecisionTreeClassifier" => TREE.DecisionTreeClassifier,
                      "GaussianNB" => NB.GaussianNB,
                      "MultinomialNB" => NB.MultinomialNB,
                      "ComplementNB" => NB.ComplementNB,
                      "BernoulliNB" => NB.BernoulliNB,
                      "SVR" => SVM.SVR,
                      "Ridge" => LM.Ridge,
                      "RidgeCV" => LM.RidgeCV,
                      "Lasso" => LM.Lasso,
                      "ElasticNet" => LM.ElasticNet,
                      "Lars" => LM.Lars,
                      "LassoLars" => LM.LassoLars,
                      "OrthogonalMatchingPursuit" => LM.OrthogonalMatchingPursuit,
                      "BayesianRidge" => LM.BayesianRidge,
                      "ARDRegression" => LM.ARDRegression,
                      "SGDRegressor" => LM.SGDRegressor,
                      "PassiveAggressiveRegressor" => LM.PassiveAggressiveRegressor,
                      "KernelRidge" => KR.KernelRidge,
                      "KNeighborsRegressor" => NN.KNeighborsRegressor,
                      "RadiusNeighborsRegressor" => NN.RadiusNeighborsRegressor,
                      "GaussianProcessRegressor" => GP.GaussianProcessRegressor,
                      "DecisionTreeRegressor" => TREE.DecisionTreeRegressor,
                      "RandomForestRegressor" => ENS.RandomForestRegressor,
                      "ExtraTreesRegressor" => ENS.ExtraTreesRegressor,
                      "AdaBoostRegressor" => ENS.AdaBoostRegressor,
                      "GradientBoostingRegressor" => ENS.GradientBoostingRegressor,
                      "IsotonicRegression" => ISO.IsotonicRegression,
                      "MLPRegressor" => ANN.MLPRegressor
                     )
end

mutable struct SKLearner <: TSLearner
    model
    args

    function SKLearner(args=Dict())
        default_args=Dict(
           :output => :class,
           :learner => "LinearSVC",
           :impl_args => Dict()
        )
        initlibs()
        new(nothing,mergedict(default_args,args))
    end
end

function fit!(skl::SKLearner, x::T, y::Vector) where {T<:Union{Vector,Matrix,DataFrame}}
  impl_args = copy(skl.args[:impl_args])
  learner = skl.args[:learner]
  py_learner = learner_dict[learner]

  # Assign CombineML-specific defaults if required
  if learner == "RadiusNeighborsClassifier"
    if get(impl_args, :outlier_label, nothing) == nothing
      impl_options[:outlier_label] = labels[rand(1:size(labels, 1))]
    end
  end

  # Train
  skl.model = py_learner(;impl_args...)
  #skl.model[:fit](x, y)
  skl.model.fit(x, y)
end

function transform!(skl::SKLearner, x::T) where {T<:Union{Vector,Matrix,DataFrame}}
  #return collect(skl.model[:predict](x))
  return collect(skl.model.predict(x))
end

function skkrun()
    iris=getiris()
    instances=iris[:,1:4] |> Matrix
    labels=iris[:,5] |> Vector
    model1 = SKLearner(Dict(:learner=>"LinearSVC",:impl_args=>Dict(:max_iter=>5000)))
    model2 = SKLearner(Dict(:learner=>"QDA"))
    model3 = SKLearner(Dict(:learner=>"MLPClassifier"))
    model = SKLearner(Dict(:learner=>"BernoulliNB"))
    fit!(model,instances,labels)
    println(sum(transform!(model,instances).==labels)/length(labels)*100)

    x=iris[:,1:3] |> Matrix
    y=iris[:,4] |> Vector
    #regmodel = SKLearner(Dict(:learner => "SVR",:impl_args=>Dict(:gamma=>"scale")))
    #regmodel = SKLearner(Dict(:learner => "RidgeCV"))
    regmodel = SKLearner(Dict(:learner => "GradientBoostingRegressor"))
    #regmodel = SKLearner(Dict(:learner => "MLPRegressor"))
    fit!(regmodel,x,y)
    println(sum(transform!(regmodel,x).-y)/length(labels)*100)
    xx=iris[:,1] |> Vector
    regmodel = SKLearner(Dict(:learner => "IsotonicRegression"))
    fit!(regmodel,xx,y)
    println(sum(transform!(regmodel,xx).-y)/length(labels)*100)
end

end

