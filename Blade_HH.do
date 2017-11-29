clear
clear mata
clear matrix

cd "C:\Users\chisholmc\Dropbox (Personal)\Grattan\GitHub\Industry-concentration\IBIS data"

use Industry_3, clear

gen anzsic3 = substr(anzsic,2,4)

destring anzsic3, replace

merge 1:1 anzsic3 using Anzsic3Names

keep if _merge==2 | _merge==3
drop _merge

save Anzsic_3, replace



use "C:\Users\chisholmc\Dropbox (Personal)\Grattan\GitHub\Industry-concentration\BLADE data\HH03_vs_14.dta", clear

reshape wide n h share_one share_two, i(anzsic) j(year)

rename anzsic anzsic3

merge 1:1 anzsic3 using Anzsic_3

keep if _merge==3
drop _merge
