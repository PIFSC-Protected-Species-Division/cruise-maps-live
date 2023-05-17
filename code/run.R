#' ---------------------------
#' title: Daily Survey Effort and Sightings Map
#' authors: Selene Fregosi, Janelle Badger, Yvonne Barkley, Kym Yano
#' inspired by: Emily Markowitz et al at NWFSC
#' purpose: pull in raw survey data, parse out relevant bits, and create a 
#' map with the most recent survey effort and sightings
#' ---------------------------


# ------ Libraries --------------------------------------------------------

library(googledrive)
# library(here)
library(swfscDAS) #https://github.com/smwoodman/swfscDAS
library(flextable)


# ------ USER SPECIFIED INPUTS --------------------------------------------

yr <- 2017
data_source <- 'gd' # google drive
dates0 <- 'latest' # "all" # 'latest' #"2021-06-05",
# Sys.Date(), # as.character(seq(as.Date("2022-07-30"), as.Date("2022-08-14"), by="days"))
ship = 'OES' # 'LSK'
leg = '00'

# dir_gd_raw <- paste0('cruise-maps-live/raw_das_files/', yr)
# specifying path this way searches through all of google drive and is kind of slow
# alternative hard code to url. 
if (yr == 2017){
  dir_gd_raw <- 'https://drive.google.com/drive/u/0/folders/1x4GzvtLQDGT1nA7nuAPHs5CPXxsX6Umt'
} else if (yr == 2023){
  dir_gd_raw <- 'https://drive.google.com/drive/u/0/folders/1a0GjIQs9RUY-eVoe45K7Q4zcgwHh9J2O'
}


# May not be able to use here package??
# note from EM - it actually causes issues with 
## the tasks scheduler, which has no concept of a project root folder. 
locations <- c(
  'C:/users/selene.fregosi/documents/github/cruise-maps-live/'
  # '//picqueenfish/psd/crp/' # want to set up a server location? for virtual machines?
) # others add path on thier local machine

for (i in 1:length(locations)){
  if (file.exists(locations[i])) {
    dir_wd  <- locations[i]
  }
}
# dir_wd <- "C:/Users/liz.dawson/Work/R/GAPSurveyTemperatureMap/"

# as of now, all functions sourced individually, but could source all together
# functionNames <- list.files(pattern = '[.]R$', path = paste0(dir_wd, 'code', 
#                                                              functions), 
#                             full.names = TRUE);
# invisible(sapply(functionNames, FUN = source))
#

# ------ Make a log file --------------------------------------------------

# sink(file = paste0(dir_wd, "/outputs/", Sys.Date(), ".txt"), append=TRUE)

# ------ Sign in to google drive ------------------------------------------

googledrive_dl <- TRUE
googledrive::drive_deauth()
googledrive::drive_auth()
1 # push through autorization approval



# ------ Download latest survey data --------------------------------------

# open up list of previously checked das files
if (file.exists(paste0(dir_wd, 'outputs/dasList_', yr, '.Rda'))){
  load(paste0(dir_wd, 'outputs/dasList_', yr, '.Rda'))
  dasNames_old = dasList$name
} else {
  dasNames_old = character()
}

# look for current list of .das files on Google Drive
dasList = googledrive::drive_ls(path = dir_gd_raw, pattern = 'DAS')
dasNames_new = dasList$name
save(dasList, file = paste0(dir_wd, 'outputs/dasList_', yr, '.Rda'))

# identify which files are new/need to be processed
idxNew = which(!(dasNames_new %in% dasNames_old))
# eventually loop through all idxNew
# for (i in 1:length(idxNew)){
#     d = dasList[idxNew[i],]

# ### for testing ###
i = 3
d = dasList[idxNew[i],]
# ###################

# download new das and save to git repo
googledrive::drive_download(file = googledrive::as_id(d$id),  
                            overwrite = TRUE, 
                            path = paste0(dir_wd, 'inputs/', yr, '/', d$name))

# ------ Parse track data from das ----------------------------------------

# parse on-effort segments as straight lines from Begin/Resume to End 
source(paste0(dir_wd, 'code/functions/', 'parseTrack.R'))
etNew = parseTrack(paste0(dir_wd, 'inputs/', yr, '/', d$name))

# combine the old vs dataframe with the new one
outStr = paste0('outputs/compiledEffortTracks_', yr, '_leg', leg, '_', ship)
if (file.exists(paste0(dir_wd, outStr, '.Rda'))){
  # load old if it exists
  load(paste0(dir_wd, outStr, '.Rda'))
  # combine
  et = rbind(et, etNew)
  et = unique(et)                 # remove duplicates (in case ran already)
  et = et[order(et$DateTime1),]   # sort in case out of order
} else {
  et = etNew
}

save(et, file = paste0(dir_wd, outStr, '.Rda'))
write.csv(et, file = paste0(dir_wd, outStr, '.csv'))


# ------ Parse track data as points ---------------------------------------
# alternatively, can parse individual lines to get the segments out as points

source(paste0(dir_wd, 'code/functions/', 'parseTrack_asPoints.R'))
epNew = parseTrack_asPoints(paste0(dir_wd, 'inputs/', yr, '/', d$name))

# combine the old vs dataframe with the new one
outStr = paste0('outputs/compiledEffortPoints_', yr, '_leg', leg, '_', ship)
if (file.exists(paste0(dir_wd, outStr, '.Rda'))){
  # load old if it exists
  load(paste0(dir_wd, outStr, '.Rda'))
  # combine, remove dupes, sort by date
  ep = rbind(ep, epNew)
  ep = unique(ep) 
  ep = ep[order(ep$DateTime),] 
} else {
  ep = epNew
}

save(ep, file = paste0(dir_wd, outStr, '.Rda'))
write.csv(ep, file = paste0(dir_wd, outStr, '.csv'))

# ------ Extract visual sighting data -------------------------------------

# do some stuff here to extract visual sighting data for the day from das
source(paste0(dir_wd, 'code/functions/', 'extractVisualSightings.R'))
vsNew = extractVisualSightings(paste0(dir_wd, 'inputs/', yr, '/', d$name))


# combine the old vs dataframe with the new one
outStr = paste0('outputs/compiledSightings_', yr, '_leg', leg, '_', ship)
if (file.exists(paste0(dir_wd, outStr, '.Rda'))){
  # load old if it exists
  load(paste0(dir_wd, outStr, '.Rda'))
  # combine, remove dupes, sort by date
  vs = rbind(vs, vsNew)
  vs = unique(vs)
  vs = vs[order(vs$DateTime),] 
} else { # if no previous sightings file exists
  vs = vsNew
}

save(vs, file = paste0(dir_wd, outStr, '.Rda'))
write.csv(vs, file = paste0(dir_wd, outStr, '.csv'))

# ------ Extract acoustic detections --------------------------------------

# FUTURE GOALS
# source(here('code', 'functions', 'extractAcousticDetections.R'))
# ad = extractAcousticDetections()

# } # for looping through all idxNew

# ------ Plot map ---------------------------------------------------------
source(paste0(dir_wd, 'code/functions/', 'plotMap.R'))
# plotMap()



# ------ Make summary stats table -----------------------------------------

# flextable::save_as_image

# ------ Save stuff -------------------------------------------------------

# ------ PNG --------------------------------------------------------------
# save the latest
ggsave(filename = paste0(dir_wd, 'outputs/', 'dailyMap_', yr, '.png'), 
       height = height, 
       width = width,
       plot = gg, 
       dpi = 320,
       bg = "white", 
       device = "png") 

# save a copy of today's run
dateName = paste0(dir_wd, 'outputs/daily_', yr, '_', Sys.Date(), '.png')
ggsave(filename = here('outputs', dateName), 
       height = height, 
       width = width,
       plot = gg, 
       dpi = 320,
       bg = "white", 
       device = "png") 


# ------ PDF --------------------------------------------------------------
# save the latest
ggsave(filename = paste0(dir_wd, 'outputs/', 'dailyMap_', yr, '.pdf'), 
       height = height, 
       width = width,
       plot = gg, 
       dpi = 320,
       bg = "white", 
       device = "png") 

# save a copy of today
dateName = paste0(dir_wd, 'outputs/daily_', yr, '_', Sys.Date(), '.pdf')
ggsave(filename = paste0('outputs', dateName), 
       height = height, 
       width = width,
       plot = gg, 
       dpi = 320,
       bg = "white", 
       device = "png") 


# then save daily udpate plot as .png, .pdf, whatever else we want
# will all be generated on the posit connect 

# sink()
