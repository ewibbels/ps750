install.packages("Cairo")
library("tmap")
library("leaflet")
library(rgdal)
library(scales)
library(ggmap)
library(dplyr)
library(Cairo)
usshapefile <-"/Users/changqing/Documents/R/Kenya_admin_WGS84/Kenya_admin_2014_WGS84.shp"
usgeo <- read_shape(file=usshapefile)
####### 1997 election 
kenyavote<-read.csv("kenyavote.csv",header=T)
str(usgeo@data) 
usgeo@data$Province <- as.character(usgeo@data$Province)
kenyavote$Regions<-as.character(kenyavote$Regions)
usgeo <- usgeo[order(usgeo@data$Province),]
kenyavote <-kenyavote[order(kenyavote$Regions),]

nhmap <- append_data(usgeo, kenyavote, key.shp = "Province", key.data="Regions")
qtm(nhmap, "Daniel.ARAP.MOI")
qtm(nhmap, "Mwai.Kibaki")


#####1992
kenya1992<-read.csv("kenya1992.csv",header=T)
str(usgeo@data) 
usgeo@data$Province <- as.character(usgeo@data$Province)
kenya1992$Province<-as.character(kenya1992$Province)
usgeo <- usgeo[order(usgeo@data$Province),]
kenya1992 <-kenya1992[order(kenya1992$Province),]

nhmap1 <- append_data(usgeo, kenya1992, key.shp = "Province", key.data="Province")
qtm(nhmap1, "Moi")

 tm_shape(nhmap1)+
  tm_fill(col="Moi",title="Moi.1992")+
  tm_borders(alpha = .5)+
  tm_text("COUNTY",size = 0.5)
 
 tm_shape(nhmap)+
   tm_fill(col="Daniel.ARAP.MOI",title="Moi.1997")+
   tm_borders(alpha = .5)+
   tm_text("COUNTY",size = 0.5)
 
