use CompanyVAShares, clear

merge m:1 asx year using Goodwill
drop if _merge==2
drop _merge

drop if id==5968 // Error

forvalues i=1(1)12 {
replace share_`i'=0 if share_`i'<.05
}

forvalues i=1(1)6 {
replace share2_`i'=0 if share2_`i'<.05
}

forvalues i=1(1)3 {
replace share1_`i'=0 if share1_`i'<.05
}

drop share3* MS4* VA* id anzsic3*

sort company ysc

tostring ysc, gen(Y)

gen id=company+" "+Y

reshape long share_ share2_ share1_ traded_ public_ anzsic_ anzsic2_ anzsic1_, i(id) j(A)

replace anzsic2_ = substr(anzsic_,1,3)
replace anzsic1_ = substr(anzsic_,1,1)

gen equity4 = equity*share_/10^6
gen revenue4 = revenue*share_/10^6
gen composite = equity4 + revenue4/2
rename anzsic_ anzsic
rename anzsic2_ anzsic2
rename anzsic1_ anzsic1

drop if traded_==.
drop if in_sample==0

gen mining = substr(anzsic,1,1)=="B"

replace equity = equity*equity_ratio if equity_ratio>0 & equity_ratio<1
replace roe = roe/equity_ratio if equity_ratio>0 & equity_ratio<1
replace equity4 = equity4*equity_ratio if equity_ratio>0 & equity_ratio<1
replace debtequity = debtequity/equity_ratio if equity_ratio>0 & equity_ratio<1
replace assetsrevenue = assetsrevenue*equity_ratio if equity_ratio>0 & equity_ratio<1
drop if debtequity>20 | assetsrevenue<0.2 | equity_ratio<0

mixed growth i.ysc i.mining#i.ysc [fw=revenue4] if growth<1 || anzsic1: || anzsic2: || anzsic: || company:

predict GROWTH
predict A1 A2 A4 C, reffects
gen GROWTH_A4 = GROWTH + A1 + A2 + A4
gen GROWTH_A2 = GROWTH + A1 + A2
gen GROWTH_A1 = GROWTH + A1
gen GROWTH_C = GROWTH_A4 + C

sort anzsic

encode anzsic, gen(A_4)
encode anzsic2, gen(A_2)
encode anzsic1, gen(A_1)
drop id
encode company, gen(id)
gen CO_A = company+anzsic
encode CO_A, gen(CA)
drop CO_A

gen GROWTH_A4a = 0
gen GROWTH_A2a = 0
gen GROWTH_A1a = 0
gen GROWTH_co = 0
gen equity_C = 0

forvalues i=1(1)386 {
sum GROWTH_C if A_4==`i' [w=revenue4]
replace GROWTH_A4a = r(mean) if A_4==`i'
sum GROWTH_A4 if A_4==`i' [w=revenue4]
replace GROWTH_A4 = r(mean) if A_4==`i'
}
replace GROWTH_A4a = GROWTH_A4 if GROWTH_A4a==0

forvalues i=1(1)78 {
sum GROWTH_C if A_2==`i' [w=revenue4]
replace GROWTH_A2a = r(mean) if A_2==`i'
sum GROWTH_A2 if A_2==`i' [w=revenue4]
replace GROWTH_A2 = r(mean) if A_2==`i'
}
replace GROWTH_A2a = GROWTH_A2 if GROWTH_A2a==0

forvalues i=1(1)19 {
sum GROWTH_C if A_1==`i' [w=revenue4]
replace GROWTH_A1a = r(mean) if A_1==`i'
sum GROWTH_A1 if A_1==`i' [w=revenue4]
replace GROWTH_A1 = r(mean) if A_1==`i'
}
replace GROWTH_A1a = GROWTH_A1 if GROWTH_A1a==0

forvalues i=1(1)1496 {
sum GROWTH_C if id==`i' [w=revenue4]
replace GROWTH_co = r(mean) if id==`i'
}

forvalues i=1(1)1732 {
sum GROWTH_C if CA==`i' [w=revenue4]
replace GROWTH_C = r(mean) if CA==`i'
sum equity4 if CA==`i'
replace equity4 = r(mean) if CA==`i'
sum revenue4 if CA==`i'
replace revenue4 = r(mean) if CA==`i'
}

keep company anzsic anzsic2 anzsic1 A_4 equity4 revenue4 GROWTH_A4-GROWTH_C GROWTH_A4a-GROWTH_A1a GROWTH_co type

save "Estimated company GROWTH_", replace

bysort company anzsic: keep if _n==1

forvalues i=1(1)386 {
sum equity4 if A_4==`i' 
replace equity4 = r(sum) if A_4==`i'
sum revenue4 if A_4==`i'
replace revenue4 = r(sum) if A_4==`i'
}

gen missing = GROWTH_C==.
bysort anzsic missing: gen N = _N
replace N = . if missing==1
drop missing

bysort anzsic: egen equity_ind_ = max(equity4)
bysort anzsic: egen rev_ind_ = max(revenue4)

save "Estimated company GROWTH", replace

bysort anzsic: keep if _n==1
keep anzsic* GROWTH_A4-GROWTH_A1 GROWTH_A4a-GROWTH_A1a N equity_ind_ rev_ind_

save "Estimated industry GROWTH", replace

bysort anzsic2: keep if _n==1
keep anzsic2 anzsic1 GROWTH_A2 GROWTH_A1 GROWTH_A2a-GROWTH_A1a

save "Estimated industry2 GROWTH", replace

bysort anzsic1: keep if _n==1
keep anzsic1 GROWTH_A1 GROWTH_A1a

save "Estimated industry1 GROWTH", replace

use "Estimated company GROWTH_", clear

keep company GROWTH_co

bysort company: keep if _n==1

save "Estimated company GROWTH_", replace

use Industry, clear

merge 1:1 anzsic company using "Estimated company GROWTH"
drop if _merge==2
drop _merge GROWTH_A4-GROWTH_A1 GROWTH_A4a-GROWTH_A1a type equity_ind_ rev_ind_

merge m:1 anzsic using "Estimated industry GROWTH"
drop if _merge==2
drop _merge GROWTH_A2-GROWTH_A1 GROWTH_A2a-GROWTH_A1a

replace anzsic2 = substr(anzsic,1,3)

merge m:1 anzsic2 using "Estimated industry2 GROWTH"
drop if _merge==2
drop _merge GROWTH_A1 GROWTH_A1a

replace anzsic1 = substr(anzsic,1,1)

merge m:1 anzsic1 using "Estimated industry1 GROWTH"
drop _merge GROWTH_co

merge m:1 company using "Estimated company GROWTH_"
drop if _merge==2
drop _merge

/*
gen GROWTH = GROWTH_C
replace GROWTH = GROWTH_co if GROWTH==.
replace GROWTH = GROWTH_A4a if GROWTH==.
replace GROWTH = GROWTH_A2a if GROWTH==.
replace GROWTH = GROWTH_A1a if GROWTH==.
gen GROWTH_other = GROWTH_A4
replace GROWTH_other = GROWTH_A2 if GROWTH_other==.
replace GROWTH_other = GROWTH_A1 if GROWTH_other==.
*/

gsort anzsic -marketshare
by anzsic: gen n=_n
by anzsic: egen MS = sum(marketshare) if N~=.
replace N = 0 if N==.
by anzsic: egen N_ = max(N)
drop N

gen GROWTH = GROWTH_A4a if N>=4 | (N>=3 & MS>60)
replace GROWTH = GROWTH_A4a*MS/100 + GROWTH_A4*(100-MS)/100 if GROWTH==. | N<=2
by anzsic: egen GROWTH_ = max(GROWTH)
replace GROWTH = GROWTH_ if GROWTH==.
drop GROWTH_
replace GROWTH = GROWTH_A4 if GROWTH==.
replace GROWTH = GROWTH_A2 if GROWTH==.
replace GROWTH = GROWTH_A1 if GROWTH==.

drop n
gsort anzsic -marketshare
by anzsic: gen n = _n
drop if n>4

by anzsic: egen MS_4firm = sum(marketshare)
keep if n==1

keep GROWTH anzsic

save "Estimated industry growth", replace

use Anzsic4Results, clear

merge 1:1 anzsic using "Estimated industry growth"
drop _merge

merge 1:1 anzsic using IndustryGrowth
drop if _merge==2
drop _merge

