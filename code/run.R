#' ---------------------------
#' title: Daily Survey Effort and Sightings Map
#' authors: Selene Fregosi, Janelle Badger, Yvonne Barkley, Kym Yano
#' inspired by: Emily Markowitz et al at NWFSC
#' purpose: pull in raw survey data, parse out relevant bits, and create a 
#' map with the most recent survey effort and sightings
#' ---------------------------


# ------ Libraries --------------------------------------------------------

library(googledrive)
library(here)
library(swfscDAS) #https://github.com/smwoodman/swfscDAS

# ------ Download latest survey data from Google Drive --------------------
load(here('outputs', 'dasList.Rda'))
dasListOld = dasList

dasList = googledrive::drive_ls(path = 'cruise-maps-live', pattern = '*.das')
save(dasList, file = here('outputs', 'dasList.Rda'))

# compare dasListOld vs dasList and find any new files
# TO DO
dasNew = dasList[1,] # for now just pull first one for testing

# download them
for (d in nrow(dasList)){
  googledrive::drive_download(file = googledrive::as_id(dasNew$id),  
                              overwrite = TRUE, path = here('inputs', dasNew$name))
}


# ------ Parse track data from das ----------------------------------------

# do some stuff here to parse track data from das
source(here('code', 'functions', 'parseTrack.R'))

# trk = parseTrack()


# ------ Extract visual sighting data -------------------------------------

# do some stuff here to extract visual sighting data for the day from das
source(here('code', 'functions', 'extractVisualSightings.R'))

# vs = extractVisualSightings()

# ------ Extract acoustic detections --------------------------------------

# FUTURE GOALS
# source(here('code', 'functions', 'extractAcousticDetections.R'))
# ad = extractAcousticDetections()


# ------ Plot map ---------------------------------------------------------
source(here('code', 'functions', 'plotMap.R'))
# plotMap()


# ------ Save stuff -------------------------------------------------------

# ------ PNG --------------------------------------------------------------
# save the latest
ggsave(filename = here('outputs', 'dailyMap.png'), 
       height = height, 
       width = width,
       plot = gg, 
       dpi = 320,
       bg = "white", 
       device = "png") 

# save a copy of today
dateName = paste0('daily_', Sys.Date(), '.png')
ggsave(filename = here('outputs', dateName), 
       height = height, 
       width = width,
       plot = gg, 
       dpi = 320,
       bg = "white", 
       device = "png") 


# ------ PDF --------------------------------------------------------------
# save the latest
ggsave(filename = here('outputs', 'dailyMap.pdf'), 
       height = height, 
       width = width,
       plot = gg, 
       dpi = 320,
       bg = "white", 
       device = "png") 

# save a copy of today
dateName = paste0('daily_', Sys.Date(), '.pdf')
ggsave(filename = here('outputs', dateName), 
       height = height, 
       width = width,
       plot = gg, 
       dpi = 320,
       bg = "white", 
       device = "png") 


# then save daily udpate plot as .png, .pdf, whatever else we want
# will all be generated on the posit connect 
