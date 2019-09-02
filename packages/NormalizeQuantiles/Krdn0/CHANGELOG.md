## 0.3.3 (2017-12-20)

####Features:

* none
	
####Bug fixes:

* none

####Remarks:

  * julia 0.7-DEV introduces "missing", therefor major recoding is needed.
  * This version will be freezed for julia 0.4 to 0.6(including)

## 0.3.2

####Features:

* none
	
####Bug fixes:

* none

####Remarks:

  * Julia 0.7-DEV sharedArrayes removed from base

## 0.3.1 (2017-05-16)

####Features:

* none
	
####Bug fixes:

* none

####Remarks:

  * Julia 0.6 syntax change and deprecation
  
    * WARNING: !(A::AbstractArray{Bool}) is deprecated, use .!(A) instead.

## 0.3.0 (2017-01-20)

####Features:

  - none
	
####Bug fixes:

  - none

####Remarks:

  - dropped julia 0.3 support

## 0.2.1 (2017-01-20)

####Features:

  - none
	
####Bug fixes:

  - none

####Remarks:

  - Only changes to reflect changes in syntax coming with julia 0.6
  - This version still supports julia 0.3

## 0.2.0 (2016-08-11)

####Features:

  - started changelog
  - for function `sampleRanks` removed methods with optional parameters in favor of methods with keyword parameters
	
####Bug fixes:

  - none

####Remarks:

In julia 0.5 and 0.6 using optional parameters in functions like

```julia
function test(a,b=1,c=1)
	a+b+c
end


```

together with keyword parameters:

```julia
function test(a;b=1,c=1)
	a+b+c
end


```

results in warning messages when importing the package with `using`:

```
WARNING: Method definition test(Any) in ... overwritten at ...
```
	



