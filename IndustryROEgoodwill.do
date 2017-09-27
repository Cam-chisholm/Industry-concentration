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

mixed roe i.ysc i.mining#i.ysc [fw=equity4] if roe>-1.9 & roe<2.1 || anzsic1: || anzsic2: || anzsic: || company:

predict ROE
predict A1 A2 A4 C, reffects
gen ROE_A4 = ROE + A1 + A2 + A4
gen ROE_A2 = ROE + A1 + A2
gen ROE_A1 = ROE + A1
gen ROE_C = ROE_A4 + C

sort anzsic

encode anzsic, gen(A_4)
encode anzsic2, gen(A_2)
encode anzsic1, gen(A_1)
drop id
encode company, gen(id)
gen CO_A = company+anzsic
encode CO_A, gen(CA)
drop CO_A

gen ROE_A4a = 0
gen ROE_A2a = 0
gen ROE_A1a = 0
gen ROE_co = 0
gen equity_C = 0

forvalues i=1(1)386 {
sum ROE_C if A_4==`i' [w=equity4]
replace ROE_A4a = r(mean) if A_4==`i'
sum ROE_A4 if A_4==`i' [w=equity4]
replace ROE_A4 = r(mean) if A_4==`i'
}
replace ROE_A4a = ROE_A4 if ROE_A4a==0

forvalues i=1(1)78 {
sum ROE_C if A_2==`i' [w=equity4]
replace ROE_A2a = r(mean) if A_2==`i'
sum ROE_A2 if A_2==`i' [w=equity4]
replace ROE_A2 = r(mean) if A_2==`i'
}
replace ROE_A2a = ROE_A2 if ROE_A2a==0

forvalues i=1(1)19 {
sum ROE_C if A_1==`i' [w=equity4]
replace ROE_A1a = r(mean) if A_1==`i'
sum ROE_A1 if A_1==`i' [w=equity4]
replace ROE_A1 = r(mean) if A_1==`i'
}
replace ROE_A1a = ROE_A1 if ROE_A1a==0

forvalues i=1(1)1496 {
sum ROE_C if id==`i' [w=equity4]
replace ROE_co = r(mean) if id==`i'
}

forvalues i=1(1)1732 {
sum ROE_C if CA==`i' [w=equity4]
replace ROE_C = r(mean) if CA==`i'
sum equity4 if CA==`i'
replace equity4 = r(mean) if CA==`i'
sum revenue4 if CA==`i'
replace revenue4 = r(mean) if CA==`i'
}

keep company anzsic anzsic2 anzsic1 A_4 equity4 revenue4 ROE_A4-ROE_C ROE_A4a-ROE_A1a ROE_co type

save "Estimated company ROE_", replace
save "Estimated company ROE plus", replace

bysort company anzsic: keep if _n==1

forvalues i=1(1)386 {
sum equity4 if A_4==`i' 
replace equity4 = r(sum) if A_4==`i'
sum revenue4 if A_4==`i'
replace revenue4 = r(sum) if A_4==`i'
}

gen missing = ROE_C==.
bysort anzsic missing: gen N = _N
replace N = . if missing==1
drop missing

bysort anzsic: egen equity_ind_ = max(equity4)
bysort anzsic: egen rev_ind_ = max(revenue4)

save "Estimated company ROE", replace

bysort anzsic: keep if _n==1
keep anzsic* ROE_A4-ROE_A1 ROE_A4a-ROE_A1a N equity_ind_ rev_ind_

save "Estimated industry ROE", replace

bysort anzsic2: keep if _n==1
keep anzsic2 anzsic1 ROE_A2 ROE_A1 ROE_A2a-ROE_A1a

save "Estimated industry2 ROE", replace

bysort anzsic1: keep if _n==1
keep anzsic1 ROE_A1 ROE_A1a

save "Estimated industry1 ROE", replace

use "Estimated company ROE_", clear

keep company ROE_co

bysort company: keep if _n==1

save "Estimated company ROE_", replace

use Industry, clear

merge 1:1 anzsic company using "Estimated company ROE"
drop if _merge==2
drop _merge ROE_A4-ROE_A1 ROE_A4a-ROE_A1a type equity_ind_ rev_ind_

merge m:1 anzsic using "Estimated industry ROE"
drop if _merge==2
drop _merge ROE_A2-ROE_A1 ROE_A2a-ROE_A1a

replace anzsic2 = substr(anzsic,1,3)

merge m:1 anzsic2 using "Estimated industry2 ROE"
drop if _merge==2
drop _merge ROE_A1 ROE_A1a

replace anzsic1 = substr(anzsic,1,1)

merge m:1 anzsic1 using "Estimated industry1 ROE"
drop _merge ROE_co

merge m:1 company using "Estimated company ROE_"
drop if _merge==2
drop _merge

/*
gen ROE = ROE_C
replace ROE = ROE_co if ROE==.
replace ROE = ROE_A4a if ROE==.
replace ROE = ROE_A2a if ROE==.
replace ROE = ROE_A1a if ROE==.
gen ROE_other = ROE_A4
replace ROE_other = ROE_A2 if ROE_other==.
replace ROE_other = ROE_A1 if ROE_other==.
*/

gsort anzsic -marketshare
by anzsic: gen n=_n
by anzsic: egen MS = sum(marketshare) if N~=.
replace N = 0 if N==.
by anzsic: egen N_ = max(N)
drop N

gen ROE = ROE_A4a if N>=4 | (N>=3 & MS>60)
replace ROE = ROE_A4a*MS/100 + ROE_A4*(100-MS)/100 if ROE==. | N<=2
by anzsic: egen ROE_ = max(ROE)
replace ROE = ROE_ if ROE==.
drop ROE_
replace ROE = ROE_A4 if ROE==.
replace ROE = ROE_A2 if ROE==.
replace ROE = ROE_A1 if ROE==.

drop n
gsort anzsic -marketshare
by anzsic: gen n = _n
drop if n>4

by anzsic: egen MS_4firm = sum(marketshare)
keep if n==1

keep anzsic-profit_pc N_ ROE MS_4firm equity_ind_ rev_ind_ equity4

merge 1:1 anzsic using AnzsicNames
drop if _merge==2
drop _merge

merge 1:1 anzsic using IndustryTradability
drop if _merge==2
drop _merge

gen profit = profit*rev_ind/100

merge 1:1 anzsic using "Estimated industry ROE"
drop if _merge==2
replace N_=0 if N_==.
gen uncertain_flag = 0
replace uncertain_flag = 1 if N_==. | N==. | N<=1

drop ROE_A4-ROE_A1a _merge

merge 1:1 anzsic using AnzsicBeta
drop if _merge==2
drop _merge
replace ROE = ROE*100

scalar R_rf = 3.7
sum beta if public==0 & traded==0 [w=VA_ind]
scalar beta_avg = r(mean)
sum ROE if public==0 & traded==0 [w=VA_ind]
scalar R_rp = 5.6

gen ROE_ra = ROE + (1-beta)*R_rp
gen equity_ind = min(profit/ROE,profit*.75/max(8,ROE))*100 // .75 accounts for the average tax rate
replace equity_ind = profit*.75/8*100 if equity_ind<0 & ROE~=. & profit>0
replace equity_ind = profit/8*100 if equity_ind<0 & ROE~=. & profit<0
replace equity_ind = 0 if equity_ind<0
gen equity_obs = equity_ind_
replace equity_ind_ = equity_ind_*rev_ind/(rev_ind_)
gen equity = equity_ind
replace equity = min(profit*.75/max(5,ROE)*100,equity_ind_) if ROE<8 & equity_ind_>equity_ind & profit>0

gsort -ROE

merge 1:1 anzsic using IndustryBarriers
drop if _merge==2
drop _merge

* avg. ROE by no. of barriers to entry
scalar baseline = 10
gen supernormal_profit = max(0,ROE_ra-baseline)*equity/100

drop if public==1 | traded==1

* avg. ROE by concentration group
matrix cut = (25,50,75)
gen conc = 0
replace conc = 1 if MS_4firm>cut[1,1] & MS_4firm<=cut[1,2]
replace conc = 2 if MS_4firm>cut[1,2] & MS_4firm<=cut[1,3]
replace conc = 3 if MS_4firm>cut[1,3]

reg ROE i.conc if uncertain_flag==0 [w=equity]
matrix R = _b[_cons] \ _b[_cons] + _b[1.conc] \ _b[_cons] + _b[2.conc] ///
\ _b[_cons] + _b[3.conc] 
reg ROE_ra i.conc if uncertain_flag==0 [w=equity]
matrix R_ra = _b[_cons] \ _b[_cons] + _b[1.conc] \ _b[_cons] + _b[2.conc] ///
\ _b[_cons] + _b[3.conc] 
matrix SNR = R_ra - J(4,1,baseline)

matrix E = J(4,1,0)
* avg. profit by concentration group
sum equity if MS_4firm<=cut[1,1]
matrix E[1,1] = r(sum)/1000
sum equity if MS_4firm>cut[1,1] & MS_4firm<=cut[1,2]
matrix E[2,1] = r(sum)/1000
sum equity if MS_4firm>cut[1,2] & MS_4firm<=cut[1,3]
matrix E[3,1] = r(sum)/1000
sum equity if MS_4firm>cut[1,3]
matrix E[4,1] = r(sum)/1000
matrix list E
matrix list R
matrix list SNR

reg ROE natural_monopoly regulatory_barriers network_effects if uncertain_flag==0 [w=equity]
matrix R = _b[_cons] \ _b[_cons] + _b[natural_monopoly] \ _b[_cons] + _b[regulatory_barriers] \ _b[_cons] + _b[network_effects]
reg ROE_ra natural_monopoly regulatory_barriers network_effects if uncertain_flag==0 [w=equity]
matrix R_ra = _b[_cons] \ _b[_cons] + _b[natural_monopoly] \ _b[_cons] + _b[regulatory_barriers] \ _b[_cons] + _b[network_effects]
matrix SNR = R_ra - J(4,1,baseline)

reg MS_4firm natural_monopoly regulatory_barriers network_effects if uncertain_flag==0  [w=equity]
matrix M = _b[_cons] \ _b[_cons] + _b[natural_monopoly] \ _b[_cons] + _b[regulatory_barriers] \ _b[_cons] + _b[network_effects]

matrix E = J(4,1,0)
* avg. profit by no. of barriers to entry
sum equity if natural_monopoly==0 & network_effects==0 & regulatory_barriers==0
matrix E[1,1] = r(sum)/1000
sum equity if natural_monopoly==1
matrix E[2,1] = r(sum)/1000
sum equity if regulatory_barriers==1
matrix E[3,1] = r(sum)/1000
sum equity if network_effects==1
matrix E[4,1] = r(sum)/1000
matrix list M
matrix list R
matrix list SNR
matrix list E


/*
matrix R_bounds = J(3,4,0)
matrix M_bounds = J(3,2,0)
gen MS4 = MS_4firm/100
* Bounds
sum ROE if barriers_count==0 & traded==0 & public==0 [w=equity], detail
matrix R_bounds[1,1] = R[1,1] - r(sd)
matrix R_bounds[1,2] = R[1,1] + r(sd)
sum ROE if barriers_count==1 & traded==0 & public==0 [w=equity], detail
matrix R_bounds[2,1] = R[2,1] - r(sd)
matrix R_bounds[2,2] = R[2,1] + r(sd)
sum ROE if barriers_count==2 & traded==0 & public==0 [w=equity], detail
matrix R_bounds[3,1] = R[3,1] - r(sd)
matrix R_bounds[3,2] = R[3,1] + r(sd)
glm MS4 if barriers_count==0 & ROE~=. [aw=VA_ind], family(binomial) link(logit)
matrix T = e(V)
matrix M_bounds[1,1] = 1/(1+exp(-(_b[_cons]-sqrt(1+T[1,1]))))*100
matrix M_bounds[1,2] = 1/(1+exp(-(_b[_cons]+sqrt(1+T[1,1]))))*100
reg ROE MS_4firm [w=VA_ind] if public==0 & traded==0 & barriers_count==0
matrix R_bounds[1,3] = _b[_cons] + _b[MS_4firm]*M_bounds[1,1]
matrix R_bounds[1,4] = _b[_cons] + _b[MS_4firm]*M_bounds[1,2]
glm MS4 if barriers_count==1 & ROE~=. [aw=VA_ind], family(binomial) link(logit)
matrix T = e(V)
matrix M_bounds[2,1] = 1/(1+exp(-(_b[_cons]-sqrt(1+T[1,1]))))*100
matrix M_bounds[2,2] = 1/(1+exp(-(_b[_cons]+sqrt(1+T[1,1]))))*100
reg ROE MS_4firm [w=VA_ind] if public==0 & traded==0 & barriers_count==1
matrix R_bounds[2,3] = _b[_cons] + _b[MS_4firm]*M_bounds[2,1]
matrix R_bounds[2,4] = _b[_cons] + _b[MS_4firm]*M_bounds[2,2]
glm MS4 if barriers_count==2 & ROE~=. [aw=VA_ind], family(binomial) link(logit)
matrix T = e(V)
matrix M_bounds[3,1] = 1/(1+exp(-(_b[_cons]-sqrt(1+T[1,1]))))*100
matrix M_bounds[3,2] = 1/(1+exp(-(_b[_cons]+sqrt(1+T[1,1]))))*100
reg ROE MS_4firm [w=VA_ind] if public==0 & traded==0 & barriers_count==2
matrix R_bounds[3,3] = _b[_cons] + _b[MS_4firm]*M_bounds[3,1]
matrix R_bounds[3,4] = _b[_cons] + _b[MS_4firm]*M_bounds[3,2]

matrix list M_bounds
matrix list R_bounds
*/

* Aggregate to level 2 and level 1 ANZSICs
merge 1:1 anzsic using AnzsicNames
drop if _merge==2 & length(anzsic)>3
drop if traded==1 | public==1
gen aggregation = uncertain_flag==1 | equity<1000
replace aggregation = 1 if anzsic=="D2611" | anzsic=="D2612" | anzsic=="D2619" | anzsic=="D2640"


sort anzsic
replace anzsic2 = substr(anzsic,1,3) if length(anzsic)>=3
encode anzsic2, gen(A)

forvalues x=1(1)86 {
sum VA_ind if A==`x' & aggregation==1
replace VA_ind = r(sum) if A==`x' & _merge==2 & length(anzsic)==3
sum rev_ind if A==`x' & aggregation==1
replace rev_ind = r(sum) if A==`x' & _merge==2 & length(anzsic)==3
sum profit if A==`x' & aggregation==1
replace profit = r(sum) if A==`x' & _merge==2 & length(anzsic)==3
sum equity if A==`x' & aggregation==1
replace equity = r(sum) if A==`x' & _merge==2 & length(anzsic)==3
sum ROE if A==`x' & aggregation==1 [w=equity]
replace ROE = r(mean) if A==`x' & _merge==2 & length(anzsic)==3
sum ROE_ra if A==`x' & aggregation==1 [w=equity]
replace ROE_ra = r(mean) if A==`x' & _merge==2 & length(anzsic)==3
sum MS_4firm if A==`x' & aggregation==1 [w=equity]
replace MS_4firm = r(mean) if A==`x' & _merge==2 & length(anzsic)==3
sum natural_monopoly if A==`x' & aggregation==1 [w=equity]
replace natural_monopoly = round(r(mean),1) if A==`x' & _merge==2 & length(anzsic)==3
sum network_effects if A==`x' & aggregation==1 [w=equity]
replace network_effects = round(r(mean),1) if A==`x' & _merge==2 & length(anzsic)==3
sum regulatory_barriers if A==`x' & aggregation==1 [w=equity]
replace regulatory_barriers = round(r(mean),1) if A==`x' & _merge==2 & length(anzsic)==3
replace ind_name = "Other " + ind_name if A==`x' & _merge==2 & length(anzsic)==3
}

drop if rev_ind==0 & length(anzsic)==3
drop if equity==0
drop if aggregation==1
drop A
replace anzsic1 = substr(anzsic,1,1)

replace aggregation = equity<1000 & length(anzsic)==3

local IND "B C I"

foreach x of local IND {
sum VA_ind if anzsic1=="`x'" & aggregation==1
replace VA_ind = r(sum) if anzsic=="`x'"
sum rev_ind if anzsic1=="`x'" & aggregation==1
replace rev_ind = r(sum) if anzsic=="`x'"
sum profit if anzsic1=="`x'" & aggregation==1
replace profit = r(sum) if anzsic=="`x'" 
sum equity if anzsic1=="`x'" & aggregation==1
replace equity = r(sum) if anzsic=="`x'"
sum ROE if anzsic1=="`x'" & aggregation==1 [w=equity]
replace ROE = r(mean) if anzsic=="`x'"
sum ROE_ra if anzsic1=="`x'" & aggregation==1 [w=equity]
replace ROE_ra = r(mean) if anzsic=="`x'"
sum MS_4firm if anzsic1=="`x'" & aggregation==1 [w=equity]
replace MS_4firm = r(mean) if anzsic=="`x'"
sum natural_monopoly if anzsic1=="`x'" & aggregation==1 [w=equity]
replace natural_monopoly = round(r(mean),1) if anzsic=="`x'"
sum network_effects if anzsic1=="`x'" & aggregation==1 [w=equity]
replace network_effects = round(r(mean),1) if anzsic=="`x'"
sum regulatory_barriers if anzsic1=="`x'" & aggregation==1 [w=equity]
replace regulatory_barriers = round(r(mean),1) if anzsic=="`x'"
replace ind_name = "Other " + ind_name if anzsic=="`x'"
}

drop if aggregation==1 & length(anzsic)==3 & (substr(anzsic,1,1)=="B" | substr(anzsic,1,1)=="C" | substr(anzsic,1,1)=="I")
drop aggregation _merge

* three industries left - aggregate into a similar two-digit
sum VA_ind if anzsic=="F35" | anzsic=="F3501"
replace VA_ind = r(sum) if anzsic=="F3501"
sum VA_ind if anzsic=="J55" | anzsic=="J5511"
replace VA_ind = r(sum) if anzsic=="J5511"
sum VA_ind if anzsic=="R91" | anzsic=="R9114"
replace VA_ind = r(sum) if anzsic=="R911"

sum equity if anzsic=="F35" | anzsic=="F3501"
replace equity = r(sum) if anzsic=="F3501"
sum equity if anzsic=="J55" | anzsic=="J5511"
replace equity = r(sum) if anzsic=="J5511"
sum equity if anzsic=="R91" | anzsic=="R9114"
replace equity = r(sum) if anzsic=="R911"

sum rev_ind if anzsic=="F35" | anzsic=="F3501"
replace rev_ind = r(sum) if anzsic=="F3501"
sum rev_ind if anzsic=="J55" | anzsic=="J5511"
replace rev_ind = r(sum) if anzsic=="J5511"
sum rev_ind if anzsic=="R91" | anzsic=="R9114"
replace rev_ind = r(sum) if anzsic=="R911"

sum profit if anzsic=="F35" | anzsic=="F3501"
replace profit = r(sum) if anzsic=="F3501"
sum profit if anzsic=="J55" | anzsic=="J5511"
replace profit = r(sum) if anzsic=="J5511"
sum profit if anzsic=="R91" | anzsic=="R9114"
replace profit = r(sum) if anzsic=="R911"

sum ROE if anzsic=="F35" | anzsic=="F3501"
replace ROE = r(mean) if anzsic=="F3501"
sum ROE if anzsic=="J55" | anzsic=="J5511"
replace ROE = r(mean) if anzsic=="J5511"
sum ROE if anzsic=="R91" | anzsic=="R9114"
replace ROE = r(mean) if anzsic=="R911"

sum ROE_ra if anzsic=="F35" | anzsic=="F3501"
replace ROE_ra = r(mean) if anzsic=="F3501"
sum ROE_ra if anzsic=="J55" | anzsic=="J5511"
replace ROE_ra = r(mean) if anzsic=="J5511"
sum ROE_ra if anzsic=="R91" | anzsic=="R9114"
replace ROE_ra = r(mean) if anzsic=="R911"

sum MS_4firm if anzsic=="F35" | anzsic=="F3501"
replace MS_4firm = r(mean) if anzsic=="F3501"
sum MS_4firm if anzsic=="J55" | anzsic=="J5511"
replace MS_4firm = r(mean) if anzsic=="J5511"
sum MS_4firm if anzsic=="R91" | anzsic=="R9114"
replace MS_4firm = r(mean) if anzsic=="R9114"

drop if anzsic=="F35" | anzsic=="J55" | anzsic=="R91"
drop if ROE==.

gen barriers = 0
replace barriers = 1 if natural_monopoly==1
replace barriers = 2 if network_effects==1
replace barriers = 3 if regulatory_barriers==1

gsort ROE_ra

edit ind_name ROE_ra profit equity 

gsort -equity
edit anzsic ind_name ROE ROE_ra profit equity rev_ind VA_ind barriers conc MS_4firm
