extractVisualSightings <- function(dasFile){
  
  #' extractVisualSightings
  #' 
  #' description: Pull visual sightings from a relativly raw daily .das file 
  #' generated during HICEAS 2023. Utilizes the package 'swfscDAS' and then 
  #' cleans up those outputs a bit. 
  #' 
  #' author: Selene Fregosi selene.fregosi [at] noaa.gov
  #' date: 20 April 2023
  #'
  #' @param dasFile fullfile path to das file to be processed
  #' 
  #' @return a dataframe of visual cetacean sightings with date and lat/lon
  #' @export
  #'
  #' @examples
  #' # extract all new sightings from a given das file, d$name
  #' vsNew = extractVisualSightings(here('inputs', d$name))
  
  # for testing
  dasFile = here('inputs', d$name)
  df = dasFile
  head(readLines(df, warn = FALSE))
  
  #Do basic checks on data
  df_check <- das_check(df, skip = 0, print.cruise.nums = TRUE)
  #Read and process data
  df_read <- das_read(df, skip = 0)
  df_proc <- das_process(df)
  
  View(df_proc)
  
  #Summarize sighting data, only want "S" events of cetaceans regardless of effort
  vs_all <- das_sight(df_proc, return.format = "default")
  vs_S <- subset(vs_all, Event == "S")
  vs_S$SpCode <- as.integer(vs_S$SpCode)
  vs_Scet <- subset(vs_S, SpCode >= 0)
  
  #Pare down and reorder columns
  vs_Scet <- subset(vs_Scet, select = c(SpCode, SightNo, DateTime, Cruise, Lat, Lon, EffType, OnEffort, EffortDot, ObsStd, Mixed, Bft, PerpDistKm))
  
  # example cleaned up das file that we have already has negative lon values, put perhaps that is not the case for raw ones?
  # saving this here in case I need it 
  #Need to create a Lon2 column that goes negative past 180 degrees
  y.sight.Scet$Lon2 <- y.sight.Scet$Lon
  for(i in 1:length(y.sight.Scet$Lon2)) {
    if (y.sight.Scet$Lon2[i] >= 0)
    {y.sight.Scet$Lon2[i] <- -360 + y.sight.Scet$Lon2[i]}
  }
  
  # species codes for SF to remember (because she knows nothing!)
  # Spotted dolphin - 002
  # Striped dolphin - 013
  # Rough-toothed dolphin - 015
  # Bottlenose dolphin - 018
  # Risso's dolphin - 021
  # False killer whale - 033
  # Short-finned pilot whale - 036
  # Bryde's whale - 072
  
  return
  
}