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
drop if anzsic=="J5800" | anzsic=="G4200" | anzsic=="Q8400" | anzsic=="K6200" ///
| anzsic=="Q8700" | anzsic=="M6900" | anzsic=="E" | anzsic=="B" | anzsic=="P"
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
* keep if yearsincecurrent==0 // keep only most recent year
keep if yearsincecurrent<7
replace npat = npat*12/accountingperiod
replace revenue = revenue*12/accountingperiod
drop if accountingperiod<6
rename yearsincecurrent ysc

keep id company assets equity npat revenue ysc

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

*merge 1:1 company using CompanyFinancials
merge 1:m company using CompanyFinancials
keep if _merge==3
drop _merge

*merge 1:1 id using CompanySegment
merge m:1 company using CompanySegment
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
drop if anzsic=="J5800" | anzsic=="G4200" | anzsic=="Q8400" | anzsic=="K6200" ///
| anzsic=="Q8700" | anzsic=="M6900" | anzsic=="E" | anzsic=="B" | anzsic=="P"

gen ind_match = _merge==3
drop _merge

save Industry, replace

* create equivalent for level-3 industries
use Industry, clear

encode anzsic, gen(A)
sort anzsic
gen t = _n
tsset t
drop if A==f.A
sort ANZSIC3 t
by ANZSIC3: replace rev_ind = sum(rev_ind)
by ANZSIC3: replace VA_ind = sum(VA_ind)
drop A
encode ANZSIC3, gen(A)
sort A t
drop t
gen t = _n
tsset t
drop if A==f.A
replace anzsic = ANZSIC3
keep anzsic rev_ind VA_ind

save Industry3, replace

use Industry, clear

gen rev_firm = rev_ind*marketshare/100
encode company, gen(C)
encode ANZSIC3, gen(A)
sort ANZSIC3 company
by ANZSIC3 company: replace rev_firm = sum(rev_firm)
sort ANZSIC3 company
gen t = _n
tsset t
drop if C==f.C & A==f.A & company~="There are no major players in this industry"
drop C A t marketshare

replace anzsic = ANZSIC3
drop ANZSIC4 rev_ind VA_ind

merge m:1 anzsic using Industry3
drop _merge

save Industry3, replace

* create equivalent for level-2 industries
use Industry3, clear

encode ANZSIC3, gen(A)
sort ANZSIC3
gen t = _n
tsset t
drop if A==f.A
sort ANZSIC2
by ANZSIC2: replace rev_ind = sum(rev_ind)
by ANZSIC2: replace VA_ind = sum(VA_ind)
drop A t
encode ANZSIC2, gen(A)
sort A rev_ind
gen t = _n
tsset t
drop if A==f.A
replace anzsic = ANZSIC2
keep anzsic rev_ind VA_ind

save Industry2, replace

use Industry, clear

gen rev_firm = rev_ind*marketshare/100
encode company, gen(C)
encode ANZSIC2, gen(A)
sort ANZSIC2 company
by ANZSIC2 company: replace rev_firm = sum(rev_firm)
sort ANZSIC2 company
gen t = _n
tsset t
drop if C==f.C & A==f.A & company~="There are no major players in this industry"
drop C A t marketshare

replace anzsic = ANZSIC2
drop ANZSIC4 ANZSIC3 rev_ind VA_ind

merge m:1 anzsic using Industry2
drop _merge

save Industry2, replace


* create equivalent for level-1 industries
use Industry2, clear

encode ANZSIC2, gen(A)
sort ANZSIC2
gen t = _n
tsset t
drop if A==f.A
sort ANZSIC1
by ANZSIC1: replace rev_ind = sum(rev_ind)
by ANZSIC1: replace VA_ind = sum(VA_ind)
drop A t
encode ANZSIC1, gen(A)
sort A rev_ind
gen t = _n
tsset t
drop if A==f.A
replace anzsic = ANZSIC1
keep anzsic rev_ind VA_ind

save Industry1, replace

use Industry, clear

gen rev_firm = rev_ind*marketshare/100
encode company, gen(C)
encode ANZSIC1, gen(A)
sort ANZSIC1 company
by ANZSIC1 company: replace rev_firm = sum(rev_firm)
sort ANZSIC1 company
gen t = _n
tsset t
drop if C==f.C & A==f.A & company~="There are no major players in this industry"
drop C A t marketshare

replace anzsic = ANZSIC1
drop ANZSIC2 rev_ind VA_ind

merge m:1 anzsic using Industry1
drop _merge

save Industry1, replace

* Remove duplicates of 'no major players'
forvalues i=1(1)3 {
use Industry`i', clear
gen t = _n
tsset t
encode anzsic, gen(A)
drop if A==f.A & company=="There are no major players in this industry"
drop t A
save Industry`i', replace
gen t = _n
tsset t
encode anzsic, gen(A)
drop if A==f.A
drop t A
keep anzsic rev_ind VA_ind
save Industry_`i', replace
}

use Industry, clear
gen t = _n
tsset t
encode anzsic, gen(A)
drop if A==f.A
drop t A
save Industry_4, replace

* Estimate 4-firm market shares
use Industry, clear

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
*merge 1:1 company anzsic using Industry
merge m:1 company anzsic using Industry
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

replace rev_1 = revenue - rev_2 if rev_1==. & revenue>rev_2
replace rev3_1 = revenue - rev3_2 if rev3_1==. & revenue>rev3_2
replace rev2_1 = revenue - rev2_2 if rev2_1==. & revenue>rev2_2
replace rev1_1 = revenue - rev1_2 if rev1_1==. & revenue>rev1_2
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


/* calculate number of firms in each industry at each level (for the purposes
of excluding some from fixed effects) */

use CompanyRevenueShares, clear

forvalues i=1(1)12 {
rename anzsic_`i' anzsic
merge m:1 anzsic using MarketShares
drop if _merge==2 & `i'>1
drop marketshare* MS_*
drop _merge
rename anzsic anzsic_`i'
}

sort anzsic_1

multencode anzsic_1-anzsic_12, gen(A_1 A_2 A_3 A_4 A_5 A_6 A_7 A_8 A_9 A_10 A_11 A_12)
multencode anzsic3_1-anzsic3_11, gen(B_1 B_2 B_3 B_4 B_5 B_6 B_7 B_8 B_9 B_10 B_11)
multencode anzsic2_1-anzsic2_6, gen(C_1 C_2 C_3 C_4 C_5 C_6)
multencode anzsic1_1-anzsic1_3, gen(D_1 D_2 D_3)

gen no_firms = 0
gen no_firms3 = 0
gen no_firms2 = 0
gen no_firms1 = 0

forvalues i=1(1)600 {
forvalues j=1(1)12 {
gen test = A_`j'==`i' & negequityflag~=.
sum test
replace no_firms = no_firms + r(sum) if A_1==`i'
drop test
}
}

* set minimum number of firms per group
scalar minfirms = 100

gen L4_flag = no_firms>=minfirms

rename anzsic_1 anzsic
drop rev_ind VA_ind
merge m:1 anzsic using Industry_4
drop if _merge==2
drop _merge
rename anzsic anzsic_1

replace L4_flag = 1 if VA_ind>=2000 & VA_ind~=.
replace L4_flag = 1 if rev_ind>=20000 & rev_ind~=.

forvalues i=1(1)250 {
forvalues j=1(1)11 {
gen test = B_`j'==`i' & negequityflag~=.
sum test if L4_flag==0
replace no_firms3 = no_firms3 + r(sum) if B_1==`i' & L4_flag==0
drop test
}
}


gen L3_flag = no_firms3>=minfirms

rename anzsic3_1 anzsic
drop rev_ind VA_ind
merge m:1 anzsic using Industry_3
drop if _merge==2
drop _merge
rename anzsic anzsic3_1

replace L3_flag = 1 if VA_ind>2000 & VA_ind~=.
replace L3_flag = 1 if rev_ind>20000 & rev_ind~=.


forvalues i=1(1)100 {
forvalues j=1(1)6 {
gen test = C_`j'==`i' & negequityflag~=.
sum test if L3_flag==0 & L4_flag==0
replace no_firms2 = no_firms2 + r(sum) if C_1==`i' & L3_flag==0 & L4_flag==0
drop test
}
}

gen L2_flag = no_firms2>=minfirms

rename anzsic2_1 anzsic
drop rev_ind VA_ind
merge m:1 anzsic using Industry_2
drop if _merge==2
drop _merge
rename anzsic anzsic2_1

replace L2_flag = 1 if VA_ind>2000 & VA_ind~=.
replace L2_flag = 1 if rev_ind>20000 & rev_ind~=.

forvalues i=1(1)20 {
forvalues j=1(1)3 {
gen test = D_`j'==`i' & negequityflag~=.
sum test if L2_flag==0 & L3_flag==0 & L4_flag==0
replace no_firms1 = no_firms1 + r(sum) if D_1==`i' & L2_flag==0 & L3_flag==0 & L4_flag==0
drop test
}
}

gen L1_flag = no_firms1>=minfirms     

rename anzsic1_1 anzsic
drop rev_ind VA_ind
merge m:1 anzsic using Industry_1
drop if _merge==2
drop _merge
rename anzsic anzsic1_1

replace L1_flag = 1 if VA_ind>2000 & VA_ind~=.
replace L1_flag = 1 if rev_ind>20000 & rev_ind~=.           

sort A_1 B_1 C_1 D_1

gen t = _n
tsset t
drop if A_1 == l.A_1

rename anzsic_1 anzsic
rename A_1 ANZSIC

drop if no_firms==0
keep anzsic ANZSIC no_firms* L1_flag L2_flag L3_flag L4_flag

save IndustryDummies, replace

gen AA = substr(anzsic,1,1)
replace AA = substr(anzsic,1,3) if L2_flag==1
replace AA = substr(anzsic,1,4) if L3_flag==1
replace AA = anzsic if L4_flag==1
replace AA = "misc" if L1_flag==0 & L2_flag==0 & L3_flag==0 & L4_flag==0

multencode AA, gen(A)

sort A
gen t = _n
tsset t
drop if A==l.A
drop t

local obs = _N

forvalues i=1(1)`obs' {
gen S`i' = 0
replace S`i' = 1 in `i'
}

keep AA-S`obs' no_firms*

save IndPredict, replace


// Estimate regressions against higher-level industries and market shares

use CompanyRevenueShares, clear

gen lnrev = ln(revenue000)
gen lnDE = ln(debtequity) if negequityflag==0

gen MS_miss = MS4_1==-99 & traded_1==.


forvalues i=1(1)12 {
rename anzsic_`i' anzsic
merge m:1 anzsic using IndustryDummies
drop if _merge==2
drop _merge
gen AA_`i' = substr(anzsic,1,1)
replace AA_`i' = substr(anzsic,1,3) if L2_flag==1
replace AA_`i' = substr(anzsic,1,4) if L3_flag==1
replace AA_`i' = anzsic if L4_flag==1
replace AA_`i' = "misc" if L1_flag==0 & L2_flag==0 & L3_flag==0 & L4_flag==0
drop L1_flag L2_flag L3_flag L4_flag ANZSIC
rename anzsic anzsic_`i'
}

multencode AA_1-AA_12, gen(A_1 A_2 A_3 A_4 A_5 A_6 A_7 A_8 A_9 A_10 A_11 A_12)

* calculate share in each industry group
forvalues i=1(1)200 {
gen S`i' = 0
forvalues j=1(1)12 {
replace S`i' = share_`j' if A_`j'==`i'
}
sum S`i', meanonly
if (r(mean)==0) {
drop S`i'
}
}



* calculate share in each 4-firm market share group
matrix define cut = (0,15,30,50,75,100) // generate cut points for concentration
forvalues i=1(1)5 {
gen MS_`i' = 0
forvalues j=1(1)12 {
replace MS_`i' = MS_`i' + share_`j' if MS4_`j'>=cut[1,`i'] & MS4_`j'<cut[1,`i'+1] & traded_`j'==0
}
}

gen MS_traded = 0
forvalues i=1(1)12 {
replace MS_traded = MS_traded + share_`i' if traded_`i'==1
}

* generate firm-level controls
gen lnsize = ln(equity)
*gen lnsize2 = lnsize^2
gen lnde = ln(debtequity)
*gen lnde2 = lnde^2
gen public = type==6
gen proprietary = type==5

// Linear regressions with extremes removed
reg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss i.ysc if roe>-.7 & roe<.9 & type>3
reg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public i.ysc if roe>-.7 & roe<.9 & type>3
reg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public S* i.ysc if roe>-.7 & roe<.9 & type>3
reg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if roe>-.7 & roe<.9 & ysc==0 & type>3
reg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if roe>-.7 & roe<.9 & ysc==1 & type>3
reg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if roe>-.7 & roe<.9 & ysc==2 & type>3
reg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if roe>-.7 & roe<.9 & ysc==3 & type>3
reg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if roe>-.7 & roe<.9 & ysc==4 & type>3

reg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss i.ysc if roc>-.7 & roc<.9 & type>3
reg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public i.ysc if roc>-.7 & roc<.9 & type>3
reg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public S* i.ysc if roc>-.7 & roc<.9 & type>3
reg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if roc>-.7 & roc<.9 & ysc==0 & type>3
reg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if roc>-.7 & roc<.9 & ysc==1 & type>3
reg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if roc>-.7 & roc<.9 & ysc==2 & type>3
reg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if roc>-.7 & roc<.9 & ysc==3 & type>3
reg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if roc>-.7 & roc<.9 & ysc==4 & type>3

// Censored regression (I'm sceptical, but for completeness sake)
tobit roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss i.ysc if type>3, ll(-.4) ul(.6)
tobit roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public i.ysc if type>3, ll(-.4) ul(.6)
tobit roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if type>3 & ysc==0, ll(-.4) ul(.6)

tobit roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss i.ysc if type>3, ll(-.4) ul(.6)
tobit roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public i.ysc if type>3, ll(-.4) ul(.6)
tobit roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if type>3 & ysc==0, ll(-.4) ul(.6)

// Quantile regressions (no need for special treatment of extremes)
qreg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss i.ysc if type>3
qreg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public i.ysc if type>3
qreg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if type>3 & ysc==0
qreg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if type>3 & ysc==1
qreg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if type>3 & ysc==2
qreg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if type>3 & ysc==3
qreg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if type>3 & ysc==4

qreg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss i.ysc if type>3
qreg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public i.ysc if type>3
qreg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if type>3 & ysc==0
qreg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if type>3 & ysc==1
qreg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if type>3 & ysc==2
qreg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if type>3 & ysc==3
qreg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_miss lnsize* lnde* public if type>3 & ysc==4

	/* difficult to obtain any significance with quantile regression (could
	perhaps bootstrap and see if any difference) */


// Regressions against industry dummies

use CompanyRevenueShares, clear

forvalues i=1(1)12 {
rename anzsic_`i' anzsic
merge m:1 anzsic using IndustryDummies
drop if _merge==2
drop _merge
gen AA_`i' = substr(anzsic,1,1)
replace AA_`i' = substr(anzsic,1,3) if L2_flag==1
replace AA_`i' = substr(anzsic,1,4) if L3_flag==1
replace AA_`i' = anzsic if L4_flag==1
replace AA_`i' = "misc" if L1_flag==0 & L2_flag==0 & L3_flag==0 & L4_flag==0
drop L1_flag L2_flag L3_flag L4_flag ANZSIC
rename anzsic anzsic_`i'
}

multencode AA_1-AA_12, gen(A_1 A_2 A_3 A_4 A_5 A_6 A_7 A_8 A_9 A_10 A_11 A_12)

* calculate share in each industry group
forvalues i=1(1)200 {
gen S`i' = 0
forvalues j=1(1)12 {
replace S`i' = share_`j' if A_`j'==`i'
}
sum S`i', meanonly
if (r(mean)==0) {
drop S`i'
}
}

reg roe S* if roe>-.5 & roe<.7 & type>3 [w=revenue000]
est sto IndDum
reg roc S* if roc>-.5 & roc<.7 & type>3 [w=revenue000]
est sto IndDumROC

use Indpredict, clear

est res IndDum
predict ROE
est res IndDumROC
predict ROC

drop S*

/*
ANZSIC level 4 (some are 'other' categories): 
Wired telcos: ROE = 56%, ROC = 23%
Accounting services: ROE = 49%, ROC = 18%
Consumer goods retailing: ROE = 25%, ROC = 10%
Superannuation funds: ROE = 22%, ROC = 2.6% (some funds missing data)
Petroleum product wholesaling: ROE = 22%, ROC = 7%
Construction: ROE = 16%, ROC = 4.5%
Motor vehicle retailing: ROE = 20%, ROC = 8.5%
Car wholesaling: ROE = 18%, ROC = 2%
Electricity, elect. and gas appliance retailing: ROE = 17%, ROC = 11%
Professional, Sci. Tech. ind (general): ROE = 17%, ROC = 7%
Health insurance: ROE = 15%, ROC = 8%
Supermarkets: ROE = 15%, ROC = 7%
Banking: ROE = 14%, ROC = 1% (not sure if ROC is reliable for banking)
Telcos (other): ROE = 13%, ROC = 7%
Clothing retailing: ROE = 13%, ROC = 5%
Take-away food services: ROE = 13%, ROC = 8%
Legal services: ROE = 13%, ROC = 8%
Eng consulting: ROE = 12%, ROC = 5%

ANZSIC level 3 or higher:
Grocery, liquor and tobacco wholesaling: ROE = 20%, ROC = 9%
Motor vehicle wholesaling: ROE = 17%, ROC = 5%
Machinery and equipment wholesaling: ROE = 14%, ROC = 5%
Auxiliary finance and investment services: ROE = 13%, ROC = 4%
Water transport support services: ROE = 12%, ROC = 4%
Property operators: ROE = 12%, ROC = 6%
Administration services: ROE = 14%, ROC = 8%
Public administration and safety: ROE = 22%, ROC = 7%
Accommodation and food services: ROE = 15%, ROC = 6%
Information media and telcos: ROE = 14%, ROC = 7%
*/














/*
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

