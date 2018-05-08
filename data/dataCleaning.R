# Global options
setwd('/Users/amsr/Documents/GitHub/qapScoring-Final/data')
options(stringsAsFactors = FALSE)

library(rjson)
library(plyr)



library(geojsonio)
library(sp)
library(rgdal)
library(dplyr)
library(tidyr)
library(devtools)
library(sf)
library(XML)
library(xml2)
library(RCurl)
library(xmltools)
library(DT)
library(mapview)
library(readr)

censusKey <- "4d92e5c53d5b7046bae0b72874aceed0fde3e0b4"
walkscoreKey <-"a0a34de0dd2261f99677763bb3861e33"

# Get geography set up
hoods <- st_read("https://raw.githubusercontent.com/alisanroman/philly-hoods/master/data/Neighborhoods_Philadelphia.geojson")
#hoods$mapname <- as.character(hoods$mapname)
#allHoods <- unique(hoods$mapname)
#write.csv(allHoods,"hoods.csv")
allHoods <- read.csv('csv/hoods.csv')
allHoods$mapname <- as.character(allHoods$mapname)
allHoods$planURL <- as.character(allHoods$planURL)
hoods2 <- merge(hoods,allHoods)
mapview(hoods2)

tracts <- st_read("https://raw.githubusercontent.com/alisanroman/qapScoring/master/data/Census_Tracts_2010.geojson")
cent<-  st_centroid(tracts)
hoodsTracts <- st_join(hoods2, cent)
hoodsTracts$mapname <- as.character(hoodsTracts$mapname)
ds_hoodsTracts <- data.frame(hoodsTracts) %>%
  select("mapname","TRACTCE10","GEOID10")
mapview(hoodsTracts)


# Get census data 
census_pull <- function(year,vars,stateFICS,county) {
  final_url <- paste0("https://api.census.gov/data/",year,"/acs/acs5?get=",vars
                      ,"&for=tract:*&in=state:",stateFICS,"&in=county:",county,"&key=",censusKey)
  dat <- fromJSON(file = final_url)
  d = ldply(dat)
  colnames(d) <- d[1, ] # the first row will be the header
  d = d[-1, ]          # removing the first row.
  d <- unite(d,"GEOID10", c("state","county","tract"),sep="",remove=TRUE)
  colNames <- colnames(d)
  d[,colNames]<-lapply(d[,colNames],as.numeric)
  d$GEOID10 <- as.factor(d$GEOID10)
  d %>%
    left_join(hoodsTracts,d,by='GEOID10')
}

#total pop, numb ppl living in poverty, numb HHs, numb HHs homeowners
test <- census_pull(year=2016
                    ,vars = 'B17001_001E,B17001_002E,B25003_001E,B25003_002E'
                    ,stateFICS = 42,county = 101)

## combine spatial & census data
combo3 <- ddply(test, c("mapname"), summarise, 
                pop = sum(B17001_001E, na.rm = TRUE),
                pov = sum(B17001_002E, na.rm = TRUE), 
                hhs = sum(B25003_001E, na.rm = TRUE),
                hom = sum(B25003_002E,na.rm=TRUE))

combo3$povPct <- ifelse(combo3$pop != 0, as.numeric(round((combo3$pov / combo3$pop) * 100,1)), NA)
combo3$homPct <- ifelse(combo3$hhs != 0, as.numeric(round((combo3$hom / combo3$hhs) * 100,1)), NA)

polyData <- left_join(x=hoods2,y=combo3,by="mapname")
polyData <- subset(polyData,select = -c(cartodb_id,created_at,updated_at,name,listname))
polyData$lowPov <-  ifelse(polyData$povPct < 25.9,1,0)
polyData$ownerOcc <- ifelse(polyData$homPct >= 52.4, 1,0)

geojson_write(input=polyData,file="censusData.geojson")
