# Global options
setwd('/Users/amsr/Documents/GitHub/qapScoring-Final/data')
options(stringsAsFactors = FALSE)
library(units)
library(tidyverse)
library(sf)
library(mapview)
library(geojsonio)

# Read in all files
norStations <- st_read("SEPTA__Norristown_Highspeed_Line_Stations.geojson")
bslStations <- st_read("SEPTA__Broad_Street_Line_Stations.geojson")
mflStations <- st_read("SEPTA__MarketFrankford_Line_Stations.geojson")
rrStations  <- st_read("SEPTA_Regional_Rail_Stations.geojson")
trolStations<- st_read("SEPTA__Trolley_Stops.geojson")
busStations <- st_read("SEPTA__Bus_Stops.geojson")

createBuffer <- function(x) {
  buffer <- 
    x[,c("OBJECTID","Route","Station","Latitude","Longitude","geometry")] %>%
    #st_transform(select(x,geometry), crs = 4326) %>% # projection
    st_buffer(dist=804.672) %>% # this is 0.5 miles in meters
    st_union() # make one shapefile of all buffers
}
colnames(norStations)
norBuff <- createBuffer(norStations)
mapview(norStations)

colnames(bslStations)
bslBuff <- createBuffer(bslStations)
mapview(bslBuff)

colnames(mflStations)
mflBuff <- createBuffer(mflStations)
mapview(mflBuff)

colnames(rrStations)
colnames(rrStations)[2] <- "Route"
colnames(rrStations)[3] <- "Station"
rrBuff <- createBuffer(rrStations)
mapview(rrBuff)

colnames(trolStations)
colnames(trolStations)[9] <- "Station"
trolBuff <- createBuffer(trolStations)
mapview(trolBuff)

colnames(busStations)
colnames(busStations)[9] <- "Station"
busBuff <- createBuffer(busStations)
mapview(busBuff)

allBuffs <- 
  st_union(bslBuff,busBuff) %>%
  st_union(mflBuff) %>%
  st_union(norBuff) %>%
  st_union(rrBuff) %>%
  st_union(trolBuff) 

allBuffs  <- st_as_sf(allBuffs)
# Fix projection
allBuffs <- st_transform(allBuffs,st_crs(bslStations))
mapview(allBuffs)
geojson_write(input=allBuffs,file="transitPoly.geojson")
