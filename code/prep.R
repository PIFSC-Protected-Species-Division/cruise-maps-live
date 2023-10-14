#' ---------------------------
#' title: Prep for Daily Survey Effort and Sightings Map
#' authors: Selene Fregosi, Janelle Badger, Yvonne Barkley, Kym Yano
#' purpose: set up a computer to automatically create the daily maps with run.R. 
#' This script will check for and and install any needed packages, create the 
#' necessary output folder structure, and map the Google Drive input/output 
#' folder structure and save it locally (slow step to do each time)
#' Only needs to be run once on any new computer being set up with task scheduler
#' to run map generation
#' ---------------------------

# ------ SET UP WORKING DIRECTORY -----------------------------------------
# cannot use the here package for this effort because it doesn't work with task
# scheduler instead, define a few options, try them, and use the first valid one

# add initials and path to this repo on your local machine
locationCodes <- c('sf', 'yb', 'vm')
locations <- c(
  'C:/users/selene.fregosi/documents/github/cruise-maps-live',
  'C:/users/yvonne.barkley/Github/cruise-maps-live',
  '//piccrpnas/crp4/HICEAS_2023/cruise-maps-live' # server for vms?
) 
for (i in 1:length(locations)){
  if (dir.exists(locations[i])) {
    dir_wd  <- locations[i]
    locCode <- locationCodes[i]
    dir_code = file.path(dir_wd, 'code')
    break # take first available valid location
  }
}


# ------ CREATE LOCAL FOLDERS IF NEEDED -----------------------------

# data - stores raw and processed data files to keep private
if (!dir.exists(file.path(dir_wd, 'data'))){
  dir.create(file.path(dir_wd, 'data'))
}

# outputs
if (!dir.exists(file.path(dir_wd, 'outputs'))){
  dir.create(file.path(dir_wd, 'outputs'))
}
# subfolders within outputs
if (!dir.exists(file.path(dir_wd, 'outputs', 'map_archive'))){
  dir.create(file.path(dir_wd, 'outputs', 'map_archive'))
}
if (!dir.exists(file.path(dir_wd, 'outputs', 'table_archive'))){
  dir.create(file.path(dir_wd, 'outputs', 'table_archive'))
}
if (!dir.exists(file.path(dir_wd, 'outputs', 'run_logs'))){
  dir.create(file.path(dir_wd, 'outputs', 'run_logs'))
}



# ------ SEARCH/INSTALL/LOAD NEEDED PACKAGES ------------------------------

source(file.path(dir_wd, 'code', 'functions', 'using.R'))

using("googledrive",
      "swfscDAS", #https://github.com/smwoodman/swfscDAS
      "tidyverse",
      "flextable",
      "ggspatial",
      "ggsn",
      "ggnewscale",
      "terra",
      "sf",
       "sp",
      "RColorBrewer",
      "DBI"
      # "raster", # retired
      # "cowplot", # not actually used? 
      # "rgdal", # being retired so removed
      # "rgeos",  # being retired so removed
      # "viridis", # not actually used? 
      #"ggrepel", # not actually used? 
      # "plotKML", # not actually used?
       )
# if it seems frozen...look for a pop up!


# ------ MAP GOOGLE DRIVE FOLDERS AND SAVE --------------------------------

# this can be slow, so beneficial to save a dribble (drive tibble) locally and 
# load that each time rather than search the full GD paths 
# they need to be separate for each ship

data_source = 'test_gd'
# data_source = 'gd'

# projID = 'OES2303'
projID = 'LSK2401'

source(file.path(dir_code, 'functions', 'mapGDDirs.R'))
dir_gd = mapGDDirs(data_source, projID)


save(dir_gd, file = file.path(dir_wd, 'inputs', 
                              paste0('dir_gd_', projID, '.rda')))


# --- Google Drive IDs to save --------------------------------------------
# hard-coded IDs to certain Google Drive folders 
# faster to load them this way, but more lines of code...

# OES2303
# if (data_source == 'gd'){
#   dir_gd_raw_das =    googledrive::as_id('1a0GjIQs9RUY-eVoe45K7Q4zcgwHh9J2O')
#   dir_gd_proc_shp =   googledrive::as_id('1URoovHoWbYxO7-QOsnQ6uE9CUvub2hOo')
#   dir_gd_snaps =  googledrive::as_id('1hl4isf9jn8vwNrXZ-EGwyY0qPjSJqPWd')
#   dir_gd_gpx_shp =    googledrive::as_id('1yscmHW2cZ_uP5V79MlpWnP2-1ziLWusp')
# } else if (data_source == 'test'){
#   dir_gd_raw_das =    googledrive::as_id('1ivy3JzfYV7B5tQaGllhomqcyZh0c18U4')
#   dir_gd_proc_shp =   googledrive::as_id('12P03T2frWuCBsDZcN2ZSYzAr9lxRZ0Iq')
#   dir_gd_snaps =  googledrive::as_id('1ubIn5fO3xH5hfwk256fDbh0dQ0n8FmVz')
#   dir_gd_gpx_shp =    googledrive::as_id('1vU_LsU5zSOdgDA8hh2aVWYBIUO12rdSa')
# }

# LSK2401
# if (data_source == 'gd'){
#   dir_gd_raw_das = googledrive::as_id('1D6vZ9S_tmu_Wn4_NhSBD-y4KxEjCJCYN')
#   dir_gd_proc_shp =   googledrive::as_id('13r2m9vGpf9CqDeCEvA2WHnxi1vvoLd89')
#   dir_gd_snaps =  googledrive::as_id('1NtgC_A42XjzNXKNnQGZqwa-7x5P6E6Ca')
#   dir_gd_gpx_shp =    googledrive::as_id('1hGLdiVwGjAVw34rScjLPyLxwvj8uKftP')
# } else if (data_source == 'test'){
#   dir_gd_raw_das = googledrive::as_id('1AHhZ8vi0p5z3v-u1PBchJII7muB8jlUJ')
#   dir_gd_proc_shp =   googledrive::as_id('1w3rD9v3fRdm79rnPYVitHmqoD8gHxZW1')
#   dir_gd_snaps =  googledrive::as_id('1jeqYIqjWkcD6W9vWvZdbQIiIWnslMsyY')
#   dir_gd_gpx_shp =    googledrive::as_id('1WsmVdMMGFkKv-pfumFGRldSk5-xulNrQ')
# }