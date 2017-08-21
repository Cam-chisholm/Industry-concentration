use Industry, clear
keep anzsic
bysort anzsic: keep if _n==1
save "ROE Bootstrap", replace

local reps 200

forvalues a=1(1)`reps' {

use CompanyVAShares, clear

drop if id==5968 // Dow Chemical

forvalues i=1(1)12 {
replace share_`i'=0 if share_`i'<.1
}

forvalues i=1(1)6 {
replace share2_`i'=0 if share2_`i'<.1
}

forvalues i=1(1)3 {
replace share1_`i'=0 if share1_`i'<.1
}

drop share3* MS4* VA* id anzsic3*

sort company ysc

tostring ysc, gen(Y)

gen id=company+" "+Y

reshape long share_ share2_ share1_ traded_ public_ anzsic_ anzsic2_ anzsic1_, i(id) j(A)
bsample, cl(company anzsic_)

replace anzsic2_ = substr(anzsic_,1,3)
replace anzsic1_ = substr(anzsic_,1,1)

drop if traded_==.
drop if in_sample==0

gen equity4 = equity*share_/10^6
gen revenue4 = revenue*share_/10^6
gen composite = equity4 + revenue4/2
rename anzsic_ anzsic
rename anzsic2_ anzsic2
rename anzsic1_ anzsic1

* simulate values for extreme ROEs (closer to a normal distribution)
gen rand = runiform()*runiform()
gen roe_sim = roe
replace roe_sim = rand*.4 + 0.8 if roe>.8
replace roe_sim = roe if roe_sim>roe & roe>.8
replace roe_sim = rand*.4 - 1 if roe<-.6
replace roe_sim = roe if roe_sim<roe & roe<-.6

*mixed roe i.ysc if roe<0.8 & roe>-.6 [fw=revenue4] || anzsic1: || anzsic2: || anzsic:
*mixed roe i.ysc if roe<0.8 & roe>-.6 [fw=composite] || anzsic1: || anzsic2: || anzsic:
*mixed roe i.ysc if roe<0.8 & roe>-.6 [fw=equity4] || anzsic1: || anzsic2: || anzsic: || company:

mixed roe_sim i.ysc [fw=equity4] || anzsic1: || anzsic2: || anzsic: || company:, nostd iterate(15)

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

gen ROE_A4a = 0
gen ROE_A2a = 0
gen ROE_A1a = 0

forvalues i=1(1)382 {
sum ROE_C if A_4==`i' [w=equity4]
replace ROE_A4a = r(mean) if A_4==`i'
sum ROE_A4 if A_4==`i' [w=equity4]
replace ROE_A4 = r(mean) if A_4==`i'
}

forvalues i=1(1)79 {
sum ROE_C if A_2==`i' [w=equity4]
replace ROE_A2a = r(mean) if A_2==`i'
sum ROE_A2 if A_2==`i' [w=equity4]
replace ROE_A2 = r(mean) if A_2==`i'
}

forvalues i=1(1)19 {
sum ROE_C if A_1==`i' [w=equity4]
replace ROE_A1a = r(mean) if A_1==`i'
sum ROE_A1 if A_1==`i' [w=equity4]
replace ROE_A1 = r(mean) if A_1==`i'
}

keep company anzsic anzsic2 anzsic1 equity4 revenue4 roe_sim ROE_A4-ROE_C ROE_A4a-ROE_A1a

bysort company anzsic: keep if _n==1

save "Estimated company ROE", replace

bysort anzsic: keep if _n==1
keep anzsic* ROE_A4-ROE_A1 ROE_A4a-ROE_A1a

save "Estimated industry ROE", replace

bysort anzsic2: keep if _n==1
keep anzsic2 anzsic1 ROE_A2 ROE_A1 ROE_A2a-ROE_A1a

save "Estimated industry2 ROE", replace

bysort anzsic1: keep if _n==1
keep anzsic1 ROE_A1 ROE_A1a

save "Estimated industry1 ROE", replace

use Industry, clear

merge 1:1 anzsic company using "Estimated company ROE"
drop if _merge==2
drop _merge ROE_A4-ROE_A1 ROE_A4a-ROE_A1a

merge m:1 anzsic using "Estimated industry ROE"
drop if _merge==2
drop _merge ROE_A2-ROE_A1 ROE_A2a-ROE_A1a

replace anzsic2 = substr(anzsic,1,3)

merge m:1 anzsic2 using "Estimated industry2 ROE"
drop if _merge==2
drop _merge ROE_A1 ROE_A1a

replace anzsic1 = substr(anzsic,1,1)

merge m:1 anzsic1 using "Estimated industry1 ROE"
drop _merge

gen ROE = ROE_C
replace ROE = ROE_A4 if ROE==.
replace ROE = ROE_A2 if ROE==.
replace ROE = ROE_A1 if ROE==.
gen ROE_other = ROE_A4
replace ROE_other = ROE_A2 if ROE_other==.
replace ROE_other = ROE_A1 if ROE_other==.

drop company equity4-ROE_A1a

gsort anzsic -marketshare
by anzsic: gen n=_n

reshape wide marketshare ROE, i(anzsic) j(n)

forvalues i=1(1)7 {
replace marketshare`i' = 0 if marketshare`i'==.
replace ROE`i' = 0 if ROE`i'==.
}

gen marketshare_other = 100 - marketshare1 - marketshare2 - marketshare3 - ///
marketshare4 - marketshare5 - marketshare6 - marketshare7

gen ROE = 0
forvalues i=1(1)7 {
replace ROE = ROE + marketshare`i'*ROE`i'
}

replace ROE = ROE + marketshare_other*ROE_other

keep anzsic ROE marketshare* VA_ind
rename ROE ROE_`a'

merge 1:1 anzsic using "ROE Bootstrap"
drop if _merge==2
drop _merge
save "ROE Bootstrap", replace
}

gen MS_4firm = marketshare1+marketshare2+marketshare3+marketshare4

merge 1:1 anzsic using AnzsicNames
drop if _merge==2
drop _merge

merge 1:1 anzsic using IndustryTradability
drop if _merge==2
drop _merge

order traded public MS_4firm ROE* ind_name anzsic, seq

matrix CI = J(200,3,0)
forvalues i=1(1)200 {
sum ROE_`i' if MS_4firm<35 & traded==0 & public==0 [w=VA_ind]
matrix CI[`i',1] = r(mean)
sum ROE_`i' if MS_4firm>=35 & MS_4firm<65 & traded==0 & public==0 [w=VA_ind]
matrix CI[`i',2] = r(mean)
sum ROE_`i' if MS_4firm>=65 & traded==0 & public==0 [w=VA_ind]
matrix CI[`i',3] = r(mean)
}

save "ROE Bootstrap", replace

use "ROE Bootstrap", clear
putmata X=(ROE*) anzsic, replace
mata
roe = J(cols(X),rows(X),0)
for(i=1; i<=rows(X); i++) {
i
roe[.,i] = sort(X[i,.]',1)
}
lb = roe[6,.]'
ub = roe[195,.]'
median = (roe[100,.]'+roe[101,.]')/2
sd = diagonal(sqrt(variance(roe)))
CI =  sort(st_matrix("CI")[.,1],1), sort(st_matrix("CI")[.,2],1),sort(st_matrix("CI")[.,3],1)
CI_lb = CI[6,.]'
CI_ub = CI[195,.]'
CI_lb,CI_ub
end

clear
getmata anzsic lb ub sd median
