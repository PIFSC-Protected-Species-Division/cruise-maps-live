plotMap <- function(dir_wd, ep, epNew, ce, shipCode, dataType){
  
  #' plotMap
  #' 
  #' @description create an overview map of HICEAS 2023 survey ep
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
  #' date: 13 October 2023
  #'
  #' @param dir_wd character string to the cruise-maps-live working directory
  #' @param ep data.frame of effort as points, cumulative over a HICEAS leg
  #' @param epNew data.frame of effort as tracks, just new additions
  #' @param ce data.frame of 'cetacean encounters', either from visual sightings
  #' or from acoustic detections, cumulative over a HICEAS leg
  #' @param shipCode character string with code for ship (either 'OES' or 'LSK',
  #'  or in the future, both as c('OES', 'LSK'))
  #' @param dataType character string of either 'visual' or 'acoustic' to set
  #' legend, title, and symbol size
  #' 
  #' @return base_map map figure 
  #'
  #' @examples
  #'    mapOutV = plotMap(dir_wd, ep, epNew, vs, shipCode, dataType = 'visual')
  #'
  #' ######################################################################
  library(ggtext)
  
  ## Load map layers & helpers
  key <- read.csv(file.path(dir_wd, 'inputs', "SpeciesCodestoNames.csv"), 
                  fileEncoding="UTF-8-BOM")
  load(file.path(dir_wd, 'inputs', "map_layers.RData")) 
  bathy <- readRDS(file=file.path(dir_wd, 'inputs', "Bathymetry_EEZ.rda")) %>%
    terra::rast()
  
  # # to crop the LSK tracks to the correct window
  # crop<-terra::ext(bathy) %>% 
  #   terra::as.polygons(crs=crs(bathy)) %>% 
  #   sf::st_as_sf(crs=4326)  
  
  #######################################
  ## Load HICEAS points, cumulative #####
  
  # clean up effort locations
  ep$lon <- ifelse(ep$Lon > 0, ep$Lon-360, ep$Lon)    #correct dateline 
  ep<-ep[ep$lon<(-150),] # filter to only points west of map extent
  ep <- sf::st_as_sf(ep, coords=c("lon","Lat"), crs = 4326)
  
  ## Load HICEAS points, recent (epNew)
  # clean up newest effort locations
  epNew$lon <- ifelse(epNew$Lon > 0, epNew$Lon-360, epNew$Lon)
  epNew<-epNew[epNew$lon<(-150),]
  epNew <- sf::st_as_sf(epNew, coords=c("lon","Lat"), crs = 4326)
  
  
  #######################################
  ## Load cetacean encounter data #######
  
  # clean up sightings locations and add spNames
  key$SpCode<-as.integer(key$SpCode)   #COULD CAUSE PROBLEMS IF CHARACTERS PRESENT
  ce$lon <- ifelse(ce$Lon > 0, ce$Lon-360, ce$Lon)
  ceMap = dplyr::left_join(ce, key, by = 'SpCode')
  ceMap <- ceMap[ceMap$lon<(-150),]
  ceMap <- sf::st_as_sf(ceMap, coords=c("lon","Lat"), crs = 4326) 
  ceMap = ceMap[!is.na(ceMap$SpName),] # remove species names without a match
  #sort ce by species name 
  ceMap = ceMap[rev(order(ceMap$SpName)),]
  
  
  #######################################
  ## Now for THE MAP ####################
  
  # set variables independent of number of ships
  colors_enc <- unique(ceMap$SpColor)
  uci = match(unique(ceMap$SpColor), ceMap$SpColor)
  shapes_enc <- ceMap$SpSymbol[uci]
  labels_enc<-unique(ceMap$SpName)
  
  if (dataType == 'visual'){
    plotTitle = 'What cetaceans have we seen during HICEAS 2023?'
    legendName = 'Visual Sightings'
    shapesSize = 3
  } else if (dataType == 'acoustic'){
    plotTitle = 'What cetaceans have we heard during HICEAS 2023?'
    legendName = 'Acoustic Detections'
    shapesSize = 2
  }
  
  tw = 0.3 # track width
  ta = 0.2 # track alpha
  
  
  # start map
  base_map <- ggplot() + 
    theme_bw() +
    theme(axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.ticks = element_blank(),
          axis.text.x = element_blank(),
          panel.grid = element_blank(),
          panel.border = element_blank(), 
          plot.margin = unit(c(0,0,0,0), "cm"),
          legend.text = element_markdown())+
    
    scale_fill_distiller(guide= "none")+
    
    ## add bathymetry layer, depth contours, & tracklines
    ggnewscale::new_scale_color() +
    ggspatial::layer_spatial(bathy)+ 
    geom_sf(data=p_x1, fill = "white", alpha=0.1, color=NA)+
    geom_sf(data=pmnm_shifted, fill="white", alpha = 0.1, color=NA)
  
  
  ### ONE SHIP ##########################
  if ((length(shipCode) == 1) || (length(unique(ep$shipCode)) == 1)){
    
    colors_lines <- c("deeppink","deeppink4", "grey0")
    
    labels_lines <- c( "Survey effort (recent, *Sette*)", 
                       "Survey effort (to date, *Sette*)", 
                       "Pre-determined transect lines")
    
    base_map = base_map +
      geom_line(data=lines, aes(x=Longitude, y=Latitude, group=Line, 
                                color=colors_lines[3]), alpha=0.5, linewidth=0.5) +
      ggspatial::layer_spatial(eez, fill=NA, color = "white")+
      geom_sf(data=mhi, fill = "white", color="black", lwd=0.5)+
      geom_sf(data=nwhi, fill= "white", color = "white")+
      
      ggspatial::layer_spatial(ep, alpha=ta, size=tw, 
                               aes(color=colors_lines[2]))+
      ggspatial::layer_spatial(epNew, alpha=ta, size=tw, 
                               aes(color=colors_lines[1]))+
      scale_color_manual(name = "Tracklines & Effort", values = colors_lines, 
                         labels = labels_lines)+
      guides(colour = guide_legend(order = 1))
    
    
    ### TWO SHIPS #######################
  } else if ((length(shipCode) == 2) && (length(unique(ep$shipCode)) == 2)){
    
    # colors must be defined in legend order, but called ?? order
    colors_lines <- c("deeppink", "deeppink4", "gold", "darkorange2", "grey0")
    # even though a call to colors_lines[3] at this point would give you gold, 
    # when plotting it would give darkorange2
    # ?? mystery order ?? 1-deeppink4 2-gold 3-darkorange2 4-deeppink 5-grey0 
    
    # specify labels in actual order they should appear in legend
    labels_lines <- c('Survey effort (recent, *Sette*)', 
                      "Survey effort (to date, *Sette*)", 
                      "Survey effort (recent, *Lasker*)", 
                      "Survey effort (to date, *Lasker*)", 
                      "Pre-determined transect lines")
    
    
    base_map = base_map +
      geom_line(data=lines, aes(x = Longitude, y= Latitude, group=Line, 
                                color = colors_lines[5]),
                alpha=0.5, linewidth=0.5)+
      ggspatial::layer_spatial(eez, fill=NA, color = "white")+
      geom_sf(data=mhi, fill = "white", color="black", lwd=0.5)+
      geom_sf(data=nwhi, fill= "white", color = "white")+
      
      
      ggspatial::layer_spatial(ep[ep$shipCode == 'OES',], alpha=ta, size=tw,
                               aes(color=colors_lines[1]))+
      ggspatial::layer_spatial(ep[ep$shipCode == 'LSK',], alpha=ta, size=tw,
                               aes(color=colors_lines[3]))+
      
      ggspatial::layer_spatial(epNew[epNew$shipCode == 'OES',], alpha=ta,
                               size=tw, aes(color=colors_lines[4]))+
      ggspatial::layer_spatial(epNew[epNew$shipCode == 'LSK',], alpha=ta, 
                               size=tw, aes(color=colors_lines[2]))+
      
      scale_color_manual(name = "Tracklines & Effort", values = colors_lines, 
                         labels = labels_lines)+
      guides(colour = guide_legend(override.aes = list(size = 1, linewidth = 1,
                                                       alpha = 1), 
                                   nrow = 3, byrow = TRUE, order = 1))
  }
  
  
  ### CETACEANS #####################
  base_map = base_map +
    ggnewscale::new_scale_color() +
    geom_sf(data=ceMap, aes(color=SpName, shape = SpName), size = shapesSize, 
            stroke = 0.8)+
    scale_color_manual(name = legendName, values = rev(colors_enc), 
                       labels = rev(labels_enc))+
    scale_shape_manual(name = legendName, values = rev(shapes_enc), 
                       labels = rev(labels_enc))+
    guides(shape = guide_legend(nrow = 13, order = 2),
           colour = guide_legend(override.aes = list(size = 3), nrow = 13, 
                                 order = 2))+
    
    
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
  
  
  base_map # display map during testing
  
  ### Output ############################
  numColsCet = ceiling(length(unique(ceMap$SpName))/13)
  numColsShp = ceiling(length(labels_lines)/3)
  numCols = max(c(numColsCet, numColsShp))
  
  # need two outputs to make a list
  # need updated ceMap that has SpName col
  mapOut = list(base_map = base_map, ceMap = ceMap, numCols = numCols)
  return(mapOut)
  
}

