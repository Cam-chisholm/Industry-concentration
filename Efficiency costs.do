clear
clear matrix
clear mata

cd "C:\Users\chisholmc\Dropbox (Personal)\Grattan\GitHub\Industry-concentration\IBIS data"

import delimited Industry17.csv, clear

rename code anzsic
rename revenuem20162017 rev_ind
rename ivam20162017 VA_ind
rename wagesm20162017 wages_ind
gen profits_ind = coststructureprofit*rev_ind/100
rename majorplayers company
keep anzsic rev_ind VA_ind profits_ind company marketshare
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

drop MS_1firm-MS_3firm MS_5firm-MS_7firm

gen high = MS_4firm>=65 & MS_4firm~=.
gen low = MS_4firm<35 & MS_4firm~=.
gen medium = MS_4firm>=35 & MS_4firm<65 & MS_4firm~=.

gen profit_margins = profits_ind/(rev_ind-profits_ind)

gen NT = substr(anzsic,1,1)=="D" | substr(anzsic,1,1)=="E" | substr(anzsic,1,1)=="F" | ///
substr(anzsic,1,1)=="G" | substr(anzsic,1,1)=="H" | substr(anzsic,1,1)=="I" | substr(anzsic,1,1)=="J" | ///
substr(anzsic,1,1)=="K" | substr(anzsic,1,1)=="L" | substr(anzsic,1,1)=="M" | substr(anzsic,1,1)=="S"

sum profits if high==1 & NT==1
di r(sum)*(12.7-9)/12.7 // Size of transfer from consumers to producers if high ROE is 12.7 vs 9
di r(sum)*(12.7-9)/12.7*.05*.5 // Size of efficiency cost if consumers would have consumed 5% more
