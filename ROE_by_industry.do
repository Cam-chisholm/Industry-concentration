clear
clear matrix
clear mata

cd "C:\Users\chisholmc\Dropbox (Personal)\Grattan\GitHub\Industry-concentration\IBIS data"

// Import IBISWorld Data from various spreadsheets //

* Company Information
import delimited CompanyInfo.csv, clear

rename identerprise id
rename companyname company
rename asxcode asx
rename stateofincorporation state

encode companytype, gen(type)
encode ownershiptype, gen(ownership)
gen main_anzsic = substr(mainindustrycode,1,6)
replace main_anzsic = substr(main_anzsic,1,5) if substr(main_anzsic,6,6)==" "
replace main_anzsic = substr(main_anzsic,1,3) if substr(main_anzsic,5,5)=="-"
gen years_active = 2016-incorporationyear

keep id-revenuerank asx state-years_active

save CompanyInfo, replace

* Data on Firms' various segments
import delimited CompanySegment.csv, clear

rename identerprise id
rename companyname company
rename anzsiccode anzsic
encode ismajorplayer, gen(major_player)

drop segmenttype ismajorplayer

replace assets = . if assets==0
replace revenue = . if revenue==0
replace profits = . if profits==0

egen anzsic_firm = group(anzsic revenuerank)

putmata anzsic_firm, replace

mata
no_segments = J(rows(anzsic_firm),1,1)
for(a=1; a<=rows(anzsic_firm); a++) {
a
no_segments[a] = sum(anzsic_firm:==anzsic_firm[a])
}
end

getmata no_segments, replace
replace no_segments = 1 if no_segments>100
drop anzsic_firm

save CompanySegment, replace

* Financials going back up to 10 years
import delimited CompanyTimeSeries.csv, clear

drop currency
rename identerprise id
rename companyname company

keep id-accountingperiod totalrevenue npbt npat totalassets totalliabilities ///
sharecapital totalshareholderequity employees 

replace npbt = . if npbt==0
replace npat = . if npat==0
replace totalassets = . if totalassets==0
replace totalliabilities = . if totalliabilities==0
replace totalshareholderequity = . if totalshareholderequity==0
replace employees = . if employees==0
gen roe = npat/totalshareholderequity

putmata revenuerank year npat tse=totalshareholderequity, replace

mata
roe_5yr = J(rows(revenuerank),1,.)
npat_5yr = J(rows(revenuerank),1,.)
equity_5yr = J(rows(revenuerank),1,.)
a = 1
b = 1
while (a<rows(revenuerank)) {
a
profit = 0
equity = 0
b = a
while (revenuerank[a]==revenuerank[a+1] & year[a]>2010 & year[a]<2016) {
profit = profit + npat[a]
equity = equity + tse[a]
a = a+1
}
if (b<a) {
roe_5yr[b..a-1] = J(a-b,1,profit/equity)
npat_5yr[b..a-1] = J(a-b,1,profit)
equity_5yr[b..a-1] = J(a-b,1,equity)
}
a = a+1
}
end

getmata roe_5yr npat_5yr equity_5yr, replace

save CompanyTimeSeries, replace

keep if year==2015 | yearsincecurrent==0
keep if accountingperiod==12
drop if year==2016

save CompanyROE2015, replace



* Data across ANZSIC industies
import delimited FiveYearIndustry.csv, clear

forvalues i=2011(1)2016 {
rename revenuem`i' ind_rev_`i'
rename ivam`i' ind_value_added_`i'
rename enterprises`i' no_of_businesses_`i'
rename wagesm`i' ind_wages_`i'
replace ind_rev_`i' = ind_rev_`i'*1000
replace ind_value_added_`i' = ind_value_added_`i'*1000
replace ind_wages_`i' = ind_wages_`i'*1000
}

drop revenuecagr
rename code anzsic

gen anzsic4 = substr(anzsic,1,5)

merge m:1 anzsic4 using ANZSIC
drop if _merge==2
rename _merge merge
rename anzsic3 anzsic_3
gen anzsic3 = substr(anzsic,1,4)
merge m:1 anzsic3 using ANZSIC3
drop if _merge==2
gen major_industry = _merge==1 & substr(anzsic,1,1)~="X" & substr(anzsic,1,1)~="O"
drop anzsic_3
replace anzsic2 = substr(anzsic,1,3) if anzsic2==""
replace anzsic1 = substr(anzsic,1,1) if anzsic1==""
drop merge _merge anzsic4

save FiveYearIndustry, replace

* Market shares
import delimited MarketShares.csv, clear

rename code anzsic
rename coststructureprofit profit_share
rename coststructurewages wages_share
rename majorplayer company
rename marketshare market_share
replace company = "No major players" if company=="There are no major players in this industry"
replace market_share = . if market_share==0

keep anzsic profit_share wages_share company market_share

save MarketShares, replace

* Mergers (and acquisitions...)
merge m:1 anzsic using FiveYearIndustry
drop _merge

gen ind_profits_2015 = profit_share*ind_rev_2015/100
gen firm_ind_rev_2015 = market_share*ind_rev_2015/100

merge m:1 company using CompanyROE2015
drop if _merge==2
drop _merge

keep if major_industry==0
drop major_industry

gen firm_share = firm_ind_rev_2015/totalrevenue*100

gsort anzsic -market_share

by anzsic: gen firm_no = _n
by anzsic: gen no_firm = _N

reshape wide profit_share-market_share firm_ind_rev_2015-firm_share, i(anzsic) j(firm_no)

move title profit_share1

gen MS_1firm = market_share1
forvalues i=1(1)6 {
local j =`i'+1
gen MS_`j'firm = MS_`i'firm + market_share`j' if market_share`j'~=.
replace MS_`j'firm = MS_`i'firm if MS_`j'firm==.
}

/*
forvalues i=1(1)7 {
gen weight`i' = 0
forvalues j=`i'(1)7 {
replace weight`i' = market_share`i'/MS_`j'firm if no_firm==`j'
}
}
*/

gen ind_profit = 0
gen ind_profit_5yr = 0
gen ind_equity = 0
gen ind_equity_5yr = 0
gen MS_sum1 = 0
gen MS_sum2 = 0
forvalues i=1(1)7 {
replace ind_profit = ind_profit + market_share`i'*npat`i' if npat`i'~=. & totalshareholderequity`i'~=.
replace ind_profit_5yr = ind_profit_5yr + market_share`i'*npat_5yr`i' if npat_5yr`i'~=. & equity_5yr`i'~=.
replace ind_equity = ind_equity + market_share`i'*totalshareholderequity`i' if npat`i'~=. & totalshareholderequity`i'~=.
replace ind_equity_5yr = ind_equity_5yr + market_share`i'*equity_5yr`i' if npat_5yr`i'~=. & equity_5yr`i'~=.
replace MS_sum1 = MS_sum1 + market_share`i' if npat`i'~=. & totalshareholderequity`i'~=.
replace MS_sum2 = MS_sum2 + market_share`i' if npat_5yr`i'~=. & equity_5yr`i'~=.
}

replace ind_profit = ind_profit/MS_sum1
replace ind_profit_5yr = ind_profit_5yr/MS_sum2
replace ind_equity = ind_equity/MS_sum1
replace ind_equity_5yr = ind_equity_5yr/MS_sum2
gen ind_roe = ind_profit/ind_equity
gen ind_roe_5yr = ind_profit_5yr/ind_equity_5yr



*merge 1:m anzsic company using CompanySegment

