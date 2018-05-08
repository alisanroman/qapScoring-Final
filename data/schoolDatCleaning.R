# Global options
setwd('/Users/amsr/Documents/GitHub/qapScoring-Final/data')
options(stringsAsFactors = FALSE)
library(units)
library(tidyverse)
library(sf)
library(mapview)
library(geojsonio)

greatSchoolsKey <- "4c6cbbb25c5ad456271f0b1e1b8fe9d4"


# get school data
stateAbbrev='PA'
city='Philadelphia'
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
#write.csv(schoolData,"gsDat.csv")
gsDat <- read_csv("gsDat.csv")

schoolPoint <- st_as_sf(x = gsDat, coords = c("lon", "lat"), crs = "+proj=longlat +datum=WGS84")
schoolPoint  <- as(schoolPoint, "Spatial")
mapview(schoolPoint)

geojson_write(input=schoolPoint,file="schoolPoints.geojson")