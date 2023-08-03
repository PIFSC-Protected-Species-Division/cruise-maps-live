plotMap <- function(dir_wd, ep, epNew, vs, shipCode, leg, test_code){
  
  #' plotMap
  #' 
  #' description:
  #' 
  #' author: Janelle Badger janelle.badger [at] noaa.gov
  #' date: 30 June 2023
  #'
  #' @param dir_wd character string to the cruise-maps-live working directory
  #' @param ep data.frame of effort as points, cumulative over a HICEAS leg
  #' @param epNew data.frame of effort as tracks, just new additions
  #' @param vs data.frame of visual sightings, cumulative over a HICEAS leg
  #' @param shipCode character string with code for ship (either 'OES' or 'LSK', or
  #' in the future, both as c('OES', 'LSK'))
  #' #' @param leg character string with leg number (e.g., '01')
  #' @param test_code logical input to randomly generate and plot data for testing
  #' 
  #' @return base_map map figure 
  #' @export
  #'
  #' @examples
  #'  plotMap(dir, leg, ship, test_code=TRUE)
  #'
  #'
  #'
  
  ## Load map layers & helpers
  key <- read.csv(file.path(dir_wd, 'inputs', "SpeciesCodestoNames.csv"), 
                  fileEncoding="UTF-8-BOM")
  load(file.path(dir_wd, 'inputs', "map_layers.RData")) 
  bathy <- readRDS(file=file.path(dir_wd, 'inputs', "Bathymetry_EEZ.rda")) %>%
    terra::rast()
  
  if(test_code==FALSE){
    if(length(shipCode) > 1){stop("We're not ready for two boats yet!! Bug Janelle and Selene.")}
    
    #######################################
    ## Load HICEAS points, cumulative #####
    # if working from files, define and load
    # file.name.effort<-paste0("compiledEffortPoints_2023_leg",leg,"_",ship,".csv")
    # effort<-read.csv(file.path(dir, file.name.effort))  #read in file
    effort = ep  # if running within run.R, just rename input 
    
    # clean up effort locations
    effort$lon <- ifelse(effort$Lon > 0, effort$Lon-360, effort$Lon)    #correct dateline 
    effort <- sf::st_as_sf(effort, coords=c("lon","Lat"), crs = 4326)
    
    ## Load HICEAS points, recent (etNew) #
    # file.name.recent<-paste0("epNew_2023_leg",leg,"_",ship,".csv")
    # tmp<-read.csv(file.path(dir, file.name.recent))
    tmp = epNew # if running within run.R, just rename input
    
    # clean up tmp locations
    tmp$lon <- ifelse(tmp$Lon > 0, tmp$Lon-360, tmp$Lon)
    tmp <- sf::st_as_sf(tmp, coords=c("lon","Lat"), crs = 4326)
    
    
    #######################################
    ## Load sightings data ################
    # if working from files, define and load
    # file.name.sightings<-paste0("compiledSightings_2023_leg",leg,"_",ship,".Rda")
    # load(file.path(dir, file.name.sightings))
    # vs already exists and is now a function input so don't need to load file. 
    vsMap = vs # don't need to read in visual sightings, just rename vs
    
    # clean up sightings locations and add spNames
    key$SpCode<-as.integer(key$SpCode)   #COULD CAUSE PROBLEMS IF CHARACTERS PRESENT
    vsMap$lon <- ifelse(vsMap$Lon > 0, vsMap$Lon-360, vsMap$Lon)
    vsMap <- sf::st_as_sf(vsMap,coords=c("lon","Lat"), crs = 4326)%>%
      dplyr::left_join(key, by = "SpCode")
    vsMap = na.omit(vsMap) # remove any species names that didn't find a match
    #sort vsMap by species name 
    vsMap = vsMap[order(vsMap$SpName),]
    # vsMap$SpNameFactor = factor(vsMap$SpName, levels = unique(vsMap$SpName[order(vsMap$Level)]), ordered = TRUE)
    
    
    # #################
    # ## Load acoustics events data 
    # ac<-read.csv(file.path(dir, "AcousticsDatabase.csv"))%>%
    #   mutate(DateTime = as.POSIXct(DateTime, format = "%Y-%m-%d %H:%M:%OS"))
    # 
    # ac$lon <- ifelse(ac$Lon > 0, effort$Lon-360, effort$Lon)
    # effort <- filter(effort, lon <= -150)%>% 
    #   st_as_sf(coords=c("lon","Lat"), crs = 4326)
    
  }else{ # TEST DATA
    effort<-read.csv(file.path(dir_wd, "data", "compiledEffortPoints_2017_leg00_OES.csv"))%>%
      mutate(DateTime = as.POSIXct(DateTime, format = "%Y-%m-%d %H:%M:%OS"))
    effort$lon <- ifelse(effort$Lon > 0, effort$Lon-360, effort$Lon)
    effort <- filter(effort, lon <= -150)%>% 
      sf::st_as_sf(coords=c("lon","Lat"), crs = 4326)
    
    ## Load HICEAS points, recent 
    tmp<-effort%>%filter(DateTime >  "2017-07-31 00:00:00")# Fake, just to show--"recent" data vs "all"
    
    load(file.path(dir_wd, "data", "compiledSightings_2017_leg00_OES.Rda"))
    key$SpCode<-as.integer(key$SpCode)                            #COULD CAUSE PROBLEMS IF CHARACTERS PRESENT
    
    vsMap$lon <- ifelse(vsMap$Lon > 0, vsMap$Lon-360, vsMap$Lon)
    vsMap <- filter(vsMap, lon <= -150,)%>% 
      sf::st_as_sf(coords=c("lon","Lat"), crs = 4326)%>%
      dplyr::left_join(key, by = "SpCode")
  }
  
  
  
  ######################
  ##Now for THE MAP ####
  
  colors_lines<-c("deeppink","deeppink4", "grey0")
  
  colors_enc<-unique(vsMap$SpColor)

  shapes_enc<-vsMap$SpSymbol #[uci]
  
  labels_lines<-c( "Survey effort (recent)", 
                   "Survey effort (to date)", 
                   "Pre-determined transect lines")
  
  labels_enc<-unique(vsMap$SpName)
  
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
    ggspatial::layer_spatial(bathy)+ 
    geom_sf(data=p_x1, fill = "white", alpha=0.1, color=NA)+
    geom_sf(data=pmnm_shifted, fill="white", alpha = 0.1, color=NA)+
    geom_line(data=lines, aes(x = Longitude, y= Latitude, group=Line, 
                              color=colors_lines[3]), alpha=0.5, linewidth=0.5)+
    ggspatial::layer_spatial(eez, fill=NA, color = "white")+
    geom_sf(data=mhi, fill = "white", color="black", lwd=0.5)+
    geom_sf(data=nwhi, fill= "white", color = "white")+
    ggspatial::layer_spatial(effort, alpha=ta, size=tw, aes(color=colors_lines[2]))+
    ggspatial::layer_spatial(tmp, alpha=ta, size=tw, aes(color=colors_lines[1]))+
    scale_color_manual(name = "Tracklines & Effort", values = colors_lines, 
                       labels = labels_lines)+
    
    
    ggnewscale::new_scale_color() +
    geom_sf(data=vsMap, aes(color=SpName, shape = SpName), size = 3, stroke = 0.8)+
    scale_color_manual(name = "Encounters", values = colors_enc, labels = labels_enc)+
    scale_shape_manual(name = "Encounters", values = shapes_enc, labels = labels_enc)+
    guides(colour = guide_legend(override.aes = list(size = 3)))+
    
    
    annotate("text", x=-168, y=29.5, 
             label= expression("Papah"*bar(a)*"naumoku"*bar(a)*"kea Marine National Monument"), 
             col="white", size = 3,
             angle=-20)+
    
    annotate("text", x=-155, y=25, 
             label= "Main Hawaiian Islands", 
             col="white", size = 3,
             angle=-20)+
    
    annotate("text", x=-179, y=16.5, 
             label= paste0("Last Updated: ", Sys.Date()),
             col="white", size = 2.5)+
    
    ggsn::scalebar(location = "bottomleft", dist = 200, dist_unit = "nm", 
                   st.dist = 0.025,
                   transform=TRUE, st.size = 3, st.color="white",
                   model = 'WGS84', st.bottom=TRUE,
                   x.min = min(lines$Longitude),
                   x.max = max(lines$Longitude),
                   y.min = min(lines$Latitude),
                   y.max = max(lines$Latitude))
  
  
  # rather than print and save within function going to have it as output
  # so easier to map where it needs to be saved and modify name with each leg, etc. 
  # print(base_map)
  # 
  # png(file = file.path(dir, "HICEAS_map.png"), 
  #     width = 10, height = 5, res = 400, units = "in")
  # 
  # print(base_map)
  # dev.off()
  
  # need two outputs to make a list
  # need updated vsMap that has SpName col
  mapOut = list(base_map = base_map, vsMap = vsMap)
  return(mapOut)
}


