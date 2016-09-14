use CompanyExposure, clear
gen revenue = totalrevenue*share_firm_ind_rev

local industries "371 393 404 236 261 202 312 289 200 386 228 240"

matrix ROE = J(12,3,0)
local i "1"
foreach x of local industries {
sum roe2015 if A==`x' & extreme2015~=1 [aweight=revenue]
matrix ROE[`i',1] = r(mean)*100
sum roe2015 if A==`x' [aweight=revenue], detail
matrix ROE[`i',2] = r(p50)*100
sum roe_5yr if A==`x' & extreme~=1 [aweight=revenue]
matrix ROE[`i',3] = r(mean)*100
local i = `i'+1
}

matrix list ROE
