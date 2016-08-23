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

save CompanySegment, replace

* Financials going back up to 10 years
import delimited CompanyTimeSeries.csv, clear

drop currency
rename identerprise id
rename companyname company

keep id-accountingperiod totalrevenue npbt npat totalassets totalliabilities ///
sharecapital totalshareholderequity employees 

save CompanyTimeSeries, replace

* Data across ANZSIC industies
import delimited FiveYearIndustry.csv, clear

forvalues i=2011(1)2016 {
rename revenuem`i' rev_`i'
rename ivam`i' value_added_`i'
rename enterprises`i' no_of_businesses_`i'
rename wagesm`i' wages_`i'
}

drop revenuecagr
rename code anzsic

save FiveYearIndustry, replace

* Market shares
import delimited MarketShares.csv, clear

rename code anzsic
rename coststructureprofit profit_share
rename coststructurewages wages_share
rename majorplayer company
rename marketshare market_share

keep anzsic profit_share wages_share company market_share

save MarketShares, replace

