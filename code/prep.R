#' ---------------------------
#' title: Prep for Daily Survey Effort and Sightings Map
#' authors: Selene Fregosi, Janelle Badger, Yvonne Barkley, Kym Yano
#' purpose: set up a computer to automatically create the daily maps with run.R. 
#' This script will check for and and install any needed packages
#' Only needs to be run once on any new computer being set up with task scheduler
#' to run map generation
#' ---------------------------

# ------ SET UP WORKING DIRECTORY -----------------------------------------
# cannot use the here package for this because it doesn't work with task scheduler
# instead, define a few options, try them, and use the first valid one

# add initials and path to this repo on your local machine
locationCodes <- c('sf', 'yb', 'vm')
locations <- c(
  'C:/users/selene.fregosi/documents/github/cruise-maps-live/',
  'C:/users/yvonne.barkley/github/cruise-maps-live/',
  '//piccrpnas/crp4/HICEAS_2023/cruise-maps-live/' # server for vms?
) 

for (i in 1:length(locations)){
  if (dir.exists(locations[i])) {
    dir_wd  <- locations[i]
    locCode <- locationCodes[i]
    break # take first available valid location
  }
}


# ------ CREATE GD_DOWNLOADS FOLDER IF NEEDED -----------------------------

# this stores data files downloaded from google drive
# it is ignored in .gitignore because we don't want the files publically shared 
# and because the acoustics file is too big to host on GitHub
if (!dir.exists(file.path(dir_wd, 'gd_downloads'))){
  dir.create(file.path(dir_wd, 'gd_downloads'))
}


# ------ SEARCH/INSTALL/LOAD NEEDED PACKAGES ------------------------------

source(paste0(dir_wd, 'code/functions/', 'using.R'))

using("googledrive",
      "swfscDAS", #https://github.com/smwoodman/swfscDAS
      "tidyverse",
      "flextable",
      "ggspatial",
      "ggsn",
      "ggnewscale",
      "terra",
      "raster",
      "sf",
      "sp",
      "RColorBrewer"
      # "cowplot", # not actually used? 
      # "rgdal", # being retired so removed
      # "rgeos",  # being retired so removed
      # "viridis", # not actually used? 
      #"ggrepel", # not actually used? 
      # "plotKML", # not actually used?
       )
# if it seems frozen...look for a pop up!
