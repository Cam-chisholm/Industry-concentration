clear
clear matrix
clear mata

cd "C:\Users\chisholmc\Dropbox (Personal)\Grattan\GitHub\Industry-concentration\IBIS data"

use MarketShares, clear

matrix cut = (0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,101)

matrix share = J(20,1,0)

gen NT = substr(anzsic,1,1)=="D" | substr(anzsic,1,1)=="E" | substr(anzsic,1,1)=="F" | ///
substr(anzsic,1,1)=="G" | substr(anzsic,1,1)=="H" | substr(anzsic,1,1)=="I" | substr(anzsic,1,1)=="J" | ///
substr(anzsic,1,1)=="K" | substr(anzsic,1,1)=="L" | substr(anzsic,1,1)=="M" | substr(anzsic,1,1)=="S"

forvalues i=1(1)20 {
local j = `i'+1
sum VA_ind if MS_4firm>=cut[1,`i'] & MS_4firm<cut[1,`j'] & NT==1
matrix share[`i',1] = r(sum)
}

matrix list share

forvalues i=1(1)20 {
local j = `i'+1
sum VA_ind if MS_4firm>=cut[1,`i'] & MS_4firm<cut[1,`j']
matrix share[`i',1] = r(sum)
}

matrix list share
