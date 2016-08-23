# Hugh Parsonage variation on a theme by Cameron Chisholm
# 2016-08-01

library(data.table)
library(taRifx)
library(dplyr)
library(dtplyr)
library(tidyr)
library(readxl)  # read_excel
library(magrittr)
library(xlsx)

# Probably best to read it
read_and_clean <- function(filename){
  # Captures any numbers between Sector and .csv in the filename
  group2 <- gsub("^.*MS.Sector([0-9]+)\\.csv$", "\\1", filename)
#  group2 <- gsub("^.*MS.Sector([0-9]+)\\.csv$", "\\1", filename)
  fread(filename, na.strings = c("", "NA", " "), header = TRUE) %>%
    # record the group
    mutate(sector = group2) %>%
    as.data.table
}

read_and_clean2 <- function(filename){
  # Captures any numbers between Sector and .csv in the filename
  group2 <- gsub("^.*Classification([0-9]+)\\.csv$", "\\1", filename)
  #  group2 <- gsub("^.*MS.Sector([0-9]+)\\.csv$", "\\1", filename)
  fread(filename, na.strings = c("", "NA", " "), header = TRUE) %>%
    # record the group
    mutate(sector = group2) %>%
    as.data.table
}

new.data <- list.files(path = "./Morningstar/GICS Sector/",  pattern = "^MS.Sector([0-9]+)\\.csv$", 
                         full.names = TRUE) %>%
  lapply(read_and_clean) %>%
  rbindlist(use.names = TRUE, fill = TRUE) %>%
  melt.data.table(measure.vars = grep("^[0-9]{4}$", names(.), value = TRUE), variable.name = "year") %>%
  mutate(value_num = ifelse(grepl("[%]$", value), 
                            # value is a percent
                            as.numeric(gsub("[,%]", "", value)) / 100, 
                            as.numeric(gsub(",", "", value, fixed = TRUE)))) %>% 
  filter(complete.cases(.)) %>%
  select(-value) %>%
  spread(Item, value_num)

sector.data <- list.files(path = "./Morningstar/Classifications/", pattern = "^Classification([0-9]+)\\.csv$",
                          full.names = TRUE) %>%
  lapply(read_and_clean2) %>%
  rbindlist(use.names = TRUE, fill = TRUE)

clean.data <- merge(new.data,sector.data, by= c("ASX Code", "Company Name", "sector"), all.x = FALSE, all.y = TRUE)
clean.data$`Annual Profit and Loss - Total Revenue Excluding Int`[is.na(clean.data$`Annual Profit and Loss - Total Revenue Excluding Int`)] <- clean.data$`Annual Profit and Loss - Total Operating Income (ban`[is.na(clean.data$`Annual Profit and Loss - Total Revenue Excluding Int`)]


clean.data <- group_by(clean.data,`GICS Industry`,year) %>%
  mutate(market_share_equity = `Annual Balance Sheet - Total Equity`[`Annual Balance Sheet - Total Equity`>0]/sum(`Annual Balance Sheet - Total Equity`[`Annual Balance Sheet - Total Equity`>0],na.rm=TRUE),
         market_share_revenue = `Annual Profit and Loss - Total Revenue Excluding Int`[`Annual Profit and Loss - Total Revenue Excluding Int`>0]/sum(`Annual Profit and Loss - Total Revenue Excluding Int`[`Annual Profit and Loss - Total Revenue Excluding Int`>0],na.rm=TRUE))
clean.data$market_share_equity[clean.data$market_share_equity==-Inf] <- NA

#  clean.data$sector <- destring(clean.data$sector)


ROE <- group_by(clean.data,`GICS Industry`,year) %>% 
  summarize(roe2 = sum(`Annual Profit and Loss - Reported NPAT After Abnorma`,na.rm = TRUE)/sum(`Annual Balance Sheet - Total Equity`,na.rm = TRUE)) %>%
  spread(year,roe2)
HH_Equity <- group_by(clean.data,`GICS Industry`,year) %>% 
  summarize(HH_equity = 10000*sum(`market_share_equity`*`market_share_equity`,na.rm = TRUE)) %>%
  spread(year,HH_equity)
HH_Rev <- group_by(clean.data,`GICS Industry`,year) %>%
  summarize(HH_revenue = 10000*sum(`market_share_revenue`*`market_share_revenue`,na.rm = TRUE)) %>%
  spread(year,HH_revenue)
FourFirm_Rev <- group_by(clean.data,`GICS Industry`,year) %>%
  summarize(FF_revenue = sum(head(sort(group_by(clean.data,`GICS Industry`,year),decreasing = TRUE)),na.rm = TRUE)) %>%
  spread(year,FF_revenue)
Equity <- group_by(clean.data,`GICS Industry`,year) %>%
  summarize(year,total_equity = sum(`Annual Balance Sheet - Total Equity`,na.rm = TRUE)) %>%
  spread(year,total_equity)

write.csv(ROE, "Return on equity (GICS industry).csv")
write.csv(HH_Equity, "HH Index Equity (GICS industry).csv")
write.csv(HH_Rev, "HH Index Revenue (GICS industry).csv")
write.csv(Equity, "Total Equity (GICS industry).csv")




read_and_clean <- function(filename){
  # Captures any numbers between Sector and .csv in the filename
  group2 <- gsub("^.*Current.Formula.Results([0-9]+)\\.csv$", "\\1", filename)
  #  group2 <- gsub("^.*MS.Sector([0-9]+)\\.csv$", "\\1", filename)
  fread(filename, na.strings = c("", "NA", " "), header = TRUE) %>%
    # record the group
    mutate(sector = group2) %>%
    as.data.table
}

industry <- data.table(c("Consumer Discretionary: Automobiles & Components",
"Consumer Discretionary: Consumer Durables & Apparel",
"Consumer Discretionary: Consumer Services",
"Consumer Discretionary: Media",
"Consumer Discretionary: Retailing",
"Consumer Staples: Food & Staples Retailing",
"Consumer Staples: Food, Beverage & Tobacco",
"Consumer Staples: Household & Personal Products",
"Energy",
"Financials: Banks",
"Financials: Diversified Financials",
"Financials: Insurance",
"Financials: Real Estate",
"Health Care: Health Care Equipment & Services",
"Health Care: Pharmaceuticals, Biotechnology & Life Sciences",
"Industrials: Capital Goods",
"Industrials: Commercial & Professional Services",
"Industrials: Transportation",
"Information Technology: Software & Services",
"Information Technology: Technology Hardware & Equipment",
"Information Technology: Semiconductors & Semiconductor Equipment",
"Materials",
"Telecommunications",
"Utilities"))


clean.data <- list.files(path = "./Morningstar/GICS Industry Group/",  pattern = "^Current.Formula.Results([0-9]+)\\.csv$", 
                         full.names = TRUE) %>%
  lapply(read_and_clean) %>%
  rbindlist(use.names = TRUE, fill = TRUE) %>%
  melt.data.table(measure.vars = grep("^[0-9]{4}$", names(.), value = TRUE), variable.name = "year") %>%
  mutate(value_num = ifelse(grepl("[%]$", value), 
                            # value is a percent
                            as.numeric(gsub("[,%]", "", value)) / 100, 
                            as.numeric(gsub(",", "", value, fixed = TRUE)))) %>% 
  filter(complete.cases(.)) %>%
  select(-value) %>%
  spread(Item, value_num) %>%
  group_by(sector,year) %>%
  mutate(market_share_equity = `Annual Balance Sheet - Total Equity`/sum(`Annual Balance Sheet - Total Equity`,na.rm=TRUE),
         market_share_assets = `Annual Balance Sheet - Total Assets`/sum(`Annual Balance Sheet - Total Assets`,na.rm=TRUE),
         market_share_revenue = `Annual Profit and Loss - Operating Revenue`/sum(`Annual Profit and Loss - Operating Revenue`,na.rm=TRUE))
clean.data$sector <- destring(clean.data$sector)
clean.data <- clean.data[order(sector)]

group_by(clean.data,sector,year) %>% 
  summarize(roe = sum(`Annual Ratio Analysis - ROE`*`Annual Balance Sheet - Total Equity`,na.rm = TRUE)/sum(`Annual Balance Sheet - Total Equity`,na.rm = TRUE)) %>%
  spread(year,roe) %>%
  mutate(industry)
ROE <- group_by(clean.data,sector,year) %>% 
  summarize(roe2 = sum(`Annual Profit and Loss - Reported NPAT After Abnorma`,na.rm = TRUE)/sum(`Annual Balance Sheet - Total Equity`,na.rm = TRUE)) %>%
  spread(year,roe2) %>%
  mutate(industry)
HH_Equity <- group_by(clean.data,sector,year) %>% 
  summarize(HH_equity = 10000*sum(`market_share_equity`*`market_share_equity`,na.rm = TRUE)) %>%
  spread(year,HH_equity) %>%
  mutate(industry)
HH_Assets <- group_by(clean.data,sector,year) %>%
  summarize(HH_assets = 10000*sum(`market_share_assets`*`market_share_assets`,na.rm = TRUE)) %>%
  spread(year,HH_assets) %>%
  mutate(industry)
HH_Rev <- group_by(clean.data,sector,year) %>%
  summarize(HH_revenue = 10000*sum(`market_share_revenue`*`market_share_revenue`,na.rm = TRUE)) %>%
  spread(year,HH_revenue) %>%
  mutate(industry)
Equity <- group_by(clean.data,sector,year) %>%
  summarize(year,total_equity = sum(`Annual Balance Sheet - Total Equity`,na.rm = TRUE)) %>%
  spread(year,total_equity) %>%
  mutate(industry)

write.csv(ROE, "Return on equity (GICS industry group).csv")
write.csv(HH_Equity, "HH Index Equity (GICS industry group).csv")
write.csv(HH_Rev, "HH Index Revenue (GICS industry group).csv")
write.csv(HH_Assets, "HH Index Assets (GICS industry group).csv")
write.csv(Equity, "Total Equity (GICS industry group).csv")

