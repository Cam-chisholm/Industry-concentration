use IndPredict, clear
keep AA
rename AA anzsic
save "ROE Bootstrap", replace

local reps 2000

forvalues a=1(1)`reps' {

use CompanyVAShares, clear
bsample

forvalues i=1(1)12 {
rename anzsic_`i' anzsic
merge m:1 anzsic using IndustryDummies
drop if _merge==2
drop _merge
gen AA_`i' = substr(anzsic,1,1) if L1_flag==1
replace AA_`i' = substr(anzsic,1,3) if L2_flag==1
replace AA_`i' = substr(anzsic,1,4) if L3_flag==1
replace AA_`i' = substr(anzsic,1,3) if L3_flag==1 & L4_flag==0 & substr(anzsic,4,1)=="0"
replace AA_`i' = anzsic if L4_flag==1
replace AA_`i' = "misc" if L1_flag==0 & L2_flag==0 & L3_flag==0 & L4_flag==0
drop L1_flag L2_flag L3_flag L4_flag ANZSIC
rename anzsic anzsic_`i'
}

multencode AA_1-AA_12, gen(A_1 A_2 A_3 A_4 A_5 A_6 A_7 A_8 A_9 A_10 A_11 A_12)

* calculate share in each industry group
forvalues i=1(1)300 {
gen S`i' = 0
forvalues j=1(1)12 {
replace S`i' = share_`j' if A_`j'==`i'
}
sum S`i', meanonly
if (r(mean)==0) {
drop S`i'
}
}

reg roe S* if roe>-.5 & roe<.7 & type>3 & debtequity<100 [iw=equity]
est sto IndDum
reg roc S* if roc>-.5 & roc<.7 & type>3 & debtequity<100 [iw=equity]
est sto IndDumROC
tobit roe S* if type>3 & debtequity<100 [iw=equity], ll(-.3) ul(.5)
est sto IndDumTobit
tobit roc S* if type>3 & debtequity<100 [iw=equity], ll(-.3) ul(.5)
est sto IndDumROCTobit

* Prediction by industry
use Indpredict, clear

est res IndDum
predict ROE
est res IndDumROC
predict ROC
est res IndDumTobit
predict ROE2
est res IndDumROCTobit
predict ROC2

drop S*

gen sorting = max(1,min(4,strlen(AA)-1))
gsort -sorting -ROE

* Estimate ROE/ROC at each industry level
rename AA anzsic

local obs = _N + 1
set obs `obs'
replace anzsic="M" in `obs'
replace sorting=1 in `obs'
replace ROE = 0 in `obs'
replace ROE2 = 0 in `obs'
replace ROC = 0 in `obs'
replace ROC2 = 0 in `obs'

forvalues i=4(-1)1 {
merge 1:1 anzsic using Industry_`i'
drop if _merge==2
drop _merge
rename rev_ind rev_ind`i'
rename VA_ind VA_ind`i'
}

gen ANZSIC4 = anzsic if sorting==4
gen ANZSIC3 = substr(anzsic,1,4) if sorting>=3
gen ANZSIC2 = substr(anzsic,1,3) if sorting>=2
gen ANZSIC1 = substr(anzsic,1,1)

egen rev_ind = rowmean(rev_ind*)
egen VA_ind = rowmean(VA_ind*)

forvalues i=3(-1)1 {
local k = `i'+1
encode ANZSIC`i', gen(B)
sum B
local max = r(max)
sort B
forvalues j=1(1)`max' {
sum VA_ind if B==`j' & sorting>`i'
replace VA_ind = VA_ind - r(sum) if B==`j' & sorting==`i'
replace VA_ind = 0 if ROE==.
}
drop B
}

gen temp1 = VA_ind*ROE
gen temp2 = VA_ind*ROE2
gen temp_1 = VA_ind*ROC
gen temp_2 = VA_ind*ROC2

replace temp1 = 0 if temp1==.
replace temp2 = 0 if temp2==.
replace temp_1 = 0 if temp_1==.
replace temp_2 = 0 if temp_2==.

gen ROE_ = 0
gen ROE_2 = 0
gen ROC_ = 0
gen ROC_2 = 0
gen temp3 = 0

replace ROE_ = ROE if sorting==5
replace ROE_2 = ROE2 if sorting==5
replace ROC_ = ROC if sorting==5
replace ROC_2 = ROC2 if sorting==5

gen temp1_ = 0
gen temp_1_ = 0
gen temp2_ = 0
gen temp_2_ = 0

forvalues i=3(-1)1 {
encode ANZSIC`i', gen(B)
sum B
local max = r(max)
sort B
forvalues j=1(1)`max' {
sum VA_ind if B==`j' & sorting>=`i'
replace temp3 = r(sum) if B==`j' & sorting==`i'
local TEMP "temp1 temp2 temp_1 temp_2"
foreach x of local TEMP {
sum `x' if B==`j' & sorting>=`i'
replace `x'_ = r(sum) if B==`j' & sorting==`i'
}
}
drop B
replace temp3 = 0 if temp1_==0
replace ROE_ = temp1_/temp3 if sorting==`i'
replace ROE_2 = temp2_/temp3 if sorting==`i'
replace ROC_ = temp_1_/temp3 if sorting==`i'
replace ROC_2 = temp_2_/temp3 if sorting==`i'
}
replace ROE_ = ROE if sorting==4
replace ROE_2 = ROE2 if sorting==4
replace ROC_ = ROC if sorting==4
replace ROC_2 = ROC2 if sorting==4
drop temp*

keep anzsic ROE* ROC*
rename ROE _ROE_`a'
rename ROE2 _ROE2_`a'
rename ROC _ROC_`a'
rename ROC2 _ROC2_`a'
rename ROE_ ROE__`a'
rename ROE_2 ROE_2_`a'
rename ROC_ ROC__`a'
rename ROC_2 ROC_2_`a'
merge 1:1 anzsic using "ROE Bootstrap"
drop if _merge==2
drop _merge
save "ROE Bootstrap", replace
}

order ROC_2_* ROC__* ROE_2_* ROE__* _ROC2_* _ROC_* _ROE2_* _ROE_* , seq
order anzsic, before(ROC_2_1)
save "ROE Bootstrap", replace

use "ROE Bootstrap", clear
putmata X=(ROE__*) anzsic, replace
mata
anzsic=anzsic[1..rows(X)-1]
roe = J(2000,rows(X)-1,0)
for(i=1; i<=rows(X)-1; i++) {
i
roe[.,i] = sort(X[i,.]',1)
}
lb = roe[51,.]'
ub = roe[1950,.]'
median = (roe[1000,.]'+roe[1001,.]')/2
sd = diagonal(sqrt(variance(roe)))
end

clear
getmata anzsic lb ub sd median
