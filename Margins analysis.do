set seed 1234

matrix results1 = J(100,4,0)
matrix results2 = J(100,4,0)

scalar i = 1

forvalues i=1(1)100 {
use Industry, clear

merge m:1 company using Margins
keep if _merge==3
drop _merge

merge m:1 anzsic using IndustryTradability
drop if _merge==2
drop _merge

merge m:1 anzsic using IndustryBarriers
drop if _merge==2
drop _merge

drop if traded==1 | public==1 | margin==.
drop if inlist(anzsic,"A0192" ,"B0602" ,"B0911" ,"B0919","C113","C1171","C2021") & network_effects==0
drop if inlist(anzsic,"C2032","C2033","C2210","D2612" ,"D2640","D2619" ,"D2700" ,"D2611" ,"K6229") & network_effects==0
drop if inlist(anzsic,"K6310","K6419b","E3101","E3109","D2921","D2919","D2911","K6411b") & network_effects==0
drop if inlist(anzsic,"E3022","F3601","F3606a","H4513","I4901","I4902","J5412","J5411") & network_effects==0
drop if inlist(anzsic,"J5801","J5911","G4271b","G4211","G4222","G4212","G4241","G4252") & network_effects==0
drop if inlist(anzsic,"J5622","I5292b","I5309","I5102","R9131","G4000","G4260","F3339") & network_effects==0
drop if inlist(anzsic,"G4123","G4222","F3332","F3331","G3922","G4272","S9532","H4520") & network_effects==0
drop if inlist(anzsic,"F3606b","I5220") & network_effects==0


merge m:1 anzsic using MarketShares
drop if _merge==2
drop _merge marketshare1-MS_3firm MS_5firm-MS_7firm

gen rev_firm = rev_ind*marketshare/100

replace marketshare = marketshare + runiform()/100

bysort anzsic: egen rank = rank(marketshare)
bysort anzsic: egen max = max(rank)
replace rank = max - rank + 1
drop if rank>4
replace max = 4 if max>4

encode anzsic, gen(AA)
gen mean = 0
gen cost = 100/(margin/100+1)
gen SD = 0

gen max_rev_ = rev_firm if rank==1
bysort anzsic: egen max_rev = max(max_rev_)
drop max_rev_
gen rev_frac = rev_firm/max_rev

gen rank1_margin_ = margin if rank==1
bysort anzsic: egen rank1_margin = max(rank1_margin_)
drop rank1_margin_

bysort anzsic: egen max_cost = max(cost)
drop if max_cost>150

forvalues i=1(1)136 {
sum margin if AA==`i' [w=rev_firm]
replace mean = r(mean) if AA==`i'
sum margin if AA==`i'
replace SD = r(sd) if AA==`i'
}

replace mean = . if mean==0

gen margin_dev_mean = margin - mean
gen margin_dev_max = margin - rank1_margin

* Final regressions
reg margin_dev_mean i.rank if SD<15 & max>=3
matrix results1[i,1] = _b[_cons]
matrix results1[i,2] = _b[_cons] + _b[2.rank]
matrix results1[i,3] = _b[_cons] + _b[3.rank]
matrix results1[i,4] = _b[_cons] + _b[4.rank]
qreg margin_dev_mean i.rank if max>=3
matrix results2[i,1] = _b[_cons]
matrix results2[i,2] = _b[_cons] + _b[2.rank]
matrix results2[i,3] = _b[_cons] + _b[3.rank]
matrix results2[i,4] = _b[_cons] + _b[4.rank]

scalar i = i + 1
}

mata
(mean(st_matrix("results1"))\mean(st_matrix("results2")))'
end


/*
* weighted
reg margin_dev_mean i.rank if max>=3 [w=rev_firm]
qreg margin_dev_mean i.rank if max>=3 [pw=rev_firm]
reg margin_dev_max i.rank if max>=3 [w=rev_firm], nocons

* unweighted
reg margin_dev_mean i.rank if margin_dev_mean>-15 & margin_dev_mean<15 & max>=3
qreg margin_dev_mean i.rank if max>=3 
qreg margin_dev_mean i.rank if max==4 // rank 4 should be compared to industries with 4 major players
reg margin_dev_max i.rank if MS_4firm>50 & max>=3, nocons
reg margin_dev_max i.rank if MS_4firm>50 & max==4, nocons

lpoly margin_dev_mean marketshare if MS_4firm>50, gen(X Y)
twoway || sc margin_dev_mean marketshare if MS_4firm>50 [w=rev_firm], mcolor("248 168 102") mlcolor("246 139 51") mlw(.01) msize(1) ///
|| line Y X, lcolor("160 34 38") lw(.5)


reg rev_firm i.rank if MS_4firm>50 & max==4
*/
