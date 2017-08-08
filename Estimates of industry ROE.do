clear
clear matrix
clear mata

cd "C:\Users\chisholmc\Dropbox (Personal)\Grattan\GitHub\Industry-concentration\IBIS data"

// Import IBISWorld Data from various spreadsheets //

* Data across ANZSIC industies
import delimited ANZSIC.csv, clear
rename v1 ANZSIC1
rename v2 ANZSIC2
rename v3 ANZSIC3
rename v4 ANZSIC4

save ANZSIC, replace

import delimited AnzsicNames.csv, clear
rename v1 anzsic
rename v2 ind_name

save AnzsicNames, replace

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
| anzsic=="Q8700" | anzsic=="D2600" | anzsic=="M6900" | anzsic=="F3400" ///
| anzsic=="E" | anzsic=="B" | anzsic=="P"

gen ind_match = _merge==3
drop _merge

save Industry, replace

keep if (VA_ind>3000 | (VA_ind>2200 & rev_ind>20000)) & company~="There are no major players in this industry"

gen large=1

save IndustryLarge, replace

sort anzsic
by anzsic: gen n = _n
keep if n==1
drop company marketshare n


save Industry_Large, replace

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
keep anzsic rev_ind VA_ind
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


replace MS_2firm = MS_2firm + 1.5 if MS_2firm==MS_1firm & MS_2firm<97
replace MS_3firm = MS_3firm + 1.5 if MS_3firm==MS_2firm & MS_3firm<98
replace MS_3firm = MS_3firm + 2.5 if MS_3firm==MS_1firm & MS_3firm<95
replace MS_4firm = MS_4firm + 1.5 if MS_4firm==MS_3firm & MS_4firm<99
replace MS_4firm = MS_4firm + 2.5 if MS_4firm==MS_2firm & MS_4firm<97
replace MS_4firm = MS_4firm + 3.5 if MS_4firm==MS_1firm & MS_4firm<94

save MarketShares, replace

* calculate average 4-firm market share for each industry group
use MarketShares, clear

local obs = _N

append using Industry_3
append using Industry_2
append using Industry_1

gen ANZSIC3 = substr(anzsic,1,4) if strlen(anzsic)>=4
gen ANZSIC2 = substr(anzsic,1,3) if strlen(anzsic)>=3
gen ANZSIC1 = substr(anzsic,1,1)

encode anzsic, gen(A)
encode ANZSIC3, gen(B)
encode ANZSIC2, gen(C)
encode ANZSIC1, gen(D)

gen rev4 = rev_ind*MS_4firm

local inds "B C D"

foreach x of local inds {
sum `x'
forvalues i=1(1)`r(max)' {
sum rev4 if `x'==`i' in 1/`obs'
scalar temp = r(sum)
sum rev_ind if `x'==`i' in 1/`obs'
scalar temp_ = r(sum)
replace MS_4firm = temp/temp_ if `x'==`i' & MS_4firm==.
}
}

keep anzsic MS_4firm rev_ind VA_ind

save MarketSharesAllIndustries, replace

import delimited IndustryClassifications.csv, clear

sort code
by code: gen t = _n
keep if t==1
rename code anzsic
drop if substr(anzsic,1,1)=="X"
gen traded = exportslevel=="Medium" | exportslevel=="High" | importslevel=="Medium" | ///
importslevel=="High"

keep anzsic traded
gen public = substr(anzsic,1,1)=="O" | substr(anzsic,1,1)=="P" | substr(anzsic,1,1)=="Q" | substr(anzsic,1,1)=="R" 

save IndustryTradability, replace

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
gen major = ismajorplayer=="Yes"
drop ismajorplayer

merge m:1 anzsic company using Industry
drop if _merge==2
drop _merge

sort company
by company: egen ct = sum(major)
drop if ct>0 & major==0

merge m:1 anzsic using Industry_Large
drop if _merge==1 & major==0
drop _merge

sort revenuerank anzsic
by revenuerank anzsic: gen dup = cond(_N==1,0,_n)

drop if dup>1
drop dup

replace large = 0 if large==.

keep id company anzsic major large

drop if (anzsic=="J5800" | anzsic=="G4200" | anzsic=="Q8400" | anzsic=="K6200" ///
| anzsic=="Q8700" | anzsic=="D2600" | anzsic=="M6900" | anzsic=="F3400" ///
| anzsic=="E" | anzsic=="B" | anzsic=="P") & major==1

sort id

save CompanySegment, replace

use CompanyInfo, clear

merge 1:m company using CompanySegment
drop if _merge==2
drop _merge

merge m:1 anzsic using Industry_4
drop if _merge==2
drop _merge

sort company

by company: gen n = _n
by company: gen N = _N

gen match = substr(anzsic,1,3)==substr(main_anzsic,1,3)

by company: egen sum_match = sum(match)
drop if sum_match==0 & n>1 & major==0
drop if match==0 & sum_match>0 & major==0

gen digit2 = strlen(main_anzsic)<=3

by company: replace N = _N

replace main_anzsic = anzsic if N==1 & digit2==1 & strlen(anzsic)>4

gsort company -match -VA_ind
by company: replace n = _n

drop if major==0 & n>1

replace main_anzsic = anzsic if N>1 & digit2==1 & match==1 & strlen(anzsic)>4

replace main_anzsic = main_anzsic[_n-1] if company[_n]==company[_n-1]

replace anzsic = main_anzsic if anzsic==""

sort company
drop id
encode company, gen(id)

save CompanySegment, replace

sort anzsic

keep company main_anzsic anzsic asx revenue000 type local id

sort id anzsic

by id: gen ind = _n
rename anzsic anzsic_
reshape wide anzsic_, i(id) j(ind)

gen gov = "_G" if type==3
egen main_anzsic_g = concat(main_anzsic gov)
drop gov

save CompanySegment, replace

* Proportion of revenue earned in Australia
import delimited GeographicSegment.csv, clear

rename companyname company

gen local = strpos(segmentname,"Australia")>0 | strpos(segmentname,"Unallocated")>0 | ///
strpos(segmentname,"Australasia")>0 | strpos(segmentname,"Worldwide")>0 | ///
strpos(segmentname,"Asia Pacific")>0 | strpos(segmentname,"Victoria")>0 | ///
strpos(segmentname,"International")>0 |  strpos(segmentname,"Queensland")>0  

replace revenue=0 if revenue<0

bysort company: egen rev = sum(revenue)
bysort company local: egen revL = sum(revenue)

gen aus_percent = revL/rev if local==1
replace aus_percent=0 if local==0

gsort company -local
by company: gen n = _n
keep if n==1

keep company aus_percent

save Geography, replace

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
replace roe=. if npat==0 | equity<=0
gen roc = npat/assets
replace roc=. if npat==0 | assets<=0
drop in 1803 // Error in data set (same company listed twice)
gen debtequity = (assets-equity)/equity
replace debtequity = . if assets==0 | equity<=0
gen negequityflag = equity<0

xtset id ysc

gen growth = (revenue-f.revenue)/f.revenue if revenue~=0 & f.revenue~=0

save CompanyFinancials, replace

* Merge company data
use CompanyInfo, clear
drop in 1803
drop main_anzsic

* merge in financials
merge 1:m company using CompanyFinancials
keep if _merge==3
drop _merge

*merge segment information
merge m:1 company using CompanySegment
drop if _merge==2
drop _merge

*merge goegraphy information
merge m:1 company using Geography
drop if _merge==2
drop _merge

replace revenue = revenue*aus_percent if aus_percent~=.
replace equity = equity*aus_percent if aus_percent~=.

replace anzsic_1 = anzsic_1 + "00" if strlen(anzsic_1)==3
replace anzsic_1 = anzsic_1 + "0" if strlen(anzsic_1)==4

gen assetsrevenue = assets/revenue
replace assetsrevenue = . if assets<=0 | revenue<=0

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


* Match company info to market shares
use CompanyMerged, clear

forvalues i=1(1)12 {
rename anzsic_`i' anzsic
*merge 1:1 company anzsic using Industry
merge m:1 company anzsic using Industry
drop if _merge==2
gen VA_`i' = VA_ind*marketshare
drop _merge marketshare VA_ind ANZSIC4-ind_match rev_ind
merge m:1 anzsic using MarketSharesAllIndustries
drop if _merge==2
rename MS_4firm MS4_`i'
drop rev_ind VA_ind _merge
merge m:1 anzsic using IndustryTradability
drop if _merge==2
drop _merge
rename traded traded_`i'
rename public public_`i'
rename anzsic anzsic_`i'
}

order MS4_* VA_* traded_*, alphabetic after(assetsrevenue)
order MS4_10-MS4_12, alphabetic after(MS4_9)
order VA_10-VA_12, alphabetic after(VA_9)
order traded_10-traded_12, alphabetic after(traded_9)

forvalues i=1(1)12 {
gen VA3_`i' = VA_`i'
}
forvalues i=1(1)12 {
gen anzsic3_`i' = substr(anzsic_`i',1,4)
}

forvalues i=1(1)12 {
gen VA2_`i' = VA_`i'
}
forvalues i=1(1)12 {
gen anzsic2_`i' = substr(anzsic_`i',1,3)
}

forvalues i=1(1)12 {
gen VA1_`i' = VA_`i'
}
forvalues i=1(1)12 {
gen anzsic1_`i' = substr(anzsic_`i',1,1)
}


* combine some 2-digit industries
forvalues i=1(1)6 {
replace anzsic2_`i' = "J58" if anzsic2_`i'=="J59"
replace anzsic2_`i' = "D26" if anzsic2_`i'=="D27"
replace anzsic2_`i' = "D28" if anzsic2_`i'=="D29"
}

forvalues i=2(1)12 {
local k = `i'-1
forvalues j=1(1)`k' {
replace VA3_`j' = VA3_`i' + VA3_`j' if anzsic3_`i'==anzsic3_`j' // sum revenue shares in same industry
replace VA3_`i' = . if anzsic3_`i'==anzsic3_`j'
replace anzsic3_`i' = "" if anzsic3_`i'==anzsic3_`j'

replace VA2_`j' = VA2_`i' + VA2_`j' if anzsic2_`i'==anzsic2_`j'
replace VA2_`i' = . if anzsic2_`i'==anzsic2_`j'
replace anzsic2_`i' = "" if anzsic2_`i'==anzsic2_`j'

replace VA1_`j' = VA1_`i' + VA1_`j' if anzsic1_`i'==anzsic1_`j'
replace VA1_`i' = . if anzsic1_`i'==anzsic1_`j'
replace anzsic1_`i' = "" if anzsic1_`i'==anzsic1_`j'
}
}

forvalues i=3(1)12 {
local k = `i'-1
forvalues j=2(1)`k' {
replace VA3_`j' = VA3_`i' if anzsic3_`j'=="" & anzsic3_`i'~="" // skip blanks
replace VA3_`i' = . if anzsic3_`j'=="" & anzsic3_`i'~=""
replace anzsic3_`j' = anzsic3_`i' if anzsic3_`j'=="" & anzsic3_`i'~=""
replace anzsic3_`i' = "" if anzsic3_`j'==anzsic3_`i'

replace VA2_`j' = VA2_`i' if anzsic2_`j'=="" & anzsic2_`i'~=""
replace VA2_`i' = . if anzsic2_`j'=="" & anzsic2_`i'~=""
replace anzsic2_`j' = anzsic2_`i' if anzsic2_`j'=="" & anzsic2_`i'~=""
replace anzsic2_`i' = "" if anzsic2_`j'==anzsic2_`i'

replace VA1_`j' = VA1_`i' if anzsic1_`j'=="" & anzsic1_`i'~=""
replace VA1_`i' = . if anzsic1_`j'=="" & anzsic1_`i'~=""
replace anzsic1_`j' = anzsic1_`i' if anzsic1_`j'=="" & anzsic1_`i'~=""
replace anzsic1_`i' = "" if anzsic1_`j'==anzsic1_`i'
}
}

drop if VA_1==. & VA_2~=.

gen VA_total=0

forvalues i=1(1)12 {
replace VA_total = VA_total + VA_`i' if VA_`i'~=.
}
replace VA_total = . if VA_total==0

forvalues i=1(1)12 {
gen share_`i' = VA_`i'/VA_total // generate VA shares 
replace share_`i' = 0 if share_`i'==.
replace VA_`i' = 0 if VA_`i'==.
}

forvalues i=1(1)12 {
gen share3_`i' = VA3_`i'/VA_total
replace share3_`i' = 0 if share3_`i'==.
replace VA3_`i' = 0 if VA3_`i'==.
}

forvalues i=1(1)12 {
gen share2_`i' = VA2_`i'/VA_total
replace share2_`i' = 0 if share2_`i'==.
replace VA2_`i' = 0 if VA2_`i'==.
}

forvalues i=1(1)12 {
gen share1_`i' = VA1_`i'/VA_total
replace share1_`i' = 0 if share1_`i'==.
replace VA1_`i' = 0 if VA1_`i'==.
}

replace share_1 = 1 if share_1==0
replace share3_1 = 1 if share3_1==0
replace share2_1 = 1 if share2_1==0
replace share1_1 = 1 if share1_1==0

forvalues i=1(1)12 {
sum share3_`i'
if (r(mean)==0) {
drop VA3_`i' anzsic3_`i' share3_`i' // remove unnecessary variables
}

sum share2_`i'
if (r(mean)==0) {
drop VA2_`i' anzsic2_`i' share2_`i' 
}

sum share1_`i'
if (r(mean)==0) {
drop VA1_`i' anzsic1_`i' share1_`i' 
}
}

replace MS4_1=-99 if MS4_1==.

save CompanyVAShares, replace

/* Set up for mixed effects regression */

use CompanyVAShares, clear

multencode anzsic2_1-anzsic2_6, gen(A_1 A_2 A_3 A_4 A_5 A_6)

* calculate share in each industry group
forvalues i=1(1)100 {
gen S`i' = 0
forvalues j=1(1)6 {
replace S`i' = share2_`j' if A_`j'==`i'
}
sum S`i', meanonly
if (r(mean)==0) {
drop S`i'
}
}

egen test = rowmean(S*)
replace test = test*79
forvalues i=1(1)79 {
replace S`i' = S`i'*test
}
drop test

reg roe S* if roe>-.5 & roe<.7 & debtequity<20 & assetsrevenue>0.25 & type>2 [w=equity], vce(cl company)
est sto Ind2

tobit roe S* if debtequity<20 & assetsrevenue>0.25 & type>2 [w=equity], ll(-.5) ul(.7) vce(cl company)
est sto Ind2tobit

replace equity = equity/10^6
mixed roe S* || main_anzsic_g: if roe>-.5 & roe<.7 & debtequity<20 & assetsrevenue>0.25 & type>2 [fw=equity]
est sto Ind2me


predict ROE, fit
predict ROE_
gen fit = ROE-ROE_

keep fit main_anzsic_g

bysort main_anzsic_g: keep if _n==1

gen ANZSIC2 = substr(main_anzsic_g,1,3)

save IndustryME, replace

use CompanyVAShares, clear

multencode anzsic2_1-anzsic2_6, gen(A_1 A_2 A_3 A_4 A_5 A_6)

keep if ysc==0
keep company A_1-A_6

drop if company=="Dow Chemical"

reshape long A_, i(company) j(a)
drop company
drop if A_==.

sort A_
by A_: gen n = _n
keep if n==1
keep A_

decode A_, gen(ANZSIC2)

forvalues i=1(1)79 {
gen S`i' = A_==`i'
}

est res Ind2tobit
predict ROE_Tobit

merge 1:m ANZSIC2 using IndustryME
drop _merge

est res Ind2me

predict ROE_ME
replace ROE_ME = ROE_ME + fit


est sto IndDum
reg roc S* if roc>-.5 & roc<.7 & debtequity<20 [w=equity], vce(r)
est sto IndDumROC
tobit roe S* if debtequity<20 & assetsrevenue>0.25 [w=equity], ll(-.3) ul(.5) vce(r)
est sto IndDumTobit
tobit roc S* if debtequity<20 & assetsrevenue>0.25 [w=equity], ll(-.3) ul(.5) vce(r)
est sto IndDumROCTobit








/* calculate number of firms in each industry at each level (for the purposes
of excluding some from fixed effects) */

use CompanyVAShares, clear

forvalues i=1(1)12 {
rename anzsic_`i' anzsic
merge m:1 anzsic using MarketShares
drop if _merge==2 & `i'>1
drop MS_*
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
gen test = A_`j'==`i' & equity>0 & roe~=. & debtequity<20 & assetsrevenue>0.25
sum test
replace no_firms = no_firms + r(sum) if A_1==`i'
drop test
}
}

* set minimum number of firms per group
scalar minfirms = 100
scalar min_firms = 50
* set minimum value added and revenue per group
scalar ValAdd = 3000
scalar REV = 20000

gen L4_flag = no_firms>=minfirms

rename anzsic_1 anzsic
drop rev_ind VA_ind
merge m:1 anzsic using Industry_4
drop if _merge==2
drop _merge
rename anzsic anzsic_1

replace L4_flag = 1 if VA_ind>=ValAdd & VA_ind~=. & no_firms>=min_firms
replace L4_flag = 1 if rev_ind>=REV & rev_ind~=. & no_firms>=min_firms
replace L4_flag = 0 if substr(anzsic_1,-2,2)=="00"
replace L4_flag = 1 if anzsic_1=="G4111" | anzsic_1=="E3109" | anzsic_1=="J5802" | ///
anzsic_1=="K6322" | anzsic_1=="E3011" | anzsic_1=="E3021" | anzsic_1=="K6310" | ///
anzsic_1=="K6420" | anzsic_1=="E3101" | anzsic_1=="D2640" | anzsic_1=="G4251" | ///
anzsic_1=="K6330" | anzsic_1=="E3021" | anzsic_1=="K6321" | anzsic_1=="G4000"

forvalues i=1(1)250 {
forvalues j=1(1)11 {
gen test = B_`j'==`i' & negequityflag~=. & roe~=.
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

replace L3_flag = 1 if VA_ind>ValAdd & VA_ind~=. & no_firms3>=min_firms
replace L3_flag = 1 if rev_ind>REV & rev_ind~=. & no_firms3>=min_firms
replace L3_flag = 0 if substr(anzsic_1,-2,2)=="00"
replace L3_flag = 1 if L4_flag==1

forvalues i=1(1)100 {
forvalues j=1(1)6 {
gen test = C_`j'==`i' & negequityflag~=. & roe~=.
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

replace L2_flag = 1 if VA_ind>ValAdd & VA_ind~=. & no_firms2>=min_firms
replace L2_flag = 1 if rev_ind>REV & rev_ind~=. & no_firms2>=min_firms
replace L2_flag = 1 if L3_flag==1
replace L2_flag = 1 if substr(anzsic_1,1,3)=="G41" | substr(anzsic_1,1,3)=="D27"
replace L2_flag = 0 if substr(anzsic_1,1,3)=="J56"

forvalues i=1(1)20 {
forvalues j=1(1)3 {
gen test = D_`j'==`i' & negequityflag~=. & roe~=.
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

replace L1_flag = 1 if VA_ind>ValAdd & VA_ind~=. & no_firms1>=min_firms
replace L1_flag = 1 if rev_ind>REV & rev_ind~=. & no_firms1>=min_firms
replace L1_flag = 1 if L2_flag==1
replace L1_flag = 1 if substr(anzsic_1,1,1)=="N"            

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
replace AA = substr(anzsic,1,3) if L3_flag==1 & L4_flag==0 & substr(anzsic,4,1)=="0"
replace L3_flag=0 if L3_flag==1 & L4_flag==0 & substr(anzsic,4,1)=="0"
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

use CompanyVAShares, clear

gen lnrev = ln(revenue000)
gen lnDE = ln(debtequity) if negequityflag==0

gen MS_miss = MS4_1==-99 & traded_1~=1


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



* calculate share in each 4-firm market share group
matrix define cut = (0,15,35,50,65,101) // generate cut points for concentration
forvalues i=1(1)5 {
gen MS_`i' = 0
forvalues j=1(1)12 {
replace MS_`i' = MS_`i' + share_`j' if MS4_`j'>=cut[1,`i'] & MS4_`j'<cut[1,`i'+1] & traded_`j'==0 & public_`j'==0
}
}

gen MS_traded = 0
gen MS_public = 0
forvalues i=1(1)12 {
replace MS_traded = MS_traded + share_`i' if traded_`i'==1
replace MS_public = MS_public + share_`i' if public_`i'==1
replace MS_public = 0 if MS_miss==1
}

* generate firm-level controls
gen lnsize = ln(equity)
*gen lnsize2 = lnsize^2
gen lnde = ln(debtequity)
*gen lnde = ln(debtequity)>6
gen public = type==6
gen proprietary = type==5
gen MS_12 = MS_1 + MS_2

// Linear regressions with extremes removed
reg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss i.ysc if roe>-.7 & roe<.9 & type>3
reg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public i.ysc if roe>-.7 & roe<.9 & type>3
reg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public i.ysc if roe>-.7 & roe<.9 & type>3 [w=equity]
reg roe MS_12 MS_5 MS_traded MS_public MS_miss public local if roe>-.7 & roe<.9 & type>3 [w=equity]
reg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnde* public S* i.ysc if roe>-.7 & roe<.9 & type>3 [w=equity]
reg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if roe>-.7 & roe<.9 & ysc==0 & type>3
reg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if roe>-.7 & roe<.9 & ysc==1 & type>3
reg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if roe>-.7 & roe<.9 & ysc==2 & type>3
reg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if roe>-.7 & roe<.9 & ysc==3 & type>3
reg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if roe>-.7 & roe<.9 & ysc==4 & type>3

reg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss i.ysc if roc>-.7 & roc<.9 & type>3
reg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public i.ysc if roc>-.7 & roc<.9 & type>3
reg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public S* i.ysc if roc>-.7 & roc<.9 & type>3
reg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if roc>-.7 & roc<.9 & ysc==0 & type>3
reg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if roc>-.7 & roc<.9 & ysc==1 & type>3
reg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if roc>-.7 & roc<.9 & ysc==2 & type>3
reg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if roc>-.7 & roc<.9 & ysc==3 & type>3
reg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if roc>-.7 & roc<.9 & ysc==4 & type>3

// Censored regression (I'm sceptical, but for completeness sake)
replace equity = . if equity<=0
tobit roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss i.ysc if type>3, ll(-.4) ul(.6)
tobit roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public i.ysc if type>3, ll(-.4) ul(.6)
tobit roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if type>3 & ysc==0, ll(-.4) ul(.6)
tobit roe MS_12 MS_5 MS_traded MS_public MS_miss public local if type>3 & equity>0 [w=equity], ll(-.4) ul(.6)

tobit roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss i.ysc if type>3, ll(-.4) ul(.6)
tobit roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public i.ysc if type>3, ll(-.4) ul(.6)
tobit roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if type>3 & ysc==0, ll(-.4) ul(.6)

// Quantile regressions (no need for special treatment of extremes)
qreg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss i.ysc if type>3
qreg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public i.ysc if type>3
qreg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if type>3 & ysc==0
qreg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if type>3 & ysc==1
qreg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if type>3 & ysc==2
qreg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if type>3 & ysc==3
qreg roe MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if type>3 & ysc==4

qreg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss i.ysc if type>3
qreg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public i.ysc if type>3
qreg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if type>3 & ysc==0
qreg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if type>3 & ysc==1
qreg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if type>3 & ysc==2
qreg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if type>3 & ysc==3
qreg roc MS_1 MS_2 MS_4 MS_5 MS_traded MS_public MS_miss lnsize* lnde* public if type>3 & ysc==4

	/* difficult to obtain any significance with quantile regression (could
	perhaps bootstrap and see if any difference) */


// Regressions against industry dummies

use CompanyVAShares, clear

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


reg roe S* if roe>-.5 & roe<.7 & debtequity<20 & assetsrevenue>0.25 [w=equity], vce(r)
est sto IndDum
reg roc S* if roc>-.5 & roc<.7 & debtequity<20 [w=equity], vce(r)
est sto IndDumROC
tobit roe S* if debtequity<20 & assetsrevenue>0.25 [w=equity], ll(-.3) ul(.5) vce(r)
est sto IndDumTobit
tobit roc S* if debtequity<20 & assetsrevenue>0.25 [w=equity], ll(-.3) ul(.5) vce(r)
est sto IndDumROCTobit

* Prediction by industry
use Indpredict, clear

est res IndDum
predict ROE
predict ROE_SE, stdp
est res IndDumROC
predict ROC
est res IndDumTobit
predict ROE2
predict ROE2_SE, stdp
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

merge 1:1 anzsic using AnzsicNames
drop if _merge==2
drop _merge

merge 1:1 anzsic using IndustryTradability
drop if _merge==2
drop _merge

merge 1:1 anzsic using MarketSharesAllIndustries
drop if _merge==2
drop _merge

* put in two aggregated industries
local obs = _N + 1
set obs `obs'
replace anzsic = "K63_" in `obs'
replace ind_name = "Other insurance" in `obs'
local obs = _N + 1
set obs `obs'
replace anzsic = "J_" in `obs'
replace ind_name = "Information media" in `obs'

drop rev_ind VA_ind
egen rev_ind = rowmean(rev_ind*)
egen VA_ind = rowmean(VA_ind*)

replace ANZSIC4 = anzsic if strlen(anzsic)>4
replace ANZSIC3 = substr(anzsic,1,4) if strlen(anzsic)>3
replace ANZSIC2 = substr(anzsic,1,3) if strlen(anzsic)>2
replace ANZSIC1 = substr(anzsic,1,1)

replace traded = 1 if ANZSIC1=="A" | ANZSIC1=="B" | ANZSIC1=="C"
replace traded = 0 if traded==.
replace public = 1 if ANZSIC1=="O" | ANZSIC1=="P" | ANZSIC1=="Q" | ANZSIC1=="R"
replace public = 0 if public==.

gsort traded -ROE_

edit anzsic ind_name ROE_ ROE_2 MS_4firm VA_ind rev_ind ROE_2 ROC_* no_firms*  if ///
anzsic=="D26" | anzsic=="E30" | anzsic=="E31" | anzsic=="E32" | anzsic=="G42" | ///
anzsic=="F" | anzsic=="G41" | anzsic=="G39" | anzsic=="G4000" | anzsic=="H44" | anzsic=="H45" | ///
anzsic=="I" | anzsic=="J58" | anzsic=="J" | anzsic=="K62" | anzsic=="N" | anzsic=="D27" | ///
anzsic=="K63" | anzsic=="K64" | anzsic=="L67" | anzsic=="M69" | anzsic=="M70" | anzsic=="L66"














// Estimate regressions against firm (not industry) market shares //
use CompanyMerged, clear

forvalues i=1(1)12 {
rename anzsic_`i' anzsic
*merge 1:1 company anzsic using Industry
merge m:1 company anzsic using Industry
drop if _merge==2
drop ANZSIC4-_merge
rename marketshare marketshare_`i' 
rename VA_ind VA_ind_`i'
rename rev_ind rev_ind_`i'
merge m:1 anzsic using IndustryTradability
drop if _merge==2
drop _merge
rename traded traded_`i'
rename public public_`i'
rename anzsic anzsic_`i'
}

order marketshare_* traded_* public_* VA_ind_* rev_ind_*, alphabetic after(major)
order marketshare_10-marketshare_12, alphabetic after(marketshare_9)
order public_10-public_12, alphabetic after(public_9)
order traded_10-traded_12, alphabetic after(traded_9)
order VA_ind_10-VA_ind_12, alphabetic after(VA_ind_9)
order rev_ind_10-rev_ind_12, alphabetic after(rev_ind_9)



* calculate share in each 4-firm market share group
matrix define cut = (0,7,12,20,30,40,101) // generate cut points for concentration
forvalues i=1(1)6 {
gen MS_`i' = 0
forvalues j=1(1)12 {
replace MS_`i' = MS_`i' + marketshare_`j'*rev_ind_`j'/revenue000 if marketshare_`j'>=cut[1,`i'] & marketshare_`j'<cut[1,`i'+1] & traded_`j'==0 & public_`j'==0
}
}


gen MS_miss = marketshare_1==. & traded_1~=1 & public_1~=1
gen MS_traded = 0
gen MS_public = 0
forvalues i=1(1)12 {
replace MS_traded = MS_traded + marketshare_`i'*rev_ind_`i'/revenue000 if traded_`i'==1
replace MS_public = MS_public + marketshare_`i'*rev_ind_`i'/revenue000 if public_`i'==1
replace MS_public = 0 if MS_miss==1
}

egen MS_sum = rowmean(MS_1-MS_public)
replace MS_sum = MS_sum*9
local MS "MS_1 MS_2 MS_3 MS_4 MS_5 MS_6 MS_miss MS_traded MS_public"

foreach x of local MS {
replace `x' = `x'/MS_sum
}

gen public = type==6
gen MS_12 = MS_1 + MS_2
gen MS_56 = MS_5 + MS_6

reg roe MS_12 MS_56 MS_traded MS_public MS_miss public if roe>-.7 & roe<.9 & type>3 [w=equity]
reg roe MS_1 MS_2 MS_3 MS_5 MS_6 MS_traded MS_public MS_miss public if roe>-.7 & roe<.9 & type>3 [w=equity]
