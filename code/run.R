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

# open up list of previously checked das files
load(here('outputs', 'dasList.Rda'))
dasNames_old = dasList$name

# look for current list of .das files on Google Drive
dasList = googledrive::drive_ls(path = 'cruise-maps-live', pattern = '*.das$')
# this prompts me to 'select a pre-authorised token' every time - is there a way around that?
dasNames_new = dasList$name
# save(dasList, file = here('outputs', 'dasList.Rda'))

# identify which files are new/need to be processed
idxNew = !(dasNames_new %in% dasNames_old)
d = dasList[2,] # for now just pull the example daily one from HICEAS 2017

# eventually loop through all idxNew
# for (i in 1:length(idxNew)){
#     d = dasList[idxNew(i),]

  # download new das and save to git repo
    googledrive::drive_download(file = googledrive::as_id(d$id),  
                                overwrite = TRUE, path = here('inputs', d$name))
  
  



# ------ Parse track data from das ----------------------------------------

# do some stuff here to parse track data from das
source(here('code', 'functions', 'parseTrack.R'))

# et = parseTrack(here('inputs', d$name))


# ------ Extract visual sighting data -------------------------------------

# do some stuff here to extract visual sighting data for the day from das
source(here('code', 'functions', 'extractVisualSightings.R'))
vsNew = extractVisualSightings(here('inputs', d$name))


# combine the old vs dataframe with the new one
load(here('outputs', 'compiledVisualSightings.Rda'))
vs = rbind(vs, vsNew)
save(vs, file = here('outputs', 'compiledVisualSightings.Rda'))

# ------ Extract acoustic detections --------------------------------------

# FUTURE GOALS
# source(here('code', 'functions', 'extractAcousticDetections.R'))
# ad = extractAcousticDetections()

# } # for looping through all idxNew

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
