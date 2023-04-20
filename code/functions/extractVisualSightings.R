extractVisualSightings <- function(dasFile){
  
  #' pull visual sightings from das
  #'
  #' @param dasFile fullfile path to das file to be processed
  #' 
  #' @return
  #' @export
  #'
  #' @examples
  
  # for testing
  dasFile = here('inputs', d$name)
  df = dasFile
  head(readLines(df, warn = FALSE))
  
  #Do basic checks on data
  df_check <- das_check(df, skip = 0, print.cruise.nums = TRUE)
  #Read and process data
  df_read <- das_read(df, skip = 0)
  df_proc <- das_process(df)
  return
  
}