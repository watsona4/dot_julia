*(adapted from the [scikit-learn docs](http://scikit-learn.org/stable/developers/contributing.html#apis-of-scikit-learn-objects))*

# APIs of scikit-learn objects

To have a uniform API, we try to have a common basic API for all the
objects. In addition, to avoid the proliferation of framework code, we try to
adopt simple conventions and limit to a minimum the number of methods an object
must implement.

## Different objects

The main objects in ScikitLearn.jl are (one type usually implements multiple
interfaces):

Interface | Description
---- | ----
Estimator | The base object, implements a fit method to learn from data, either `estimator = fit!(obj, data, targets)` or `estimator = fit!(obj, data)`
Predictor | For supervised learning, or some unsupervised problems, implements `prediction = predict(obj, data)`. Classification algorithms usually also offer a way to quantify certainty of a prediction, either using `decision_function` or `predict_proba`: `probability = predict_proba(obj, data)`
Transformer | For filtering or modifying the data, in a supervised or unsupervised way, implements: `new_data = transform(obj, data)`. When fitting and transforming can be performed much more efficiently together than separately, implements: `new_data = fit_transform!(obj, data)`
Model | A model that can give a goodness of fit measure or a likelihood of unseen data, implements (higher is better): `score = score(obj, data)`

## Estimators

The API has one predominant object: the estimator. A estimator is an object that fits a model based on some training data and is capable of inferring some properties on new data. It can be, for instance, a classifier or a regressor. All estimators implement the fit method:

```julia
fit!(estimator, X, y)
```

All built-in estimators also have a `set_params!` method, which sets data-independent parameters (overriding previous parameter values passed to the constructor).

#### Instantiation

This concerns the creation of an object. The object’s constructor might accept constants as arguments that determine the estimator’s behavior (like the C constant in SVMs). It should not, however, take the actual training data as an argument, as this is left to the `fit!()` method:

```julia
clf2 = SVC(C=2.3)
clf3 = SVC([[1, 2], [2, 3]], [-1, 1]) # WRONG!
```

The arguments accepted by the constructor should all be keyword arguments with a default value. In other words, a user should be able to instantiate an estimator without passing any arguments to it. The arguments should all correspond to hyperparameters describing the model or the optimisation problem the estimator tries to solve. These initial arguments (or parameters) are always remembered by the estimator. Also note that they should not be documented under the “Attributes” section, but rather under the “Parameters” section for that estimator.

There should be no logic in the constructor, not even input validation, and the parameters should not be changed. The corresponding logic should be put where the parameters are used, typically in fit. The following is wrong:

```julia
function RidgeRegression(self; param1=1, param2=2, param3=3)
    # WRONG: parameters should not be modified
    if param1 > 1
        param2 += 1
    end
    self.param1 = param1
    # WRONG: the object's attributes should have exactly the name of
    # the argument in the constructor
    self.param3 = param2
end
```

The reason for postponing the validation is that the same validation would have to be performed in `set_params!`, which is used in algorithms like `GridSearchCV`.

#### Fitting

The next thing you will probably want to do is to estimate some parameters in the model. This is implemented in the `fit!()` method.

The `fit!()` method takes the model, and the training data as arguments, which can be one array in the case of unsupervised learning, or two arrays in the case of supervised learning.

Note that the model is fitted using X and y, but the object holds no reference to X and y. There are, however, some exceptions to this, as in the case of precomputed kernels where this data must be stored for use by the predict method.

Parameters | Description
----- | -----
X | array-like, with shape = (N, D), where N is the number of samples and D is the number of features.
y | array, with shape = (N), where N is the number of samples.
kwargs | optional data-dependent parameters.

`size(X, 1)` should be the same as `size(y, 1)`. If this requisite is not met, an exception of type `ArgumentError` should be raised.

`y` might be ignored in the case of unsupervised learning. However, to make it possible to use the estimator as part of a pipeline that can mix both supervised and unsupervised transformers, even unsupervised estimators need to accept a `y=nothing` keyword argument in the second position that is just ignored by the estimator. For the same reason, `fit_predict!`, `fit_transform!`, `score` and `partial_fit!` methods need to accept a `y` argument in the second place if they are implemented.

The `fit!` method should return the estimator object. This pattern is useful to be able to implement quick one liners at the REPL, such as:

```julia
y_predicted = predict(fit!(SVC(C=100), X_train, y_train), X_test)
```

Depending on the nature of the algorithm, `fit!` can sometimes also accept additional keywords arguments. However, any parameter that can have a value assigned prior to having access to the data should be a constructor keyword argument. `fit!` parameters should be restricted to directly data dependent variables. For instance a Gram matrix or an affinity matrix which are precomputed from the data matrix X are data dependent. A tolerance stopping criterion tol is not directly data dependent (although the optimal value according to some scoring function probably is).

#### Optional Arguments

In iterative algorithms, the number of iterations should be specified by an integer called `n_iter`.

## Rolling your own estimator

Most models will need:

- `fit!`
- `predict` / `predict_proba` for supervised learning models, along with `is_classifier(::ModelType) = true/false`
- `transform` for unsupervised learning

Given those, calling `declare_hyperparameters` at the top-level will
automatically provide `set_params!`, `get_params`, `clone` and `fit_transform!`:

```julia
declare_hyperparameters(ModelType, [:param1, :param2, ...])
```

The only estimators that should not use `declare_hyperparameters` are those that contain other estimators (eg. boosting)

#### Implementation tip

Many Julia libraries already define a type that does not contain the model
hyperparameters. In that case, it's easiest to create a new type that contains
an instance of the old type, along with the hyperparameters. For instance, if
your type is called `RidgeRegression`, the scikit-learn-compatible type might
be called `SkRidgeRegression` and contain a `RidgeRegression` instance.