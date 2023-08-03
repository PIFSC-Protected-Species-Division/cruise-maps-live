parseTrack <- function(df_proc){
  
  #' parseTrack
  #' 
  #' @description Pull effort tracks from a relatively raw daily .das file 
  #' generated during HICEAS 2023. Utilizes the package 'swfscDAS' and then 
  #' cleans up those outputs a bit. 
  #' 
  #' author: Selene Fregosi selene.fregosi [at] noaa.gov
  #' date: 01 August 2023
  #'
  #' @param df_proc processed das file (with swfscDAS::das_process)
  #' 
  #' @return a dataframe of effort tracks with date and lat/lon
  #'
  #' @examples
  #' # extract all new tracks from a given das file, d$name
  #' et = parseTrack(here('inputs', d$name))
  #' 
  #' ######################################################################
  

  
  # summarize effort segments. 'section' method pulls lat/lon for all 'R' (resume
  # effort) and all 'E' (end effort) entries, then calcs dist btwn
  et_all = swfscDAS::das_effort(df_proc, method = 'section', dist.method = 'greatcircle', 
                       num.cores = 1)
  # trim to just what we want
  et_seg = et_all$segdata
  et = subset(et_seg, select = c(Cruise, segnum, stlin:mtime, Mode, 
                                          EffType, avgSpdKt, avgBft))
  # effort types can be 'N' non-standard, 'S' standard', and 'F' fine-scale
  # could further trim by this. 
  
  # apply correct timezone to datetime cols
  et$DateTime1 = lubridate::force_tz(et$DateTime1, tzone = 'HST')
  et$DateTime2 = lubridate::force_tz(et$DateTime2, tzone = 'HST')
  et$mDateTime = lubridate::force_tz(et$mDateTime, tzone = 'HST')
  # View(et)
  
  return(et)
  
}
