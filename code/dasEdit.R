#' ---------------------------
#' title: Daily Survey Effort and Sightings Map
#' authors: Selene Fregosi, Janelle Badger, Yvonne Barkley, Kym Yano
#' inspired by: Emily Markowitz et al at NWFSC
#' purpose: pull in raw survey data, parse out relevant bits, and create a 
#' map with the most recent survey effort and sightings
#' ---------------------------


# ------ MAKE MANUAL CHANGES ----------------------------------------------

# first tackle epNew
# load the file of interest
load("~/GitHub/cruise-maps-live/data/OES2303/snapshots/newEffortPoints_OES2303_leg2_DASALL.805_ran2023-08-06.Rda")
# create a backup variable
epNewOrig = epNew
# save a backup '_original'
save(epNew, file = "~/GitHub/cruise-maps-live/data/OES2303/snapshots/newEffortPoints_OES2303_leg2_DASALL.805_ran2023-08-06_original.Rda")

# edit out the bad row
epNew = epNew[-which(epNew$line_num == 297 & epNew$leg == 2 & 
                       format(epNew$DateTime, format = "%d") == '05'),]

# save corrected file
save(epNew, file = "~/GitHub/cruise-maps-live/data/OES2303/snapshots/newEffortPoints_OES2303_leg2_DASALL.805_ran2023-08-06.Rda")


# then tackle ep
load("~/GitHub/cruise-maps-live/data/OES2303/compiledEffortPoints_OES2303.Rda")
# create a backup variable
epOrig = ep
# edit out the bad row
ep = ep[-which(ep$line_num == 297 & ep$leg == 2 & 
                       format(ep$DateTime, format = "%d") == '05'),]
# save corrected file
save(ep, file = "~/GitHub/cruise-maps-live/data/OES2303/compiledEffortPoints_OES2303.Rda")



# ------ CREATE NEW MAPS AND TABLES ---------------------------------------

# run a shortened version of 'run.R' to remake map and table. 

# ------ USER SPECIFIED INPUTS --------------------------------------------

crNum = 2303
# ship = 'OES' # 'LSK'
leg = '2'

# specify ship info and google drive paths for each cruise num/ship
if (crNum == 2303){
  shipCode = 'OES'
  shipName = 'Sette'
  projID = 'OES2303'
  
  dir_gd_raw_das <- googledrive::as_id('1a0GjIQs9RUY-eVoe45K7Q4zcgwHh9J2O')
  dir_gd_proc <- googledrive::as_id('1URoovHoWbYxO7-QOsnQ6uE9CUvub2hOo')
  dir_gd_snaps <- googledrive::as_id('1hl4isf9jn8vwNrXZ-EGwyY0qPjSJqPWd')
  dir_gd_gpx <- googledrive::as_id('1yscmHW2cZ_uP5V79MlpWnP2-1ziLWusp')
  
} else if (crNum == 2401){
  shipCode = 'LSK'
  shipName = 'Lasker'
  projID = 'LSK2401'
  
  dir_gd_raw_das <- googledrive::as_id('1D6vZ9S_tmu_Wn4_NhSBD-y4KxEjCJCYN')
  dir_gd_proc <- googledrive::as_id('13r2m9vGpf9CqDeCEvA2WHnxi1vvoLd89')
  dir_gd_snaps <- googledrive::as_id('1NtgC_A42XjzNXKNnQGZqwa-7x5P6E6Ca')
  dir_gd_gpx <- googledrive::as_id('1hGLdiVwGjAVw34rScjLPyLxwvj8uKftP')
}

# all pam data is in a single folder
dir_gd_raw_pam <- googledrive::as_id('1hevcdNvX_EpdYGXmWHQU5W-a04EL4FVX')

# set working directory
# will search through list of possible and select first one
# add initials and path to run on your local machine
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
    break # take first available valid location
  }
}

# build string with leg num used throughout for filename generation
legID = paste0(projID, '_leg', leg)

# ------ Set up folder structure ------------------------------------------
# define the local output paths (so don't have to be changed below)
# these are projID and legID specific! 
dir_data = file.path(dir_wd, 'data', projID)                      # outer 'data' folder
dir_gd_dwnl = file.path(dir_wd, 'data', projID, 'gd_downloads')   # gd downloads
dir_snaps = file.path(dir_wd, 'data', projID, 'snapshots')        # data snapshots
dir_gpx = file.path(dir_wd, 'data', projID, 'gpx')                # gpx files
dir_tsnaps = file.path(dir_wd, 'outputs', 'table_archive', legID) # table snapshots - saved by leg
dir_msnaps = file.path(dir_wd, 'outputs', 'map_archive', legID)   # map snapshots - saved by leg


# ------ sign in to google drive ------------------------------------------
# sign in to google drive
googledrive::drive_deauth()
googledrive::drive_auth()
# push through authorization approval
2 # this may need to change??

# ------ Libraries --------------------------------------------------------

# most functions are called with :: so don't have to load all libraries, but do 
# have to load a few for using %>% pipeline
library(raster)
library(tidyverse)

# ------ Load files needed for mapping and table --------------------------

# visual sightings
load("~/GitHub/cruise-maps-live/data/OES2303/compiledSightings_OES2303.Rda")
# acoustic detections
load("~/GitHub/cruise-maps-live/data/OES2303/compiledDetections_OES2303.Rda")

 # load newly replaced effort points
load("~/GitHub/cruise-maps-live/data/OES2303/compiledEffortPoints_OES2303.Rda")
load("~/GitHub/cruise-maps-live/data/OES2303/snapshots/newEffortPoints_OES2303_leg2_DASALL.805_ran2023-08-06.Rda")
  
  # ------ Make summary table -----------------------------------------------
  
  # load previously created summary table if it exists
  stName = paste0('summaryTable.Rda')
  if (file.exists(file.path(dir_wd, 'outputs', stName))){
    load(file.path(dir_wd, 'outputs', stName))
  } else {
    st = data.frame()
  }
  
  source(file.path(dir_wd, 'code', 'functions', 'makeSummaryTable.R'))
  lt = makeSummaryTable(st, et, vs, ad, shipCode, leg, blank_table = FALSE)
  # break out pieces of returned list
  st = lt$st
  ft = lt$ft
  
  # save st .rda as combined for the whole year (bc loaded on later legs)
  save(st, file = file.path(dir_wd, 'outputs', stName))
  # save ft (formatted flexttable) as image
  outName = paste0('summaryTable.png')
  flextable::save_as_image(ft, path = file.path(dir_wd, 'outputs', outName), 
                           res = 300)
  outName = paste0('summaryTable_', legID, '_ran', Sys.Date(), '.png')
  flextable::save_as_image(ft, path = file.path(dir_tsnaps, outName), res = 300)
  
  # ------ Plot visual sightings map --------------------------------------
  source(file.path(dir_wd, 'code', 'functions', 'plotMap.R'))
  
  mapOutV = plotMap(dir_wd, ep, epNew, vs, shipCode, leg, test_code = FALSE)
  base_map_V = mapOutV$base_map
  vsMap = mapOutV$ceMap
  
  # ------ Save visuals map figures ---------------------------------------
  # then save daily update plot as .png and .pdf
  height = 5
  width = 10
  res = 400
  
  # save the latest - as .png and .pdf
  outStr = paste0('dailyMap_visuals')
  ggsave(filename = file.path(dir_wd, 'outputs', paste0(outStr, '.png')),
         height = height,
         width = width,
         units = 'in', 
         plot = base_map_V,
         dpi = res,
         bg = 'white',
         device = 'png')
  
  ggsave(filename = file.path(dir_wd, 'outputs', paste0(outStr, '.pdf')),
         height = height,
         width = width,
         plot = base_map_V,
         dpi = res,
         bg = 'white',
         device = 'pdf')
  
  # save a copy of today's run - as .png and .pdf
  outStr = paste0('dailyMap_visuals_', legID, '_ran', Sys.Date())
  ggsave(filename = file.path(dir_msnaps, paste0(outStr, '.png')),
         height = height,
         width = width,
         plot = base_map_V,
         dpi = res,
         bg = 'white',
         device = 'png')
  
  ggsave(filename = file.path(dir_msnaps, paste0(outStr, '.pdf')),
         height = height,
         width = width,
         plot = base_map_V,
         dpi = res,
         bg = 'white',
         device = 'pdf')
  
  # save a large copy for CLs as PDF
  outStr = paste0('dailyMap_visuals_CL')
  ggsave(filename = file.path(dir_wd, 'outputs', paste0(outStr, '.pdf')),
         height = 10,
         width = 20,
         plot = base_map_V,
         # dpi = 1200,
         bg = 'white',
         device = 'pdf')
  googledrive::drive_put(file.path(dir_wd, 'outputs', paste0(outStr, '.pdf')),
                         path = dir_gd_proc)
  googledrive::drive_put(file.path(dir_wd, 'outputs', paste0(outStr, '.pdf')),
                         path = dir_gd_gpx)
  
  # ------ Plot acoustic detections map -----------------------------------
  # add correctly formated SpCode col
  ad$SpCode = as.integer(ad$sp_map)
  
  mapOutA = plotMap(dir_wd, ep, epNew, ad, shipCode, leg, test_code = FALSE)
  base_map_A = mapOutA$base_map
  adMap = mapOutA$ceMap
  
  # ------ Save acoustics map figures -------------------------------------
  # then save daily update plot as .png and .pdf
  height = 5
  width = 10
  res = 400
  
  # save the latest - as .png and .pdf
  outStr = paste0('dailyMap_acoustics')
  ggsave(filename = file.path(dir_wd, 'outputs', paste0(outStr, '.png')),
         height = height,
         width = width,
         units = 'in', 
         plot = base_map_A,
         dpi = res,
         bg = 'white',
         device = 'png')
  
  ggsave(filename = file.path(dir_wd, 'outputs', paste0(outStr, '.pdf')),
         height = height,
         width = width,
         plot = base_map_A,
         dpi = res,
         bg = 'white',
         device = 'pdf')
  
  # save a copy of today's run - as .png and .pdf
  outStr = paste0('dailyMap_acoustics_', legID, '_ran', Sys.Date())
  ggsave(filename = file.path(dir_msnaps, paste0(outStr, '.png')),
         height = height,
         width = width,
         plot = base_map_A,
         dpi = res,
         bg = 'white',
         device = 'png')
  
  ggsave(filename = file.path(dir_msnaps, paste0(outStr, '.pdf')),
         height = height,
         width = width,
         plot = base_map_A,
         dpi = res,
         bg = 'white',
         device = 'pdf')
  
