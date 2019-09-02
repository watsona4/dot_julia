# Examples - Data interpolation

Suppose we have want to approximate some function with some sampled points. First to generate some points
```
const global_base_date = Date(2000,1,1)
StartDate = Date(2018, 7, 21)
x = Array{Date}(undef, 20)
for i in 1:20
    x[i] = StartDate +Dates.Day(2* (i-1))
end
function ff(x::Date)
    days_between = years_from_global_base(x)
    return log(days_between) + sqrt(days_between)
end
y = ff.(x)
```
Now we can generate a function that can be used to easily interpolate from the sampled points:
```
func = create_quadratic_spline(x,y)
```
And we can evaluate from this function and integrate it and differentiate it in the normal way:
```
evaluate(func, Date(2020,1,1))
evaluate.(Ref(func), [Date(2020,1,1), Date(2021,1,2)])
evaluate(derivative(func), Date(2021,1,2))
integral(func, Date(2020,1,1), Date(2021,1,2))
```
If we had wanted to interpolate instead with a constant method(from left or from right) or by linearly
interpolating then we could have just generated func with a different method:
create\_constant\_interpolation\_to\_left,
create\_constant\_interpolation\_to\_right or
create\_linear\_interpolation.
