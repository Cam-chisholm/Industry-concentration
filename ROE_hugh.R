# Hugh Parsonage variation on a theme by Cameron Chisholm
# 2016-08-01

library(data.table)
library(dplyr)
library(dtplyr)
library(tidyr)
library(readxl)  # read_excel

# Probably best to read it
read_and_clean <- function(filename){
  # Captures any numbers between Sector and .csv in the filename
  group <- gsub("^.*MS.Sector([0-9]+)\\.csv$", "\\1", filename)
  fread(filename, na.strings = c("", "NA", " "), header = TRUE) %>%
    # record the group
    mutate(group = group) %>%
    as.data.table
}

list.files(path = "./Morningstar/GICS Sector/",  pattern = "^MS.Sector([0-9]+)\\.csv$", 
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
  # 
# equity[j,i-2] <- sum(destring(data[[i]][data$Item=="Annual Balance Sheet - Total Equity"]),na.rm = TRUE) 
# assets[j,i-2] <- sum(destring(data[[i]][data$Item=="Annual Balance Sheet - Total Assets"]),na.rm = TRUE)
# revenue[j,i-2] <- sum(destring(data[[i]][data$Item=="Annual Profit and Loss - Operating Revenue"]),na.rm = TRUE)
# npat[j,i-2] <- sum(destring(data[[i]][data$Item=="Annual Profit and Loss - Reported NPAT After Abnorma"]),na.rm = TRUE)
# roe[j,i-2] <- sum(destring(data[[i]][data$Item=="Annual Ratio Analysis - ROE"])*destring(data[[i]][data$Item=="Annual Balance Sheet - Total Equity"]),na.rm = TRUE)/equity[j,i-2]
# roe2[j,i-2] <- npat[j,i-2]/equity[j,i-2]*100 # note: gives a different result to 'roe' (in theory, should be the same)
# roa[j,i-2] <- npat[j,i-2]/assets[j,i-2]*100
# market_share <- destring(data[[i]][data$Item=="Annual Balance Sheet - Total Equity"])/equity[j,i-2]*100
# hh_e[j,i-2] <- sum(market_share^2,na.rm = TRUE)
# market_share <- destring(data[[i]][data$Item=="Annual Profit and Loss - Operating Revenue"])/revenue[j,i-2]*100
# hh_r[j,i-2] <- sum(market_share^2,na.rm = TRUE)
# market_share <- destring(data[[i]][data$Item=="Annual Balance Sheet - Total Assets"])/revenue[j,i-2]*100
# hh_a[j,i-2] <- sum(market_share^2,na.rm = TRUE)
  mutate(roe = `Annual Ratio Analysis - ROE` * `Annual Balance Sheet - Total Equity`, 
         roe2 = `Annual Ratio Analysis - ROE` / `Annual Profit and Loss - Reported NPAT After Abnorma`, 
         roa = `Annual Profit and Loss - Reported NPAT After Abnorma` / `Annual Balance Sheet - Total Assets`, 
         market_share = `Annual Balance Sheet - Total Equity` )