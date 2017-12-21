clear
clear matrix
clear mata

cd "C:\Users\chisholmc\Dropbox (Personal)\Grattan\GitHub\Industry-concentration\IBIS data"

// Import IBISWorld Data from various spreadsheets //

* Data across ANZSIC industies
import delimited FiveYearIndustry.csv, clear

gen growth_rev = ((revenuem2016/revenuem2011)^0.2-1)*100
gen growth_VA = ((ivam2016/ivam2011)^0.2-1)*100

rename code anzsic

keep anzsic growth*

save IndustryGrowth, replace

import delimited ANZSIC.csv, clear
rename v1 ANZSIC1
rename v2 ANZSIC2
rename v3 ANZSIC3
rename v4 ANZSIC4

save ANZSIC, replace

import delimited AnzsicNames.csv, clear
rename v1 anzsic
rename v2 ind_name

* provide shorter names for certain industries
replace ind_name = substr(ind_name,1,strpos(ind_name," and "))+"&"+substr(ind_name,strpos(ind_name, " and ")+4,length(ind_name)) if strpos(ind_name, " and ")>0
replace ind_name = substr(ind_name,1,strpos(ind_name," and "))+"&"+substr(ind_name,strpos(ind_name, " and ")+4,length(ind_name)) if strpos(ind_name, " and ")>0
replace ind_name = substr(ind_name,1,strpos(ind_name," AND "))+"&"+substr(ind_name,strpos(ind_name, " AND ")+4,length(ind_name)) if strpos(ind_name, " AND ")>0

replace ind_name = substr(ind_name,1,strpos(ind_name,"Manufacturing")-1)+"Mfg." if strpos(ind_name, "Manufacturing")==length(ind_name)-12 & strpos(ind_name, "Manufacturing")>0
replace ind_name = substr(ind_name,1,strpos(ind_name,"Retailing")-1)+"Rtl." if strpos(ind_name, "Retailing")==length(ind_name)-8 & strpos(ind_name, "Retailing")>0
replace ind_name = substr(ind_name,1,strpos(ind_name,"Wholesaling")-1)+"Whl." if strpos(ind_name, "Wholesaling")==length(ind_name)-10 & strpos(ind_name, "Wholesaling")>0
replace ind_name = substr(ind_name,1,strpos(ind_name,"Services")-1)+"Serv." if strpos(ind_name, "Services")==length(ind_name)-7 & strpos(ind_name, "Services")>0

replace ind_name = "Prof., Sci. & Tech." if ind_name=="Professional, Scientific & Technical Services (Except Computer System Design & Related Services)"
replace ind_name = "Domestic Banks" if ind_name=="National & Regional Commercial Banks"
replace ind_name = "Financial Planning" if ind_name=="Financial Planning & Investment Advice"
replace ind_name = "Other Property Operators" if ind_name=="Industrial & Other Property Operators"
replace ind_name = "Funds Mgt. Serv." if ind_name=="Funds Management Serv."
replace ind_name = "Heavy Industry Const." if ind_name=="Heavy Industry & Other Non-Building Construction"
replace ind_name = "Wired Telecom." if ind_name=="Wired Telecommunications Network Operation"
replace ind_name = "Wireless Telecom." if ind_name=="Wireless Telecommunications Carriers"
replace ind_name = "Free-to-Air TV" if ind_name=="Free-to-Air Television Broadcasting"
replace ind_name = "Fossil Fuel Elec. Gen." if ind_name=="Fossil Fuel Electricity Generation"
replace ind_name = "Supermarkets" if ind_name=="Supermarkets & Grocery Stores"
replace ind_name = "Road & Bridge Const." if ind_name=="Road & Bridge Construction"
replace ind_name = "Pharmaceutical Prod. Mfg." if ind_name=="Pharmaceutical Product Mfg."
replace ind_name = "ISPs" if ind_name=="Internet Service Providers"
replace ind_name = "Ready-Mixed Concr. Mfg." if ind_name=="Ready-Mixed Concrete Mfg."
replace ind_name = "Petroleum Prod. Whl." if ind_name=="Petroleum Product Whl."
replace ind_name = "Sports Betting" if ind_name=="Horse & Sports Betting"
replace ind_name = "Internet Publishing" if ind_name=="Internet Publishing & Broadcasting"
replace ind_name = "Comp. & Software Rtl." if ind_name=="Computer & Software Rtl."
replace ind_name = "Auxiliary Financial Serv." if ind_name=="Custody, Trustee & Stock Exchange Serv."
replace ind_name = "Computer Whl." if ind_name=="Computer & Computer Peripheral Whl."
replace ind_name = "Inv. & Security Serv." if ind_name=="Investigation & Security Serv."
replace ind_name = "Commercial Const." if ind_name=="Commercial & Industrial Building Construction"
replace ind_name = "Medical Equip. Whl." if ind_name=="Medical & Scientific Equipment Whl."
replace ind_name = "Pre-packaged Food Whl." if ind_name=="Soft Drink & Pre-Packaged Food Whl."
replace ind_name = "Serv. to Water Transport" if ind_name=="Navigation, Towage & Services to Water Transport"
replace ind_name = "Travel Serv." if ind_name=="Travel Agency & Tour Arrangement Serv."
replace ind_name = "Chem. Product Whl." if ind_name=="Industrial & Agricultural Chemical Product Whl."
replace ind_name = "Delivery Serv." if ind_name=="Courier Pick-up & Delivery Serv."
replace ind_name = "Freight Forwarding" if ind_name=="Rail, Air & Sea Freight Forwarding"
replace ind_name = "Ind. Mach. Whl." if ind_name=="Mining & Industrial Machinery Whl."
replace ind_name = "General Warehousing" if ind_name=="General Warehousing & Cold Storage"
replace ind_name = "Farm & Const. Mach. Whl." if ind_name=="Farm & Construction Machinery Whl."
replace ind_name = "Comp. System Design" if ind_name=="Computer System Design Serv."
replace ind_name = "Passenger Car Rental" if ind_name=="Passenger Car Rental & Hiring"
replace ind_name = "Wooden Struc. Cmpt. Mfg." if ind_name=="Wooden Structural Component Mfg."
replace ind_name = "Investment Banking" if ind_name=="Investment Banking & Securities Brokerage"
replace ind_name = "Commercial Cleaning" if ind_name=="Commercial Cleaning Serv."
replace ind_name = "Inst. Building Const." if ind_name=="Institutional Building Construction"
replace ind_name = "Sport & Camping Equip. Rtl." if ind_name=="Sport & Camping Equipment Rtl."
replace ind_name = "Heavy Mach. Repair & Maint." if ind_name=="Heavy Machinery Repair & Maintenance"
replace ind_name = "Aged Care Residential" if ind_name=="Aged Care Residential Serv."
replace ind_name = "Residential Prop. Opr." if ind_name=="Residential Property Operators"
replace ind_name = "Office Prop. Opr." if ind_name=="Office Property Operators"
replace ind_name = "Oil & Gas Extrac." if ind_name=="Oil & Gas Extraction"
replace ind_name = "Higher Ed." if ind_name=="University & Other Higher Education"
replace ind_name = "Telecom. Whl." if ind_name=="Telecommunications & Other Electrical Goods Whl."
replace ind_name = "Retail Prop. Opr." if ind_name=="Retail Property Operators"
replace ind_name = "Petroleum Fuel Mfg." if ind_name=="Petroleum Refining & Petroleum Fuel Mfg."
replace ind_name = "Hardware Rtl." if ind_name=="Hardware & Building Supplies Rtl."
replace ind_name = "Grocery Whl." if ind_name=="General Line Grocery Whl."
replace ind_name = "Apartment & Townhouse Cons." if ind_name=="Multi-Unit Apartment & Townhouse Construction"
replace ind_name = "Gold Processing" if ind_name=="Gold & Other Non-Ferrous Metal Processing"
replace ind_name = "Police & Firefighting" if ind_name=="Police & Firefighting Serv."
replace ind_name = "MV Engine & Parts Repair" if ind_name=="Motor Vehicle Engine & Parts Repair & Maintenance"
replace ind_name = "Agri. Supplies Whl." if ind_name=="Livestock & Other Agricultural Supplies Whl."
replace ind_name = "Meat & Smallgoods Whl." if ind_name=="Meat, Poultry & Smallgoods Whl."
replace ind_name = "Financial Asset Inv." if ind_name=="Financial Asset Investing"
replace ind_name = "Other Prop. Opr." if ind_name=="Other Property Operators"
replace ind_name = "Land Development" if ind_name=="Land Development & Subdivision"
replace ind_name = "GP Medical Serv." if ind_name=="General Practice Medical Serv."
replace ind_name = "Specialist Medical" if ind_name=="Specialist Medical Serv."
replace ind_name = "Fruit & Veg. Whl." if ind_name=="Fruit & Vegetable Whl."
replace ind_name = "Emp. & Recruitment Serv." if ind_name=="Employment Placement & Recruitment Serv."
replace ind_name = "Grain Cattle Farming" if ind_name=="Grain-Sheep or Grain-Beef Cattle Farming"
replace ind_name = "Super Funds Mgt. Serv." if ind_name=="Superannuation Funds Management Serv."
replace ind_name = "Motor Vehicle Parts Whl." if ind_name=="Motor Vehicle New Parts Whl."
replace ind_name = "Telecom. Resellers" if ind_name=="Telecommunications Resellers"
replace ind_name = "Tech. & Vocational Ed." if ind_name=="Technical & Vocational Education & Training"
replace ind_name = "Community Associations" if ind_name=="Community Associations & Other Interest Groups"
replace ind_name = "Sewerage Serv." if ind_name=="Sewerage & Drainage Serv."
replace ind_name = "Scaffolding Serv." if ind_name=="Metal Cladding, Waterproofing & Scaffolding Serv."
replace ind_name = "Air-Con & Heating" if ind_name=="Air Conditioning & Heating Serv."
replace ind_name = "MV Body, Paint & Interior Repair" if ind_name=="Motor Vehicle Body, Paint & Interior Repair"
replace ind_name = "Confectionery Mfg." if ind_name=="Chocolate & Confectionery Mfg."
replace ind_name = "Fresh Meat Rtl." if ind_name=="Fresh Meat, Fish & Poultry Rtl."
replace ind_name = "Urban Buses & Tramways" if ind_name=="Urban Bus & Tramway Transport"
replace ind_name = "Specialised Grocery Rtl." if ind_name=="Tobacconists & Specialised Grocery Rtl."
replace ind_name = "Painting & Decorating" if ind_name=="Painting & Decorating Serv."
replace ind_name = "Fruit & Veg. Processing" if ind_name=="Fruit & Vegetable Processing"
replace ind_name = "Taxi & Limo. Transport" if ind_name=="Taxi & Limousine Transport"
replace ind_name = "Art Education" if ind_name=="Art & Non-Vocational Education"
replace ind_name = "Agri. Support Serv." if ind_name=="Shearing, Cropping & Agricultural Support Serv."
replace ind_name = "Correctional Serv." if ind_name=="Correctional & Detention Serv."
replace ind_name = "Solid Waste Collection" if ind_name=="Solid Waste Collection Serv."
replace ind_name = "MV Parts Rtl." if ind_name=="Motor Vehicle Parts Rtl."
replace ind_name = "Hair & Beauty Serv." if ind_name=="Hairdressing & Beauty Serv."
replace ind_name = "Sports Admin. Serv." if ind_name=="Sports Administrative Serv."
replace ind_name = "Event Promotion & Mgt." if ind_name=="Event Promotion & Management Serv."
replace ind_name = "Furniture, Appl. & Equip. Rental" if ind_name=="Furniture, Appliance & Equipment Rental"
replace ind_name = "Const. Mach. & Op. Hire" if ind_name=="Construction Machinery & Operator Hire"
replace ind_name = "Mkt. Research Serv." if ind_name=="Market Research & Statistical Serv."
replace ind_name = "Office Admin. Serv." if ind_name=="Payroll & Other Office Administrative Serv."
replace ind_name = "Waste Disposal Serv." if ind_name=="Waste Treatment & Disposal Serv."
replace ind_name = "Motion Picture Dist." if ind_name=="Motion Picture & Video Distribution"
replace ind_name = "Data Processing Serv." if ind_name=="Data Processing & Web Hosting Serv."
replace ind_name = "Motion Picture Prod." if ind_name=="Motion Picture & Video Production"
replace ind_name = "Struc. Metal Prod. Mfg." if ind_name=="Structural Metal Product Mfg."
replace ind_name = "Smallgoods Mfg." if ind_name=="Cured Meat & Smallgoods Mfg."
replace ind_name = "Security Alarm Inst." if ind_name=="Fire & Security Alarm Installation Serv."
replace ind_name = "Mach. & Scaffolding Rental" if ind_name=="Machinery & Scaffolding Rental"

replace ind_name = "Private Activities of Households" if anzsic=="S96"
replace ind_name = "ISPs & Data Processing" if anzsic=="J59"
replace ind_name = "Non-Store Rtl." if anzsic=="G43"
replace ind_name = "Other Elect. Equip. Mfg." if anzsic=="C2439"
replace ind_name = "Printing" if anzsic=="C16"
replace ind_name = "Building Support Serv." if anzsic=="N73"
replace ind_name = "Non-Metallic Mineral Prod. Mfg." if anzsic=="C2090"
replace ind_name = "Metal Smelting & Refining" if anzsic=="C2133"
replace ind_name = "Other Publishing" if anzsic=="J54"
replace ind_name = "Plastic Material Mfg." if anzsic=="C1912b"
replace ind_name = "Rental & Hiring Serv." if anzsic=="L66"
replace ind_name = "Polymer Product Mfg." if anzsic=="C1919a"
replace ind_name = "Agri. Support Serv." if anzsic=="A05"
replace ind_name = "Scientific Equip. Mfg." if anzsic=="C2419"
replace ind_name = "Heating & Cooling Equip. Mfg." if anzsic=="C2452"
replace ind_name = "Waste Disposal Serv." if anzsic=="D29"
replace ind_name = "Waste Remediation Serv." if anzsic=="D2922"
replace ind_name = "Motion Picture Activities" if anzsic=="J55"
replace ind_name = "Clothing Mfg." if anzsic=="C1351c"
replace ind_name = "MV Used Parts Whl." if anzsic=="F3505"
replace ind_name = "Elect. Office Equip. Mfg." if anzsic=="C2421"
replace ind_name = "Textile, Clothing & Footwear Mfg." if anzsic=="C13"
replace ind_name = "Funerals" if anzsic=="S9520"
replace ind_name = "Transport Equipment Rental" if anzsic=="L6619"
replace ind_name = "Pulp, Paper & Paper Prod. Mfg." if anzsic=="C15"
replace ind_name = "Postal & Courier Serv." if anzsic=="I51"
replace ind_name = "Leather Product Mfg." if anzsic=="C1320"
replace ind_name = "Petroleum Prod. Mfg." if anzsic=="C1709"
replace ind_name = "Wooden Furniture Mfg." if anzsic=="C2511"
replace ind_name = "Sports & Rec. Facilities" if anzsic=="R9113"
replace ind_name = "MV & Parts Whl." if anzsic=="F35"
replace ind_name = "Mining Support Serv." if anzsic=="B10"
replace ind_name = "MV & Parts Rtl." if anzsic=="G39"
replace ind_name = "Synthetic Rubber Mfg." if anzsic=="C1821"
replace ind_name = "Non-Metal Mining & Quarrying" if anzsic=="B09"
replace ind_name = "Water Supply Serv." if anzsic=="D28"
replace ind_name = "Domestic Appl. Repair & Maint." if anzsic=="S9421"
replace ind_name = "Safety & Reg. Serv." if anzsic=="O77"
replace ind_name = "AV Elect. Equip. Mfg." if anzsic=="C2429"
replace ind_name = "Prop. Op. & Real Estate Serv." if anzsic=="L67"
replace ind_name = "MV Parts & Accessories Mfg." if anzsic=="C2319"
replace ind_name = "Heavy Construction" if anzsic=="E31"
replace ind_name = "Comp. System Design" if anzsic=="M70"
replace ind_name = "Basic Chem. Mfg." if anzsic=="C18"
replace ind_name = "Grocery Whl." if anzsic=="F36"
replace ind_name = "Polymer & Rubber Prod. Mfg." if anzsic=="C19"
replace ind_name = "Mining & Constr. Mach. Mfg." if anzsic=="C2462"
replace ind_name = "Cosmetics Mfg." if anzsic=="C1852"
replace ind_name = "Primary Metal Mfg." if anzsic=="C21"
replace ind_name = "Other Agriculture" if anzsic=="A"
replace ind_name = "Non-Metal Mineral Prod. Mfg." if anzsic=="C20"
replace ind_name = "Medical Serv." if anzsic=="Q85"
replace ind_name = "MV Body & Trailor Mfg." if anzsic=="C2312"
replace ind_name = "Med. Equip. Mfg." if anzsic=="C2412"
replace ind_name = "Other Mineral Mining" if anzsic=="B0809"
replace ind_name = "Textile Prod. Mfg." if anzsic=="C1333"
replace ind_name = "Optometry" if anzsic=="Q8532"

save AnzsicNames, replace

import delimited Industry17.csv, clear

rename code anzsic
rename revenuem20162017 rev_ind
rename ivam20162017 VA_ind
rename majorplayers company
rename coststructureprofit profit_pc
keep anzsic rev_ind VA_ind company marketshare profit_pc
drop if substr(anzsic,1,1)=="X"
gen ANZSIC4 = substr(anzsic,1,5)
gen ANZSIC3 = substr(ANZSIC4,1,4)
gen ANZSIC2 = substr(ANZSIC4,1,3)
gen ANZSIC1 = substr(ANZSIC4,1,1)

merge m:1 ANZSIC4 ANZSIC3 ANZSIC2 ANZSIC1 using ANZSIC
drop if _merge==2
drop if anzsic=="J5800" | anzsic=="G4200" | anzsic=="Q8400" | anzsic=="K6200" ///
| anzsic=="Q8700" | anzsic=="D2600" | anzsic=="M6900" | anzsic=="F3400" ///
| anzsic=="E" | anzsic=="B" | anzsic=="P"

gen ind_match = _merge==3
drop _merge

save Industry, replace

*keep if (VA_ind>3000 | (VA_ind>2200 & rev_ind>20000)) & company~="There are no major players in this industry"
*keep if company~="There are no major players in this industry"

gen large=1 if (VA_ind>3000 | (VA_ind>2200 & rev_ind>20000)) & company~="There are no major players in this industry"

save IndustryLarge, replace

sort anzsic
by anzsic: gen n = _n
keep if n==1
drop company marketshare n


save Industry_Large, replace

* create equivalent for level-3 industries
use Industry, clear

encode anzsic, gen(A)
sort anzsic
gen t = _n
tsset t
drop if A==f.A
sort ANZSIC3 t
by ANZSIC3: replace rev_ind = sum(rev_ind)
by ANZSIC3: replace VA_ind = sum(VA_ind)
drop A
encode ANZSIC3, gen(A)
sort A t
drop t
gen t = _n
tsset t
drop if A==f.A
replace anzsic = ANZSIC3
keep anzsic rev_ind VA_ind

save Industry3, replace

use Industry, clear

gen rev_firm = rev_ind*marketshare/100
encode company, gen(C)
encode ANZSIC3, gen(A)
sort ANZSIC3 company
by ANZSIC3 company: replace rev_firm = sum(rev_firm)
sort ANZSIC3 company
gen t = _n
tsset t
drop if C==f.C & A==f.A & company~="There are no major players in this industry"
drop C A t marketshare

replace anzsic = ANZSIC3
drop ANZSIC4 rev_ind VA_ind

merge m:1 anzsic using Industry3
drop _merge

save Industry3, replace

* create equivalent for level-2 industries
use Industry3, clear

encode ANZSIC3, gen(A)
sort ANZSIC3
gen t = _n
tsset t
drop if A==f.A
sort ANZSIC2
by ANZSIC2: replace rev_ind = sum(rev_ind)
by ANZSIC2: replace VA_ind = sum(VA_ind)
drop A t
encode ANZSIC2, gen(A)
sort A rev_ind
gen t = _n
tsset t
drop if A==f.A
replace anzsic = ANZSIC2
keep anzsic rev_ind VA_ind

save Industry2, replace

use Industry, clear

gen rev_firm = rev_ind*marketshare/100
encode company, gen(C)
encode ANZSIC2, gen(A)
sort ANZSIC2 company
by ANZSIC2 company: replace rev_firm = sum(rev_firm)
sort ANZSIC2 company
gen t = _n
tsset t
drop if C==f.C & A==f.A & company~="There are no major players in this industry"
drop C A t marketshare

replace anzsic = ANZSIC2
drop ANZSIC4 ANZSIC3 rev_ind VA_ind

merge m:1 anzsic using Industry2
drop _merge

save Industry2, replace


* create equivalent for level-1 industries
use Industry2, clear

encode ANZSIC2, gen(A)
sort ANZSIC2
gen t = _n
tsset t
drop if A==f.A
sort ANZSIC1
by ANZSIC1: replace rev_ind = sum(rev_ind)
by ANZSIC1: replace VA_ind = sum(VA_ind)
drop A t
encode ANZSIC1, gen(A)
sort A rev_ind
gen t = _n
tsset t
drop if A==f.A
replace anzsic = ANZSIC1
keep anzsic rev_ind VA_ind

save Industry1, replace

use Industry, clear

gen rev_firm = rev_ind*marketshare/100
encode company, gen(C)
encode ANZSIC1, gen(A)
sort ANZSIC1 company
by ANZSIC1 company: replace rev_firm = sum(rev_firm)
sort ANZSIC1 company
gen t = _n
tsset t
drop if C==f.C & A==f.A & company~="There are no major players in this industry"
drop C A t marketshare

replace anzsic = ANZSIC1
drop ANZSIC2 rev_ind VA_ind

merge m:1 anzsic using Industry1
drop _merge

save Industry1, replace

* Remove duplicates of 'no major players'
forvalues i=1(1)3 {
use Industry`i', clear
gen t = _n
tsset t
encode anzsic, gen(A)
drop if A==f.A & company=="There are no major players in this industry"
drop t A
save Industry`i', replace
gen t = _n
tsset t
encode anzsic, gen(A)
drop if A==f.A
drop t A
keep anzsic rev_ind VA_ind
save Industry_`i', replace
}

use Industry, clear
gen t = _n
tsset t
encode anzsic, gen(A)
drop if A==f.A
keep anzsic rev_ind VA_ind
save Industry_4, replace

* Estimate 4-firm market shares
use Industry, clear

drop company ANZSIC* ind_match
gsort anzsic -marketshare
by anzsic: gen firm_no = _n

reshape wide marketshare, i(anzsic) j(firm_no)

gen MS_1firm = marketshare1
forvalues i=1(1)6 {
local j =`i'+1
gen MS_`j'firm = MS_`i'firm + marketshare`j' if marketshare`j'~=.
replace MS_`j'firm = MS_`i'firm if MS_`j'firm==.
}


save MarketShares, replace

* calculate average 4-firm market share for each industry group
use MarketShares, clear

local obs = _N

append using Industry_3
append using Industry_2
append using Industry_1

gen ANZSIC3 = substr(anzsic,1,4) if strlen(anzsic)>=4
gen ANZSIC2 = substr(anzsic,1,3) if strlen(anzsic)>=3
gen ANZSIC1 = substr(anzsic,1,1)

encode anzsic, gen(A)
encode ANZSIC3, gen(B)
encode ANZSIC2, gen(C)
encode ANZSIC1, gen(D)

gen rev4 = rev_ind*MS_4firm

local inds "B C D"

foreach x of local inds {
sum `x'
forvalues i=1(1)`r(max)' {
sum rev4 if `x'==`i' in 1/`obs'
scalar temp = r(sum)
sum rev_ind if `x'==`i' in 1/`obs'
scalar temp_ = r(sum)
replace MS_4firm = temp/temp_ if `x'==`i' & MS_4firm==.
}
}

keep anzsic MS_4firm rev_ind VA_ind

save MarketSharesAllIndustries, replace

import delimited IndustryClassifications.csv, clear

sort code
by code: gen t = _n
keep if t==1
rename code anzsic
drop if substr(anzsic,1,1)=="X"
gen traded = exportslevel=="Medium" | exportslevel=="High" | importslevel=="Medium" | ///
importslevel=="High" | anzsic=="H4530" | anzsic=="A0146" 

keep anzsic traded
gen public = substr(anzsic,1,1)=="P" | anzsic=="Q8539" | anzsic=="R9113" | anzsic=="I4622" ///
| anzsic=="I4720" | anzsic=="O7714" | anzsic=="Q8401" | anzsic=="Q8402" ///
| anzsic=="Q8591" | anzsic=="O7710" | anzsic=="J6010" | anzsic=="M6910" ///
| anzsic=="K6330" | anzsic=="K6419d" | anzsic=="I5101" | anzsic=="S9540" ///
| anzsic=="S9551" | anzsic=="S9559" | anzsic=="R8910" | anzsic=="R8921" ///
| anzsic=="R8922" | anzsic=="O7600" | anzsic=="K6222" | anzsic=="K6223" ///
| anzsic=="D2812" | anzsic=="D2811" | anzsic=="R9112" | anzsic=="Q8609" ///
| anzsic=="H4530"

replace traded = 0 if public==1 

save IndustryTradability, replace

* IBISWorld competition indicators
import delimited IndustryClassifications.csv, clear
bysort code: keep if _n==1
drop if substr(code,1,1)=="X"

rename code anzsic
gen global_low = globalizationlevel=="Low"
gen global_high = globalizationlevel=="High"

keep anzsic global_low global_high

save "IndustryIndicators", replace

import delimited BarriersToEntryIndicators.csv, clear
drop if substr(code,1,1)=="X" | substr(code,1,2)=="OD"

rename code anzsic
gen growth_ = lifecyclestage=="Growth"
gen decline = lifecyclestage=="Decline"
gen comp_low = basisofcompetitionlevel=="Low"
gen comp_high = basisofcompetitionlevel=="High"
gen barriers_low = barrierstoentrylevel=="Low"
gen barriers_high = barrierstoentrylevel=="High"
gen cap_int_low = capitalintensitylevel=="Low"
gen cap_int_high = capitalintensitylevel=="High"
gen reg_low = regulationpolicylevel=="Light" | regulationpolicylevel=="None"
gen reg_high = regulationpolicylevel=="Heavy"
gen ind_assist_high = industryassistancelevel=="High"
gen ind_assist_med = industryassistancelevel=="Medium"

keep anzsic growth_-ind_assist_med

merge 1:1 anzsic using IndustryIndicators
drop _merge

save "IndustryIndicators", replace

import delimited Barriers, clear

save IndustryBarriers, replace

* Industry Beta information
import delimited AnzsicBeta.csv, clear
keep anzsic beta

save AnzsicBeta, replace

* Company Information
import delimited CompanyID16, clear
rename identerprise id
rename companyname company
drop if id==id[_n-1]

save CompanyID, replace

import delimited CompanyID17, clear
rename identerprise id
rename companyname company
drop if id==id[_n-1]
drop in 1803 // Error in data set (same company listed twice)

merge 1:1 id using CompanyID
gen only16 = _merge==2
gen only17 = _merge==1
drop _merge

save CompanyID, replace

import delimited CompanyInfo16.csv, clear
rename identerprise id
rename mainindustrycode main_anzsic
encode companytype, gen(type)
encode ownershiptype, gen(local)
replace main_anzsic = substr(main_anzsic,1,6)
replace main_anzsic = substr(main_anzsic,1,5) if substr(main_anzsic,6,6)==" "
replace main_anzsic = substr(main_anzsic,1,4) if substr(main_anzsic,6,6)=="-"
replace main_anzsic = substr(main_anzsic,1,3) if substr(main_anzsic,5,5)=="-"
gen anzsic_level = min(5,length(main_anzsic))-1

keep id asx main_anzsic anzsic_level type local

gen only16=1

merge m:1 id only16 using CompanyID
keep if _merge==3
drop _merge

save "CompanyInfo16", replace

import delimited CompanyInfo17.csv, clear

rename tradingname company
rename mainindustrybrcode main_anzsic

encode companytype, gen(type)
encode ownership, gen(local)
gen anzsic_level = min(5,length(main_anzsic))-1

keep company asx main_anzsic anzsic_level revenue000 type local
drop in 1803 // Error in data set (same company listed twice)
drop if company=="Energy Queensland" | company=="Kogan.com" | company=="Vesco Foods"

save CompanyInfo17, replace

gen only16=0

append using CompanyInfo16
drop only17 id

merge 1:1 company only16 using CompanyID
drop if _merge==2
drop _merge

save CompanyInfo, replace

* Data on Firms' various segments
import delimited CompanySegment.csv, clear

rename identerprise id
rename companyname company
rename anzsiccode anzsic
gen major = ismajorplayer=="Yes"
drop ismajorplayer

merge m:1 anzsic company using Industry
drop if _merge==2
drop _merge

sort company
by company: egen ct = sum(major)
drop if ct>0 & major==0

merge m:1 anzsic using Industry_Large
drop if _merge==1 & major==0
drop _merge

sort revenuerank anzsic
by revenuerank anzsic: gen dup = cond(_N==1,0,_n)

drop if dup>1
drop dup

replace large = 0 if large==.

keep id company anzsic major large

drop if (anzsic=="J5800" | anzsic=="G4200" | anzsic=="Q8400" | anzsic=="K6200" ///
| anzsic=="Q8700" | anzsic=="D2600" | anzsic=="M6900" | anzsic=="F3400" ///
| anzsic=="E" | anzsic=="B" | anzsic=="P") & major==1

sort id
drop if id==.

save CompanySegment, replace

use CompanyInfo, clear

merge 1:m id using CompanySegment
drop _merge

merge m:1 anzsic using Industry_4
drop if _merge==2
drop _merge

sort company

by company: gen n = _n
by company: gen N = _N

gen match = substr(anzsic,1,3)==substr(main_anzsic,1,3)

by company: egen sum_match = sum(match)
drop if sum_match==0 & n>1 & major==0
drop if match==0 & sum_match>0 & major==0

gen digit2 = strlen(main_anzsic)<=3

by company: replace N = _N

replace main_anzsic = anzsic if N==1 & digit2==1 & strlen(anzsic)>4

gsort company -match -VA_ind
by company: replace n = _n

drop if major==0 & n>1

replace main_anzsic = anzsic if N>1 & digit2==1 & match==1 & strlen(anzsic)>4
drop N

replace main_anzsic = main_anzsic[_n-1] if company[_n]==company[_n-1]

replace anzsic = main_anzsic if anzsic==""

rename anzsic anzsic_
rename main_anzsic anzsic

merge m:1 anzsic using Industry_Large
drop if _merge==2

rename anzsic main_anzsic
rename anzsic_ anzsic

/*
sort company
drop id
encode company, gen(id)
*/

save CompanySegment, replace

sort anzsic

rename _merge merge
keep company main_anzsic anzsic asx revenue000 type local id merge

sort id anzsic

by id: gen ind = _n
rename anzsic anzsic_
reshape wide anzsic_, i(id) j(ind)

gen main_anzsic2 = substr(main_anzsic,1,3)

save CompanySegment, replace

* Proportion of revenue earned in Australia
import delimited GeographicSegment.csv, clear

rename companyname company
rename identerprise id

gen local = strpos(segmentname,"Australia")>0 | strpos(segmentname,"Unallocated")>0 | ///
strpos(segmentname,"Australasia")>0 | strpos(segmentname,"Worldwide")>0 | ///
strpos(segmentname,"Asia Pacific")>0 | strpos(segmentname,"Victoria")>0 | ///
strpos(segmentname,"International")>0 |  strpos(segmentname,"Queensland")>0  

replace revenue=0 if revenue<0

bysort company: egen rev = sum(revenue)
bysort company local: egen revL = sum(revenue)

gen aus_percent = revL/rev if local==1
replace aus_percent=0 if local==0

gsort company -local
by company: gen n = _n
keep if n==1

keep id aus_percent

save Geography, replace

* Financials going back up to 10 years
import delimited CompanyTimeSeries.csv, clear


rename companyname company
rename totalassets assets
rename totalsalesrevenue revenue
rename totalshareholderequity equity
keep if yearsincecurrent<=5 & year>=2011
replace npat = npat*12/accountingperiod
replace revenue = revenue*12/accountingperiod
drop if accountingperiod<6
rename yearsincecurrent ysc
rename totalintangibleassets intangibles

keep id company assets equity npat revenue ysc year intangibles

gen roe = npat/equity
replace roe=. if npat==0 | equity<=0
gen roc = npat/assets
replace roc=. if npat==0 | assets<=0
drop in 1803 // Error in data set (same company listed twice)
gen debtequity = (assets-equity)/equity
replace debtequity = . if assets==0 | equity<=0
gen negequityflag = equity<0

xtset id ysc

gen growth = (revenue-f.revenue)/f.revenue if revenue~=0 & f.revenue~=0

save CompanyFinancials, replace

* Financials going back up to 10 years
import delimited CompanyFinancials2016.csv, clear

rename identerprise id
rename companyname company
rename totalassets assets
rename totalsalesrevenue revenue
rename totalshareholderequity equity
keep if yearsincecurrent<=5 & year>=2011
replace npat = npat*12/accountingperiod
replace revenue = revenue*12/accountingperiod
drop if accountingperiod<6
rename yearsincecurrent ysc
rename totalintangibleassets intangibles

keep id assets equity npat revenue ysc intangibles

gen roe = npat/equity
replace roe=. if npat==0 | equity<=0
gen roc = npat/assets
replace roc=. if npat==0 | assets<=0
gen debtequity = (assets-equity)/equity
replace debtequity = . if assets==0 | equity<=0
gen negequityflag = equity<0

xtset id ysc

gen growth = (revenue-f.revenue)/f.revenue if revenue~=0 & f.revenue~=0

merge m:1 id using CompanyInfo16
keep if _merge==3
drop _merge

save CompanyFinancials2016, replace

import delimited Margins.csv, clear

replace profitmargin=. if profitmargin==0
rename totalsalesrevenue revenue
replace revenue=. if revenue<=0
encode company, gen(id_)
gen margin = 0

forvalues i=1(1)2000 {
sum profit if id_==`i' [w=revenue]
replace margin = r(mean) if id_==`i'
}

bysort id: keep if _n==1
keep id company margin

save "Margins", replace

* Merge company data
use CompanyInfo, clear
drop main_anzsic

* merge in financials
merge 1:m id using CompanyFinancials
drop if _merge==2
drop _merge

append using CompanyFinancials2016

*merge segment information
merge m:m id using CompanySegment
drop if _merge==2
drop _merge

*merge goegraphy information
merge m:1 id using Geography
drop if _merge==2
drop _merge

replace revenue = revenue*aus_percent if aus_percent~=.
replace equity = equity*aus_percent if aus_percent~=.

replace anzsic_1 = anzsic_1 + "00" if strlen(anzsic_1)==3
replace anzsic_1 = anzsic_1 + "0" if strlen(anzsic_1)==4

gen assetsrevenue = assets/revenue
replace assetsrevenue = . if assets<=0 | revenue<=0

forvalues i=1(1)12 {
forvalues j=1(1)12 {
gen temp = substr(anzsic_`i',1,4)==substr(anzsic_`j',1,4) & substr(anzsic_`i',-1,1)=="0" & `i'~=`j'
replace anzsic_`i'="" if temp==1
drop temp
gen temp = substr(anzsic_`i',1,3)==substr(anzsic_`j',1,3) & substr(anzsic_`i',-2,2)=="00" & `i'~=`j'
replace anzsic_`i'="" if temp==1
drop temp
gen temp = strlen(anzsic_`i')==1 & substr(anzsic_`i',1,1)==substr(anzsic_`j',1,1) & `i'~=`j'
replace anzsic_`i'="" if temp==1
drop temp
}
}

* skip blanks
forvalues i=2(1)12 {
local k = `i'-1
forvalues j=1(1)`k' {
replace anzsic_`j' = anzsic_`i' if anzsic_`j'=="" & anzsic_`i'~=""
replace anzsic_`i' = "" if anzsic_`j'==anzsic_`i'
}
}

gen in_sample = 1
replace in_sample = 0 if company=="Australian Rail Track" | company=="NBN Co" | company=="Housing SA" ///
| main_anzsic=="K6330" | main_anzsic=="K6419d" | type<=3
replace in_sample = 1 if company=="Synergy" | company=="Essential Energy" | company=="Power & Water" ///
| company=="Horizon Power" | company=="Delta Electricity" | company=="Hydro Tasmania" | company=="Western Power" ///
| company=="Transpower" | company=="Ausgrid" | company=="Endeavour Energy" | company=="Orion" | main_anzsic=="D28" ///
| main_anzsic=="D281" | company=="Sydney Water" | company=="Water NSW" | company=="Pilbara Ports Authority" ///
| company=="Victorian Ports Corporation (Melbourne)" | company=="Fremantle Ports" | company=="Port Authority of New South Wales"
replace in_sample = 0 if debtequity>20 | assetsrevenue<0.25 | equity<=0 | roe==.

* Fix firms that are clearly misallocated
replace anzsic_1 = "B1011" if company=="Chevron Australia"
replace anzsic_2 = "B10" if company=="Chevron Australia"
replace main_anzsic = "B1011" if company=="Chevron Australia"

gen small=0

bysort main_anzsic in_sample: replace small=1 if merge==1 | _N<=5
bysort main_anzsic2 in_sample: egen N = sum(small)
bysort main_anzsic2 in_sample: replace small=1 if _N-small<=10 & merge==1
drop merge N

save CompanyMerged, replace 


* Match company info to market shares
use CompanyMerged, clear

forvalues i=1(1)12 {
rename anzsic_`i' anzsic
*merge 1:1 company anzsic using Industry
merge m:1 company anzsic using Industry
drop if _merge==2
gen VA_`i' = VA_ind*marketshare
replace VA_`i' = 0 if VA_`i'==.
drop _merge marketshare VA_ind ANZSIC4-ind_match rev_ind
merge m:1 anzsic using MarketSharesAllIndustries
drop if _merge==2
rename MS_4firm MS4_`i'
drop rev_ind VA_ind _merge
merge m:1 anzsic using IndustryTradability
drop if _merge==2
drop _merge
rename traded traded_`i'
rename public public_`i'
rename anzsic anzsic_`i'
}

order MS4_* VA_* traded_*, alphabetic after(assetsrevenue)
order MS4_10-MS4_12, alphabetic after(MS4_9)
order VA_10-VA_12, alphabetic after(VA_9)
order traded_10-traded_12, alphabetic after(traded_9)

forvalues i=1(1)12 {
gen VA3_`i' = VA_`i'
}
forvalues i=1(1)12 {
gen anzsic3_`i' = substr(anzsic_`i',1,4)
}

forvalues i=1(1)12 {
gen VA2_`i' = VA_`i'
}
forvalues i=1(1)12 {
gen anzsic2_`i' = substr(anzsic_`i',1,3)
}

forvalues i=1(1)12 {
gen VA1_`i' = VA_`i'
}
forvalues i=1(1)12 {
gen anzsic1_`i' = substr(anzsic_`i',1,1)
}


forvalues i=2(1)12 {
local k = `i'-1
forvalues j=1(1)`k' {
replace VA3_`j' = VA3_`i' + VA3_`j' if anzsic3_`i'==anzsic3_`j' // sum revenue shares in same industry
replace VA3_`i' = . if anzsic3_`i'==anzsic3_`j'
replace anzsic3_`i' = "" if anzsic3_`i'==anzsic3_`j'

replace VA2_`j' = VA2_`i' + VA2_`j' if anzsic2_`i'==anzsic2_`j'
replace VA2_`i' = . if anzsic2_`i'==anzsic2_`j'
replace anzsic2_`i' = "" if anzsic2_`i'==anzsic2_`j'

replace VA1_`j' = VA1_`i' + VA1_`j' if anzsic1_`i'==anzsic1_`j'
replace VA1_`i' = . if anzsic1_`i'==anzsic1_`j'
replace anzsic1_`i' = "" if anzsic1_`i'==anzsic1_`j'
}
}

forvalues i=3(1)12 {
local k = `i'-1
forvalues j=2(1)`k' {
replace VA3_`j' = VA3_`i' if anzsic3_`j'=="" & anzsic3_`i'~="" // skip blanks
replace VA3_`i' = . if anzsic3_`j'=="" & anzsic3_`i'~=""
replace anzsic3_`j' = anzsic3_`i' if anzsic3_`j'=="" & anzsic3_`i'~=""
replace anzsic3_`i' = "" if anzsic3_`j'==anzsic3_`i'

replace VA2_`j' = VA2_`i' if anzsic2_`j'=="" & anzsic2_`i'~=""
replace VA2_`i' = . if anzsic2_`j'=="" & anzsic2_`i'~=""
replace anzsic2_`j' = anzsic2_`i' if anzsic2_`j'=="" & anzsic2_`i'~=""
replace anzsic2_`i' = "" if anzsic2_`j'==anzsic2_`i'

replace VA1_`j' = VA1_`i' if anzsic1_`j'=="" & anzsic1_`i'~=""
replace VA1_`i' = . if anzsic1_`j'=="" & anzsic1_`i'~=""
replace anzsic1_`j' = anzsic1_`i' if anzsic1_`j'=="" & anzsic1_`i'~=""
replace anzsic1_`i' = "" if anzsic1_`j'==anzsic1_`i'
}
}

drop if VA_1==. & VA_2~=.

gen VA_total=0

forvalues i=1(1)12 {
replace VA_total = VA_total + VA_`i' if VA_`i'~=.
}
replace VA_total = . if VA_total==0

forvalues i=1(1)12 {
gen share_`i' = VA_`i'/VA_total // generate VA shares 
replace share_`i' = 0 if share_`i'==.
replace VA_`i' = 0 if VA_`i'==.
}

forvalues i=1(1)12 {
gen share3_`i' = VA3_`i'/VA_total
replace share3_`i' = 0 if share3_`i'==.
replace VA3_`i' = 0 if VA3_`i'==.
}

forvalues i=1(1)12 {
gen share2_`i' = VA2_`i'/VA_total
replace share2_`i' = 0 if share2_`i'==.
replace VA2_`i' = 0 if VA2_`i'==.
}

forvalues i=1(1)12 {
gen share1_`i' = VA1_`i'/VA_total
replace share1_`i' = 0 if share1_`i'==.
replace VA1_`i' = 0 if VA1_`i'==.
}

replace share_1 = 1 if share_1==0 & share_2==0 & share_3==0
replace share3_1 = 1 if share3_1==0 & share3_1==0
replace share2_1 = 1 if share2_1==0 & share2_2==0
replace share1_1 = 1 if share1_1==0 & share1_2==0

forvalues i=1(1)12 {
sum share3_`i'
if (r(mean)==0) {
drop VA3_`i' anzsic3_`i' share3_`i' // remove unnecessary variables
}

sum share2_`i'
if (r(mean)==0) {
drop VA2_`i' anzsic2_`i' share2_`i' 
}

sum share1_`i'
if (r(mean)==0) {
drop VA1_`i' anzsic1_`i' share1_`i' 
}
}

replace MS4_1=-99 if MS4_1==.

save CompanyVAShares, replace

/* Add goodwill from Morningstar */
import delimited "C:\Users\chisholmc\Dropbox (Personal)\Grattan\GitHub\Industry-concentration\Morningstar\Goodwill.csv", clear

destring goodwill, replace force
destring equity, gen(equity_MS) force
destring equity_star, replace force
drop equity

gen equity_ratio = equity_star/equity_MS

save Goodwill, replace

/* Set up for mixed effects regression */

do "C:\Users\chisholmc\Dropbox (Personal)\Grattan\GitHub\Industry-concentration\IndustryROEgoodwill"
