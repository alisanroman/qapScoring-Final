setwd('/Users/amsr/Documents/GitHub/qapScoring-Final/data')

library(sp)
library(rgdal)
library(plyr)
library(dplyr)
library(rjson)
library(tidyr)
library(devtools)
library(sf)
library(geojsonio)
library(XML)
library(xml2)
library(RCurl)
library(xmltools)
library(DT)
library(mapview)

censusKey <- "4d92e5c53d5b7046bae0b72874aceed0fde3e0b4"
greatSchoolsKey <- "4c6cbbb25c5ad456271f0b1e1b8fe9d4"

# Get geography set up
hoods <- st_read("https://raw.githubusercontent.com/alisanroman/philly-hoods/master/data/Neighborhoods_Philadelphia.geojson")
tracts <- st_read("https://raw.githubusercontent.com/alisanroman/qapScoring/master/data/Census_Tracts_2010.geojson")
cent<-  st_centroid(tracts)
hoodsTracts <- st_join(hoods, cent)
hoodsTracts$mapname <- as.character(hoodsTracts$mapname)
ds_hoodsTracts <- data.frame(hoodsTracts) %>%
  select("mapname","TRACTCE10","GEOID10")

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
# get school data
schoolURL_charter <- paste0("https://api.greatschools.org/schools/",stateAbbrev,"/",city,"/charter/high-schools","?key=",greatSchoolsKey,"&sort=gs_rating&limit=-1" )
schoolURL_public <- paste0("https://api.greatschools.org/schools/",stateAbbrev,"/",city,"/public/high-schools","?key=",greatSchoolsKey,"&sort=gs_rating&limit=-1" )

xmlFile <- getURL(schoolURL_charter)
xmlContent <- xmlParse(xmlFile)
xmlroot <- xmlRoot(xmlContent)
charterData <- xmlToDataFrame(xmlroot)

xmlFile <- getURL(schoolURL_public)
xmlContent <- xmlParse(xmlFile)
xmlroot <- xmlRoot(xmlContent)
publicData <- xmlToDataFrame(xmlroot)

schoolData <- rbind(publicData,charterData)
schoolData$lat <- as.numeric(schoolData$lat)
schoolData$lon <- as.numeric(schoolData$lon)

# now load in Pa specific data
schoolDataPA <- read.delim("SPP.APD.2016.2017.txt",sep="|")
colnames(schoolDataPA)
unique(schoolDataPA$Data.Element)
schoolDataPA1 <- subset(schoolDataPA, Data.Element == 'Calculated Score'
                        & (tolower(as.character(LEA.Name)) %in% 
                           tolower(c(unique(schoolData$district),'Esperanza Academy Charter School'
                                     ,"Mastery CS - Hardy Williams"
                                     ,"HOPE for Hyndman CS"
                                     ,"MaST Community CS II"
                                     ,"Frederick Douglass Mastery Charter School"
                                     ,"Multicultural Academy CS"
                                     ,"Preparatory CS of Mathematics, Science, Tech, and Careers"))
                        | grepl('phila',tolower(as.character(LEA.Name)))) )
schoolDataPA1$BLAS <- as.numeric(as.character(schoolDataPA1$Display.Value))

schoolDataPA1$pts <- ifelse(schoolDataPA1$BLAS >= 80, 2
                            ,ifelse(schoolDataPA1$BLAS >= 70,1,0))
colnames(schoolDataPA1)
ds <- schoolDataPA1[,c(2,7,8)]
colnames(ds)[1] <- 'name'
write.csv(ds,"scldatPA.csv")
write.csv(schoolData,"gsDat.csv")
gsDat <- read_csv("gsDat.csv")

schoolPoint <- st_as_sf(x = gsDat, coords = c("lon", "lat"), crs = "+proj=longlat +datum=WGS84")
schoolPoint  <- as(schoolPoint, "Spatial")
mapview(schoolPoint)

geojson_write(input=schoolPoint,file="schoolPoints.geojson")




## combine spatial & census data
combo3 <- ddply(test, c("mapname"), summarise, 
                pop = sum(B17001_001E, na.rm = TRUE),
                pov = sum(B17001_002E, na.rm = TRUE), 
                hhs = sum(B25003_001E, na.rm = TRUE),
                hom = sum(B25003_002E,na.rm=TRUE))

combo3$povPct <- ifelse(combo3$pop != 0, as.numeric(round((combo3$pov / combo3$pop) * 100,1)), NA)
combo3$homPct <- ifelse(combo3$hhs != 0, as.numeric(round((combo3$hom / combo3$hhs) * 100,1)), NA)

polyData <- left_join(x=hoods,y=combo3,by="mapname")
polyData <- subset(polyData,select = -c(cartodb_id,created_at,updated_at,name,listname))
polyData$lowPov <-  ifelse(polyData$povPct < 25.9,1,0)
polyData$affordOptions <- ()
polyData$affordProduction <- ()
polydata$ownerOcc <- ifelse(polyData$homPct >= 52.4, 1,0)
polydata$hsScores <- ifelse()



# Create category var for final slide
polyData$categ <- ifelse(polyData$povPct < 25.9 & polyData$homPct >= 52.4, "Low poverty, high homeownership",
                         ifelse(polyData$povPct < 25.9 & polyData$homPct < 52.4, "Low poverty, low homeownership",
                                ifelse(polyData$povPct >= 25.9 & polyData$homPct < 52.4, "High poverty, low homeownership",
                                       ifelse(polyData$povPct >= 25.9 & polyData$homPct >= 52.4
                                              , "High poverty, high homeownership",""))))
unique(polyData$categ)
plot(polyData)

geojson_write(input=polyData,file="polyData.geojson")
