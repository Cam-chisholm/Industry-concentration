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
replace equity_ratio = 0.75 if equity_ratio<0
replace equity_ratio = max(equity_ratio,.2) if equity_ratio~=.
replace equity_ratio = (equity - 0.8*intangibles)/equity if equity_ratio==.
replace equity_ratio = 0.75 if 0.8*intangibles>equity & type<6
replace equity_ratio = max(equity_ratio,.5) if equity_ratio~=. & type<6

drop if traded_==.
drop if in_sample==0

gen mining = substr(anzsic,1,1)=="B"

replace equity = equity*equity_ratio if equity_ratio>0 & equity_ratio<1
replace roe = roe/equity_ratio  if equity_ratio>0 & equity_ratio<1
replace equity4 = equity4*equity_ratio  if equity_ratio>0 & equity_ratio<1
replace debtequity = debtequity/equity_ratio  if equity_ratio>0 & equity_ratio<1
replace assetsrevenue = assetsrevenue*equity_ratio if equity_ratio>0 & equity_ratio<1
drop if debtequity>20 | assetsrevenue<0.2 

mixed roe i.ysc i.mining#i.ysc [fw=equity4] if roe>-2 & roe<2.2 || anzsic1: || anzsic2: || anzsic: || company:

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
sum beta [w=VA_ind]
scalar beta_avg = r(mean)
sum ROE [w=VA_ind]
scalar R_rp = 6

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

* combine domestic and foreign banks
replace anzsic = "K6221" if anzsic=="K6221a" | anzsic=="K6221b"
replace ind_name = "Banks" if anzsic=="K6221"
sum ROE if anzsic=="K6221" [w=equity]
replace ROE = r(mean) if anzsic=="K6221"
sum ROE_ra if anzsic=="K6221" [w=equity]
replace ROE_ra = r(mean) if anzsic=="K6221"
sum VA_ind if anzsic=="K6221"
replace VA_ind = r(sum) if anzsic=="K6221"
sum rev_ind if anzsic=="K6221"
replace rev_ind = r(sum) if anzsic=="K6221"
replace MS_4firm = MS_4firm*r(max)/r(sum)
sum profit if anzsic=="K6221"
replace profit = r(sum) if anzsic=="K6221"
sum equity if anzsic=="K6221"
replace equity = r(sum) if anzsic=="K6221"
bysort anzsic: drop if _n==2

save "Anzsic4Results", replace



* avg. ROE by no. of barriers to entry
scalar baseline = R_rf + R_rp
gen supernormal_profit = max(0,ROE_ra-baseline)*equity/100
gen normal_profit_deviation = (ROE_ra-baseline)*equity/100
replace profit = ROE*equity/100

drop if public==1

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

gen barriers = 0
replace barriers = 1 if natural_monopoly==1
replace barriers = 2 if network_effects==1
replace barriers = 3 if regulatory_barriers==1

* Aggregate to level 2 and level 1 ANZSICs
merge 1:1 anzsic using AnzsicNames
drop if _merge==2 & length(anzsic)>3
drop if public==1
gen aggregation = uncertain_flag==1 | equity<1000
replace aggregation = 1 if barriers==0 & (anzsic=="D2611" | anzsic=="D2612" | ///
anzsic=="D2619" | anzsic=="D2640" | anzsic=="F3312" | anzsic=="F3319" | ///
anzsic=="H4513" | anzsic=="I5292b" | anzsic2=="F36" | anzsic2=="F35" | ///
anzsic2=="D29" | anzsic2=="A01" | anzsic2=="A02" | anzsic2=="C11" | anzsic2=="D29" | ///
anzsic2=="C20" | anzsic2=="C22" | anzsic2=="E31" | anzsic2=="E32" | anzsic2=="F37" | ///
anzsic2=="G39" | (anzsic2=="G42" & anzsic~="G4231") | anzsic2=="H44" | ///
anzsic2=="J54" | anzsic2=="J55" | anzsic2=="L66" | (anzsic2=="N72" & anzsic~="N7212") | ///
anzsic2=="N73" | anzsic2=="S95")
replace aggregation = 0 if barriers>0 & barriers~=.

drop barriers 


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
sum traded if A==`x' & aggregation==1 [w=equity]
replace  traded = round(r(mean),1) if A==`x' & _merge==2 & length(anzsic)==3
}

drop if rev_ind==0 & length(anzsic)==3
drop if equity==0
drop if aggregation==1
drop A
replace anzsic1 = substr(anzsic,1,1)

gen barriers = 0
replace barriers = 1 if natural_monopoly==1
replace barriers = 2 if network_effects==1
replace barriers = 3 if regulatory_barriers==1

replace aggregation = equity<1000 & length(anzsic)==3
replace aggregation = 1 if barriers==0 & (anzsic1=="R" | anzsic=="A01")
replace aggregation = 0 if length(anzsic)==1 | (barriers>0 & barriers~=.)

drop barriers

local IND "A B C I R"

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
sum traded if anzsic1=="`x'" & aggregation==1 [w=equity]
replace  traded = round(r(mean),1) if anzsic=="`x'"
}

drop if aggregation==1 | ROE==.
drop aggregation _merge

replace supernormal_profit = max(0,ROE_ra-baseline)*equity/100 if supernormal_profit==.

gen barriers = 0
replace barriers = 1 if natural_monopoly==1
replace barriers = 2 if network_effects==1
replace barriers = 3 if regulatory_barriers==1

matrix SNP = J(3,1,0)
sum supernormal_profit if barriers==1
matrix SNP[1,1] = r(sum)
sum supernormal_profit if barriers==2
matrix SNP[2,1] = r(sum)
sum supernormal_profit if barriers==3
matrix SNP[3,1] = r(sum)
matrix list SNP

matrix P = J(3,1,0)
sum profit if barriers==1
matrix P[1,1] = r(sum)
sum profit if barriers==2
matrix P[2,1] = r(sum)
sum profit if barriers==3
matrix P[3,1] = r(sum)
matrix list P

matrix NP = (P[1,1]-SNP[1,1]\P[2,1]-SNP[2,1]\P[3,1]-SNP[3,1])
matrix list NP

gen sort = 0
replace sort = ROE_ra if ROE_ra>=10
gsort sort ROE

edit ind_name ROE profit equity ROE_ra if barriers==1
edit ind_name ROE profit equity ROE_ra if barriers==2
edit ind_name ROE profit equity ROE_ra if barriers==3
edit ind_name ROE profit equity ROE_ra if barriers==0

gen test str33 = ind_name
drop ind_name
rename test ind_name


gsort -equity
edit anzsic ind_name ROE ROE_ra profit equity rev_ind VA_ind barriers conc MS_4firm

gen sorting = ROE
replace sorting = ROE_ra + 10 if ROE_ra>baseline
gsort sorting

sum ROE if MS_4firm==0 [aw=equity]

* calculate additional amount paid by consumers
replace profit_pc = profit/rev_ind*100/.75
gen super_profit_pc = profit_pc*max(0,ROE_ra-baseline)/ROE
gen rev_ind_noSP = rev_ind*(100-super_profit_pc)/100

* calculate Harberger triangles
gen P_e = -.8
replace P_e = -.4 if substr(anzsic,1,1)=="D"
replace P_e = -.6 if substr(anzsic,1,1)=="G"
replace P_e = -.5 if substr(anzsic,1,3)=="J58"
replace P_e = -.43 if anzsic=="J5911"
replace P_e = -1 if substr(anzsic,1,1)=="I"
replace P_e = -1.1 if substr(anzsic,1,1)=="Q"
replace P_e = -0.85 if substr(anzsic,1,1)=="P"
replace P_e = -1.2 if substr(anzsic,1,1)=="R" | substr(anzsic,1,1)=="S"

gen quantity_change = (rev_ind_noSP-rev_ind)/rev_ind*P_e
gen Harberger = quantity_change*(rev_ind - rev_ind_noSP)/2

* estimate ROE spread by four-firm market share
egen X = fill(0 1 to 100)
replace X = . if X>100

lpoly ROE MS_4firm if MS_4firm>0 & barriers~=1 [aw=equity], bw(20) gen(Y) at(X)
gen ROE_2 = ROE^2
lpoly ROE_2 MS_4firm if MS_4firm>0 & barriers~=1 [aw=equity], bw(20) gen(Y2) at(X)
gen Y_se = sqrt(Y2 - Y^2)

edit X Y Y_se
