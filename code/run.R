#' ---------------------------
#' title: Daily Survey Effort and Sightings Map
#' authors: Selene Fregosi, Janelle Badger, Yvonne Barkley, Kym Yano
#' inspired by: Emily Markowitz et al at NWFSC
#' purpose: pull in raw survey data, parse out relevant bits, and create a 
#' map with the most recent survey effort and sightings
#' ---------------------------


# ------ USER SPECIFIED INPUTS --------------------------------------------

yr = 2017
data_source = 'gd' # google drive
dates0 = 'latest' # "all" # 'latest' #"2021-06-05",
# Sys.Date(), # as.character(seq(as.Date("2022-07-30"), as.Date("2022-08-14"), by="days"))
ship = 'OES' # 'LSK'
leg = '00'

# dir_gd_raw <- paste0('cruise-maps-live/raw_das_files/', yr)
# specifying path this way searches through all of google drive and is kind of slow
# alternative hard code to url.
if (yr == 2017){
  dir_gd_raw_das <- 'https://drive.google.com/drive/u/0/folders/1x4GzvtLQDGT1nA7nuAPHs5CPXxsX6Umt'
  dir_gd_raw_pam <- 'https://drive.google.com/drive/u/0/folders/1uONES1aEE9SGxAIgI7g1EY-qb1pkwH16'
} else if (yr == 2023){
  dir_gd_raw_das <- 'https://drive.google.com/drive/u/0/folders/1a0GjIQs9RUY-eVoe45K7Q4zcgwHh9J2O'
  dir_gd_raw_pam <- 'https://drive.google.com/drive/u/0/folders/1vpj86kkgbC4Y84u3EH4AFx0jmmWuwlRp'
}

locationCodes <- c('sf', 'yb', 'vm'
)
locations <- c(
  'C:/users/selene.fregosi/documents/github/cruise-maps-live/',
  'C:/users/yvonne.barkley/github/cruise-maps-live/',
  '//piccrpnas/crp4/HICEAS_2023/cruise-maps-live/' # want to set up a server location? for virtual machines?
) # others add path on their local machine

for (i in 1:length(locations)){
  if (dir.exists(locations[i])) {
    dir_wd  <- locations[i]
    locCode <- locationCodes[i]
    break # take first available valid location
  }
}


# or specify manually
# dir_wd <- "C:/Users/selene.fregosi/documents/github/cruise-maps-live/"

# as of now, all functions sourced individually, but could source all together
# functionNames <- list.files(pattern = '[.]R$', path = paste0(dir_wd, 'code',
#                                                              functions),
#                             full.names = TRUE);
# invisible(sapply(functionNames, FUN = source))
#

# ------ Make a log file --------------------------------------------------
# define directory to save log file
logDir = paste0(dir_wd, 'outputs/run_logs/', yr, '_leg', leg, '_', ship, '/')
# check that the directory exists
if (!dir.exists(logDir)) {
  dir.create(logDir)}
# define log file name
logFile = paste0(logDir, 'run_', Sys.Date(), '_', locCode, '.log')

sink(logFile, append = TRUE)

cat('\n...run started', format(Sys.time(), '%Y-%m-%d %H:%M:%S %Z'), '...\n')
cat(' dir_wd =', dir_wd, '\n')

# ------ Libraries --------------------------------------------------------

# search/install/load needed packages
source(paste0(dir_wd, 'code/functions/', 'using.R'))

using("googledrive",
      "swfscDAS", #https://github.com/smwoodman/swfscDAS
      # 'ggplot2', within tidyverse?
      "flextable",
      "raster",
      "viridis",
      "plotKML",
      "rgdal",
      "tidyverse",
      "sf",
      "sp",
      "rgeos",
      "ggsn",
      "ggrepel",
      "cowplot",
      "ggnewscale",
      "RColorBrewer",
      "ggspatial")
# if it seems frozen...look for a pop up!

# library(googledrive)
# library(swfscDAS) 
# library(ggplot2)
# library(flextable)

# ------ Sign in to google drive ------------------------------------------

googledrive_dl <- TRUE
googledrive::drive_deauth()
googledrive::drive_auth()
# push through authorization approval
2 # this may need to change??

# ------ Identify new das file --------------------------------------------

# open up list of previously checked das files
if (file.exists(paste0(dir_wd, 'outputs/dasList_', yr, '.Rda'))){
  load(paste0(dir_wd, 'outputs/dasList_', yr, '.Rda'))
  dasNames_old = dasList$name
} else {
  dasNames_old = character()
}

# look for current list of .das files on Google Drive
dasList = googledrive::drive_ls(path = dir_gd_raw_das, pattern = 'DAS')
dasNames_new = dasList$name
save(dasList, file = paste0(dir_wd, 'outputs/dasList_', yr, '.Rda'))

# identify which files are new/need to be processed
idxNew = which(!(dasNames_new %in% dasNames_old))
cat(' Processing', length(idxNew), 'new das files:\n')

### UNCOMMENT BELOW WHEN DONE TESTING ###
# eventually loop through all idxNew
# for (i in 1:length(idxNew)){
# d = dasList[idxNew[i],]

### for testing #########################
# COMMENT OUT WHEN DONE TESTING
i = 3
d = dasList[i,]
#########################################

# download new das and save to git repo
googledrive::drive_download(file = googledrive::as_id(d$id),
                            overwrite = TRUE,
                            path = paste0(dir_wd, 'gd_downloads/', yr, '/', d$name))

# ------ Read and process das file ----------------------------------------

dasFile = paste0(dir_wd, 'gd_downloads/', yr, '/', d$name)
cat(' ', d$name, '\n')

# basic data checks
df_check = das_check(dasFile, skip = 0, print.cruise.nums = FALSE)
# read and process
df_read = das_read(dasFile, skip = 0)
df_proc = das_process(dasFile)
# View(df_proc)

# ------ Parse track data from das ----------------------------------------

# parse on-effort segments as straight lines from Begin/Resume to End 
source(paste0(dir_wd, 'code/functions/', 'parseTrack.R'))
etNew = parseTrack(df_proc)

# save a 'snapshot' of the data for this run
outStr = paste0('outputs/data_snapshots/newEffortTracks_', yr, '_leg', leg, '_', 
                ship, '_', Sys.Date(), '.Rda')
save(etNew, file = paste0(dir_wd, outStr))
cat('   saved', outStr, '\n')

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
cat('   saved', outStr, 'as .Rda and .csv\n')

# ------ Parse track data as points ---------------------------------------
# alternatively, can parse individual lines to get the segments out as points

source(paste0(dir_wd, 'code/functions/', 'parseTrack_asPoints.R'))
epNew = parseTrack_asPoints(df_proc)

# save a 'snapshot' of the data for this run
outStr = paste0('outputs/data_snapshots/newEffortPoints_', yr, '_leg', leg, '_', ship, 
                '_', Sys.Date(), '.Rda')
save(epNew, file = paste0(dir_wd, outStr))
cat('   saved', outStr, '\n')

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
cat('   saved', outStr, 'as .Rda and .csv\n')

# ------ Extract visual sighting data -------------------------------------

# do some stuff here to extract visual sighting data for the day from das
source(paste0(dir_wd, 'code/functions/', 'extractVisualSightings.R'))
vsNew = extractVisualSightings(df_proc)

# confirm all species codes are numeric and delete rows that aren't
vsNew_clean <- vsNew[!is.na(as.numeric(vsNew$SpCode)), ] 
vsNew = vsNew_clean

# save a 'snapshot' of the data for this run
outStr = paste0('outputs/data_snapshots/newSightings_', yr, '_leg', leg, '_', ship, 
                '_', Sys.Date(), '.Rda')
save(vsNew, file = paste0(dir_wd, outStr))
cat('   saved', outStr, '\n')

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
cat('   saved', outStr, 'as .Rda and .csv\n')


#### UNCOMMENT THIS WHEN DONE TESTING ####
# } # for looping through all idxNew
##########################################

# ------ Extract acoustic detections --------------------------------------


# acoustics file will just be a single sql file that is updated/appended to each day
# it can be large so may be a bit slow to download
pamList = googledrive::drive_ls(path = dir_gd_raw_pam, pattern = 'PAM')
googledrive::drive_download(file = googledrive::as_id(pamList$id[1]),
                            overwrite = TRUE,
                            path = paste0(dir_wd, 'gd_downloads/', yr, '/', pamList$name[1]))


# FUTURE GOALS
# source(paste0(dir_wd, 'code/functions/', 'extractAcousticDetections.R')
# adNew = extractAcousticDetections()
adNew = data.frame()

# # save a 'snapshot' of the data for this run
# outStr = paste0('outputs/newDetections_', yr, '_leg', leg, '_', ship, 
#                 '_', Sys.Date(), '.Rda')
# save(adNew, file = paste0(dir_wd, outStr))
# cat('   saved', outStr, '\n')
# 
# # combine the old vs dataframe with the new one
# outStr = paste0('outputs/compiledDetections_', yr, '_leg', leg, '_', ship)
# if (file.exists(paste0(dir_wd, outStr, '.Rda'))){
#   # load old if it exists
#   load(paste0(dir_wd, outStr, '.Rda'))
#   # combine, remove dupes, sort by date
#   ad = rbind(ad, adNew)
#   ad = unique(ad)
#   ad = ad[order(ad$DateTime),]
# } else { # if no previous detections file exists
#   ad = adNew
# }
# 
# save(ad, file = paste0(dir_wd, outStr, '.Rda'))
# write.csv(ad, file = paste0(dir_wd, outStr, '.csv'))
# cat('   saved', outStr, 'as .Rda and .csv\n')

# ------ Make summary table -----------------------------------------------

# load previously created summary table if it exists
if (file.exists(paste0(dir_wd, 'outputs/summaryTable_', yr, '.Rda'))){
  load(paste0(dir_wd, 'outputs/summaryTable_', yr, '.Rda'))
  dasNames_old = dasList$name
} else {
  st = data.frame()
}

source(paste0(dir_wd, 'code/functions/', 'makeSummaryTable.R'))
lt = makeSummaryTable(st, et, vs, ad, leg, ship)

# breakup the list that is returned by the function and save
# summary table .rda
st = lt$st
# save .rda as combined for the whole year (bc loaded on later legs)
save(st, file = paste0(dir_wd, 'outputs/summaryTable_', yr, '.Rda'))
cat('   saved', paste0('outputs/summaryTable_', yr, '.Rda'), '\n')

# formatted flextable as image
ft = lt$ft
# save with leg/ship info and copy with run date
outStr = paste0('summaryTable_', yr, '_leg', leg, '_', ship)
save_as_image(ft, path = paste0(dir_wd, 'outputs/', outStr, '.png'), res = 300)
save_as_image(ft, paste0(dir_wd, 'outputs/table_archive/', outStr, 
                         '_', Sys.Date(), '.png'), res = 300)
cat('   saved', paste0('outputs/', outStr, '.png'), '\n')
cat('   saved', paste0('outputs/table_archive/', outStr, 
                       '_', Sys.Date(), '.png'), '\n')


# ------ Plot map ---------------------------------------------------------
source(paste0(dir_wd, 'code/functions/', 'plotMap.R'))

test_code = FALSE
mapOut = plotMap(dir_wd, ep, epNew, vs, leg, ship, test_code)
base_map = mapOut$base_map
vsMap = mapOut$vsMap

# ------ Save stuff -------------------------------------------------------
# then save daily update plot as .png and .pdf
# the latest will be in the 'outputs' folder and a snapshot of each day will
# saved in the 'map_archive' folder
height = 5
width = 10
res = 400

# ------ PNG --------------------------------------------------------------
# # save the latest
outStr = paste0('dailyMap_', yr, '_leg', leg, '_', ship)
ggsave(filename = paste0(dir_wd, 'outputs/', outStr, '.png'),
       height = height,
       width = width,
       units = 'in', 
       plot = base_map,
       dpi = res,
       bg = 'white',
       device = 'png')
cat('   saved', paste0('outputs/', outStr, '.png'), '\n')

# save a copy of today's run
dateName = paste0(outStr, '_', Sys.Date(), '.png')
ggsave(filename = paste0(dir_wd, 'outputs/map_archive/', dateName),
       height = height,
       width = width,
       plot = base_map,
       dpi = res,
       bg = 'white',
       device = 'png')
cat('   saved', paste0('outputs/map_archive/', dateName), '\n')

# ------ PDF --------------------------------------------------------------
# save the latest
ggsave(filename = paste0(dir_wd, 'outputs/', outStr, '.pdf'),
       height = height,
       width = width,
       plot = base_map,
       dpi = res,
       bg = 'white',
       device = 'pdf')
cat('   saved', paste0('outputs/', outStr, '.pdf'), '\n')

# save a copy of today
dateName = paste0(outStr, '_', Sys.Date(), '.pdf')
ggsave(filename = paste0(dir_wd, 'outputs/map_archive/', dateName),
       height = height,
       width = width,
       plot = base_map,
       dpi = res,
       bg = 'white',
       device = 'pdf')
cat('   saved', paste0('outputs/map_archive/', dateName), '\n')



# # ------ Simple test outputs ----------------------------------------------
# 
# # make a dummy csv and dummy plot just to confirm we can make it this far!
# s = data.frame(col1 = seq(1,5,1), col2 = seq(101, 105, 1))
# 
# gg = ggplot(data = s, aes(x = col1, y = col2)) + geom_line()
# # gg
# outStr = paste0('outputs/plot_', yr, '_leg', leg, '_', ship)
# ggsave(filename = paste0(dir_wd, outStr, '.png'),
#        height = 2,
#        width = 2,
#        plot = gg,
#        dpi = 120,
#        bg = 'white',
#        device = 'png')
# cat('   saved', outStr, '\n')

# ------ Close up log -----------------------------------------------------

cat('...run complete', format(Sys.time(), '%Y-%m-%d %H:%M:%S %Z'), '...\n')
sink()
