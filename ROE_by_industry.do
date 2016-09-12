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
keep if accountingperiod==12
drop accountingperiod
gen month = substr(balancedate,4,3)
gen Month = .
replace Month = 1 if month=="Jan"
replace Month = 2 if month=="Feb"
replace Month = 3 if month=="Mar"
replace Month = 4 if month=="Apr"
replace Month = 5 if month=="May"
replace Month = 6 if month=="Jun"
replace Month = 7 if month=="Jul"
replace Month = 8 if month=="Aug"
replace Month = 9 if month=="Sep"
replace Month = 10 if month=="Oct"
replace Month = 11 if month=="Nov"
replace Month = 12 if month=="Dec"
sort id year Month
by id: gen t = _n
xtset id t

gen month_gap = (year-l.year)*12 + Month-l.Month

gen roe = npat/totalshareholderequity
gen roe_beginning = npat/l.totalshareholderequity if month_gap>9 & month_gap<19

replace company = "IBM A/NZ Holdings" if company=="IBM A/NZ Holdings "
replace company = "Caterpillar Financial" if company=="Caterpillar Financial "

save CompanyTimeSeries, replace

keep id company year t roe roe_beginning npat totalshareholderequity Month month_gap

sort id t

gen same_year = 0
forvalues i=1(1)10 {
replace same_year = year==f.year
replace year = year-1 if same_year==1
}



drop Month t month_gap same_year

reshape wide roe roe_beginning npat totalshareholderequity , i(id) j(year)

drop npat2016-roe_beginning2016

gen npat = 0
gen equity = 0
forvalues i=2015(-1)2011 {
local j =`i'-1
replace npat = npat + npat`i' if npat`i'~=. & totalshareholderequity`j'~=.
replace equity = equity + totalshareholderequity`j' if npat`i'~=. & totalshareholderequity`j'~=.
}

gen roe_5yr = npat/equity

keep id company roe* npat equity
drop roe2003-roe_beginning2009
move company roe2010
replace roe_5yr=. if roe_5yr==0
rename npat profit_2011_15
rename equity equity_2010_14

save CompanyROE2015, replace

use CompanyTimeSeries, clear
drop t month_gap

sort id year Month
by id: egen max_year = max(year)
by id: gen t = _n
sort id t
gen max_year2 = max_year==2016 & l.year==2015
drop if max_year2==1
drop max_year2
keep if year==max_year | year==2015

merge 1:1 id company using CompanyROE2015
keep if _merge==3
drop _merge
drop month-t

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

* MERGERS

* using industry data as anchor
use MarketShares, clear

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
gen HH = market_share1^2
forvalues i=1(1)6 {
local j =`i'+1
gen MS_`j'firm = MS_`i'firm + market_share`j' if market_share`j'~=.
replace MS_`j'firm = MS_`i'firm if MS_`j'firm==.
replace HH = HH + market_share`j'^2 if market_share`j'~=.
}

gen ind_profit = 0
gen ind_equity = 0
gen MS_sum1 = 0
gen MS_sum2 = 0
forvalues i=1(1)7 {
replace ind_profit = ind_profit + market_share`i'*npat`i' if npat`i'~=. & totalshareholderequity`i'~=.
replace ind_equity = ind_equity + market_share`i'*totalshareholderequity`i' if npat`i'~=. & totalshareholderequity`i'~=.
replace MS_sum1 = MS_sum1 + market_share`i' if npat`i'~=. & totalshareholderequity`i'~=.
}

replace ind_profit = ind_profit/MS_sum1
replace ind_equity = ind_equity/MS_sum1
gen ind_roe = ind_profit/ind_equity

keep anzsic MS_2firm MS_3firm MS_4firm HH ind_roe

save FourFirmMS, replace



* using segment data as anchor
use CompanySegment, clear

egen rank = group(revenuerank company)
drop revenuerank

egen firm_seg = group(rank segmentcode)

sort firm_seg
by firm_seg: gen ind_no = _n
by firm_seg: gen no_ind = _N

sort rank segmentcode ind_no
by rank: egen no_seg_firm = max(segmentcode)
gen unallocated = segmentname=="Unallocated"



putmata rank revenue profits assets no_segments unallocated firm_seg ind_no no_ind, replace

mata
firm_rev = J(rows(revenue),1,.)
firm_profits = J(rows(revenue),1,.)
firm_assets = J(rows(revenue),1,.)
missing_seg_rev = J(rows(revenue),1,0)
missing_seg_prof = J(rows(revenue),1,0)
missing_seg_ast = J(rows(revenue),1,0)
rank = rank\0
a=0
while (a<rows(revenue)) {
b=a+1
b
rev = 0
prof = 0
ast = 0
while (rank[a+1]==rank[b]) {
if (ind_no[a+1]==1 & revenue[a+1]~=. & unallocated[a+1]==0) {
rev = rev + revenue[a+1]
}
if (ind_no[a+1]==1 & profits[a+1]~=. & unallocated[a+1]==0) {
prof = prof + profits[a+1]
}
if (ind_no[a+1]==1 & assets[a+1]~=. & unallocated[a+1]==0) {
ast = ast + assets[a+1]
}
a=a+1
}
if (rev~=0) {
firm_rev[b..a] = J(a-b+1,1,rev)
}
else {
firm_rev[b..a] = J(a-b+1,1,revenue[a])
missing_seg_rev[b..a] = J(a-b+1,1,1)
}
if (prof~=0) {
firm_profits[b..a] = J(a-b+1,1,prof)
}
else {
firm_profits[b..a] = J(a-b+1,1,profits[a])
missing_seg_prof[b..a] = J(a-b+1,1,1)
}
if (ast~=0) {
firm_assets[b..a] = J(a-b+1,1,ast)
}
else {
firm_assets[b..a] = J(a-b+1,1,assets[a])
missing_seg_ast[b..a] = J(a-b+1,1,1)
}
}
end

getmata firm_rev firm_profits firm_assets missing_seg_rev missing_seg_prof missing_seg_ast, replace

gen revenue_share = revenue/firm_rev
gen profit_share = profits/firm_profits
gen assets_share = assets/firm_assets

merge m:1 company using CompanyROE2015
drop _merge

sort firm_seg

gen equity = assets_share*totalshareholderequity
gen segment_roe = profit_share*npat/equity
replace segment_roe = . if unallocated==1
replace equity = . if unallocated==1

merge m:1 anzsic company using MarketShares
drop if _merge==2
drop _merge
merge m:1 anzsic using FiveYearIndustry
drop if _merge==2
drop _merge
keep id-market_share ind_rev_2015 ind_value_added_2015 no_of_businesses_2015 ind_wages_2015 anzsic1-major_industry

sort firm_seg

gen firm_ind_rev = market_share*ind_rev_2015/100

merge m:1 anzsic using FourFirmMS
drop if _merge==2
drop _merge

sort firm_seg

save Company_merged_Industry, replace

* Calculate firm's exposure to each industry

use Company_merged_Industry, clear

* Simple approach: ignore segment information

sort no_segments anzsic company

gen t = _n
tsset t
encode anzsic, gen(A)
gen drop = A==l.A & rank==l.rank
drop if drop==1
drop drop t

sort rank A

by rank: egen count_ind = count(rank) if firm_ind_rev==.

replace firm_ind_rev = totalrevenue if count_ind==1


by rank: egen cumulative_firm_revenue = sum(firm_ind_rev) if major_industry==0
gen firm_rev_remaining = max(0,totalrevenue - cumulative_firm_revenue)

sort A
by A: egen cumulative_ind_revenue = sum(firm_ind_rev)
gen ind_rev_remaining = max(0,ind_rev_2015 - cumulative_ind_revenue)

sort rank A

gen est_firm_ind_rev = ind_rev_remaining if firm_ind_rev==.
by rank: egen scale = sum(ind_rev_remaining) if firm_ind_rev==.
replace est_firm_ind_rev = est_firm_ind_rev*firm_rev_remaining/scale
replace est_firm_ind_rev = firm_ind_rev if est_firm_ind_rev==.
drop scale

by rank: egen total_firm_ind_rev = sum(est_firm_ind_rev) if major_industry==0
gen share_firm_ind_rev = est_firm_ind_rev/total_firm_ind_rev

keep id company rank anzsic* A totalrevenue share_firm_ind_rev roe* MS_3firm MS_4firm HH

drop if A==.

* assign tradable sectors (agri, manu, mining) a low concentration measure
gen tradable = anzsic1=="A" | anzsic1=="B" | anzsic1=="C"
replace HH = 50 if tradable==1 & HH>50 & HH~=.
replace MS_4firm = 5 if tradable==1 & MS_4firm>5 & MS_4firm~=.
replace MS_3firm = 5 if tradable==1 & MS_3firm>5 & MS_3firm~=.

* exposure to concentrated industries
gen weight_concHH = HH*share_firm_ind_rev
gen weight_conc4 = MS_4firm*share_firm_ind_rev

by rank: egen exposureHH = sum(weight_concHH)
by rank: egen exposure4 = sum(weight_conc4)

forvalues i=2010(1)2015 {
sum roe`i', detail
gen extreme`i' = roe`i'<r(p5) | roe`i'>r(p95) if roe`i'~=.
sum roe_beginning`i', detail
gen extreme_b_`i' = roe_beginning`i'<r(p5) | roe_beginning`i'>r(p95) if roe_beginning`i'~=.
}

gen extreme = extreme2010==1 | extreme2011==1 | extreme2012==1 | extreme2013==1 | extreme2014==1 | extreme2015==1 | ///
extreme_b_2010==1 | extreme_b_2011==1 | extreme_b_2012==1 | extreme_b_2013==1 | extreme_b_2014==1 | extreme_b_2015==1

sort rank 
by rank: egen tradability = sum(share_firm_ind_rev*tradable)

save CompanyExposure, replace

by rank: gen t = _n
keep if t==1
drop t

* local polynomial regressions
lpoly roe_5yr exposureHH if extreme~=1 [aweight=totalrevenue], ci nosc
lpoly roe2015 exposureHH if extreme2015~=1 [aweight=totalrevenue], ci nosc
lpoly roe_beginning2015 exposureHH if extreme_b_2015~=1 [aweight=totalrevenue], ci nosc

lpoly roe_5yr exposure4 if extreme~=1 [aweight=totalrevenue], ci nosc
lpoly roe2015 exposure4 if extreme2015~=1 [aweight=totalrevenue], ci nosc
lpoly roe_beginning2015 exposure4 if extreme_b_2015~=1 [aweight=totalrevenue], ci nosc

* regressions against concentration dummies
egen exp4_ = cut(exposure4), at(0,15,30,45,60,75,100)
egen expHH_ = cut(exposureHH), at(0,500,1000,1500,2000,10000)

reg roe_5yr i.exp4_ if extreme~=1 [aweight=totalrevenue]
reg roe_5yr i.expHH_ if extreme~=1 [aweight=totalrevenue]
forvalues i=2010(1)2015 {
reg roe`i' i.exp4_ if extreme`i'~=1 [aweight=totalrevenue]
reg roe_beginning`i' i.exp4_ if extreme_b_`i'~=1 [aweight=totalrevenue]
reg roe`i' i.expHH_ if extreme`i'~=1 [aweight=totalrevenue]
reg roe_beginning`i' i.expHH_ if extreme_b_`i'~=1 [aweight=totalrevenue]
}

keep A anzsic tradable

sort A

by A: gen n = _n
keep if n==1
drop n
save IndustryList, replace

* Reshape and calculate share in each concentration group (tradables given own group)

use CompanyExposure, clear

drop weight_concHH-exposure4

egen exp4_ = cut(MS_4firm), at(0,15,30,45,60,75,100)
egen expHH_ = cut(HH), at(0,500,1000,1500,2000,10000)
replace exp4_ = 9999 if tradable==1
replace expHH_ = 9999 if tradable==1

sort rank exp4_

by rank exp4_: egen SHARE = sum(share_firm_ind_rev)
local EXP4 "0 15 30 45 60 75 9999"
foreach x of local EXP4 {
by rank: egen share`x' = max(SHARE) if exp4_==`x'
by rank: egen share_`x' = max(share`x')
replace share_`x' = 0 if share_`x'==.
drop share`x'
}

gen SUM = share_0 + share_15 + share_30 + share_45 + share_60 + share_75 + share_9999
foreach x of local EXP4 {
replace share_`x' = share_`x'/SUM if SUM~=0 & SUM~=.
}
drop SUM SHARE

sort rank expHH_

by rank expHH_: egen SHARE = sum(share_firm_ind_rev)
local EXP4 "0 500 1000 1500 2000 9999"
foreach x of local EXP4 {
by rank: egen share`x' = max(SHARE) if expHH_==`x'
by rank: egen shareHH_`x' = max(share`x')
replace shareHH_`x' = 0 if shareHH_`x'==.
drop share`x'
}


gen SUM = shareHH_0 + shareHH_500 + shareHH_1000 + shareHH_1500 + shareHH_2000 + shareHH_9999
foreach x of local EXP4 {
replace shareHH_`x' = shareHH_`x'/SUM if SUM~=0 & SUM~=.
}
drop SUM SHARE

by rank: gen t = _n
keep if t==1
drop t exp4_ expHH_

rename share_9999 share_tradable
drop shareHH_9999


* regressions against shares in each concentration group
reg roe_5yr share_0-share_75 share_tradable if extreme~=1 [aweight=totalrevenue], nocons
reg roe_5yr shareHH* share_tradable if extreme~=1 [aweight=totalrevenue], nocons
forvalues i=2010(1)2015 {
reg roe`i' share_0-share_75 share_tradable if extreme`i'~=1 [aweight=totalrevenue], nocons
reg roe_beginning`i' share_0-share_75 share_tradable if extreme_b_`i'~=1 [aweight=totalrevenue], nocons
reg roe`i' shareHH* share_tradable if extreme`i'~=1 [aweight=totalrevenue], nocons
reg roe_beginning`i' shareHH* share_tradable if extreme_b_`i'~=1 [aweight=totalrevenue], nocons
}




* Reshape and run regression against share in each industry

use CompanyExposure, clear

drop weight_concHH-exposure4
drop anzsic

reshape wide anzsic1-MS_4firm share_firm_ind_rev tradable, i(rank) j(A)

forvalues i=1(1)470 {
replace share_firm_ind_rev`i' = 0 if share_firm_ind_rev`i'==.
}

reg roe_5yr share_firm_ind_rev* if roe_5yr>-.3 & roe_5yr<.5 [aweight=totalrevenue], nocons

est sto ROE



use FourFirmMS, clear

merge 1:1 anzsic using IndustryList
drop _merge
sort A


forvalues i=1(1)470 {
gen share_firm_ind_rev`i' = 0
replace share_firm_ind_rev`i' = 1 if A==`i'
}

est res ROE

predict ROE
drop share_firm_ind_rev*

merge 1:1 anzsic using FiveYearIndustry
drop _merge

egen exp4_ = cut(MS_4firm), at(0,15,30,45,60,75,100)
egen expHH_ = cut(HH), at(0,500,1000,1500,2000,10000)

reg ROE i.exp4_ [aweight=ind_rev_2015] if ROE>-.3 & ROE<.5 & tradable==0
reg ROE i.expHH_ [aweight=ind_rev_2015] if ROE>-.3 & ROE<.5 & tradable==0
