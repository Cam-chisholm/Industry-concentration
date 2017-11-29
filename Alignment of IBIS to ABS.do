clear
clear matrix
clear mata

cd "C:\Users\chisholmc\Dropbox (Personal)\Grattan\GitHub\Industry-concentration\IBIS data"

use Industry_4

merge 1:1 anzsic using IndustryBarriers
drop _merge

merge 1:1 anzsic using IndustryTradability
drop if _merge==2
drop _merge

gen ANZSIC_ABS = ""

replace ANZSIC_ABS = "A1" if inlist(substr(anzsic,1,3),"A01","A02","A05")
replace ANZSIC_ABS = "A2" if inlist(substr(anzsic,1,3),"A03","A04")
replace ANZSIC_ABS = "B1" if substr(anzsic,1,3)=="B06"
replace ANZSIC_ABS = "B2" if substr(anzsic,1,3)=="B07"
replace ANZSIC_ABS = "B3" if substr(anzsic,1,3)=="B08"
replace ANZSIC_ABS = "B4" if substr(anzsic,1,3)=="B09"
replace ANZSIC_ABS = "B5" if substr(anzsic,1,3)=="B10"
replace ANZSIC_ABS = "C1" if inlist(substr(anzsic,1,3),"C11","C12")
replace ANZSIC_ABS = "C2" if inlist(substr(anzsic,1,3),"C17","C18","C19")
replace ANZSIC_ABS = "C3" if inlist(substr(anzsic,1,3),"C21","C22")
replace ANZSIC_ABS = "C4" if inlist(substr(anzsic,1,3),"C23","C24")
replace ANZSIC_ABS = "C5" if substr(anzsic,1,1)=="C" & ANZSIC_ABS==""
replace ANZSIC_ABS = "D1" if substr(anzsic,1,3)=="D26"
replace ANZSIC_ABS = "D2" if substr(anzsic,1,3)=="D27"
replace ANZSIC_ABS = "D3" if inlist(substr(anzsic,1,3),"D28","D29")
replace ANZSIC_ABS = "E1" if substr(anzsic,1,3)=="E30"
replace ANZSIC_ABS = "E2" if substr(anzsic,1,3)=="E31"
replace ANZSIC_ABS = "E3" if substr(anzsic,1,3)=="E32"
replace ANZSIC_ABS = "F" if substr(anzsic,1,1)=="F"
replace ANZSIC_ABS = "G" if substr(anzsic,1,1)=="G"
replace ANZSIC_ABS = "H" if substr(anzsic,1,1)=="H"
replace ANZSIC_ABS = "I1" if substr(anzsic,1,3)=="I46"
replace ANZSIC_ABS = "I2" if substr(anzsic,1,3)=="I49"
replace ANZSIC_ABS = "I3" if inlist(substr(anzsic,1,3),"I47","I48","I50")
replace ANZSIC_ABS = "I4" if inlist(substr(anzsic,1,3),"I51","I52","I53")
replace ANZSIC_ABS = "J1" if substr(anzsic,1,3)=="J58"
replace ANZSIC_ABS = "J2" if substr(anzsic,1,1)=="J" & ANZSIC_ABS==""
replace ANZSIC_ABS = "K1" if substr(anzsic,1,3)=="K62"
replace ANZSIC_ABS = "K2" if inlist(substr(anzsic,1,3),"K63","K64")
replace ANZSIC_ABS = "L1" if substr(anzsic,1,3)=="L66"
replace ANZSIC_ABS = "L2" if substr(anzsic,1,3)=="L67"
replace ANZSIC_ABS = "M1" if substr(anzsic,1,3)=="M70"
replace ANZSIC_ABS = "M2" if substr(anzsic,1,3)=="M69"
replace ANZSIC_ABS = "N" if substr(anzsic,1,1)=="N"
replace ANZSIC_ABS = "O" if substr(anzsic,1,1)=="O"
replace ANZSIC_ABS = "P" if substr(anzsic,1,1)=="P"
replace ANZSIC_ABS = "Q" if substr(anzsic,1,1)=="Q"
replace ANZSIC_ABS = "R" if substr(anzsic,1,1)=="R"
replace ANZSIC_ABS = "S" if substr(anzsic,1,1)=="S"

encode ANZSIC_ABS, gen(AA)

gen group = .
replace group = 4 if natural_monopoly==0 & network_effects==0 & regulatory_barriers==0
replace group = 5 if traded==1
replace group = 6 if public==1
replace group = 1 if natural_monopoly==1
replace group = 2 if network_effects==1
replace group = 3 if regulatory_barriers==1

gen VA_NM = 0
gen VA_SE = 0
gen VA_RB = 0
gen VA_LB = 0
gen VA_Tr = 0
gen VA_Pub = 0

forvalues i=1(1)39 {
sum VA_ind if AA==`i' & group==1
replace VA_NM = r(sum) if AA==`i'
sum VA_ind if AA==`i' & group==2
replace VA_SE = r(sum) if AA==`i'
sum VA_ind if AA==`i' & group==3
replace VA_RB = r(sum) if AA==`i'
sum VA_ind if AA==`i' & group==4
replace VA_LB = r(sum) if AA==`i'
sum VA_ind if AA==`i' & group==5
replace VA_Tr = r(sum) if AA==`i'
sum VA_ind if AA==`i' & group==6
replace VA_Pub = r(sum) if AA==`i'
}

bysort AA: keep if _n==1




import delimited "C:\Users\chisholmc\Dropbox (Personal)\Grattan\GitHub\Industry-concentration\ANZSIC_ABS.csv", clear varn(1)

save ANZSIC_ABS, replace

use Industry_4

merge 1:1 anzsic using ANZSIC_ABS
