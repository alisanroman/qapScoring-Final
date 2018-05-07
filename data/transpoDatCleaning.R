# Global options
setwd('/Users/amsr/Documents/GitHub/qapScoring-Final/data')
options(stringsAsFactors = FALSE)
library(units)
library(tidyverse)
library(sf)

# Read in all files
bslStations <- st_read("SEPTA__Broad_Street_Line_Stations.geojson")
busStations <- st_read("SEPTA__Bus_Stops.geojson")
mflStations <- st_read("SEPTA__MarketFrankford_Line_Stations.geojson")
norStations <- st_read("SEPTA__Norristown_Highspeed_Line_Stations.geojson")
trolStations<- st_read("SEPTA__Trolley_Stops.geojson")
rrStations <- st_read("SEPTA_Regional_Rail_Stations.geojson")

# combine all routes
allStations <- 
  st_union(x=bslStations,y=mflStations) %>%
  st_union(norStations)
mapview(allStations)

# merge
createBuffer <- function(x) {
  buffer <- 
    x[,c(1:4,43:45)] %>%
    st_transform(crs = 32618) %>% # projection
    st_buffer(dist=804.672) %>% # this is 0.5 miles in meters
    st_union() # make one shapefile of all buffers
}
bslBuff <- createBuffer(bslStations)


mapview(bslBuff)


