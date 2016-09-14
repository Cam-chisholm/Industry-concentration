use CompanyExposure, clear

drop weight_concHH-exposure4
gen revenue = totalrevenue*share_firm_ind_rev
replace HH = 499 if HH==500

egen exp4_ = cut(MS_4firm), at(0,15,30,50,70,100)
egen expHH_ = cut(HH), at(0,515,602,797,1341,10000)
replace exp4_ = 9999 if tradable==1
replace expHH_ = 9999 if tradable==1

sort rank exp4_

by rank exp4_: egen SHARE = sum(share_firm_ind_rev)
local EXP4 "0 15 30 50 70 9999"
foreach x of local EXP4 {
by rank: egen share`x' = max(SHARE) if exp4_==`x'
by rank: egen share_`x' = max(share`x')
replace share_`x' = 0 if share_`x'==.
drop share`x'
}

gen SUM = share_0 + share_15 + share_30 + share_50 + share_70 + share_9999
foreach x of local EXP4 {
replace share_`x' = share_`x'/SUM if SUM~=0 & SUM~=.
}
drop SUM SHARE

sort rank expHH_

by rank expHH_: egen SHARE = sum(share_firm_ind_rev)
local EXP4 "0 515 602 797 1341 9999"
foreach x of local EXP4 {
by rank: egen share`x' = max(SHARE) if expHH_==`x'
by rank: egen shareHH_`x' = max(share`x')
replace shareHH_`x' = 0 if shareHH_`x'==.
drop share`x'
}


gen SUM = shareHH_0 + shareHH_515 + shareHH_602 + shareHH_797 + shareHH_1341 + shareHH_9999
foreach x of local EXP4 {
replace shareHH_`x' = shareHH_`x'/SUM if SUM~=0 & SUM~=.
}
drop SUM SHARE

by rank: gen t = _n
keep if t==1
drop t exp4_ expHH_

rename share_9999 share_tradable
drop shareHH_9999

save SampleForBootstrap, replace

qreg roe_5yr share_0-share_70 share_tradable [iweight=totalrevenue]
matrix BETA = e(b)


forvalues i=1(1)200 {
use SampleForBootstrap, clear
bsample
qreg roe_5yr share_0-share_70 share_tradable [iweight=totalrevenue]
matrix BETA = BETA \ e(b)
}

clear
svmat BETA

matrix ROE = J(6,3,0)

forvalues i=1(1)6 {
replace BETA`i' = BETA`i' + BETA7
sum BETA`i' in 1
matrix ROE[`i',1] = r(mean)
_pctile BETA`i', p(2.5, 97.5)
matrix ROE[`i',2] = r(r1)
matrix ROE[`i',3] = r(r2)
}

matrix list ROE


