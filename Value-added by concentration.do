clear
clear matrix
clear mata

cd "C:\Users\chisholmc\Dropbox (Personal)\Grattan\GitHub\Industry-concentration\IBIS data"

use MarketShares, clear

matrix cut = (0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,101)

matrix share = J(20,1,0)

gen NT = substr(anzsic,1,1)=="D" | substr(anzsic,1,1)=="E" | substr(anzsic,1,1)=="F" | ///
substr(anzsic,1,1)=="G" | substr(anzsic,1,1)=="H" | substr(anzsic,1,1)=="I" | substr(anzsic,1,1)=="J" | ///
substr(anzsic,1,1)=="K" | substr(anzsic,1,1)=="L" | substr(anzsic,1,1)=="M" | substr(anzsic,1,1)=="S"

forvalues i=1(1)20 {
local j = `i'+1
sum VA_ind if MS_4firm>=cut[1,`i'] & MS_4firm<cut[1,`j'] & NT==1
matrix share[`i',1] = r(sum)
}

matrix list share

forvalues i=1(1)20 {
local j = `i'+1
sum VA_ind if MS_4firm>=cut[1,`i'] & MS_4firm<cut[1,`j']
matrix share[`i',1] = r(sum)
}

matrix list share

merge 1:1 anzsic using IndustryTradability
keep if _merge==3
drop _merge

gsort traded -MS_4firm -VA_ind



* Grouped by value added 5% intervals
use MarketShares, clear

merge 1:1 anzsic using IndustryTradability
keep if _merge==3
drop _merge

drop if traded==1
drop if substr(anzsic,1,1)=="P" | anzsic=="Q8539" | anzsic=="R9113" | anzsic=="I4622" ///
| anzsic=="I4720" | anzsic=="O7714" | anzsic=="Q8401" | anzsic=="Q8402" ///
| anzsic=="Q8591" | anzsic=="O7710"

forvalues i=1(1)4 {
replace marketshare`i' = 0 if marketshare`i'==.
}

egen MS_2firm_ = rowmean(marketshare1-marketshare2)
egen MS_3firm_ = rowmean(marketshare1-marketshare3)
egen MS_4firm_ = rowmean(marketshare1-marketshare4)
replace MS_2firm_ = MS_2firm_*2
replace MS_3firm_ = MS_3firm_*3
replace MS_4firm_ = MS_4firm_*4
gsort -marketshare1
gsort -MS_2firm_
gsort -MS_3firm_
gsort -MS_4firm_

sum VA_ind
replace VA_ind = VA_ind/r(sum)*100
gen VA_cumulative = sum(VA_ind)




putmata MS=(marketshare1-marketshare4) VA=VA_ind VA_c=VA_cumulative, replace

mata
X = J(20,4,0)
b=1
d=5
s=0
a=1
for(c=1; c<=4; c++) {
X[b,c] = X[b,c] + VA[a]*MS[a,c]/5
}
for(a=2; a<=rows(VA); a++) {
a
s
for(c=1; c<=4; c++) {
X[b,c] = X[b,c] + min(VA[a]\d-VA_c[a-1])*MS[a,c]/5
}
if (VA_c[a]>d) {
for(c=1; c<=4; c++) {
X[b+1,c] = X[b+1,c] + (VA_c[a]-d)*MS[a,c]/5
}
b++
d=d+5
}
}
X
end

clear
getmata x*=X
