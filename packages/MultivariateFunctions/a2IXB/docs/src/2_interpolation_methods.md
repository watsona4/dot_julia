# Univariate Interpolation Methods
So far this package support the following interpolation schemes for one dimensional interpolation:
* Constant interpolation from the left to the right. Such a Piecewise\_Function spline can be constructed by the create\_constant\_interpolation\_to\_right method.
* Constant interpolation from the right to the left. Such a Piecewise\_Function spline can be constructed by the create\_constant\_interpolation\_to\_left method.
* Linear interpolation. Such a Piecewise\_Function spline can be constructed by the create\_linear\_interpolation method.
* Schumaker shape preserving spline - Such a Piecewise\_Function spline can be constructed by the create\_quadratic\_spline method. See Judd (1998) for details on how this is done.

Note that interpolation in higher dimensions is hard and no such methods are yet available in this package. There are some approximation schemes that might work in this case however as described in the next section.
