# ----------------------------------------------------------------------- #
# PURPOSE: Connect to Census API and download relevant data               #
# ----------------------------------------------------------------------- #

# ------------------------------------------------------------------------------------------------------------#
# STEP 0: Initialize    --------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------#

# Supress scientific notation so we can see census geocodes
options(scipen = 999)
library(acs)
library(tigris)
library(censusapi)
library(plyr)
library(dplyr)
library(readxl)
library(openxlsx)
library(ggplot2)
library(rgdal)

Sys.setenv(CENSUS_KEY="4d92e5c53d5b7046bae0b72874aceed0fde3e0b4")
api.key.install("4d92e5c53d5b7046bae0b72874aceed0fde3e0b4")

# ------------------------------------------------------------------------------------------------------------#
# STEP 1: Define geographies   -------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------#
geog.subset <- subset(fips_codes,fips_codes$state %in% c("PA") 
                      & fips_codes$county %in% c("Philadelphia County"))
geog.subset$FIPS <- paste0(geog.subset$state_code,geog.subset$county_code)


# ------------------------------------------------------------------------------------------------------------#
# STEP 2: Get data           --------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------#
makeVarlist(name="acs5",vintage=2016,find="poverty")



dat <- data.frame()
state.code  <- geog.subset[1,2]
county.code <- geog.subset[1,4]
geo <- paste0("state:",state.code,"+county:",county.code)





dat1 <- getCensus(name="acs5",vintage=2016, vars = c("B17001_001E","B17001_002E"), region="tract:*",regionin=geo)
    dat1$FIPS <- paste0(dat1$state,dat1$county,dat1$tract)
    dat2 <- bind_rows(dat2,dat1)
    print(paste0("Completed year ",i," for ",geog.subset[j,5],", ",geog.subset[j,1])) 
  }




# ------------------------------------------------------------------------------------------------------------#
# STEP 2c: Create Tract Crosswalk      ----------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------#
names(race2)
dat_2015_only <- subset(race2,
                        race2$yr == 2015 
                      & race2$total_pop_2015 >0 # tracts with 0 population are irrelevant [73 obvs] none missing
                        #& !is.na(race2$median_home_val_2015) # same with missing home vals [421 obvs]
                        #& !is.na(race2$median_HH_income_2015) # and same for missing household income, too. [123]
                          )
names(dat_2015_only)
names(dat_2015_only)[17] <- "GEOID10"
all_tracts <- merge(x      = dat_2015_only[,c(1,2,3,17)]
              ,y     = cw_00_10
              ,by    = "GEOID10"
              ,all.x = TRUE)

all_tracts <- merge(x     = all_tracts
                   ,y     = cw_90_00
                   ,by    = "GEOID00"
                   ,all.x =TRUE)

all_tracts <- merge(x = all_tracts
                   ,y = cw_80_90
                   ,by = "GEOID90"
                   ,all.x = TRUE)

all_tracts$GEOID80 <- ifelse(is.na(all_tracts$GEOID80),all_tracts$GEOID90,all_tracts$GEOID80)
all_tracts$metro_area <- ifelse(all_tracts$state == "53", "Seattle"
                           ,ifelse(all_tracts$state == "36", "NYC"
                                   ,ifelse(all_tracts$state == "08","Den"
                                           ,ifelse(all_tracts$state == "06" & all_tracts$county == "037", "LA"
                                                   ,"SF"))))
names(all_tracts)

all_tracts <- all_tracts[,c(8,7,1,2,3)]
names(Seattle_tracts)
seattle_merge <- merge(x = all_tracts
              ,y = Seattle_tracts[,c(11,15)]
              ,by = "GEOID10"
              ,all.x = TRUE)
test1 <- subset(seattle_merge,
                seattle_merge$metro_area %in% c("LA", "SF", "NYC", "Den") | 
                  (seattle_merge$metro_area == "Seattle" & seattle_merge$Geo_STUSAB == "wa"))
names(test1)
all_tracts <- test1[,c(3:5,1,2)]

write.xlsx(all_tracts,"~/Box Sync/Gentrification Studio/identifying_gentrification/tract_list.xlsx")

# ------------------------------------------------------------------------------------------------------------#
# STEP 3a: Clean up variables     -----------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------#
names(race2)
race2$pop_25_plus_90 <- rowSums(subset(race2,select = P0570001:P0570007 ))
race2$ed_attain_90_n <- rowSums(subset(race2,select = P0570006:P0570007 ))
race2$ed_attain_90 <- ifelse(race2$pop_25_plus_90 >0, (race2$ed_attain_90_n / race2$pop_25_plus_90) *100, NA)
race2$ed_attain_90 <- ifelse(race2$ed_attain_90 == 0, NA, race2$ed_attain_90)
race2$ed_attain_00 <- ifelse(race2$P037001 >0,
                             100 * (rowSums(subset(race2,select = P037015:P037035)) / race2$P037001),NA)
race2$ed_attain_00 <- ifelse(race2$ed_attain_00 == 0, NA, race2$ed_attain_00)
race2$ed_attain_10_15 <- ifelse(race2$B15002_001E > 0
                                , 100 * (rowSums(subset(race2, select = B15002_015E:B15002_035E))/race2$B15002_001E)
                                         ,NA)

# ------------------------------------------------------------------------------------------------------------#
# STEP 3b: Merge     -----------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------#
names(dat_1980)
merged_data1 <- merge(x = all_tracts
                     ,y = dat_1980[,c(9,4,5,7,10)]
                     ,by = "GEOID80"
                     ,all.x = TRUE)
names(race2)
merged_data1 <- merge(x = merged_data1
                      ,y = subset(race2[,c("FIPS","total_pop_1990","median_home_val_1990","median_HH_income_1990"
                                           ,"ed_attain_90","ed_attain_90_n")]
                                  ,race2$yr == 1990)
                      ,by.x = "GEOID90"
                      ,by.y = "FIPS"
                      ,all.x = TRUE)
merged_data1 <- merge(x = merged_data1
                      ,y = subset(race2[,c("FIPS","total_pop_2000","median_home_val_2000","median_HH_income_2000"
                                           ,"ed_attain_00")]
                                  ,race2$yr == 2000)
                      ,by.x = "GEOID00"
                      ,by.y = "FIPS"
                      ,all.x = TRUE)
names(race2)[54] <- "ed_attain_10"
merged_data1 <- merge(x = merged_data1
                      ,y = subset(race2[,c("FIPS","total_pop_2010","median_home_val_2010","median_HH_income_2010"
                                           ,"ed_attain_10")]
                                  ,race2$yr == 2010)
                      ,by.x = "GEOID10"
                      ,by.y = "FIPS"
                      ,all.x = TRUE)
names(race2)[54] <- "ed_attain_15"
merged_data1 <- merge(x = merged_data1
                      ,y = subset(race2[,c("FIPS","total_pop_2015","median_home_val_2015","median_HH_income_2015"
                                           ,"ed_attain_15")]
                                  ,race2$yr == 2015)
                      ,by.x = "GEOID10"
                      ,by.y = "FIPS"
                      ,all.x = TRUE)

all_data <- merged_data1

all_data$median_home_val_1990 <- ifelse(all_data$median_home_val_1990 == 0, NA, all_data$median_home_val_1990)
all_data$median_home_val_2000 <- ifelse(all_data$median_home_val_2000 == 0, NA, all_data$median_home_val_2000)

all_data$median_HH_income_1980 <- ifelse(all_data$med_hh_income == 0, NA, all_data$med_hh_income)
all_data$median_HH_income_1990 <- ifelse(all_data$median_HH_income_1990 == 0, NA, all_data$median_HH_income_1990)
all_data$median_HH_income_2000 <- ifelse(all_data$median_HH_income_2000 == 0, NA, all_data$median_HH_income_2000)
all_data$median_HH_income_2010 <- ifelse(all_data$median_HH_income_2010 == 0, NA, all_data$median_HH_income_2010)

# Inflation adjust
# Reference = Most Recent Year
# From a table of CPI-U annual averages, calculate the change between the most recent year and a preceding year 
#     (divide the newer year by the older year).
# Then multiply the unadjusted number for that year by the ratio just calculated.

# Jan 2015: 345.1
# Jan 2010: 319.5
# Jan 2000: 248.7
# Jan 1990: 193.5

all_data$med_home_val_1990_i <- all_data$median_home_val_1990 * (345.1 / 193.5)
all_data$med_home_val_2000_i <- all_data$median_home_val_2000 * (345.1 / 248.7)
all_data$med_home_val_2010_i <- all_data$median_home_val_2010 * (345.1 / 319.5)

all_data$median_HH_income_1990_i <- all_data$median_HH_income_1990 * (345.1 / 193.5)
all_data$median_HH_income_2000_i <- all_data$median_HH_income_2000 * (345.1 / 248.7)
all_data$median_HH_income_2010_i <- all_data$median_HH_income_2010 * (345.1 / 319.5)

# Need to get one line per census tract NOW
names(all_data)
all_data1 <- ddply(all_data,.(GEOID10,metro_area),summarise
                   ,pop_80 = mean(total_pop_1980, na.rm = TRUE)
                   ,pop_90 = mean(total_pop_1990, na.rm = TRUE)
                   ,pop_00 = mean(total_pop_2000, na.rm = TRUE)
                   ,pop_10 = mean(total_pop_2010, na.rm = TRUE)
                   ,pop_15 = mean(total_pop_2015, na.rm = TRUE)
                   
                   ,ed_80 = mean(ed_attain_80, na.rm = TRUE)
                   ,ed_90 = mean(ed_attain_90, na.rm = TRUE)
                   ,ed_00 = mean(ed_attain_00, na.rm = TRUE)
                   ,ed_10 = mean(ed_attain_10, na.rm = TRUE)
                   ,ed_15 = mean(ed_attain_15, na.rm = TRUE)
                   
                   ,ed_80_n = mean(edu_collormore,na.rm = TRUE)
                   ,ed_90_n = mean(ed_attain_90_n,na.rm = TRUE)
                   
                   ,home_val_90 = mean(med_home_val_1990_i, na.rm = TRUE)
                   ,home_val_00 = mean(med_home_val_2000_i, na.rm = TRUE)
                   ,home_val_10 = mean(med_home_val_2010_i, na.rm = TRUE)
                   ,home_val_15 = mean(median_home_val_2015, na.rm = TRUE)
                   
                   ,hh_inc_80 = mean(med_hh_income, na.rm = TRUE)
                   ,hh_inc_90 = mean(median_HH_income_1990_i, na.rm = TRUE)
                   ,hh_inc_00 = mean(median_HH_income_2000_i, na.rm = TRUE)
                   ,hh_inc_10 = mean(median_HH_income_2010_i, na.rm = TRUE)
                   ,hh_inc_15 = mean(median_HH_income_2015, na.rm = TRUE)
                   )

all_data1$pop_80 <- ifelse(all_data1$pop_80 == "NaN",NA,all_data1$pop_80) 
all_data1$pop_90 <- ifelse(all_data1$pop_90 == "NaN",NA,all_data1$pop_90) 
all_data1$pop_00 <- ifelse(all_data1$pop_00 == "NaN",NA,all_data1$pop_00) 
all_data1$pop_10 <- ifelse(all_data1$pop_10 == "NaN",NA,all_data1$pop_10) 
all_data1$pop_15 <- ifelse(all_data1$pop_15 == "NaN",NA,all_data1$pop_15) 

all_data1$home_val_90 <- ifelse(all_data1$home_val_90 == "NaN",NA,all_data1$home_val_90) 
all_data1$home_val_00 <- ifelse(all_data1$home_val_00 == "NaN",NA,all_data1$home_val_00) 
all_data1$home_val_10 <- ifelse(all_data1$home_val_10 == "NaN",NA,all_data1$home_val_10) 
all_data1$home_val_15 <- ifelse(all_data1$home_val_15 == "NaN",NA,all_data1$home_val_15) 

all_data1$hh_inc_80 <- ifelse(all_data1$hh_inc_80 == "NaN",NA,all_data1$hh_inc_80)
all_data1$hh_inc_90 <- ifelse(all_data1$hh_inc_90 == "NaN",NA,all_data1$hh_inc_90)
all_data1$hh_inc_00 <- ifelse(all_data1$hh_inc_00 == "NaN",NA,all_data1$hh_inc_00)
all_data1$hh_inc_10 <- ifelse(all_data1$hh_inc_10 == "NaN",NA,all_data1$hh_inc_10)
all_data1$hh_inc_15 <- ifelse(all_data1$hh_inc_15 == "NaN",NA,all_data1$hh_inc_15)


all_data <- merge(x = all_data1
                  ,y = pop_den
                  ,by.x = "GEOID10"
                  ,by.y = "GEOID"
                  ,all.x = TRUE)

all_data$metro_area <- ifelse(!is.na(all_data$metro_area), all_data$metro_area, 
                              ifelse(all_data$STATEFP == "53", "Seattle"
                                     ,ifelse(all_data$STATEFP == "36", "NYC"
                                             ,ifelse(all_data$STATEFP == "08","Den"
                                                     ,ifelse(all_data$STATEFP == "06" 
                                                             & all_data$COUNTYFP == "037", "LA"
                                                             ,"SF")))))

# aland is in sq meters - need to convert to get people per square mile 
all_data$pop_den_15 <- ifelse(all_data$ALAND > 0 , all_data$pop_15 / (all_data$ALAND * 3.86102e-7), NA)

## Map population densities HERE
#sp <- st_as_sf(shapefile.geogs)
#sp_j <- sp %>%
#  merge(all_data, by.x = "GEOID", by.y = "GEOID10")

#map_density <- function(msa) {
#  sp_j %>% 
 #   filter(metro_area == msa) %>%
  #  filter(pop_den_15 >= 50) %>%
   # ggplot() + 
  #  geom_sf(aes(fill = pop_den_15)) +
  #  theme_void() %>%
   # return()
#}

# map_density("LA")

#la_tracts <- subset(all_data,all_data$metro_area == "LA" & all_data$pop_den_15 >= 4000)

#write.xlsx(la_tracts,"la_tract_list.xlsx")

# ------------------------------------------------------------------------------------------------------------#
# STEP 3c: Calcs     -----------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------#
all_data$ed_chg_90 <- ifelse(all_data$ed_80 >0,((all_data$ed_90 - all_data$ed_80) / all_data$ed_80)*100,NA)
all_data$ed_chg_90n <- ifelse(all_data$ed_90_n >0, ((all_data$ed_90_n - all_data$ed_80_n) / all_data$ed_80_n)*100,NA)
all_data$ed_chg_00 <- ifelse(all_data$ed_90 >0,((all_data$ed_00 - all_data$ed_90) / all_data$ed_90)*100,NA)
all_data$ed_chg_10 <- ifelse(all_data$ed_00 >0,((all_data$ed_10 - all_data$ed_00) / all_data$ed_00)*100,NA)
all_data$ed_chg_15 <- ifelse(all_data$ed_10 >0,((all_data$ed_15 - all_data$ed_10) / all_data$ed_10)*100,NA)

all_data$home_val_chg_00 <- ifelse(all_data$home_val_90>0,((all_data$home_val_00 - all_data$home_val_90)/all_data$home_val_90)*100,NA)
all_data$home_val_chg_10 <- ifelse(all_data$home_val_00>0,((all_data$home_val_10 - all_data$home_val_00)/all_data$home_val_00)*100,NA)
all_data$home_val_chg_15 <- ifelse(all_data$home_val_10>0,((all_data$home_val_15 - all_data$home_val_10)/all_data$home_val_10)*100,NA)

all_data$income_chg_15 <- ifelse(all_data$hh_inc_15>0,((all_data$hh_inc_15 - all_data$hh_inc_10)/all_data$hh_inc_10)*100,NA)

names(all_data)
all_data %>% dplyr::group_by(metro_area) %>%
  dplyr::summarise( `40%_income_1980`=quantile(hh_inc_80, probs=0.4, na.rm = TRUE)
            ,`40%_income_1990`=quantile(hh_inc_90, probs=0.4, na.rm = TRUE)
            ,`40%_income_2000`=quantile(hh_inc_00, probs=0.4, na.rm = TRUE)
            ,`40%_income_2010`=quantile(hh_inc_10, probs=0.4, na.rm = TRUE)
            ,`40%_income_2015`=quantile(hh_inc_15, probs=0.4, na.rm = TRUE)
            
            ,`40%_homeval_1990`=quantile(home_val_90,probs=0.4,na.rm=TRUE)
            ,`40%_homeval_2000`=quantile(home_val_00,probs=0.4,na.rm=TRUE)
            ,`40%_homeval_2010`=quantile(home_val_10,probs=0.4,na.rm=TRUE)
            ,`40%_homeval_2015`=quantile(home_val_15,probs=0.4,na.rm=TRUE)
            
            ,`67%_edu_1990`=quantile(ed_chg_90,probs=0.67,na.rm=TRUE)
            ,`67%_edu_1990_n`=quantile(ed_chg_90n,probs=0.67,na.rm = TRUE)
            ,`67%_edu_2000`=quantile(ed_chg_00,probs=0.67,na.rm=TRUE)
            ,`67%_edu_2010`=quantile(ed_chg_10,probs=0.67,na.rm=TRUE)
            ,`67%_edu_2015`=quantile(ed_chg_15,probs=0.67,na.rm=TRUE)
            
            ,`67%_home_val_00`=quantile(home_val_chg_00,probs=0.67,na.rm=TRUE)
            ,`67%_home_val_10`=quantile(home_val_chg_10,probs=0.67,na.rm=TRUE)
            ,`67%_home_val_15`=quantile(home_val_chg_15,probs=0.67,na.rm=TRUE)
            ) -> percentiles


all_data <- join(x = all_data, y = percentiles, by = "metro_area")

# ------------------------------------------------------------------------------------------------------------#
# STEP 4: Perform analysis     -----------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------#
# To determine whether a tract was eligible to gentrify:
#   1) The tract had a population of at least 500 residents at the beginning 
#       and end of a decade and was located within a central city. 
#   2) The tract’s median household income was in the bottom 40th percentile 
#       when compared to all tracts within its metro area at the beginning of the decade.
#   3) The tract’s median home value was in the bottom 40th percentile when compared to 
#       all tracts within its metro area at the beginning of the decade.
names(all_data)

all_data$ELIG_GENT_1990 <- ifelse(all_data$pop_80  >= 500 & all_data$pop_90 >= 500
                              & all_data$hh_inc_80 <= all_data$`40%_income_1980`,1,0)

all_data$ELIG_GENT_2000 <- ifelse(all_data$pop_90 >= 500 & all_data$pop_00 >= 500
                                  & all_data$hh_inc_90   <= all_data$`40%_income_1990`
                                  & all_data$home_val_90 <= all_data$`40%_homeval_1990`,1,0)

all_data$ELIG_GENT_2010 <- ifelse(all_data$pop_00 >= 500 & all_data$pop_10 >= 500
                                  & all_data$hh_inc_00 <= all_data$`40%_income_2000`
                                  & all_data$home_val_00 <= all_data$`40%_homeval_2000`,1,0)

all_data$ELIG_GENT_2015 <- ifelse(all_data$pop_10 >= 500 & all_data$pop_15 >= 500
                                  & all_data$hh_inc_10   <= all_data$`40%_income_2010`
                                  & all_data$home_val_10 <= all_data$`40%_homeval_2010`,1,0)

## Delete Denver super big not dense tracts
gent_test0 <- subset(all_data,
                     all_data$metro_area %in% c("LA","Seattle","NYC") 
                     | (all_data$metro_area == "Den" & all_data$pop_den_15 > 50)
                     | (all_data$metro_area == "SF"  & all_data$pop_den_15 > 100)  )

# For a second test, gentrification-eligible tracts were determined to have gentrified over a time period if 
# they met the following criteria:
gent_test <- gent_test0 %>%
  mutate( DID_GENT_1990 = ifelse(ELIG_GENT_1990 == 1 & (ed_chg_90 >= `67%_edu_1990`), 1, 0)
         ,DID_GENT_2000 = ifelse(ELIG_GENT_2000 == 1 & (ed_chg_00 >= `67%_edu_2000`) 
                                 & (home_val_00 > home_val_90) 
                                 & (home_val_chg_00 >= `67%_home_val_00`), 1, 0)
         ,DID_GENT_2010 = ifelse(ELIG_GENT_2010 == 1 & (ed_chg_10 >= `67%_edu_2010`) & (home_val_10 > home_val_00)
                                 & (home_val_chg_10 >=  `67%_home_val_10`), 1, 0)
         ,DID_GENT_2015 = ifelse(ELIG_GENT_2015 == 1 & (ed_chg_15 >= `67%_edu_2015`) & (home_val_15 > home_val_10)
                                 & home_val_chg_15 >=  `67%_home_val_15`, 1, 0)
  )

# "1 - Gentrified pre-2010"
# "2 - Gentrified between 2010 and 2015"
# "3 - Eligible to gentrify but hasn't as of 2015"
# "4 - Ineligible to gentrify"

gent_test$categ <- ifelse(gent_test$DID_GENT_1990 == 1 | gent_test$DID_GENT_2000 == 1 
                          | gent_test$DID_GENT_2010 == 1
                          ,1,ifelse(gent_test$DID_GENT_2015 == 1,2,ifelse(gent_test$ELIG_GENT_2015 == 1,3,4)))

gent_test$categ <- ifelse(is.na(gent_test$categ) & gent_test$DID_GENT_2015 == 1, 2
                          ,ifelse(is.na(gent_test$categ) & gent_test$ELIG_GENT_2015 == 1, 3
                                  ,ifelse(is.na(gent_test$categ) & gent_test$ELIG_GENT_2015 == 0, 4
                                          ,gent_test$categ)))

gent_test$categ <- ifelse(is.na(gent_test$categ) & gent_test$ELIG_GENT_2010 == 1, 3
                          ,ifelse(is.na(gent_test$categ) &  gent_test$ELIG_GENT_2010 == 0, 4
                                  , gent_test$categ))

gent_test$categ <- ifelse(is.na(gent_test$categ) & gent_test$ELIG_GENT_2000 == 1, 3
                       ,ifelse(is.na(gent_test$categ) &  gent_test$ELIG_GENT_2000 == 0, 4
                               , gent_test$categ))
                            
gent_test$categ <- ifelse(is.na(gent_test$categ) & gent_test$ELIG_GENT_1990 == 1, 3
                          ,ifelse(is.na(gent_test$categ) &  gent_test$ELIG_GENT_1990 == 0, 4
                                  , gent_test$categ))
                                 
#names(gent_test)
gent_test2 <- gent_test[,c("GEOID10","metro_area","categ","pop_den_15")]

#ddply(gent_test2,.(metro_area,categ),summarise,
 #     N = length(GEOID10)
  #    )

#summary(gent_test[which(gent_test$metro_area == "Den"),])

## Map gent HERE
sp <- st_as_sf(shapefile.geogs)
sp_j <- sp %>%
  merge(gent_test2, by.x = "GEOID", by.y = "GEOID10")

map_gent <- function(msa) {
  sp_j %>% 
    filter(metro_area == msa) %>%
    ggplot() + 
    geom_sf(aes(fill = as.factor(categ))) +
    theme_void() %>%
 return()
}

names(gent_test2)
colnames(gent_test2)[3] <- "gentri_categ"
row.names(gent_test2) <- NULL


map_gent("SF")
map_gent("Den")
map_gent("NYC")
map_gent("Seattle")

nyc_gent <- subset(gent_test2,gent_test2$metro_area == "NYC")
seattle_gent <- subset(gent_test2,gent_test2$metro_area == "Seattle")
denver_gent <- subset(gent_test2,gent_test2$metro_area == "Den")
sf_gent <- subset(gent_test2,gent_test2$metro_area == "SF")

write.xlsx(nyc_gent,"~/Box Sync/Gentrification Studio/Data/identifying_gentrification/nyc_categs.xlsx")
write.xlsx(seattle_gent,"~/Box Sync/Gentrification Studio/Data/identifying_gentrification/seattle_categs.xlsx")
write.xlsx(denver_gent,"~/Box Sync/Gentrification Studio/Data/identifying_gentrification/denver_categs.xlsx")
write.xlsx(sf_gent,"~/Box Sync/Gentrification Studio/Data/identifying_gentrification/sf_categs.xlsx")

write.xlsx(all_data3,"~/Box Sync/Gentrification Studio/identifying_gentrification/tract_categorization_v2.xlsx")

# ------------------------------------------------------------------------------------------------------------#
# STEP 5a: Map!                  -----------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------#

test <- rbind_tigris(tracts(state = '06', county = ca.counties, cb = TRUE))
test <- tracts(state = geog.subset[i,2], county = geog.subset[i,4])

 
all_tracts_geog <- rbind_tigris(
  for (i in 1:nrow(geog.subset)) {
    if (i > 1) { ',' }
    tracts(state = geog.subset[i,2], county = geog.subset[i,4])
    print(paste0("Completed ",geog.subset[i,5],", ",geog.subset[i,1])) 
  }
)


all_tracts_geo_merged <- geo_join(all_tracts_geog,all_data3,by_sp = , by_df = )

nyc <- readOGR("~/Box Sync/Gentrification Studio/GIS/SF/SF_tracts_NEW/SF_Tracts_NEW.shp","nyc")
