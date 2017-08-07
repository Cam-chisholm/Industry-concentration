clear
clear matrix
clear mata

cd "C:\Users\chisholmc\Dropbox (Personal)\Grattan\GitHub\Industry-concentration\IBIS data"

use IndustryTradability, clear

replace anzsic = substr(anzsic,1,3)

sort anzsic
by anzsic: egen traded_ = max(traded)
replace traded = traded_
drop traded_

by anzsic: keep if _n==1

save IndustryTradability2, replace

use CompanyMerged, clear

rename main_anzsic anzsic
rename local ownership

gen revenue_flag = revenue>500000

sort company

by company: egen revenue_flag_ = max(revenue_flag)

drop revenue_flag
rename revenue_flag_ revenue_flag

by company: egen ROE_avg = mean(roe)
by company: egen ROE_med = median(roe)
by company: egen ROE_max = max(roe)
by company: egen ROE_min = min(roe)
gen obs = roe~=. & growth~=.
by company: egen count = sum(obs)

by company: egen ROC_avg = mean(roc)
by company: egen ROC_med = median(roc)
by company: egen ROC_max = max(roc)
by company: egen ROC_min = min(roc)

gen Assets_revenue = assets/revenue000
by company: egen assets_revenue = mean(Assets_revenue)
drop Assets_revenue

by company: egen debt_equity = mean(debtequity)

gen DE_flag = debt_equity>20 // roughly 10% excluded
gen AR_flag = assets_revenue<0.25 // roughly the bottom quartile excluded

by company: egen growth_avg = mean(growth)
by company: egen growth_med = median(growth)

gen growth_flag = growth_avg<.1

gen roe_flag = ROE_avg>.1 & ROE_med>.1
gen roc_flag = ROC_avg>.02 & ROC_med>.02

merge m:1 anzsic using AnzsicNames
drop if _merge==2
drop _merge

merge m:1 anzsic using IndustryTradability
drop if _merge==2
drop _merge

rename traded traded_
rename public public_

merge m:1 anzsic using IndustryTradability2
drop if _merge==2
drop _merge

replace traded = traded_ if traded==.
replace public = public_ if public==.

drop traded_ public_

sum ROE_med [w=equity] if equity>0, detail
gen ROE_med_trim = ROE_med if equity>0 & ROE_med>r(p1) & ROE_med<r(p99)

sum growth_med [w=equity] if equity>0, detail
gen growth_med_trim = growth_med if equity>0 & growth_med>r(p1) & growth_med<r(p99)

reg ROE_avg growth_avg [w=equity] if DE_flag==0 & AR_flag==0 & traded==0 & ysc==0 
reg ROE_med_trim growth_med_trim [w=equity] if DE_flag==0 & AR_flag==0 & traded==0 & ysc==0 
tobit ROE_med growth_med [w=equity] if DE_flag==0 & AR_flag==0 & traded==0 & ysc==0 & equity>0, ll(-.5) ul(.7)

gsort -ROE_med

list ind_name if DE_flag==0 & AR_flag==0 & traded==0 & ysc==0 & equity>0 & ROE_med>.1 & growth_med<.1 & ROE_med~=. & type>2

sort ind_name
by ind_name: egen ind_count = sum(obs) if DE_flag==0 & AR_flag==0 & traded==0 & ysc==0 & equity>0 & ROE_med>.1 & growth_med<.1  & ROE_med~=. & type>2
by ind_name: egen ind_count_total = sum(obs) if DE_flag==0 & AR_flag==0 & traded==0 & ysc==0 & equity>0 & ROE_med~=. & type>2

gen ind_frac = ind_count/ind_count_total

gsort -ind_frac

list anzsic company ROE_med ind_frac if ind_frac~=. & ind_count>3



gsort -ROE_avg 

edit company anzsic type ownership traded revenue000 ROE_avg ROE_med ROE_max ROE_min ROC_avg debt_equity assets_revenue growth_avg count ind_name  if revenue_flag==1 & ysc==0
