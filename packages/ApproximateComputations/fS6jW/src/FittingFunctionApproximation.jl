using Base.Meta
using Plots
using BenchmarkTools
using Statistics
using DataFrames

using Test

# Needed to override operator on Approximation{T} type.
import Base.-
import Base.+
import Base./
import Base.*
import Base.convert

greet() = print("Welcome to AppoximateComputations!\n
This is a growing project as part of work ongoing at the DTG Research Group of Cambridge University's Computer Laboratory.
We hope to grow this package with many usable implementations of approximate software techniques.
This package is maintained by Nicholas Timmons under an MIT license.
Any queries please feel free to get in contact by email: ngt26 at cam.ac.uk\n We hope this package is useful!")


struct ErrorResultsContainer    
    absDif::Array{Float64,1}
    absError::Float64
    meanDif::Float64
    medianDif::Float64
    benchmarkRes::Tuple{BenchmarkTools.Trial, BenchmarkTools.Trial}
end

struct GeneratedFunctionType
    generatedFunction::Any
    fitType::String
    precision::Any
    order::Any
    errordata::ErrorResultsContainer
    targetFunctionName::Symbol
    range::Tuple{Float64, Float64} 
	textstring::String
end

function GetAbsoluteError(arr::GeneratedFunctionType)        arr.errordata.absError;                      end
function GetMeanDifference(arr::GeneratedFunctionType)       arr.errordata.meanDif;                       end
function GetMedianDifference(arr::GeneratedFunctionType)     arr.errordata.medianDif;                     end
function GetMedianBenchmarkTime(arr::GeneratedFunctionType)  median(arr.errordata.benchmarkRes[2].times); end
function GetMeanBenchmarkTime(arr::GeneratedFunctionType)    mean(arr.errordata.benchmarkRes[2].times);   end


#Struct wrapper definition
struct Approximation{T}
    value::T
end

#Function to convert out of approximation space back to fixed precision space
Get(x::Approximation{T}) where {T} = x.value
Get(x) where {T} = x

# Mathematics with an approximation type will return an approximation type
+(x::Approximation{T}, y) where T<:Number = Approximation(+(x.value, y))
-(x::Approximation{T}, y) where T<:Number = Approximation(-(x.value, y))
*(x::Approximation{T}, y) where T<:Number = Approximation(*(x.value, y))
/(x::Approximation{T}, y) where T<:Number = Approximation(/(x.value, y))


## Approximation Tests
#a = Approximation(6.0)
#b = 4.0
#
#@test_throws MethodError c = a - b
#@test_throws MethodError c = a + b
#@test_throws MethodError c = a * b
#@test_throws MethodError c = a / b
#
#@test typeof(convert(Float32, a)) == Float32
#@test typeof(convert(Float64, a)) == Float64


# From CurveFit.jl (and slightly tweaked). CurveFit.jl is currently not upgraded to Julia 1.0
#=
Copyright (c) 2014: Paulo Jabardo.
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction, 
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial 
portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
=#
function polyfit(x, y, order::Integer)
    inputCount = length(x)
    A = ones(eltype(x), inputCount, order+1)
    for i in 1:order
        for k in 1:inputCount
            A[k,i+1] = A[k,i] * x[k]
        end
    end
    A \ y
end

function pateLinearRationalFit(x::AbstractVector{T}, y::AbstractVector{T}, p, q) where T<:Number
    n = size(x,1)
    A = zeros(T, n, q+p+1)
    for i = 1:n
        A[i,1] = one(T)
        for k = 1:p
            A[i,k+1] = x[i]^k
        end
        for k = 1:q
            A[i, p+1+k] = -y[i] * x[i]^k
        end
    end

    A \ y
end

## End CurveFit.jl functions


function GetAbsoluteError(inputDiff)
   dif = abs.(inputDiff)
   sum = Base.sum(dif,dims=1)[1,1]
end

function GetAbsoluteError(input0, input1)
   dif = abs.(input0-input1)
   sum = Base.sum(dif,dims=1)[1,1]
end

function PadArray(input, length)
    arr = zeros(length)
    len = size(input)[1]
    for i in 1:len
        arr[i] = input[i]
    end
    arr
end

function GetErrorDataForFunction(targetFunction, generatedFunction, inputs)
    # Test compile to ensure it is "warmed up"
    # Alternatively could use precompile(f, args::Tuple{Vararg{Any}})
    for i in 0.0f0:0.1f0:3.140f0
        yRes = generatedFunction(i)   
    end

    targetRes       = targetFunction.(inputs)
    generatedRes    = Get.(generatedFunction.(inputs))
    
    absDif          = abs.(generatedRes-targetRes)
    meanDif         = mean(absDif)
    medianDif       = median(absDif)

    absError        = GetAbsoluteError(targetRes, generatedRes)
    normabsError    = meanDif
    
    targetBench     = @benchmark $targetFunction.(convert(Array{Float64}, $inputs))
    generatedBench  = @benchmark $generatedFunction.($inputs)
    
    ErrorResultsContainer(absDif, absError, meanDif, medianDif, (targetBench, generatedBench))
end

function TestFunction(fn, targetfn, inputs64)
   float64letFunctionData      = GetErrorDataForFunction(targetfn, fn, inputs64) 
end

function CreateDataFrameRow(functionData::GeneratedFunctionType)
    DataFrame( Name      = functionData.targetFunctionName, 
               Precision = functionData.precision,
               FitType   = functionData.fitType,
               Order     = functionData.order,
               abserror  = functionData.errordata.absError,
               mean      = functionData.errordata.meanDif,
               median    = functionData.errordata.medianDif,
               benchmark = functionData.errordata.benchmarkRes[2],
               range     = functionData.range)
end

function GetFunctionName(approxData::GeneratedFunctionType)
    string(approxData.targetFunctionName,"_",approxData.fitType,approxData.order,"_", approxData.precision,"bit")
end

function FilterFunctionList(arr; 
                            filterType = Any, 
                            maxMeanError   = 99999.0 , minMeanError   = 0.0, 
                            maxMedianError = 99999.0 , minMedianError = 0.0,
                            maxMeanTime    = 999999.0, minMeanTime    = 0.0,
                            maxMedianTime  = 999999.0, minMedianTime  = 0.0)
    filteredList = []
    for entry in arr
        if(  filterType == Any || (entry.precision == filterType))
            if(GetMedianDifference(entry) > minMedianError)
               if( GetMedianDifference(entry) < maxMedianError)
                    if( GetMeanDifference(entry) < maxMeanError)
                        if(GetMeanDifference(entry) > minMeanError)                
                            if(GetMeanBenchmarkTime(entry) < maxMeanTime)
                                if(GetMeanBenchmarkTime(entry) > minMeanTime)
                                    if(GetMedianBenchmarkTime(entry) < maxMedianTime)
                                        if(GetMedianBenchmarkTime(entry) > minMedianTime)
                                            push!(filteredList, entry)
                                        end
                                    end     
                                end
                            end
                        end
                    end
                end
            end
        end
    end  
    filteredList
end

function GetFastestAcceptable(arr; targetMode="Time", meanErrorLimit=99999.0, maxTimeLimit=999999.0, verbose=true)
    printText(x) = verbose ? println(x) : nothing
    
    # Filter out results which have too much error or take too long
    shortlist = FilterFunctionList(arr, maxMeanError=meanErrorLimit, maxMedianTime=maxTimeLimit)
    
    # Select the most optimal function to choose, based on the current mode.
    if(targetMode == "Time")
        minTimeEntry = 0
        minTime      = 999999999999
        printText("Selecting Function with minimum time...")
        for entry in shortlist
            t = median(entry.errordata.benchmarkRes[2].times)
            if( t < minTime)
                minTimeEntry = entry
                minTime = t
                printText(string("Current Best:",GetFunctionName(minTimeEntry)))
            end
        end
        return minTimeEntry     
    elseif(targetMode == "ErrorMean")
        minErrorEntry = 0
        minError      = 999999999999
        
        for entry in shortlist
            e =(entry.errordata.meanDif)
            if( e < minError)
                minErrorEntry = entry
                minError = e
            end
        end
        return minErrorEntry
    end
    
    return nothing
end

#### Plotting functions for generated function data structures
#### ==========================================================
# Plots the returned value for each input.
function PlotApproximationFunctionResults(arr, inputs, targetFunctionResults; filterType = Any, maxMeanError = 99999.0, minMeanError = 0.0, maxMedianError = 99999.0, minMedianError = 0.0  ) #
    p = plot(inputs, targetFunctionResults, label="Target")
    for func in arr
        testRes = func.generatedFunction.(inputs)
        
        if( (func.errordata.medianDif <= maxMedianError) && (func.errordata.medianDif >= minMedianError))
        if( (func.errordata.meanDif   <= maxMeanError)   && (func.errordata.meanDif   >= minMeanError))
        if(  filterType == Any                           || (func.precision           == filterType))
            plot!(inputs, Get.(testRes), label=string(func.fitType, "_", func.precision, "_", string(func.order)))
        end
        end
        end
    end
    p
end

# Plots the error relative to the high-resolution implementation
function PlotApproximationFunctionDiff(arr, inputs; filterType = Any, maxMeanError = 99999.0, minMeanError = 0.0, maxMedianError = 99999.0, minMedianError = 0.0 ) #
    p = plot()
    for func in arr
        if( (func.errordata.meanDif <= maxMeanError) && (func.errordata.meanDif >= minMeanError))
        if( (func.errordata.medianDif <= maxMedianError) && (func.errordata.medianDif >= minMedianError))
        if(  filterType == Any || (func.precision == filterType))
            plot!(inputs, func.errordata.absDif, label=string(func.fitType, "_", func.precision, "_", string(func.order)))
        end
        end
        end
    end
    p
end

# Plots the frequency of error ranges
function PlotApproximationFunctionDiffHist(arr; filterType = Any, maxMeanError = 99999.0, minMeanError = 0.0, maxMedianError = 99999.0, minMedianError = 0.0 ) #
    p = []
    for func in arr
        if( (func.errordata.medianDif <= maxMedianError) && (func.errordata.medianDif >= minMedianError))
        if( (func.errordata.meanDif <= maxMeanError) && (func.errordata.meanDif >= minMeanError))
        if(  filterType == Any || (func.precision == filterType))
            histogram(func.errordata.absDif, ylabel="Frequency", xlabel="ErrorValue", label=string(func.fitType, "_", func.precision, "_", string(func.order)))
            q = title!(string(func.fitType, "_", func.precision, "_", string(func.order)))
            push!(p, q)
        end
        end
        end
    end
    plot(p...,layout=(length(p),1),legend=false, size = (1000, 300*length(p)))
end

function PlotMedianError(arr; logerror = true)
    medianError = abs.((p->p.errordata.medianDif).(arr))
    orders = string.((p->p.order).(arr), (p->p.precision).(arr)) 
    b1 = 0
    if(logerror)
        b1 = bar(orders, medianError, yscale = :log10, rotation=45)
        b1 = ylabel!("Log Error (absolute)")
    else
        b1 = bar(orders, medianError)
        b1 = ylabel!("Error (absolute)")
    end
    
    b1 = title!("Median Error")
end

function PlotMedianRuntime(arr; targetLine = [0.0])
    # Extracting performance times from array to array
    trials = (p->p.errordata.benchmarkRes).(arr)
    timings = (q->q[2].times).(trials)
    medRes = abs.(median.(timings))
    orders = string.((p->p.order).(arr), (p->p.precision).(arr)) 
    b2 = bar(orders, medRes, rotation=45)
    
    if(targetLine[1] > 0.0)
        b2 = hline!(targetLine)
    end

    b2 = title!("Median Runtime")
    b2 = ylabel!("Time (ns)")   
end

function PlotRuntimeErrorPair(arr, ; logScaleY = true, targetRuntime = [0.0])   
    b1 = PlotMedianError(arr, logerror = logScaleY)
    b2 = PlotMedianRuntime(arr, targetLine = targetRuntime)
    plot(b1,b2, layout=(2,1), xlabel="Order", legend=false, size = (900, 800) )
end

# Implementation of Pate function generation using 'Eval'. This is much cleaner, but produces less optimal code.
function GetApproximatePateFunction_Eval(targetFunction, inputs64, highResResults, orderPFn, orderQFn, precision=Float64)
        
    params64       = pateLinearRationalFit(inputs64, highResResults, orderPFn(), orderQFn())   
    params         = convert(Array{precision},params64) 
    
    nparams64      = params[1:orderPFn()+1]
    nparams64      = PadArray(nparams64,20)
    
    dparams64      = params[orderPFn()+2:end]
    dparams64      = PadArray(dparams64,20)
    
    orderEitherFn = ()-> max(orderPFn(), orderQFn())
	fitfast_let_float64_string = "function(x)          
                                    if $(orderEitherFn()) >= 2 xx       = x*x        end
                                    if $(orderEitherFn()) >= 3 xxx      = xx*x       end
                                    if $(orderEitherFn()) >= 4 xxxx     = xx*xx      end
                                    if $(orderEitherFn()) >= 8 xxxxxxxx = xxxx*xxxx  end

                                    numerator =  $(nparams64[1]) 
                                    if $(orderPFn()) >= 1  numerator+= $(nparams64[2] )* x            end
                                    if $(orderPFn()) >= 2  numerator+= $(nparams64[3] )* xx           end
                                    if $(orderPFn()) >= 3  numerator+= $(nparams64[4] )* xxx          end
                                    if $(orderPFn()) >= 4  numerator+= $(nparams64[5] )* xxxx         end
                                    if $(orderPFn()) >= 5  numerator+= $(nparams64[6] )* xxxx*x       end
                                    if $(orderPFn()) >= 6  numerator+= $(nparams64[7] )* xxxx*xx      end
                                    if $(orderPFn()) >= 7  numerator+= $(nparams64[8] )* xxxx*xxx     end
                                    if $(orderPFn()) >= 8  numerator+= $(nparams64[9] )* xxxxxxxx     end
                                    if $(orderPFn()) >= 9  numerator+= $(nparams64[10])* xxxxxxxx*x   end
                                    if $(orderPFn()) >= 10 numerator+= $(nparams64[11])* xxxxxxxx*xx  end

                                    denom = 1.0 
                                    if $(orderQFn()) >= 1  denom    += $(dparams64[1] )* x            end
                                    if $(orderQFn()) >= 2  denom    += $(dparams64[2] )* xx           end
                                    if $(orderQFn()) >= 3  denom    += $(dparams64[3] )* xxx          end
                                    if $(orderQFn()) >= 4  denom    += $(dparams64[4] )* xxxx         end
                                    if $(orderQFn()) >= 5  denom    += $(dparams64[5] )* xxxx*x       end
                                    if $(orderQFn()) >= 6  denom    += $(dparams64[6] )* xxxx*xx      end
                                    if $(orderQFn()) >= 7  denom    += $(dparams64[7] )* xxxx*xxx     end
                                    if $(orderQFn()) >= 8  denom    += $(dparams64[8] )* xxxxxxxx     end
                                    if $(orderQFn()) >= 9  denom    += $(dparams64[9] )* xxxxxxxx*x   end
                                    if $(orderQFn()) >= 10 denom    += $(dparams64[10])* xxxxxxxx*xx  end

                                    (numerator/denom)
                                end" 
    fitfast_let_float64 =   @eval function(x)          
                                    if $(orderEitherFn()) >= 2 xx       = x*x        end
                                    if $(orderEitherFn()) >= 3 xxx      = xx*x       end
                                    if $(orderEitherFn()) >= 4 xxxx     = xx*xx      end
                                    if $(orderEitherFn()) >= 8 xxxxxxxx = xxxx*xxxx  end

                                    numerator =  $(nparams64[1]) 
                                    if $(orderPFn()) >= 1  numerator+= $(nparams64[2] )* x            end
                                    if $(orderPFn()) >= 2  numerator+= $(nparams64[3] )* xx           end
                                    if $(orderPFn()) >= 3  numerator+= $(nparams64[4] )* xxx          end
                                    if $(orderPFn()) >= 4  numerator+= $(nparams64[5] )* xxxx         end
                                    if $(orderPFn()) >= 5  numerator+= $(nparams64[6] )* xxxx*x       end
                                    if $(orderPFn()) >= 6  numerator+= $(nparams64[7] )* xxxx*xx      end
                                    if $(orderPFn()) >= 7  numerator+= $(nparams64[8] )* xxxx*xxx     end
                                    if $(orderPFn()) >= 8  numerator+= $(nparams64[9] )* xxxxxxxx     end
                                    if $(orderPFn()) >= 9  numerator+= $(nparams64[10])* xxxxxxxx*x   end
                                    if $(orderPFn()) >= 10 numerator+= $(nparams64[11])* xxxxxxxx*xx  end

                                    denom = 1.0 
                                    if $(orderQFn()) >= 1  denom    += $(dparams64[1] )* x            end
                                    if $(orderQFn()) >= 2  denom    += $(dparams64[2] )* xx           end
                                    if $(orderQFn()) >= 3  denom    += $(dparams64[3] )* xxx          end
                                    if $(orderQFn()) >= 4  denom    += $(dparams64[4] )* xxxx         end
                                    if $(orderQFn()) >= 5  denom    += $(dparams64[5] )* xxxx*x       end
                                    if $(orderQFn()) >= 6  denom    += $(dparams64[6] )* xxxx*xx      end
                                    if $(orderQFn()) >= 7  denom    += $(dparams64[7] )* xxxx*xxx     end
                                    if $(orderQFn()) >= 8  denom    += $(dparams64[8] )* xxxxxxxx     end
                                    if $(orderQFn()) >= 9  denom    += $(dparams64[9] )* xxxxxxxx*x   end
                                    if $(orderQFn()) >= 10 denom    += $(dparams64[10])* xxxxxxxx*xx  end

                                    Approximation(numerator/denom)
                                end
    
    return (fitfast_let_float64, fitfast_let_float64_string)
end

# Implementation of Pate function generation using 'let'. This is a bit messy but generates code as optimally as if it was hard-coded
function GetApproximatePateFunction(targetFunction, inputs64, highResResults, orderPFn, orderQFn, precision=Float64)
       
    params64       = pateLinearRationalFit(inputs64, highResResults, orderPFn(), orderQFn())   
    params         = convert(Array{precision},params64) 
    
    nparams64      = params[1:orderPFn()+1]
    dparams64      = params[orderPFn()+2:end]
    nparams64      = PadArray(nparams64,20)
    dparams64      = PadArray(dparams64,20)
    
    orderEitherFn = ()-> max(orderPFn(), orderQFn())
    
    #How we are forced to do it by compilers not catching on to what we are doing
    (fitfast_let_float64) =
    let num1  = nparams64[1]  
    let num2  = nparams64[2]  
    let num3  = nparams64[3]  
    let num4  = nparams64[4]  
    let num5  = nparams64[5]  
    let num6  = nparams64[6]  
    let num7  = nparams64[7]  
    let num8  = nparams64[8]  
    let num9  = nparams64[9]  
    let num10 = nparams64[10] 
    let num11 = nparams64[11] 
    let den1  = dparams64[1]  
    let den2  = dparams64[2]  
    let den3  = dparams64[3]  
    let den4  = dparams64[4]  
    let den5  = dparams64[5]  
    let den6  = dparams64[6]  
    let den7  = dparams64[7]  
    let den8  = dparams64[8]  
    let den9  = dparams64[9]  
    let den10 = dparams64[10]                                                              
        funca = function(x)          
            if orderEitherFn() >= 2 xx       = x*x        end
            if orderEitherFn() >= 3 xxx      = xx*x       end
            if orderEitherFn() >= 4 xxxx     = xx*xx      end
            if orderEitherFn() >= 8 xxxxxxxx = xxxx*xxxx  end
                                                                                        
            numerator = num1 
            if orderPFn() >= 1  numerator+= num2 * x            end
            if orderPFn() >= 2  numerator+= num3 * xx           end
            if orderPFn() >= 3  numerator+= num4 * xxx          end
            if orderPFn() >= 4  numerator+= num5 * xxxx         end
            if orderPFn() >= 5  numerator+= num6 * xxxx*x       end
            if orderPFn() >= 6  numerator+= num7 * xxxx*xx      end
            if orderPFn() >= 7  numerator+= num8 * xxxx*xxx     end
            if orderPFn() >= 8  numerator+= num9 * xxxxxxxx     end
            if orderPFn() >= 9  numerator+= num10* xxxxxxxx*x   end
            if orderPFn() >= 10 numerator+= num11* xxxxxxxx*xx  end
                                                                                        
            denom = 1.0 
            if orderQFn() >= 1  denom    += den1 * x            end
            if orderQFn() >= 2  denom    += den2 * xx           end
            if orderQFn() >= 3  denom    += den3 * xxx          end
            if orderQFn() >= 4  denom    += den4 * xxxx         end
            if orderQFn() >= 5  denom    += den5 * xxxx*x       end
            if orderQFn() >= 6  denom    += den6 * xxxx*xx      end
            if orderQFn() >= 7  denom    += den7 * xxxx*xxx     end
            if orderQFn() >= 8  denom    += den8 * xxxxxxxx     end
            if orderQFn() >= 9  denom    += den9 * xxxxxxxx*x   end
            if orderQFn() >= 10 denom    += den10* xxxxxxxx*xx  end
            
            Approximation(numerator/denom)
        end                                     
    end    end    end    end    end    end    end    end    end    end    end
    end    end    end    end    end    end    end    end    end   end   
	
	
	fitfast_let_float64_string ="
    let num1  = $(nparams64[1]  )
    let num2  = $(nparams64[2]  )
    let num3  = $(nparams64[3]  )
    let num4  = $(nparams64[4]  )
    let num5  = $(nparams64[5]  )
    let num6  = $(nparams64[6]  )
    let num7  = $(nparams64[7]  )
    let num8  = $(nparams64[8]  )
    let num9  = $(nparams64[9]  )
    let num10 = $(nparams64[10] )
    let num11 = $(nparams64[11] )
    let den1  = $(dparams64[1]  )
    let den2  = $(dparams64[2]  )
    let den3  = $(dparams64[3]  )
    let den4  = $(dparams64[4]  )
    let den5  = $(dparams64[5]  )
    let den6  = $(dparams64[6]  )
    let den7  = $(dparams64[7]  )
    let den8  = $(dparams64[8]  )
    let den9  = $(dparams64[9]  )
    let den10 = $(dparams64[10] )                                                               
        funca = function(x)          
            if $(orderEitherFn()) >= 2 xx       = x*x        end
            if $(orderEitherFn()) >= 3 xxx      = xx*x       end
            if $(orderEitherFn()) >= 4 xxxx     = xx*xx      end
            if $(orderEitherFn()) >= 8 xxxxxxxx = xxxx*xxxx  end
                                                                                        
            numerator = num1 
            if $(orderPFn()) >= 1  numerator+= num2 * x            end
            if $(orderPFn()) >= 2  numerator+= num3 * xx           end
            if $(orderPFn()) >= 3  numerator+= num4 * xxx          end
            if $(orderPFn()) >= 4  numerator+= num5 * xxxx         end
            if $(orderPFn()) >= 5  numerator+= num6 * xxxx*x       end
            if $(orderPFn()) >= 6  numerator+= num7 * xxxx*xx      end
            if $(orderPFn()) >= 7  numerator+= num8 * xxxx*xxx     end
            if $(orderPFn()) >= 8  numerator+= num9 * xxxxxxxx     end
            if $(orderPFn()) >= 9  numerator+= num10* xxxxxxxx*x   end
            if $(orderPFn()) >= 10 numerator+= num11* xxxxxxxx*xx  end
                                                                                         
            denom = 1.0 
            if $(orderQFn()) >= 1  denom    += den1 * x            end
            if $(orderQFn()) >= 2  denom    += den2 * xx           end
            if $(orderQFn()) >= 3  denom    += den3 * xxx          end
            if $(orderQFn()) >= 4  denom    += den4 * xxxx         end
            if $(orderQFn()) >= 5  denom    += den5 * xxxx*x       end
            if $(orderQFn()) >= 6  denom    += den6 * xxxx*xx      end
            if $(orderQFn()) >= 7  denom    += den7 * xxxx*xxx     end
            if $(orderQFn()) >= 8  denom    += den8 * xxxxxxxx     end
            if $(orderQFn()) >= 9  denom    += den9 * xxxxxxxx*x   end
            if $(orderQFn()) >= 10 denom    += den10* xxxxxxxx*xx  end
            
            (numerator/denom)
        end                                     
    end    end    end    end    end    end    end    end    end    end    end
    end    end    end    end    end    end    end    end    end   end   "
    
    return (fitfast_let_float64, fitfast_let_float64_string)
end

# Implementation of a Polynomial function using 'let'. 
# This is a bit messy but generates code as optimally as if it was hard-coded
function GetApproximatePolyFunction(targetFunction, inputs64, highResResults, orderFn, precision=Float64)    
    params64       = polyfit(inputs64, highResResults, orderFn())       
    params64       = PadArray(params64,21) 
    params         = convert(Array{precision},params64) 
    
	fitfast_let_float64_string ="
    let x1  = $(params[1]  )
    let x2  = $(params[2]  )
    let x3  = $(params[3]  )
    let x4  = $(params[4]  )
    let x5  = $(params[5]  )
    let x6  = $(params[6]  )
    let x7  = $(params[7]  )
    let x8  = $(params[8]  )
    let x9  = $(params[9]  )
    let x10 = $(params[10] )
    let x11 = $(params[11] )
    let x12 = $(params[12] )
    let x13 = $(params[13] )
    let x14 = $(params[14] )
    let x15 = $(params[15] )
    let x16 = $(params[16] )
    let x17 = $(params[17] )
    let x18 = $(params[18] )
    let x19 = $(params[19] )
    let x20 = $(params[20] )
        funca = function(x)          
            if $(orderFn()) >= 2 xx       = x*x        end
            if $(orderFn()) >= 3 xxx      = xx*x       end
            if $(orderFn()) >= 4 xxxx     = xx*xx      end
            if $(orderFn()) >= 8 xxxxxxxx = xxxx*xxxx  end
                                                                                        
            a = x1 
            if $(orderFn()) >= 1  a += x2 *  x                     end
            if $(orderFn()) >= 2  a += x3 *  xx                    end
            if $(orderFn()) >= 3  a += x4 *  xxx                   end
            if $(orderFn()) >= 4  a += x5 *  xxxx                  end
            if $(orderFn()) >= 5  a += x6 *  xxxx*x                end
            if $(orderFn()) >= 6  a += x7 *  xxxx*xx               end
            if $(orderFn()) >= 7  a += x8 *  xxxx*xxx              end
            if $(orderFn()) >= 8  a += x9 *  xxxxxxxx              end
            if $(orderFn()) >= 9  a += x10*  xxxxxxxx*x            end
            if $(orderFn()) >= 10 a += x11*  xxxxxxxx*xx           end  #checkpoint
            if $(orderFn()) >= 11 a += x12*  xxxxxxxx*xxx          end
            if $(orderFn()) >= 12 a += x13*  xxxxxxxx*xxxx         end
            if $(orderFn()) >= 13 a += x14*  xxxxxxxx*xx*xxx       end
            if $(orderFn()) >= 14 a += x15*  xxxxxxxx*xxxx*xx      end
            if $(orderFn()) >= 15 a += x16*  xxxxxxxx*xxxx*xxx     end
            if $(orderFn()) >= 16 a += x17*  xxxxxxxx*xxxxxxxx     end
            if $(orderFn()) >= 17 a += x18*  xxxxxxxx*xxxxxxxx*x   end
            if $(orderFn()) >= 18 a += x19*  xxxxxxxx*xxxxxxxx*xx  end
            if $(orderFn()) >= 19 a += x20*  xxxxxxxx*xxxxxxxx*xxx end
            (a)
        end
    end    end    end    end    end    end    end    end    end    end    end
    end    end    end    end    end    end    end    end    end       "
    (fitfast_let_float64) =
    let x1  = params[1]
    let x2  = params[2]
    let x3  = params[3]
    let x4  = params[4]
    let x5  = params[5]
    let x6  = params[6]
    let x7  = params[7]
    let x8  = params[8]
    let x9  = params[9]
    let x10 = params[10]
    let x11 = params[11]
    let x12 = params[12]
    let x13 = params[13]
    let x14 = params[14]
    let x15 = params[15]
    let x16 = params[16]
    let x17 = params[17]
    let x18 = params[18]
    let x19 = params[19]
    let x20 = params[20]
        funca = function(x)          
            if orderFn() >= 2 xx       = x*x        end
            if orderFn() >= 3 xxx      = xx*x       end
            if orderFn() >= 4 xxxx     = xx*xx      end
            if orderFn() >= 8 xxxxxxxx = xxxx*xxxx  end
                                                                                        
            a = x1 
            if orderFn() >= 1  a += x2*  x                     end
            if orderFn() >= 2  a += x3*  xx                    end
            if orderFn() >= 3  a += x4*  xxx                   end
            if orderFn() >= 4  a += x5*  xxxx                  end
            if orderFn() >= 5  a += x6*  xxxx*x                end
            if orderFn() >= 6  a += x7*  xxxx*xx               end
            if orderFn() >= 7  a += x8*  xxxx*xxx              end
            if orderFn() >= 8  a += x9*  xxxxxxxx              end
            if orderFn() >= 9  a += x10* xxxxxxxx*x            end
            if orderFn() >= 10 a += x11* xxxxxxxx*xx           end  #checkpoint
            if orderFn() >= 11 a += x12* xxxxxxxx*xxx          end
            if orderFn() >= 12 a += x13* xxxxxxxx*xxxx         end
            if orderFn() >= 13 a += x14* xxxxxxxx*xx*xxx       end
            if orderFn() >= 14 a += x15* xxxxxxxx*xxxx*xx      end
            if orderFn() >= 15 a += x16* xxxxxxxx*xxxx*xxx     end
            if orderFn() >= 16 a += x17* xxxxxxxx*xxxxxxxx     end
            if orderFn() >= 17 a += x18* xxxxxxxx*xxxxxxxx*x   end
            if orderFn() >= 18 a += x19* xxxxxxxx*xxxxxxxx*xx  end
            if orderFn() >= 19 a += x20* xxxxxxxx*xxxxxxxx*xxx end
            Approximation(a)
        end
    end    end    end    end    end    end    end    end    end    end    end
    end    end    end    end    end    end    end    end    end       

    return (fitfast_let_float64, fitfast_let_float64_string)
end

# Implementation of Pate function generation using 'Eval'. This is much cleaner, but produces less optimal code.
function GetApproximatePolyFunction_Eval(targetFunction, inputs64, highResResults, orderFn, precision=Float64)    
    params64       = polyfit(inputs64, highResResults, orderFn())       
    params64       = PadArray(params64,21) 
    params         = convert(Array{precision},params64) 
    
    fitfast_let_float64_string = "function(x)          
                                if $(orderFn()) >= 2 xx       = x*x        end
                                if $(orderFn()) >= 3 xxx      = xx*x       end
                                if $(orderFn()) >= 4 xxxx     = xx*xx      end
                                if $(orderFn()) >= 8 xxxxxxxx = xxxx*xxxx  end

                                a = $(params[1])
                                if $(orderFn()) >= 1  a += $(params[2] ) * x                     end
                                if $(orderFn()) >= 2  a += $(params[3] ) * xx                    end
                                if $(orderFn()) >= 3  a += $(params[4] ) * xxx                   end
                                if $(orderFn()) >= 4  a += $(params[5] ) * xxxx                  end
                                if $(orderFn()) >= 5  a += $(params[6] ) * xxxx*x                end
                                if $(orderFn()) >= 6  a += $(params[7] ) * xxxx*xx               end
                                if $(orderFn()) >= 7  a += $(params[8] ) * xxxx*xxx              end
                                if $(orderFn()) >= 8  a += $(params[9] ) * xxxxxxxx              end
                                if $(orderFn()) >= 9  a += $(params[10]) * xxxxxxxx*x            end
                                if $(orderFn()) >= 10 a += $(params[11]) * xxxxxxxx*xx           end 
                                if $(orderFn()) >= 11 a += $(params[12]) * xxxxxxxx*xxx          end
                                if $(orderFn()) >= 12 a += $(params[13]) * xxxxxxxx*xxxx         end
                                if $(orderFn()) >= 13 a += $(params[14]) * xxxxxxxx*xx*xxx       end
                                if $(orderFn()) >= 14 a += $(params[15]) * xxxxxxxx*xxxx*xx      end
                                if $(orderFn()) >= 15 a += $(params[16]) * xxxxxxxx*xxxx*xxx     end
                                if $(orderFn()) >= 16 a += $(params[17]) * xxxxxxxx*xxxxxxxx     end
                                if $(orderFn()) >= 17 a += $(params[18]) * xxxxxxxx*xxxxxxxx*x   end
                                if $(orderFn()) >= 18 a += $(params[19]) * xxxxxxxx*xxxxxxxx*xx  end
                                if $(orderFn()) >= 19 a += $(params[20]) * xxxxxxxx*xxxxxxxx*xxx end
                                (a)
                            end"
				
	fitfast_let_float64 = @eval function(x)          
                                if $(orderFn()) >= 2 xx       = x*x        end
                                if $(orderFn()) >= 3 xxx      = xx*x       end
                                if $(orderFn()) >= 4 xxxx     = xx*xx      end
                                if $(orderFn()) >= 8 xxxxxxxx = xxxx*xxxx  end

                                a = $(params[1])
                                if $(orderFn()) >= 1  a += $(params[2] ) * x                     end
                                if $(orderFn()) >= 2  a += $(params[3] ) * xx                    end
                                if $(orderFn()) >= 3  a += $(params[4] ) * xxx                   end
                                if $(orderFn()) >= 4  a += $(params[5] ) * xxxx                  end
                                if $(orderFn()) >= 5  a += $(params[6] ) * xxxx*x                end
                                if $(orderFn()) >= 6  a += $(params[7] ) * xxxx*xx               end
                                if $(orderFn()) >= 7  a += $(params[8] ) * xxxx*xxx              end
                                if $(orderFn()) >= 8  a += $(params[9] ) * xxxxxxxx              end
                                if $(orderFn()) >= 9  a += $(params[10]) * xxxxxxxx*x            end
                                if $(orderFn()) >= 10 a += $(params[11]) * xxxxxxxx*xx           end 
                                if $(orderFn()) >= 11 a += $(params[12]) * xxxxxxxx*xxx          end
                                if $(orderFn()) >= 12 a += $(params[13]) * xxxxxxxx*xxxx         end
                                if $(orderFn()) >= 13 a += $(params[14]) * xxxxxxxx*xx*xxx       end
                                if $(orderFn()) >= 14 a += $(params[15]) * xxxxxxxx*xxxx*xx      end
                                if $(orderFn()) >= 15 a += $(params[16]) * xxxxxxxx*xxxx*xxx     end
                                if $(orderFn()) >= 16 a += $(params[17]) * xxxxxxxx*xxxxxxxx     end
                                if $(orderFn()) >= 17 a += $(params[18]) * xxxxxxxx*xxxxxxxx*x   end
                                if $(orderFn()) >= 18 a += $(params[19]) * xxxxxxxx*xxxxxxxx*xx  end
                                if $(orderFn()) >= 19 a += $(params[20]) * xxxxxxxx*xxxxxxxx*xxx end
                                Approximation(a)
                            end
    return (fitfast_let_float64, fitfast_let_float64_string)
end

function GenerateAllApproximationFunctions(targetfunction, minValue, maxValue; 
				sampleCount = 1000, retDataFrame=false, testTypes=[Float32, Float64],
				polynomialLet_Enabled     	= true,
				polynomialEval_Enabled    	= false,
				pateFunctionsLet_Enabled  	= false,
				pateFunctionsEval_Enabled 	= false,
				orderFunArray     			= [()->7, ()->9, ()->11, ()->13, ()->15, ()->17, ()->19],
				orderFunPateArray 			= [()->2, ()->3, ()->4, ()->5] )
    
    # Generation parameters and dataframe for evaluating the results.
    df = DataFrame( Name      = String[], 
                    Precision = Int64[],
                    FitType   = String[],
                    Order     = Int64[],
                    abserror  = Float64[], 
                    mean      = Float64[], 
                    median    = Float64[], 
                    benchmark = Float64[],
                    range     = Tuple{Float64,Float64}[] )

    inputs64       = Float64.(range(minValue, stop=maxValue, length=sampleCount))
    highResResults = targetfunction.(inputs64)

    typelist          = testTypes

    #orderFunArray     = [()->7, ()->9, ()->11, ()->13, ()->15, ()->17, ()->19]
    #orderFunPateArray = [()->2, ()->3, ()->4, ()->5]
 
    polynomialFunctions       = []
    polynomialFunctions_eval  = []
    pateFunctions_eval        = []
    pateFunctions             = []
    
    
    # Generating the performance and results for each precision of the source function.
    sourceFunctions = []
    for t in typelist
        input     = t.(range(minValue, stop=maxValue, length=sampleCount))
        errorData = GetErrorDataForFunction(targetfunction, targetfunction, input)
        targetRow = GeneratedFunctionType(targetfunction, "Source", typeof(input[1]), 0 , errorData, typeof(targetfunction).name.mt.name, (minValue, maxValue), "")
        df        = vcat(df, CreateDataFrameRow(targetRow))
        push!(sourceFunctions, targetRow)
    end
    
    # Generating the polynomial approximations
    if(polynomialLet_Enabled)        
        for t in typelist
            for orderFunction in orderFunArray
                    newFunc,functext   = GetApproximatePolyFunction(targetfunction, inputs64, highResResults, orderFunction, t )
                    errorresults = TestFunction(newFunc, targetfunction, convert(Array{t},inputs64))

                    generatedFunctionData = GeneratedFunctionType(newFunc, "PolyLet", t,
                                                                  (orderFunction()),
                                                                  errorresults,
                                                                  typeof(targetfunction).name.mt.name,
                                                                  (minValue,maxValue), functext
                                                                )           
                    df = vcat(df, CreateDataFrameRow(generatedFunctionData))
                    push!(polynomialFunctions, generatedFunctionData)
            end
        end 
    end
    
    if(polynomialEval_Enabled)
        for t in typelist
            for orderFunction in orderFunArray
                    newFunc,functext      = GetApproximatePolyFunction_Eval(targetfunction, inputs64, highResResults, orderFunction, t )
                    errorresults = TestFunction(newFunc, targetfunction, convert(Array{t},inputs64))

                    generatedFunctionData = GeneratedFunctionType(newFunc, "PolyEval", t,
                                                                  (orderFunction()),
                                                                  errorresults,
                                                                  typeof(targetfunction).name.mt.name,
                                                                  (minValue,maxValue), functext
                                                                )           
                    df = vcat(df, CreateDataFrameRow(generatedFunctionData))
                    push!(polynomialFunctions, generatedFunctionData)
            end
        end
    end
    
    # Generating the Pate (Eval) approximations at different precisions and orders.
    if(pateFunctionsEval_Enabled)
        for t in typelist
            for orderPFunction in orderFunPateArray
                for orderQFunction in orderFunPateArray
                    newFunc,functext   = GetApproximatePateFunction_Eval(targetfunction, inputs64, highResResults, orderPFunction, orderQFunction, t )
                    errorresults = TestFunction(newFunc, targetfunction, inputs64)

                    generatedFunctionData = GeneratedFunctionType(newFunc, "PateEval",                                                         t,
                                                                  (orderPFunction(),orderQFunction()),
                                                                  errorresults,
                                                                  typeof(targetfunction).name.mt.name,
                                                                  (minValue,maxValue), functext
                                                                )           
                    df = vcat(df, CreateDataFrameRow(generatedFunctionData))
                    push!(pateFunctions_eval, generatedFunctionData)
                end
            end
        end
    end

    if(pateFunctionsLet_Enabled)
        # Generating the Pate (let) approximations at different precisions and orders.
        for t in typelist
            for orderPFunction in orderFunPateArray
                for orderQFunction in orderFunPateArray
                    newFunc,functext  = GetApproximatePateFunction(targetfunction, inputs64, highResResults, orderPFunction, orderQFunction, t )
                    errorresults = TestFunction(newFunc, targetfunction, inputs64)

                    generatedFunctionData = GeneratedFunctionType(newFunc, "PateLet", t,
                                                                  (orderPFunction(),orderQFunction()),
                                                                  errorresults,
                                                                  typeof(targetfunction).name.mt.name,
                                                                  (minValue,maxValue), functext
                                                                )           
                    df = vcat(df, CreateDataFrameRow(generatedFunctionData))
                    push!(pateFunctions, generatedFunctionData)
                end
            end
        end
    end
    
    #return the array of all functions
    allres = vcat(pateFunctions,polynomialFunctions, polynomialFunctions_eval, pateFunctions_eval)
    
    if(retDataFrame)
        return (allres,df)
    else
        return allres
    end
end