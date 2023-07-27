parseTrack_asPoints <- function(df_proc){
  
  #' parseTrack_asPoints
  #' 
  #' description: Pull effort tracks from a relatively raw daily .das file 
  #' generated during HICEAS 2023. Utilizes the package 'swfscDAS' and then 
  #' cleans up those outputs a bit. 
  #' 
  #' author: Selene Fregosi selene.fregosi [at] noaa.gov
  #' date: 16 May 2023
  #'
  #' @param df_proc processed das file (with swfscDAS::das_process)
  #' 
  #' @return a dataframe of effort tracks with date and lat/lon
  #' @export
  #'
  #' @examples
  #' # extract all new tracks from a given das file, d$name
  #' et = parseTrack(here('inputs', d$name))
  
  
  # trim the read in data to just the cols we care about
  df_proc_sub = subset(df_proc, select = c(line_num, Cruise, Event, DateTime, 
                                           Lat, Lon, Mode, OnEffort, EffortDot,
                                           EffType, SpdKt, Bft))
  # technically E is on effort so fix those lines
  df_proc_sub$OnEffort[which(df_proc_sub$Event == 'E')] <- TRUE
  df_proc_sub$EffortDot[which(df_proc_sub$Event == 'E')] <- TRUE
  
  # loop through all lines and add a segment number for continuous effort segments
  df_proc_sub$SegID = 0
  segCounter = 1
  for(i in 1:length(df_proc_sub$line_num)) { 
    if (df_proc_sub$OnEffort[i] == 'TRUE' & df_proc_sub$Event[i] == 'R'){
      df_proc_sub$SegID[i] = segCounter
    } else if (df_proc_sub$OnEffort[i] == 'TRUE' & df_proc_sub$Event[i] != 'E'){
      df_proc_sub$SegID[i] = segCounter
    } else if (df_proc_sub$OnEffort[i] == 'TRUE' & df_proc_sub$Event[i] == 'E'){
      df_proc_sub$SegID[i] = segCounter
      segCounter = segCounter + 1
    }
  }
  
  # clean up output
  # remove off effort lines
  ep = subset(df_proc_sub, SegID > 0)
  # remove begin effort because it's not needed
  ep = subset(ep, Event != 'B')
  # remove comments
  ep = subset(ep, Event != 'C')
  
  return(ep)
  
}
