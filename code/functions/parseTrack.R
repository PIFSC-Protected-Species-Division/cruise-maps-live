parseTrack <- function(dasFile){
  
  #' parseTrack
  #' 
  #' description: Pull effort tracks from a relatively raw daily .das file 
  #' generated during HICEAS 2023. Utilizes the package 'swfscDAS' and then 
  #' cleans up those outputs a bit. 
  #' 
  #' author: Selene Fregosi selene.fregosi [at] noaa.gov
  #' date: 20 April 2023
  #'
  #' @param dasFile fullfile path to das file to be processed
  #' 
  #' @return a dataframe of effort tracks with date and lat/lon
  #' @export
  #'
  #' @examples
  #' # extract all new tracks from a given das file, d$name
  #' et = parseTrack(here('inputs', d$name))
  
  # for testing
  dasFile = paste0(dir_wd, 'inputs/', yr, '/', d$name)
  df = dasFile
  head(readLines(df, warn = FALSE))
  
  #Do basic checks on data
  df_check <- das_check(df, skip = 0, print.cruise.nums = TRUE)
  #Read and process data
  df_read <- das_read(df, skip = 0)
  df_proc <- das_process(df)
  
  # View(df_proc)
  
  
  #Get summary of effort segments using "section" method, where each segment is a full continuous 
  #effort section (i.e., it runs from an R event to an E event) and trim unwanted columns
  et_all <- das_effort(df_proc, method = "section", dist.method = "greatcircle", num.cores = 1)
  et_seg <- et_all$segdata
  et_seg_sub <- subset(et_seg, select = c(Cruise, segnum, stlin:mtime, Mode, EffType, avgSpdKt, avgBft))
  # View(et_seg_sub)
  
  et <- et_seg_sub
  return(et)
  
}
