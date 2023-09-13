extractTrack <- function(df_proc){
  
  #' extractTrack
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
  et = subset(et_seg, select = c(Cruise, segnum, file, stlin:mtime, Mode, 
                                          EffType, avgSpdKt, avgBft))
  
  # rename the file_das column to match tracks output
  colnames(et)[3] = 'file_das'
  
  # effort types can be 'N' non-standard, 'S' standard', and 'F' fine-scale
  # could further trim by this. 
  
  return(et)
  
}
