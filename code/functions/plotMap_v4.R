
# Map for HICEAS 2023 Survey Effort

#Function to search/install/load needed packages
using<-function(...) {
  libs<-unlist(list(...))
  req<-unlist(lapply(libs,require,character.only=TRUE))
  need<-libs[req==FALSE]
  n<-length(need)
  if(n>0){
    libsmsg<-if(n>2) paste(paste(need[1:(n-1)],collapse=", "),",",sep="") else need[1]
    print(libsmsg)
    if(n>1){
      libsmsg<-paste(libsmsg," and ", need[n],sep="")
    }
    libsmsg<-paste("The following packages could not be found: ",libsmsg,"\n\r\n\rInstall missing packages?",collapse="")
    if(winDialog(type = c("yesno"), libsmsg)=="YES"){       
      install.packages(need)
      lapply(need,require,character.only=TRUE)
    }
  }
}
using("raster",
      "viridis",
      "plotKML",
      "rgdal",
      "tidyverse",
      "sf",
      "sp",
      "rgeos",
      "ggsn",
      "ggrepel",
      "cowplot",
      "ggnewscale",
      "RColorBrewer")


dir<-"~/Dropbox/work/HICEAS"
leg<-"00"                        
ship<-c("OES", "LASK")

plotMap<-function(dir, leg, ship, test_code){ 
  ## Load map layers & helpers
  key<-read.csv(file.path(dir, "SpeciesCodestoNames.csv"))
  load(file.path(dir, "map_layers.RData")) 
  bathy <- readRDS(file=file.path(dir, "Bathymetry_EEZ.rda"))%>%terra::rast()
  
  
if(test_code==FALSE){
if(length(ship)<2){
  file.name.effort<-paste0("compiledEffortPoints_2023_leg",leg,"_",ship,".csv")
  file.name.recent<-paste0("etNew_2023_leg",leg,"_",ship,".csv")
  file.name.sightings<-paste0("compiledSightings_2023_leg",leg,"_",ship,".Rda")
}else{stop("We're not ready for two boats yet!! Bug Janelle and Selene.")}

  
  ####################################
  ## Load HICEAS points, cumulative ####
  
  effort<-read.csv(file.path(dir, file.name.effort))  #read in file
  effort$lon <- ifelse(effort$Lon > 0, effort$Lon-360, effort$Lon)    #correct dateline 
  effort <- st_as_sf(effort, coords=c("lon","Lat"), crs = 4326)
  
  ## Load HICEAS points, recent (etNew)
  tmp<-read.csv(file.path(dir, file.name.recent))
  tmp$lon <- ifelse(tmp$Lon > 0, tmp$Lon-360, tmp$Lon)
  tmp <- st_as_sf(tmp, coords=c("lon","Lat"), crs = 4326)
  
  
  ##################
  ## Load sightings data 
  
  load(file.path(dir, file.name.sightings))
  key$SpCode<-as.integer(key$SpCode)                            #COULD CAUSE PROBLEMS IF CHARACTERS PRESENT
  
  vs$lon <- ifelse(vs$Lon > 0, vs$Lon-360, vs$Lon)
  vs <- st_as_sf(vs,coords=c("lon","Lat"), crs = 4326)%>%
    dplyr::left_join(key, by = "SpCode")
  

  # #################
  # ## Load acoustics events data 
  # ac<-read.csv(file.path(dir, "AcousticsDatabase.csv"))%>%
  #   mutate(DateTime = as.POSIXct(DateTime, format = "%Y-%m-%d %H:%M:%OS"))
  # 
  # ac$lon <- ifelse(ac$Lon > 0, effort$Lon-360, effort$Lon)
  # effort <- filter(effort, lon <= -150)%>% 
  #   st_as_sf(coords=c("lon","Lat"), crs = 4326)
}else{
  effort<-read.csv(file.path(dir, "compiledEffortPoints_2017_leg00_OES.csv"))%>%
    mutate(DateTime = as.POSIXct(DateTime, format = "%Y-%m-%d %H:%M:%OS"))
  effort$lon <- ifelse(effort$Lon > 0, effort$Lon-360, effort$Lon)
  effort <- filter(effort, lon <= -150)%>% 
    st_as_sf(coords=c("lon","Lat"), crs = 4326)
  
  ## Load HICEAS points, recent 
  tmp<-effort%>%filter(DateTime >  "2017-07-31 00:00:00")# Fake, just to show--"recent" data vs "all"
  
  load(file.path(dir, "compiledSightings_2017_leg00_OES.Rda"))
  key$SpCode<-as.integer(key$SpCode)                            #COULD CAUSE PROBLEMS IF CHARACTERS PRESENT
  
  vs$lon <- ifelse(vs$Lon > 0, vs$Lon-360, vs$Lon)
  vs <- filter(vs, lon <= -150,)%>% 
    st_as_sf(coords=c("lon","Lat"), crs = 4326)%>%
    dplyr::left_join(key, by = "SpCode")
  
}
  


  ######################
  ##Now for THE MAP ####
  
  colors_lines<-c("deeppink","deeppink4", "grey0")
  
  colors_enc<-brewer.pal(length(unique(vs$SpCode)), "Set2")
  
  labels_lines<-c( "Survey effort (recent)", 
                   "Survey effort (to date)", 
                   "Pre-determined transect lines")
  
  
  labels_enc<-unique(vs$SpName)
  
  
  
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
    ggspatial::layer_spatial(bathy)+ 
    geom_sf(data=p_x1, fill = "white", alpha=0.1, color=NA)+
    geom_sf(data=pmnm_shifted, fill="white", alpha = 0.1, color=NA)+
    geom_line(data=lines, aes(x = Longitude, y= Latitude, group=Line, color=colors_lines[3]), alpha=0.5, linewidth=0.5)+
    ggspatial::layer_spatial(eez, fill=NA, color = "white")+
    geom_sf(data=mhi, fill = "white", color="black", lwd=0.5)+
    geom_sf(data=nwhi, fill= "white", color = "white")+
    ggspatial::layer_spatial(effort, alpha=0.5, size=0.5, aes(color=colors_lines[2]))+
    ggspatial::layer_spatial(tmp, alpha=0.5, size=0.5, aes(color=colors_lines[1]))+
    scale_color_manual(name = "Tracklines & Effort", values = colors_lines, labels=labels_lines)+

    
     new_scale_color() +
     geom_sf(data=vs, aes(color=SpName, shape = SpName), size = 3)+
     scale_color_manual(name = "Encounters", values = colors_enc, labels = labels_enc)+
     scale_shape_manual(name="Encounters", values = 1:length(unique(vs$SpName)),labels = labels_enc)+
     guides(colour = guide_legend(override.aes = list(size=3)))+
    
    
  annotate("text", x=-168, y=29.5, 
           label= expression("Papah"*bar(a)*"naumoku"*bar(a)*"kea Marine National Monument"), 
           col="white", size = 3,
           angle=-20)+
    
    annotate("text", x=-155, y=25, 
             label= "Main Hawaiian Islands", 
             col="white", size = 3,
             angle=-20)+
    
    
    ggsn::scalebar(location = "bottomleft", dist = 200, dist_unit = "nm", st.dist = 0.025,
                   transform=TRUE, st.size = 3, st.color="white",
                   model = 'WGS84', st.bottom=TRUE,
                   x.min = min(lines$Longitude),
                   x.max = max(lines$Longitude),
                   y.min = min(lines$Latitude),
                   y.max = max(lines$Latitude))
  
  print(base_map)

  
  png(file = file.path(dir, "HICEAS_map.png"), 
      width = 10, height = 5, res = 400, units = "in")
  
  print(base_map)
  dev.off()
}


plotMap(dir, leg, ship, test_code=TRUE)
