mapGDDirs <- function(data_source, projID){
  #' mapGDDirs
  #' 
  #' @description map Google Drive directories used in run.R
  #' 
  #' Several Google Drive folders are either accessed to download raw data or 
  #' upload data processing outputs and figures. These can be defined manually
  #' by defining each by an ID (from the URL), but setting each ID manually is 
  #' not very flexible. This function searches Google Drive to map the needed 
  #' folders. Note...it can be slow. Good alternative is to run this once, save 
  #' the output list as a .rda and load that in the future. 
  #' 
  #' 
  #' author: Selene Fregosi selene.fregosi [at] noaa.gov
  #' date: 13 October 2023
  #'
  #' @param data_source character string either 'gd' or 'test_gd'
  #' @param projID character string to identify ship/cruise number e.g., OES2303
  #' 
  #' @return dir_gd list of several directory dribbles
  #'
  #' @examples
  #'    
  #'
  #' ######################################################################

  dir_gd = list()
  
  # set parent folder for actual run vs testing
  if (data_source == 'gd'){
    dir_gd$parent = googledrive::drive_get('cruise-maps-live/')
  } else if (data_source == 'test_gd'){
    dir_gd$parent = googledrive::drive_get('cruise-maps-live/testing/')
  }
  
  # these folders are the same regardless of cruise number/ship
  dir_gd$raw_pam = googledrive::drive_get(
    paste0(dir_gd$parent$path, 'raw_acoustics_files/'))
  dir_gd$proc = googledrive::drive_get(
    paste0(dir_gd$parent$path,'processed_data_files/'))
  dir_gd$gpx = googledrive::drive_get(paste0(dir_gd$parent$path, 'gpx_files/'))
  
  # these ship-specific folders could be called directly within processing but it 
  # can be slow so better to define these directly
  # alternatively can be set manually using ID copied from URL 
  # e.g., dir = googledrive::drive_get(id = '1hevcdNvX_EpdYGXmWHQU5W-a04EL4FVX')
  dir_gd$raw_das = googledrive::drive_get(
    paste0(dir_gd$parent$path, 'raw_das_files/', projID, '/'))
  dir_gd$proc_shp = googledrive::drive_get(
    paste0(dir_gd$proc$path, projID, '/'))
  dir_gd$snaps = googledrive::drive_get(
    paste0(dir_gd$proc$path, projID, '/snapshots/'))
  dir_gd$gpx_shp = googledrive::drive_get(paste0(dir_gd$gpx$path, projID, '/')) 
  
  return(dir_gd)
  
}