#install.packages("gdata")
#install.packages("taRifx")
#install.packages("rJava")
#install.packages("WriteXLS")
#install.packages("xlsx")
library(WriteXLS)
library(gdata)
library(taRifx)
library(rJava)
library(xlsx)

setwd("C:/Users/chisholmc/Dropbox (Grattan Institute)/Productivity Growth/Concentration/Data and analysis/")

# create matrices to store results 
roe <- matrix(data = NA, nrow = 10, ncol = 28)
colnames(roe) <- c("Industry Group",1990:2016)

roe <- data.frame(roe)

hh_e <- roe
hh_r <- roe
hh_a <- roe
equity <- roe
revenue <- roe
assets <- roe
npat <- roe
roa <- roe
roe2 <- roe

# loop over all sectors
for (j in 1:10) {
data <- read.csv(paste0("Morningstar/GICS Sector/MS_Sector",j,".csv"), header = TRUE) # note: data read as string

# loop over all years (1990 to 2016)
for(i in 4:30) {
  equity[j,i-2] <- sum(destring(data[[i]][data$Item=="Annual Balance Sheet - Total Equity"]),na.rm = TRUE) 
  assets[j,i-2] <- sum(destring(data[[i]][data$Item=="Annual Balance Sheet - Total Assets"]),na.rm = TRUE)
  revenue[j,i-2] <- sum(destring(data[[i]][data$Item=="Annual Profit and Loss - Operating Revenue"]),na.rm = TRUE)
  npat[j,i-2] <- sum(destring(data[[i]][data$Item=="Annual Profit and Loss - Reported NPAT After Abnorma"]),na.rm = TRUE)
  roe[j,i-2] <- sum(destring(data[[i]][data$Item=="Annual Ratio Analysis - ROE"])*destring(data[[i]][data$Item=="Annual Balance Sheet - Total Equity"]),na.rm = TRUE)/equity[j,i-2]
  roe2[j,i-2] <- npat[j,i-2]/equity[j,i-2]*100 # note: gives a different result to 'roe' (in theory, should be the same)
  roa[j,i-2] <- npat[j,i-2]/assets[j,i-2]*100
  market_share <- destring(data[[i]][data$Item=="Annual Balance Sheet - Total Equity"])/equity[j,i-2]*100
  hh_e[j,i-2] <- sum(market_share^2,na.rm = TRUE)
  market_share <- destring(data[[i]][data$Item=="Annual Profit and Loss - Operating Revenue"])/revenue[j,i-2]*100
  hh_r[j,i-2] <- sum(market_share^2,na.rm = TRUE)
  market_share <- destring(data[[i]][data$Item=="Annual Balance Sheet - Total Assets"])/revenue[j,i-2]*100
  hh_a[j,i-2] <- sum(market_share^2,na.rm = TRUE)
  }
}

# create matrices for ASX results
ASX_roe <- matrix(data = NA, nrow = 1, ncol = 27)
colnames(ASX_roe) <- c(1990:2016)
ASX_roe <- data.frame(ASX_roe)
ASX_roe2 <- matrix(data = NA, nrow = 1, ncol = 27)
colnames(ASX_roe2) <- c(1990:2016)
ASX_roe2 <- data.frame(ASX_roe2)
ASX_roa <- matrix(data = NA, nrow = 1, ncol = 27)
colnames(ASX_roa) <- c(1990:2016)
ASX_roa <- data.frame(ASX_roa)

# loop over all years
for(i in 2:28) {
  ASX_roe[i-1] <- sum(roe[i]*equity[i])/sum(equity[i])
  ASX_roe2[i-1] <- sum(npat[i])/sum(equity[i])*100
  ASX_roa[i-1] <- sum(npat[i])/sum(assets[i])*100
}

# label each sector
roe[1,1] <- "Consumer Discretionary"
roe[2,1] <- "Consumer Staples"
roe[3,1] <- "Energy"
roe[4,1] <- "Financials"
roe[5,1] <- "Health Care"
roe[6,1] <- "Industrials"
roe[7,1] <- "Information Technology"
roe[8,1] <- "Materials"
roe[9,1] <- "Telecommunications"
roe[10,1] <- "Utilities"

hh_e[1] <- roe[1]
hh_r[1] <- roe[1]
hh_a[1] <- roe[1]
equity[1] <- roe[1]
revenue[1] <- roe[1]
assets[1] <- roe[1]
npat[1] <- roe[1]
roa[1] <- roe[1]
roe2[1] <- roe[1]

write.csv(roe, "Return on equity (GICS sector).csv")
write.csv(hh_e, "HH Index Equity (GICS sector).csv")
write.csv(hh_r, "HH Index Revenue (GICS sector).csv")
write.csv(hh_a, "HH Index Assets (GICS sector).csv")
write.csv(roa, "Return on Assets (GICS sector).csv")
write.csv(assets, "Total Assets (GICS sector).csv")
write.csv(revenue, "Total Revenue (GICS sector).csv")
write.csv(equity, "Total Equity (GICS sector).csv")
write.csv(npat, "Total NPAT (GICS sector).csv")

write.csv(roe2, "Return on equity 2.csv")
write.csv(ASX_roe, "Return on equity ASX.csv")
write.csv(ASX_roe2, "Return on equity ASX 2.csv")
write.csv(ASX_roa, "Return on assets ASX.csv")





# Same analysis for 24 industry groups

roe <- matrix(data = NA, nrow = 24, ncol = 28)
colnames(roe) <- c("Industry Group",1990:2016)

roe <- data.frame(roe)

hh_e <- roe
hh_r <- roe
hh_a <- roe
equity <- roe
revenue <- roe
assets <- roe
npat <- roe
roa <- roe
roe2 <- roe

for (j in 1:24) {
  data <- read.csv(paste0("Morningstar/GICS Industry Group/Current Formula Results",j,".csv"), header = TRUE)

  
  for(i in 4:ncol(data)) {
    equity[j,i-2] <- sum(destring(data[[i]][data$Item=="Annual Balance Sheet - Total Equity"]),na.rm = TRUE)
    assets[j,i-2] <- sum(destring(data[[i]][data$Item=="Annual Balance Sheet - Total Assets"]),na.rm = TRUE)
    revenue[j,i-2] <- sum(destring(data[[i]][data$Item=="Annual Profit and Loss - Operating Revenue"]),na.rm = TRUE)
    npat[j,i-2] <- sum(destring(data[[i]][data$Item=="Annual Profit and Loss - Reported NPAT After Abnorma"]),na.rm = TRUE)
    roe[j,i-2] <- sum(destring(data[[i]][data$Item=="Annual Ratio Analysis - ROE"])*destring(data[[i]][data$Item=="Annual Balance Sheet - Total Equity"]),na.rm = TRUE)/equity[j,i-2]
    roe2[j,i-2] <- npat[j,i-2]/equity[j,i-2]*100
    roa[j,i-2] <- npat[j,i-2]/assets[j,i-2]*100
    market_share <- destring(data[[i]][data$Item=="Annual Balance Sheet - Total Equity"])/equity[j,i-2]*100
    hh_e[j,i-2] <- sum(market_share^2,na.rm = TRUE)
    market_share <- destring(data[[i]][data$Item=="Annual Profit and Loss - Operating Revenue"])/revenue[j,i-2]*100
    hh_r[j,i-2] <- sum(market_share^2,na.rm = TRUE)
    market_share <- destring(data[[i]][data$Item=="Annual Balance Sheet - Total Assets"])/revenue[j,i-2]*100
    hh_a[j,i-2] <- sum(market_share^2,na.rm = TRUE)
  }
}

roe[1,1] <- "Consumer Discretionary: Automobiles & Components"
roe[2,1] <- "Consumer Discretionary: Consumer Durables & Apparel"
roe[3,1] <- "Consumer Discretionary: Consumer Services"
roe[4,1] <- "Consumer Discretionary: Media"
roe[5,1] <- "Consumer Discretionary: Retailing"
roe[6,1] <- "Consumer Staples: Food & Staples Retailing"
roe[7,1] <- "Consumer Staples: Food, Beverage & Tobacco"
roe[8,1] <- "Consumer Staples: Household & Personal Products"
roe[9,1] <- "Energy"
roe[10,1] <- "Financials: Banks"
roe[11,1] <- "Financials: Diversified Financials"
roe[12,1] <- "Financials: Insurance"
roe[13,1] <- "Financials: Real Estate"
roe[14,1] <- "Health Care: Health Care Equipment & Services"
roe[15,1] <- "Health Care: Pharmaceuticals, Biotechnology & Life Sciences"
roe[16,1] <- "Industrials: Capital Goods"
roe[17,1] <- "Industrials: Commercial & Professional Services"
roe[18,1] <- "Industrials: Transportation"
roe[19,1] <- "Information Technology: Software & Services"
roe[20,1] <- "Information Technology: Technology Hardware & Equipment"
roe[21,1] <- "Information Technology: Semiconductors & Semiconductor Equipment"
roe[22,1] <- "Materials"
roe[23,1] <- "Telecommunications"
roe[24,1] <- "Utilities"

hh_e[1] <- roe[1]
hh_r[1] <- roe[1]
hh_a[1] <- roe[1]
equity[1] <- roe[1]
revenue[1] <- roe[1]
assets[1] <- roe[1]
npat[1] <- roe[1]
roa[1] <- roe[1]
roe2[1] <- roe[1]


write.csv(roe, "Return on equity (GICS industry group).csv")
write.csv(hh_e, "HH Index Equity (GICS industry group).csv")
write.csv(hh_r, "HH Index Revenue (GICS industry group).csv")
write.csv(hh_a, "HH Index Assets (GICS industry group).csv")
write.csv(roa, "Return on Assets (GICS industry group).csv")
write.csv(assets, "Total Assets (GICS industry group).csv")
write.csv(revenue, "Total Revenue (GICS industry group).csv")
write.csv(equity, "Total Equity (GICS industry group).csv")
write.csv(npat, "Total NPAT (GICS industry group).csv")

