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

rename anzsic anzsic_
rename main_anzsic anzsic

merge m:1 anzsic using Industry_Large
drop if _merge==2

bysort anzsic: replace anzsic = "" if _merge==1 | _N<5

rename anzsic main_anzsic
rename anzsic_ anzsic

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

bysort main_anzsic: gen N = _N
bysort main_anzsic type: gen NG = _N if type==3

gen gov = "_G" if type==3 & NG>=3 & N-NG>=3
egen main_anzsic_g = concat(main_anzsic gov)
drop gov N NG

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
replace VA_`i' = 0 if VA_`i'==.
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

forvalues j=1(1)6 {
replace share2_`j' = 0 if share2_`j'<.1
}

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
replace S`i' = S`i'/test
}
drop test

reg roe S* if roe>-.5 & roe<.7 & debtequity<20 & assetsrevenue>0.5 & type>2 [w=equity], vce(cl company)
est sto Ind2

tobit roe S* if debtequity<20 & assetsrevenue>0.5 & type>2 [w=equity], ll(-.5) ul(.7) vce(cl company)
est sto Ind2tobit

replace equity = equity/10^6
replace revenue = revenue/10^6
mixed roe S* || main_anzsic_g: if roe>-.5 & roe<.7 & debtequity<20 & assetsrevenue>0.5 & type>2 [fw=revenue]
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

drop S*
gen anzsic = main_anzsic_g
replace anzsic = substr(anzsic,1,6) if substr(anzsic,-2,2)=="_G"
replace anzsic = substr(anzsic,1,5) if substr(anzsic,-1,1)=="_"

merge m:1 anzsic using AnzsicNames

gsort -ROE_ME
edit
