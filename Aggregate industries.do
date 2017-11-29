use MarketShares, clear

keep anzsic rev_ind VA_ind

gen anzsic2 = substr(anzsic,1,3)

encode anzsic2, gen(A)

sum A

gen VA_ind2 = 0 
gen rev_ind2 = 0

forvalues i=1(1)`r(max)' {
sum rev_ind if A==`i'
replace rev_ind2 = r(sum) if A==`i'
sum VA_ind if A==`i'
replace VA_ind2 = r(sum) if A==`i'
}

bysort anzsic2: keep if _n==1

keep anzsic2 VA_ind2 rev_ind2
rename VA_ind2 VA_ind
rename rev_ind2 rev_ind

save "Industry2_", replace

gen anzsic1 = substr(anzsic2,1,1)

encode anzsic1, gen(A)

sum A

gen VA_ind1 = 0 
gen rev_ind1 = 0

forvalues i=1(1)`r(max)' {
sum rev_ind if A==`i'
replace rev_ind1 = r(sum) if A==`i'
sum VA_ind if A==`i'
replace VA_ind1 = r(sum) if A==`i'
}

bysort anzsic1: keep if _n==1

keep anzsic1 VA_ind1 rev_ind1
rename VA_ind1 VA_ind
rename rev_ind1 rev_ind

save "Industry1_", replace
