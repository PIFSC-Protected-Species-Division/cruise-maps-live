extractVisualSightings <- function(df_proc){
  
  #' extractVisualSightings
  #' 
  #' description: Pull visual sightings from a relatively raw daily .das file 
  #' generated during HICEAS 2023. Utilizes the package 'swfscDAS' and then 
  #' cleans up those outputs a bit. 
  #' 
  #' author: Selene Fregosi selene.fregosi [at] noaa.gov
  #' date: 16 May 2023
  #'
  #' @param df_proc processed das file (with swfscDAS::das_process)
  #' 
  #' @return a dataframe of visual cetacean sightings with date and lat/lon
  #' @export
  #'
  #' @examples
  #' # extract all new sightings from a given das file, d$name
  #' vsNew = extractVisualSightings(paste0(dir_wd, 'inputs/', d$name))
  
  
  # pull out 'S' events of cetaceans only, regardless of effort
  vs_all = swfscDAS::das_sight(df_proc, return.format = 'default')
  vs_S = subset(vs_all, Event == 'S')
  vs_S$SpCode = as.integer(vs_S$SpCode)
  vs_SCet = subset(vs_S, SpCode >= 0)
  
  # pare down and reorder columns
  vs_SCet <- subset(vs_SCet, select = c(SpCode, SightNo, DateTime, Cruise, Lat, 
                                        Lon, EffType, OnEffort, EffortDot, 
                                        ObsStd, Mixed, Bft, PerpDistKm))
  
  # deal with data points that might be across the dateline
  # not sure this is necessary but leaving here, commented out, in case it is
  # vs_SCet$Lon2 = vs_SCet$Lon
  # for(i in 1:length(vs_SCet$Lon2)){
  #   if (vs_SCet$Lon2[i] >= 0){
  #     vs_SCet$Lon2[i] <- -360 + vs_SCet$Lon2[i]
  #   }
  # }
  # 
  
  # trim to only on effort sightings
  vs_SCet_OE = vs_SCet[which(vs_SCet$OnEffort == TRUE),]
  
  # for now exporting all sightings, can change to only on effort
  vs = vs_SCet
  # vs = vs_SCet_OE
  
  # apply correct timezone to datetime col
  vs$DateTime = lubridate::force_tz(vs$DateTime, tzone = 'HST')


  return(vs)
  
}