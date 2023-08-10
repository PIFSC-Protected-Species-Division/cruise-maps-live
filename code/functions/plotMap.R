plotMap <- function(dir_wd, ep, epNew, ce, shipCode, leg, dataType){
  
  #' plotMap
  #' 
  #' @description create an overview map of HICEAS 2023 survey effort
  #' 
  #' The general survey area is outlined and proposed tracklines are plotted in 
  #' dark grey. Realized effort tracklines are in pink - dark pink for previous
  #' days and light pink for the most recent day. Animal sightings are overlaid
  #' with different symbols/colors for each species sighted. Sightings of 
  #' unidentified small, medium, and large dolphins are all combined with the 
  #' 'unidentified dolphins' category. Sightings of unidentified small and 
  #' large whales and unidentified whales and cetaceans are all combined in the 
  #' 'unidentified cetacenas' category. 
  #' 
  #' author: Janelle Badger janelle.badger [at] noaa.gov
  #' co-author: Selene Fregosi selene.fregosi [at] noaa.gov
  #' date: 01 August 2023
  #'
  #' @param dir_wd character string to the cruise-maps-live working directory
  #' @param ep data.frame of effort as points, cumulative over a HICEAS leg
  #' @param epNew data.frame of effort as tracks, just new additions
  #' @param ce data.frame of 'cetacean encounters', either from visual sightings
  #' or from acoustic detections, cumulative over a HICEAS leg
  #' @param shipCode character string with code for ship (either 'OES' or 'LSK',
  #'  or in the future, both as c('OES', 'LSK'))
  #' @param leg character string with leg number (e.g., '1')
  #' @param dataType character string of either 'visual' or 'acoustic' to set
  #' legend, title, and symbol size
  #' @param test_code logical input to randomly generate and plot data for testing
  #' 
  #' @return base_map map figure 
  #'
  #' @examples
  #'  plotMap(dir, leg, ep, epNew, vs, leg, ship, test_code=TRUE)
  #'
  #' ######################################################################
  
  ## Load map layers & helpers
  key <- read.csv(file.path(dir_wd, 'inputs', "SpeciesCodestoNames.csv"), 
                  fileEncoding="UTF-8-BOM")
  load(file.path(dir_wd, 'inputs', "map_layers.RData")) 
  bathy <- readRDS(file=file.path(dir_wd, 'inputs', "Bathymetry_EEZ.rda")) %>%
    terra::rast()
  
  if(length(shipCode) > 1){stop("We're not ready for two boats yet!! Bug Janelle and Selene.")}
  
  # if (test_code==TRUE){ # TEST DATA
  #   load(file.path(dir_wd, 'data', 'OES2303', 'compiledEffortPoints_OES2303.Rda'))
  #   load(file.path(dir_wd, 'data', 'OES2303', 'snapshots', 
  #                  'newEffortPoints_OES2303_leg2_DASALL.808_ran2023-08-09.Rda'))
  #   load(file.path(dir_wd, 'data', 'OES2303', 'compiledSightings_OES2303.Rda'))
  #   load(file.path(dir_wd, 'data', 'OES2303', 'compiledDetections_OES2303.Rda'))
  #   if (dataType == 'visual'){
  #     ce = vs
  #   } else if (dataType == 'acoustic'){
  #     ad$SpCode = as.integer(ad$sp_map)
  #     ce = ad
  #   }
  # }
  
  
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
  ## Load cetacean encounter data #######
  # if working from files, define and load
  # file.name.sightings<-paste0("compiledSightings_2023_leg",leg,"_",ship,".Rda")
  # load(file.path(dir, file.name.sightings))
  # vs already exists and is now a function input so don't need to load file. 
  ceMap = ce # rename whatever the encounter input is
  
  # clean up sightings locations and add spNames
  key$SpCode<-as.integer(key$SpCode)   #COULD CAUSE PROBLEMS IF CHARACTERS PRESENT
  ceMap$lon <- ifelse(ceMap$Lon > 0, ceMap$Lon-360, ceMap$Lon)
  ceMap <- sf::st_as_sf(ceMap,coords=c("lon","Lat"), crs = 4326)%>%
    dplyr::left_join(key, by = "SpCode")
  ceMap = ceMap[!is.na(ceMap$SpName),] # remove any species names that didn't find a match
  #sort ceMap by species name 
  ceMap = ceMap[rev(order(ceMap$SpName)),]
  # ceMap$SpNameFactor = factor(ceMap$SpName, levels = unique(ceMap$SpName[order(ceMap$Level)]), ordered = TRUE)
  
  
  
  
  ######################
  ##Now for THE MAP ####
  
  colors_lines <- c("deeppink","deeppink4", "grey0")
  
  colors_enc <- unique(ceMap$SpColor)
  
  uci = match(unique(ceMap$SpColor), ceMap$SpColor)
  shapes_enc <- ceMap$SpSymbol[uci]
  
  labels_lines <- c( "Survey effort (recent)", 
                     "Survey effort (to date)", 
                     "Pre-determined transect lines")
  
  labels_enc<-unique(ceMap$SpName)
  
  if (dataType == 'visual'){
    plotTitle = 'What cetaceans have we seen during HICEAS 2023?'
    legendName = 'Sightings'
    shapesSize = 3
  } else if (dataType == 'acoustic'){
    plotTitle = 'What cetaceans have we heard during HICEAS 2023?'
    legendName = 'Acoustic Detections'
    shapesSize = 2
  }
  
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
    geom_sf(data=ceMap, aes(color=SpName, shape = SpName), size = shapesSize, 
            stroke = 0.8)+
    scale_color_manual(name = legendName, values = rev(colors_enc), 
                       labels = rev(labels_enc))+
    scale_shape_manual(name = legendName, values = rev(shapes_enc), 
                       labels = rev(labels_enc))+
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
                   y.max = max(lines$Latitude)) +
    ggtitle(plotTitle) +
    theme(plot.title = element_text(hjust = 0.5))
  
  
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
  # need updated ceMap that has SpName col
  mapOut = list(base_map = base_map, ceMap = ceMap)
  return(mapOut)
}


