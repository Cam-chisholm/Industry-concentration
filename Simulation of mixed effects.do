clear
*set seed 1234

cd "C:\Users\chisholmc\Dropbox (Personal)\Grattan\GitHub\Industry-concentration\IBIS data"

set obs 20

gen a1 = _n
gen u1 = rnormal(0,3)

expand 5
sort a1

gen a2 = _n
gen u2 = rnormal(0,2)

expand 13
sort a1 a2

gen rand = runiform()

keep if rand>0.75
drop rand

gen a3 = _n
gen u3 = rnormal(0,1)

gen MS = runiform()

scalar max = _N

save IndustrySim, replace

clear
set obs 2000

gen a3_1 = 1+int((max)*runiform())
gen a3_2 = (runiform()>.4)*(1+int((max)*runiform()))

forvalues i=3(1)5 {
local j = `i'-1
gen a3_`i' = (a3_`j'>0)*(runiform()>.4)*(1+int((max)*runiform()))
}
forvalues i=6(1)10 {
local j = `i'-1
gen a3_`i' = (a3_`j'>0)*(runiform()>.3)*(1+int((max)*runiform()))
}
forvalues i=11(1)20 {
local j = `i'-1
gen a3_`i' = (a3_`j'>0)*(runiform()>.25)*(1+int((max)*runiform()))
}

gen no_ind = 0

forvalues i=2(1)20 {
local j = `i'-1
replace no_ind = `j' if a3_`i'==0 & a3_`j'>0
}

replace no_ind = 20 if no_ind==0

gen share = 0
forvalues i=1(1)20 {
gen share_`i' = runiform()
replace share_`i' = 0 if `i'>no_ind
replace share = share + share_`i'
}

forvalues i=1(1)20 {
replace share_`i' = share_`i'/share
}
drop share

gen e_firm = rnormal(0,.1)

forvalues i=1(1)20 {
rename a3_`i' a3
merge m:1 a3 using IndustrySim
keep if _merge==3 | _merge==1
rename a3 a3_`i'
gen roe_`i' = 0.1 + 0.05*u1 + 0.05*u2 + 0.05*u3 + e_firm + rnormal(0,.15)
replace roe_`i' = roe_`i' + 0.1 if MS>.7
replace roe_`i' = 0 if roe_`i'==.
rename MS MS_`i'
drop a1 a2 u1 u2 u3 _merge
}

gen roeT = 0 

forvalues i=1(1)20 {
replace roeT = roeT + share_`i'*roe_`i'
}

drop e_firm

gen co_id = _n

save CompanySim, replace

use CompanySim, clear

reshape long a3_ share_ roe_ MS_, i(co_id) j(IndNo)
drop if IndNo>no_ind

rename a3_ a3
merge m:1 a3 using IndustrySim
keep if _merge==3
drop _merge u1 u2 u3 MS_

append using IndustrySim

gen roe_ind = 0.1 + 0.05*u1 + 0.05*u2 + 0.05*u3
replace roe_ind = roe_ind + 0.1 if MS>.7
drop u1 u2 u3
replace share_=1 if co_id==.

recode MS (0/.2 = 1) (.2/.4 = 2) (.4/.6 = 3) (.6/.8 = 4) (.8/1 = 5) 

mixed roeT i.MS || a1: || a2: || a3: [fweight=share_]

predict roe_hat, fit
replace roe_hat = . if co_id!=.

mixed roe_ i.MS || a1: || a2: || a3:

predict roe_hat_, fit
replace roe_hat_ = . if co_id!=.

twoway (sc roe_hat_ roe_ind) (sc roe_hat roe_ind)

keep if co_id==.
keep a1 a2 a3 roe_ind roe_hat roe_hat_ MS
save Results, replace

/* Results suggest that roe_hat_ is unbiased, but roe_hat is biased
towards the mean, as roeT is biased towards the mean as an estimate
of roe_. At best, could argue estimates for roe_ind are conservative */

use CompanySim, clear

forvalues i=1(1)360 {
gen A`i' = 0
forvalues j=1(1)20 {
replace A`i' = share_`j' if a3_`j'==`i'
}
}

reg roeT A1-A360

append using IndustrySim

gen roe_ind = 0.1 + 0.05*u1 + 0.05*u2 + 0.05*u3
replace roe_ind = roe_ind + 0.1 if MS>.7
drop u1 u2 u3

forvalues i=1(1)360 {
replace A`i' = 0 if co_id==.
replace A`i' = 1 if a3==`i' & co_id==.
}

predict roe_hat

keep if co_id==.

keep a1 a2 a3 roe_hat
rename roe_hat roe_hat2
merge 1:1 a1 a2 a3 using Results

twoway (sc roe_hat_ roe_ind)  (sc roe_hat2 roe_ind)

save Results, replace

/* Second approach appears unbiased, but less efficient (in terms of MSE);
perhaps key is that dependent variable is unbiased, and that model does not
separate the same firm into different industries. Perhaps a hybrid approach? */

reg roe_hat2 roe_hat
predict roe_hat3

twoway (sc roe_hat_ roe_ind)  (sc roe_hat3 roe_ind)

/* Funnily enough, since the second approach appears unbiased, this can be used
to correct for the bias in the first approach (and it seems to work pretty
well!). A more sophisticated approach would be something like a mixed-effects
model which allows each firm to be part of multiple groups (with weights across
each) - I'm sure it's possible, but probably quite complex to program. */

reg roe_hat_ MS
reg roe_hat MS
reg roe_hat2 MS
reg roe_hat3 MS

// Estimate impact of concentration directly //

use CompanySim, clear

forvalues i=1(1)10 {
gen A`i' = 0
forvalues j=1(1)20 {
replace A`i' = A`i' + share_`j' if MS_`j'>(`i'-1)/10 & MS_`j'<`i'/10
}
}

reg roeT A1-A5 A7-A10

