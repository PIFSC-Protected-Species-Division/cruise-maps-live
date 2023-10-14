dir<-"~/Dropbox/work/HICEAS" #jb machie
dir<-'~/github/cruise-maps-live/testing/inputs' #sf machine

library(tidyverse)
library(sf)
library(terra)
library(ggplot2)

load(file.path(dir, "map_layers.RData")) 
bathy <- readRDS(file=file.path(dir, "Bathymetry_EEZ.rda"))%>%terra::rast()

crop<-ext(bathy)%>%as.polygons(crs=crs(bathy))%>%st_as_sf(crs=4326)  # to crop the LSK tracks to the correct window

load(file.path(dir, "compiledEffortPoints_twoBoats_combined.Rda"))  #read in file
epC$lon <- ifelse(epC$Lon > 0, epC$Lon-360, epC$Lon)    #correct dateline 
epC <- st_as_sf(epC, coords=c("lon","Lat"), crs = 4326)%>%st_crop(crop)

## Load HICEAS points, recent (etNew)
load(file.path(dir, "newEffortPoints_twoBoats_combined.Rda"))
epNewC$lon <- ifelse(epNewC$Lon > 0, epNewC$Lon-360, epNewC$Lon)
epNewC <- st_as_sf(epNewC, coords=c("lon","Lat"), crs = 4326)%>%st_crop(crop)

# should also use the same cropping function for the sightings/acoustics 


######################
##Now for THE MAP ####

# list colors in alphabetical order
colors_lines <- c("deeppink", "deeppink4", "yellow", "orange", "grey0")
# even tho if you called colors_lines[3] at this point it would give you yellow, 
# when actually plotting it gives you grey0... don't know why

# specify labels in actual order they should appear in legend
labels_lines <- c("Survey effort (recent, Sette)", 
                  "Survey effort (to date, Sette)", 
                  "Survey effort (recent, Lasker)", 
                  "Survey effort (to date, Lasker)", 
                  "Pre-determined transect lines")


  plotTitle = 'What cetaceans have we seen during HICEAS 2023?'
  legendName = 'Sightings'
  shapesSize = 3


tw = 0.3 # track width
ta = 0.2 # track alpha


base_map <- ggplot() + 
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        axis.ticks = element_blank(),
        axis.text.x = element_blank(),
        panel.grid = element_blank(),
        panel.border = element_blank(), 
        plot.margin = unit(c(0,0,0,0), "cm"))+
  
  scale_fill_distiller(guide= "none")+
  
  ## add bathymetry layer, depth contours, & tracklines
  ggnewscale::new_scale_color() +
  ggspatial::layer_spatial(bathy)+ 
  geom_sf(data=p_x1, fill = "white", alpha=0.1, color=NA)+
  geom_sf(data=pmnm_shifted, fill="white", alpha = 0.1, color=NA)+
  geom_line(data=lines, aes(x = Longitude, y= Latitude, group=Line, 
                            color=colors_lines[3]), alpha=0.5, linewidth=0.5)+
  ggspatial::layer_spatial(eez, fill=NA, color = "white")+
  geom_sf(data=mhi, fill = "white", color="black", lwd=0.5)+
  geom_sf(data=nwhi, fill= "white", color = "white")+
  ggspatial::layer_spatial(epC[epC$shipCode == 'OES',], alpha=ta, size=tw,
                           aes(color=colors_lines[2]))+
  ggspatial::layer_spatial(epC[epC$shipCode == 'LSK',], alpha=ta, size=tw,
                           aes(color=colors_lines[4]))+
  
  ggspatial::layer_spatial(epNewC[epNewC$shipCode == 'OES',], alpha=ta,
                           size=tw, aes(color=colors_lines[1]))+
  ggspatial::layer_spatial(epNewC[epNewC$shipCode == 'LSK',], alpha=ta, 
                           size=tw, aes(color=colors_lines[5]))+
  
    scale_color_manual(name = "Tracklines & Effort", values = colors_lines, 
                     labels = labels_lines)+
  guides(colour = guide_legend(order = 1))


base_map 



