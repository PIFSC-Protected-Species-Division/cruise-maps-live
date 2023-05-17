#' ---------------------------
#' title: Daily Survey Effort and Sightings Map
#' authors: Selene Fregosi, Janelle Badger, Yvonne Barkley, Kym Yano
#' inspired by: Emily Markowitz et al at NWFSC
#' purpose: pull in raw survey data, parse out relevant bits, and create a 
#' map with the most recent survey effort and sightings
#' ---------------------------


# ------ Libraries --------------------------------------------------------

library(googledrive)
library(swfscDAS) #https://github.com/smwoodman/swfscDAS
library(flextable)


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
  dir_gd_raw <- 'https://drive.google.com/drive/u/0/folders/1x4GzvtLQDGT1nA7nuAPHs5CPXxsX6Umt'
} else if (yr == 2023){
  dir_gd_raw <- 'https://drive.google.com/drive/u/0/folders/1a0GjIQs9RUY-eVoe45K7Q4zcgwHh9J2O'
}

locations <- c(
  'C:/users/selene.fregosi/documents/github/cruise-maps-live/'
  # '//picqueenfish/psd/crp/' # want to set up a server location? for virtual machines?
) # others add path on their local machine

for (i in 1:length(locations)){
  if (file.exists(locations[i])) {
    dir_wd  <- locations[i]
    # dir_wd = 'C:/users/selene.fregosi/documents/github/cruise-maps-live/'
  }
}

# as of now, all functions sourced individually, but could source all together
# functionNames <- list.files(pattern = '[.]R$', path = paste0(dir_wd, 'code',
#                                                              functions),
#                             full.names = TRUE);
# invisible(sapply(functionNames, FUN = source))
#

# ------ Make a log file --------------------------------------------------

# for messages
# logFile = file(paste0(dir_wd, 'outputs/run_', Sys.Date(), '.log'), 'at')
# sink(logFile, append = TRUE, type = 'output')
# cat('\nrun started', format(Sys.time(), '%Y-%m-%d %H:%M:%S %Z'), '...\n')
# sink(logFile, append = TRUE, type = 'message')

# simple
sink(paste0(dir_wd, 'outputs/run_', Sys.Date(), '.log'), append = TRUE)
cat('\n...\nrun started', format(Sys.time(), '%Y-%m-%d %H:%M:%S %Z'), '...\n')

# ------ Sign in to google drive ------------------------------------------

googledrive_dl <- TRUE
googledrive::drive_deauth()
googledrive::drive_auth()
1 # push through autorization approval

# sink(logFile, append = TRUE) # go back to printing console outputs

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
d = dasList[i,]
# ###################

# download new das and save to git repo
googledrive::drive_download(file = googledrive::as_id(d$id),
                            overwrite = TRUE,
                            path = paste0(dir_wd, 'inputs/', yr, '/', d$name))


# ------ Read and process new das -----------------------------------------

### for testing ###
dasFile = paste0(dir_wd, 'inputs/', yr, '/', d$name)
# head(readLines(dasFile, warn = FALSE))
###################

# basic data checks
df_check = das_check(dasFile, skip = 0, print.cruise.nums = TRUE)
# read and process data
df_read = das_read(dasFile, skip = 0)
df_proc = das_process(dasFile)
# View(df_proc)

# ------ Parse track data from das ----------------------------------------

# parse on-effort segments as straight lines from Begin/Resume to End 
source(paste0(dir_wd, 'code/functions/', 'parseTrack.R'))
etNew = parseTrack(df_proc)

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
cat('saved', outStr, '\n')

# ------ Parse track data as points ---------------------------------------
# alternatively, can parse individual lines to get the segments out as points

source(paste0(dir_wd, 'code/functions/', 'parseTrack_asPoints.R'))
epNew = parseTrack_asPoints(df_proc)

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
cat('saved', outStr, '\n')

# ------ Extract visual sighting data -------------------------------------

# do some stuff here to extract visual sighting data for the day from das
source(paste0(dir_wd, 'code/functions/', 'extractVisualSightings.R'))
vsNew = extractVisualSightings(df_proc)

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
cat('saved', outStr, '\n')




# ------ Run simple test----------------------------------------

# dir_wd = 'C:/users/selene.fregosi/documents/github/cruise-maps-live/'
s = data.frame(col1 = seq(1,5,1), col2 = seq(101, 105, 1))

write.csv(s, file = paste0(dir_wd, 'outputs/taskTest1_',
                           format(Sys.time(), '%Y-%m-%dT%H%M%S'), '.csv'))


# # ------ Save plot --------------------------------------------------------
# 
# 
# # # save the latest
# # outStr = paste0('outputs/dailyMap_', yr, '_leg', leg, '_', ship)
# # ggsave(filename = paste0(dir_wd, outStr, '.png'), 
# #        height = height, 
# #        width = width,
# #        plot = gg, 
# #        dpi = 320,
# #        bg = 'white', 
# #        device = 'png') 
# 

cat('run complete', format(Sys.time(), '%Y-%m-%d %H:%M:%S %Z'), '\n')
sink()
# 
# 
# 
