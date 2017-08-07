clear
clear matrix
clear mata

cd "C:\Users\chisholmc\Dropbox (Personal)\Grattan\GitHub\Industry-concentration\Morningstar"

import delimited MS_1990_2017, varn(1)

forvalues i=4(1)31 {
local year = `i'+1986
rename v`i' year`year'
}

replace item = "equity" if item=="Annual Balance Sheet - Total Equity"
replace item = "npat" if item=="Annual Profit and Loss - Reported NPAT After Abnorma"
replace item = "revenue" if item=="Annual Profit and Loss - Total Revenue Excluding Int"
replace item = "marketcap" if item=="Annual Ratio Analysis - Market Cap.($)"
replace item = "roc" if item=="Annual Ratio Analysis - ROA"
replace item = "roe" if item=="Annual Ratio Analysis - ROE"
replace item = "capex" if item=="Annual Sundry Analysis - Capex"
replace item = "intangibles" if item=="Annual Sundry Analysis - Intangibles Ex.Goodwill"

reshape long year, i(asxcode item) j(time)
encode item, gen(item_)
drop item
replace year = subinstr(year,",","",5)
replace year = subinstr(year,"%","",1)
destring year, force replace

reshape wide year, i(asxcode time) j(item_)

rename year1 capex
rename year2 equity
rename year3 intangibles
rename year4 marketcap
rename year5 npat
rename year6 revenue
rename year7 roc
rename year8 roe
rename companyname company
rename asxcode asx
rename time year
move company capex

sort year
by year: egen rank = rank(-marketcap)

forvalues i=1990(1)2016 {

}
