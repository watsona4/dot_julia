/* Stata file for generating and saving data, run with stata -e */

/* 10 observations */
set obs 10
/* first column "a", floats 1, ..., 10 */
gen a = _n
/* second column "b", integers 1, ..., 10 */
gen b = _n
recast int b
/* third column "c", str2, converted from integers 1, ..., 10 */
gen c = string(b)
/* introduce missing values */
replace a = . if a > 7.0
replace b = . if b < 3
/* some debugging info */
describe
list
/* save */
save testdata, replace
