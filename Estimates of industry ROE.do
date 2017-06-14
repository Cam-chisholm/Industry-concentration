clear
clear matrix
clear mata

cd "C:\Users\chisholmc\Dropbox (Personal)\Grattan\GitHub\Industry-concentration\IBIS data"

// Import IBISWorld Data from various spreadsheets //

* Company Information
import delimited CompanyInfo17.csv, clear

rename tradingname company
rename mainindustrybrcode main_anzsic

encode companytype, gen(type)
encode ownership, gen(local)
gen anzsic_level = min(5,length(main_anzsic))-1

keep company asx main_anzsic anzsic_level revenue000 type local
drop in 1803 // Error in data set (same company listed twice)

save CompanyInfo, replace

* Data on Firms' various segments
import delimited CompanySegment.csv, clear

rename identerprise id
rename companyname company
rename anzsiccode anzsic
keep if ismajorplayer=="Yes"

keep id company anzsic
sort id anzsic
gen t = _n
tsset t
encode anzsic, gen(AZ)
drop if AZ==l.AZ
drop t AZ
sort id

by id: gen ind = _n
rename anzsic anzsic_
reshape wide anzsic_, i(id) j(ind)

save CompanySegment, replace

* Financials going back up to 10 years
import delimited CompanyTimeSeries.csv, clear

rename identerprise id
rename companyname company
rename totalassets assets
rename totalsalesrevenue revenue
rename totalshareholderequity equity
keep if yearsincecurrent==0 // keep only most recent year

keep id company assets equity npat revenue

gen roe = npat/equity
replace roe=. if npat==0 | equity==0
gen roc = npat/assets
replace roc=. if npat==0 | assets==0
drop in 1803 // Error in data set (same company listed twice)
gen debtequity = (assets-equity)/equity
replace debtequity = . if assets==0 | equity==0
gen negequityflag = equity<0

save CompanyFinancials, replace

* Merge company data
use CompanyInfo, clear
drop in 1803

merge 1:1 company using CompanyFinancials
keep if _merge==3
drop _merge

merge 1:1 id using CompanySegment
drop if _merge==2
gen major = _merge==3
drop _merge

replace anzsic_1 = main_anzsic if anzsic_1==""
replace anzsic_1 = anzsic_1 + "00" if strlen(anzsic_1)==3
replace anzsic_1 = anzsic_1 + "0" if strlen(anzsic_1)==4
replace revenue = revenue000/1.09 if revenue==0 // Based on ratio of total to sales revenue 

forvalues i=1(1)12 {
forvalues j=1(1)12 {
gen temp = substr(anzsic_`i',1,4)==substr(anzsic_`j',1,4) & substr(anzsic_`i',-1,1)=="0" & `i'~=`j'
replace anzsic_`i'="" if temp==1
drop temp
gen temp = substr(anzsic_`i',1,3)==substr(anzsic_`j',1,3) & substr(anzsic_`i',-2,2)=="00" & `i'~=`j'
replace anzsic_`i'="" if temp==1
drop temp
gen temp = strlen(anzsic_`i')==1 & substr(anzsic_`i',1,1)==substr(anzsic_`j',1,1) & `i'~=`j'
replace anzsic_`i'="" if temp==1
drop temp
}
}

* skip blanks
forvalues i=2(1)12 {
local k = `i'-1
forvalues j=1(1)`k' {
replace anzsic_`j' = anzsic_`i' if anzsic_`j'=="" & anzsic_`i'~=""
replace anzsic_`i' = "" if anzsic_`j'==anzsic_`i'
}
}


save CompanyMerged, replace 

* Data across ANZSIC industies
import delimited ANZSIC.csv, clear
rename v1 ANZSIC1
rename v2 ANZSIC2
rename v3 ANZSIC3
rename v4 ANZSIC4

save ANZSIC, replace

import delimited Industry17.csv, clear

rename code anzsic
rename revenuem20162017 rev_ind
rename ivam20162017 VA_ind
rename majorplayers company
keep anzsic rev_ind VA_ind company marketshare
drop if substr(anzsic,1,1)=="X"
gen ANZSIC4 = substr(anzsic,1,5)
gen ANZSIC3 = substr(ANZSIC4,1,4)
gen ANZSIC2 = substr(ANZSIC4,1,3)
gen ANZSIC1 = substr(ANZSIC4,1,1)

merge m:1 ANZSIC4 ANZSIC3 ANZSIC2 ANZSIC1 using ANZSIC
drop if _merge==2
replace ANZSIC4="" if strlen(anzsic)==1
replace ANZSIC3="" if strlen(anzsic)==1
replace ANZSIC2="" if strlen(anzsic)==1

gen ind_match = _merge==3
drop _merge

save Industry, replace

drop company ANZSIC* ind_match
gsort anzsic -marketshare
by anzsic: gen firm_no = _n

reshape wide marketshare, i(anzsic) j(firm_no)

gen MS_1firm = marketshare1
forvalues i=1(1)6 {
local j =`i'+1
gen MS_`j'firm = MS_`i'firm + marketshare`j' if marketshare`j'~=.
replace MS_`j'firm = MS_`i'firm if MS_`j'firm==.
}


replace MS_2firm = MS_2firm + 3 if MS_2firm==MS_1firm & MS_2firm<97
replace MS_3firm = MS_3firm + 2 if MS_3firm==MS_2firm & MS_3firm<98
replace MS_3firm = MS_3firm + 5 if MS_3firm==MS_1firm & MS_3firm<95
replace MS_4firm = MS_4firm + 1 if MS_4firm==MS_3firm & MS_4firm<99
replace MS_4firm = MS_4firm + 3 if MS_4firm==MS_2firm & MS_4firm<97
replace MS_4firm = MS_4firm + 6 if MS_4firm==MS_1firm & MS_4firm<94

save MarketShares, replace

import delimited IndustryClassifications.csv, clear

sort code
by code: gen t = _n
keep if t==1
rename code anzsic
drop if substr(anzsic,1,1)=="X"
gen traded = exportslevel=="Medium" | exportslevel=="High" | ///
importslevel=="Medium" | importslevel=="High"

keep anzsic traded

save IndustryTradability, replace

* Match company info to market shares
use CompanyMerged, clear

forvalues i=1(1)12 {
rename anzsic_`i' anzsic
merge 1:1 company anzsic using Industry
drop if _merge==2
gen rev_`i' = rev_ind*marketshare
drop _merge marketshare VA_ind ANZSIC4-ind_match rev_ind
merge m:1 anzsic using MarketShares
drop if _merge==2
rename MS_4firm MS4_`i'
drop marketshare1-VA_ind MS_5firm-_merge
merge m:1 anzsic using IndustryTradability
drop if _merge==2
drop _merge
rename traded traded_`i'
rename anzsic anzsic_`i'
}

order MS4_* rev_* traded_*, alphabetic before(MS_1firm)
order MS4_10-MS4_12, alphabetic after(MS4_9)
order rev_10-rev_12, alphabetic after(rev_9)
order traded_10-traded_12, alphabetic after(traded_9)

forvalues i=1(1)12 {
gen rev3_`i' = rev_`i'
}
forvalues i=1(1)12 {
gen anzsic3_`i' = substr(anzsic_`i',1,4)
}

forvalues i=1(1)12 {
gen rev2_`i' = rev_`i'
}
forvalues i=1(1)12 {
gen anzsic2_`i' = substr(anzsic_`i',1,3)
}

forvalues i=1(1)12 {
gen rev1_`i' = rev_`i'
}
forvalues i=1(1)12 {
gen anzsic1_`i' = substr(anzsic_`i',1,1)
}

forvalues i=2(1)12 {
local k = `i'-1
forvalues j=1(1)`k' {
replace rev3_`j' = rev3_`i' + rev3_`j' if anzsic3_`i'==anzsic3_`j' // sum revenue shares in same industry
replace rev3_`i' = . if anzsic3_`i'==anzsic3_`j'
replace anzsic3_`i' = "" if anzsic3_`i'==anzsic3_`j'

replace rev2_`j' = rev2_`i' + rev2_`j' if anzsic2_`i'==anzsic2_`j'
replace rev2_`i' = . if anzsic2_`i'==anzsic2_`j'
replace anzsic2_`i' = "" if anzsic2_`i'==anzsic2_`j'

replace rev1_`j' = rev1_`i' + rev1_`j' if anzsic1_`i'==anzsic1_`j'
replace rev1_`i' = . if anzsic1_`i'==anzsic1_`j'
replace anzsic1_`i' = "" if anzsic1_`i'==anzsic1_`j'
}
}

forvalues i=3(1)12 {
local k = `i'-1
forvalues j=2(1)`k' {
replace rev3_`j' = rev3_`i' if anzsic3_`j'=="" & anzsic3_`i'~="" // skip blanks
replace rev3_`i' = . if anzsic3_`j'=="" & anzsic3_`i'~=""
replace anzsic3_`j' = anzsic3_`i' if anzsic3_`j'=="" & anzsic3_`i'~=""
replace anzsic3_`i' = "" if anzsic3_`j'==anzsic3_`i'

replace rev2_`j' = rev2_`i' if anzsic2_`j'=="" & anzsic2_`i'~=""
replace rev2_`i' = . if anzsic2_`j'=="" & anzsic2_`i'~=""
replace anzsic2_`j' = anzsic2_`i' if anzsic2_`j'=="" & anzsic2_`i'~=""
replace anzsic2_`i' = "" if anzsic2_`j'==anzsic2_`i'

replace rev1_`j' = rev1_`i' if anzsic1_`j'=="" & anzsic1_`i'~=""
replace rev1_`i' = . if anzsic1_`j'=="" & anzsic1_`i'~=""
replace anzsic1_`j' = anzsic1_`i' if anzsic1_`j'=="" & anzsic1_`i'~=""
replace anzsic1_`i' = "" if anzsic1_`j'==anzsic1_`i'
}
}

gen rev_total=0
forvalues i=1(1)12 {
replace rev_total = rev_total + rev_`i' if rev_`i'~=.
}
replace rev_total = revenue if rev_total==0

forvalues i=1(1)12 {
gen share_`i' = rev_`i'/rev_total // generate revenue shares 
replace share_`i' = 0 if share_`i'==.
replace rev_`i' = 0 if rev_`i'==.
}

forvalues i=1(1)12 {
gen share3_`i' = rev3_`i'/rev_total
replace share3_`i' = 0 if share3_`i'==.
replace rev3_`i' = 0 if rev3_`i'==.
}

forvalues i=1(1)12 {
gen share2_`i' = rev2_`i'/rev_total
replace share2_`i' = 0 if share2_`i'==.
replace rev2_`i' = 0 if rev2_`i'==.
}

forvalues i=1(1)12 {
gen share1_`i' = rev1_`i'/rev_total
replace share1_`i' = 0 if share1_`i'==.
replace rev1_`i' = 0 if rev1_`i'==.
}

replace share_1 = 1 if share_1==0
replace share3_1 = 1 if share3_1==0
replace share2_1 = 1 if share2_1==0
replace share1_1 = 1 if share1_1==0
replace rev_1 = rev_total if rev_1==0
replace rev3_1 = rev_total if rev3_1==0
replace rev2_1 = rev_total if rev2_1==0
replace rev1_1 = rev_total if rev1_1==0

forvalues i=1(1)12 {
sum share3_`i'
if (r(mean)==0) {
drop rev3_`i' anzsic3_`i' share3_`i' // remove unnecessary variables
}

sum share2_`i'
if (r(mean)==0) {
drop rev2_`i' anzsic2_`i' share2_`i' 
}

sum share1_`i'
if (r(mean)==0) {
drop rev1_`i' anzsic1_`i' share1_`i' 
}
}

drop MS_1firm MS_2firm MS_3firm
replace MS4_1=-99 if MS4_1==.

save CompanyRevenueShares, replace

// Estimate regressions against higher-level industries and market shares

use CompanyRevenueShares, clear

gen lnrev = ln(revenue000)
gen lnDE = ln(debtequity) if negequityflag==0

forvalues i=1(1)12 {
gen M_`i' = MS4_`i'==-99 & traded_`i'==.
}

/* calculate number of firms in each industry at each level (for the purposes
of excluding some from fixed effects) */

multencode anzsic_1-anzsic_12, gen(A_1 A_2 A_3 A_4 A_5 A_6 A_7 A_8 A_9 A_10 A_11 A_12)
set matsize 500

gen no_firms = 0
gen no_firms3 = 0
gen no_firms2 = 0
gen no_firms1 = 0

forvalues i=1(1)474 {
sort anzsic_`i'
by anzsic_`i': replace no_firms = no_firms+_N if anzsic_`i'~=""
}

forvalues i=1(1)11 {
sort anzsic3_`i'
by anzsic3_`i': replace no_firms3 = no_firms3+_N if anzsic3_`i'~=""
}

forvalues i=1(1)6 {
sort anzsic2_`i'
by anzsic2_`i': replace no_firms2 = no_firms2+_N if anzsic2_`i'~=""
}

forvalues i=1(1)3 {
sort anzsic1_`i'
by anzsic1_`i': replace no_firms1 = no_firms1+_N if anzsic1_`i'~=""
}




* ssc install multencode // ensures coding is the same for all anzsic variables

multencode anzsic_1-anzsic_12, gen(A_1 A_2 A_3 A_4 A_5 A_6 A_7 A_8 A_9 A_10 A_11 A_12)
set matsize 500

forvalues i=1(1)474 {
gen S`i' = 0
forvalues j=1(1)12 {
replace S`i' = share_`j' if A_`j'==`i'
}
}

































// Estimate fixed effects regression //

use CompanyRevenueShares, clear

* ssc install multencode // ensures coding is the same for all variables

multencode anzsic_1-anzsic_12, gen(A_1 A_2 A_3 A_4 A_5 A_6 A_7 A_8 A_9 A_10 A_11 A_12)
set matsize 500

forvalues i=1(1)474 {
gen S`i' = 0
forvalues j=1(1)12 {
replace S`i' = share_`j' if A_`j'==`i'
}
}

forvalues i=1(1)474 {
gen R`i' = 0
forvalues j=1(1)12 {
replace R`i' = rev_`j' if A_`j'==`i'
}
}

* unweighted
reg roe S1-S473
est sto FE_uw

* weighted by total revenue
reg roe S1-S473 [w=rev_total]
est sto FE_w

* remove extreme ROEs
reg roe S1-S473 if abs(roe)<.5
est sto FE_uw_NoExt
reg roe S1-S473 if abs(roe)<.5 [w=rev_total]
est sto FE_w_NoExt

* unweighted
reg roc S1-S473
est sto FE_uw_roc

* weighted by total revenue
reg roc S1-S473 [w=rev_total]
est sto FE_w_roc

* remove extreme ROEs
reg roc S1-S473 if abs(roc)<.5
est sto FE_uw_NoExt_roc
reg roc S1-S473 if abs(roc)<.5 [w=rev_total]
est sto FE_w_NoExt_roc

keep A_1-A_12
sort A_1

save Industries, replace
gen t=1

forvalues i=2(1)12 {
append using Industries
replace A_1=A_`i' if t==.
sort A_1
drop if A_1==.
replace t=1
}

keep A_1
gen t = _n
tsset t
drop if A_1==l.A_1
drop t

forvalues i=1(1)473 {
gen S`i' = A_1==`i'
}

rename A_1 ANZSIC
decode ANZSIC, gen(anzsic)
gen anzsic3 = substr(anzsic,1,4)
gen anzsic2 = substr(anzsic,1,3)
gen anzsic1 = substr(anzsic,1,1)
encode anzsic1, gen(A1)
encode anzsic2, gen(A2)

save Industries, replace

drop S1-S473

save Industries_, replace


// Estimate random effects regressions //

use CompanyRevenueShares, clear

reshape long anzsic_ anzsic3_ anzsic2_ anzsic1_ rev_ rev3_ rev2_ rev1_ share_ ///
share3_ share2_ share1_ , i(id) j(Ind)

rename anzsic_ anzsic
drop if anzsic==""
gen anzsic3 = substr(anzsic,1,4)
gen anzsic2 = substr(anzsic,1,3)
gen anzsic1 = substr(anzsic,1,1)
drop anzsic3_-share1_
encode anzsic1, gen(A1)
encode anzsic2, gen(A2)

append using Industries_

mixed roc i.A1 i.A2 || anzsic: || anzsic3: [fweight=share_] if abs(roc)<.5

est sto ME_3



* Industry predictions
use Industries, clear



est res FE_uw
predict test
