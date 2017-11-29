clear
clear matrix
clear mata

cd "C:\Users\chisholmc\Dropbox (Personal)\Grattan\GitHub\Industry-concentration\Morningstar"

import delimited Equity, varn(1) clear

forvalues i=9(1)36 {
local year = `i'+1981
destring v`i', replace force
replace v`i' = . if v`i'==0
rename v`i' equity`year'
}

drop if etfs==1 | foreign==1

drop etfs foreign yearstart yearend item
rename companyname company 
rename asxcode code

reshape long equity, i(code) j(year)

save Equity, replace

import delimited NPAT, varn(1) clear

forvalues i=9(1)36 {
local year = `i'+1981
replace v`i' = subinstr(v`i',",","",.)
destring v`i', replace force
replace v`i' = . if v`i'==0
rename v`i' NPAT`year'
}

drop if etfs==1 | foreign==1

drop etfs foreign yearstart yearend item
rename companyname company 
rename asxcode code

reshape long NPAT, i(code) j(year)

save NPAT, replace

import delimited Goodwill_, varn(1) clear

forvalues i=9(1)36 {
local year = `i'+1981
destring v`i', replace force
rename v`i' goodwill`year'
}

drop if etf==1 | foreign=="1"

drop etf foreign yearstart yearend item
rename companyname company 
rename asxcode code
drop if code==""

reshape long goodwill, i(code company) j(year)

save Goodwill, replace

import delimited MarketCap, varn(1) clear

forvalues i=8(1)35 {
local year = `i'+1982
destring v`i', replace force
replace v`i' = . if v`i'==0
rename v`i' marketcap`year'
}

drop if etf==1 | foreign==1

drop etf foreign yearstart yearend 
rename companyname company 
rename asxcode code

reshape long marketcap, i(code) j(year)

save MarketCap, replace

import delimited Revenue, varn(1) clear

drop v36-v65

forvalues i=8(1)35 {
local year = `i'+1982
destring v`i', replace force
replace v`i' = . if v`i'==0
rename v`i' revenue`year'
}

drop if etf==1 | foreign==1

drop etf foreign yearstart yearend 
rename companyname company 
rename asxcode code

reshape long revenue, i(code) j(year)

encode code, gen(id)
xtset id year

gen growth = (revenue/l.revenue-1)*100

save Revenue, replace

import delimited Beta, varn(1) clear

destring beta, force replace
drop status
rename companyname company 
rename asxcode code

save Beta, replace

import delimited BarriersGICS, varn(1) clear

save Barriers, replace

use "C:\Users\chisholmc\Dropbox (Personal)\Grattan\GitHub\Industry-concentration\IBIS data\CompanyVAShares", clear

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

rename asx code
keep if code~="" & ysc==0 & share_>.05
rename anzsic_ anzsic

merge m:1 anzsic using "C:\Users\chisholmc\Dropbox (Personal)\Grattan\GitHub\Industry-concentration\IBIS data\IndustryBarriers"
keep if _merge==3
drop _merge

drop if traded_==1 | public_==1

keep code natural_monopoly network_effects regulatory_barriers
drop if natural_monopoly==0 & network_effects==0 & regulatory_barriers==0

sort code natural_monopoly network_effects

gen t = _n
tsset t
encode code, gen(id)

drop if id==l.id & natural_monopoly==l.natural_monopoly & network_effects==l.network_effects

drop if code=="TLS" & natural_monopoly==1
drop if code=="SWM" & regulatory_barriers==1

save ASXIBISBarriers, replace

use Equity, clear

merge 1:1 code year using Goodwill
drop if _merge==2
drop _merge

gen equity_noGW = equity
replace equity_noGW = . if equity_noGW<0
replace equity = equity-goodwill if goodwill~=.
replace equity = . if equity<0

merge 1:1 code year using NPAT
drop if _merge==2
drop _merge

merge 1:1 code year using Revenue
drop if _merge==2
drop _merge

merge 1:1 code year using MarketCap
drop if _merge==2
drop _merge

merge m:1 code using beta
drop if _merge==2
drop _merge

gen roe = NPAT/equity
scalar R_rp = .056
gen roe_ra = roe + (1-beta)*R_rp
replace roe_ra = roe + (1-.92)*R_rp if roe_ra==.

gen tobinQ = marketcap/equity

keep if year>2010 & year<2017

replace roe = roe*100
replace roe_ra = roe_ra*100


gen ROE_0 = roe_ra<0
gen ROE0_8 = roe_ra>=0 & roe_ra<8
gen ROE8_12 = roe_ra>=8 & roe_ra<12
gen ROE12_17 = roe_ra>=12 & roe_ra<17
gen ROE17_23 = roe_ra>=17 & roe_ra<23
gen ROE23_30 = roe_ra>=23 & roe_ra<30
gen ROE30_ = roe_ra>=30 & roe_ra~=.

gen ltq = ln(tobinQ)
sum ltq [aw=equity], detail
replace ltq = . if ltq<r(p1) | ltq>r(p99)
replace tobinQ = . if ltq<r(p1) | ltq>r(p99)

reg ltq ROE_0 ROE0_8 ROE12_17 ROE17_23 ROE23_30 ROE30_ beta i.year if industry~="Metals & Mining" & roe_ra~=. [aw=equity]
reg tobinQ ROE_0 ROE0_8 ROE12_17 ROE17_23 ROE23_30 ROE30_  beta i.year if industry~="Metals & Mining" & roe_ra~=. [aw=equity]
lpoly tobinQ roe_ra if industry~="Metals & Mining" & roe_ra>0 & roe_ra<40 [aw=equity]
lpoly tobinQ roe_ra if industry~="Metals & Mining" & roe_ra>0 & roe_ra<40

drop if roe==. | tobinQ==.

bysort code: gen N = _N

sort id year
gen GROWTH = ((revenue/l5.revenue)^(1/5)-1)*100
replace GROWTH = ((revenue/l4.revenue)^(1/4)-1)*100 if GROWTH==.
replace GROWTH = ((revenue/l3.revenue)^(1/3)-1)*100 if GROWTH==.
replace GROWTH = ((revenue/l2.revenue)^(1/2)-1)*100 if GROWTH==.

gen roe_equity = roe*equity
bysort code: egen equity_sum = sum(equity) if roe~=. & abs(roe)<200
bysort code: egen roe_equity_sum = sum(roe_equity) if abs(roe)<200
gen ROE = roe_equity_sum/equity_sum
gen ROE_ra = ROE + (1-beta)*R_rp*100
replace ROE_ra = ROE + (1-.92)*R_rp*100 if ROE_ra==.
drop roe_equity equity_sum roe_equity_sum


bysort code: egen test = max(ROE)
bysort code: egen test2 = max(ROE_ra)
replace ROE = test
replace ROE_ra = test2
drop test test2

gen Q_ = tobinQ if year==2016
bysort code: egen Q = max(Q_)
replace Q_ = tobinQ if year==2015 & Q==.
drop Q
bysort code: egen Q = max(Q_)
replace Q_ = tobinQ if year==2014 & Q==.
drop Q
bysort code: egen Q = max(Q_)
drop Q_
gen lnQ = ln(Q)

/* Calculate average Q (but better to use end-of-period) */
/*
gen Q_equity = tobinQ*equity
bysort code: egen equity_sum = sum(equity) if tobinQ~=.
bysort code: egen Q_equity_sum = sum(Q_equity)
gen Q = Q_equity_sum/equity_sum
drop Q_equity equity_sum Q_equity_sum

bysort code: egen test = max(Q)
replace Q = test
drop test
gen lnQ = ln(Q)
*/

bysort code: keep if _n==_N
drop if N<4

replace ROE_0 = ROE_ra<0
replace ROE0_8 = ROE_ra>=0 & ROE_ra<8
replace ROE8_12 = ROE_ra>=8 & ROE_ra<12
replace ROE12_17 = ROE_ra>=12 & ROE_ra<17
replace ROE17_23 = ROE_ra>=17 & ROE_ra<23
replace ROE23_30 = ROE_ra>=23 & ROE_ra<30
replace ROE30_ = ROE_ra>=30 & ROE_ra~=.

reg lnQ ROE_0 ROE0_8 ROE12_17 ROE17_23 ROE23_30 ROE30_  if industry~="Metals & Mining"  & ROE_ra~=. [aw=equity]
reg Q ROE_0 ROE0_8 ROE12_17 ROE17_23 ROE23_30 ROE30_  if industry~="Metals & Mining"  & ROE_ra~=. [aw=equity]
reg Q ROE_0 ROE0_8 ROE12_17 ROE17_23 ROE23_30 ROE30_  if industry~="Metals & Mining"  & ROE_ra~=.
lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-20 & ROE_ra<50 [aw=equity], nosc bw(5)
lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-20 & ROE_ra<50, bw(5) nosc

twoway || lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-10 & ROE_ra<40 [aw=equity], bw(6) ///
|| lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-10 & ROE_ra<40, bw(5)

twoway || lowess Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-10 & ROE_ra<40 ///
|| lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-10 & ROE_ra<40

merge m:1 industry using Barriers
drop _merge

rename network_effects network_effects_
rename natural_monopoly natural_monopoly_
rename regulatory_barriers regulatory_barriers_
drop if code==""

merge 1:1 code using ASXIBISBarriers
drop if _merge==2
drop _merge

replace natural_monopoly_=1 if natural_monopoly==1 & network_effects_==0 & regulatory_barriers_==0
replace network_effects_=1 if natural_monopoly_==0 & network_effects==1 & regulatory_barriers_==0
replace regulatory_barriers_=1 if natural_monopoly_==0 & network_effects_==0 & regulatory_barriers==1

drop natural_monopoly network_effects regulatory_barriers

rename network_effects_ network_effects
rename natural_monopoly_ natural_monopoly
rename regulatory_barriers_ regulatory_barriers

gen barriers = natural_monopoly + 2*network_effects + 3*regulatory_barriers

twoway || lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-10 & ROE_ra<40 & barriers==0 [aw=equity], bw(8) || ///
lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-10 & ROE_ra<40 & barriers>0 [aw=equity], bw(8)

twoway || lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-10 & ROE_ra<40 & barriers==0, bw(8) || ///
lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-10 & ROE_ra<40 & barriers>0, bw(8)

egen rank = rank(revenue) if industry~="Metals & Mining"
egen rank_ = max(rank)
replace rank = rank_ + 1 - rank
drop rank_

twoway || lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-10 & ROE_ra<50 & barriers==0 & rank<=200, bw(5) || ///
lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-10 & ROE_ra<50 & barriers>0 & rank<=200, bw(5)

twoway || lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-10 & ROE_ra<40 & barriers==0 & rank<=200 [aw=equity], bw(6) || ///
lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-10 & ROE_ra<40 & barriers>0 & rank<=200 [aw=equity], bw(6)


lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-20 & ROE_ra<50 & barriers==0 & rank<=200, nosc bw(5) gen(X Y) se(Y_se) n(1000)
lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-20 & ROE_ra<50 & barriers>0 & rank<=200, nosc bw(5) gen(Xb Yb) se(Yb_se) n(1000)










twoway || lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-10 & ROE_ra<40 & barriers==0, bw(8) ///
|| lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-10 & ROE_ra<40 & barriers==1, bw(8) ///
|| lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-10 & ROE_ra<40 & barriers==2, bw(8) ///
|| lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-10 & ROE_ra<40 & barriers==3, bw(8)


twoway || lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-10 & ROE_ra<40 & barriers==0 [aw=equity], bw(8) ///
|| lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-10 & ROE_ra<40 & barriers==1 [aw=equity], bw(8) ///
|| lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-10 & ROE_ra<40 & barriers==2 [aw=equity], bw(8) ///
|| lpoly Q ROE_ra if industry~="Metals & Mining" & ROE_ra>-10 & ROE_ra<40 & barriers==3 [aw=equity], bw(8)

gen Barriers = barriers>0

reg Q ROE_0 ROE0_8 ROE12_17 ROE17_23 ROE23_30 ROE30_ i.barriers if industry~="Metals & Mining"  & ROE_ra~=.
reg Q ROE_0 ROE0_8 ROE12_17 ROE17_23 ROE23_30 ROE30_ i.barriers if industry~="Metals & Mining"  & ROE_ra~=. [w=equity]
reg Q ROE_0 ROE0_8 ROE12_17 ROE17_23 ROE23_30 ROE30_ Barriers if industry~="Metals & Mining"  & ROE_ra~=.
reg Q ROE_0 ROE0_8 ROE12_17 ROE17_23 ROE23_30 ROE30_ Barriers if industry~="Metals & Mining"  & ROE_ra~=. [w=equity]
reg Q ROE_0 ROE0_8 ROE12_17 ROE17_23 ROE23_30 ROE30_ Barriers if industry~="Metals & Mining"  & ROE_ra~=. [w=equity]

reg lnQ ROE_ra if industry~="Metals & Mining" [w=equity]

gen ROE_B = ROE_ra*Barriers

reg lnQ ROE_ra Barriers ROE_B if industry~="Metals & Mining" [w=equity]
