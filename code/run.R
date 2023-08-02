#' ---------------------------
#' title: Daily Survey Effort and Sightings Map
#' authors: Selene Fregosi, Janelle Badger, Yvonne Barkley, Kym Yano
#' inspired by: Emily Markowitz et al at NWFSC
#' purpose: pull in raw survey data, parse out relevant bits, and create a 
#' map with the most recent survey effort and sightings
#' ---------------------------


# ------ USER SPECIFIED INPUTS --------------------------------------------

data_source = 'gd' # google drive
# data_source = 'blank' # for making blank table and map

# yr = 2023
crNum = 2303
# ship = 'OES' # 'LSK'
leg = '1'

if (length(crNum) >1){
  stop("We're not ready for two boats yet!! Bug Janelle and Selene.")
}
# I envision a for loop here looping through both cruise numbers??!

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
dir_gd_raw_pam <- googledrive::as_id('1vpj86kkgbC4Y84u3EH4AFx0jmmWuwlRp')

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

# create nested subfolders for this projID or logID if needed
makeDirs = TRUE # change to FALSE to turn off folder creation
if (makeDirs){ 
  if (!dir.exists(dir_data)){dir.create(dir_data)}
  if (!dir.exists(dir_gd_dwnl)){dir.create(dir_gd_dwnl)}
  if (!dir.exists(dir_snaps)){dir.create(dir_snaps)}
  if (!dir.exists(dir_gpx)){dir.create(dir_gpx)}
  if (!dir.exists(dir_msnaps)){dir.create(dir_msnaps)}
  if (!dir.exists(dir_tsnaps)){dir.create(dir_tsnaps)}
}

# ------ Make a log file --------------------------------------------------
# define directory to save log file and create if doesn't exist
dir_log = file.path(dir_wd, 'outputs', 'run_logs', legID)
if (!dir.exists(dir_log)) {
  dir.create(dir_log)}

# start log
logFile = file.path(dir_log, paste0('run_', Sys.Date(), '_', locCode, '.log'))
sink(logFile, append = TRUE)

# first entries
cat('\n...run started', format(Sys.time(), '%Y-%m-%d %H:%M:%S %Z'), '...\n')
cat(' dir_wd =', dir_wd, '\n')

# ------ Libraries --------------------------------------------------------

# most functions are called with :: so don't have to load all libraries, but do 
# have to load a few for using %>% pipeline
library(raster)
library(tidyverse)

# ------ Sign in to google drive ------------------------------------------

# if just creating a blank map, don't sign in
if (data_source == 'blank'){
  # to make blank table and map - these were made by hand
  load(file.path(dir_data, 'blankEffortPoints.Rda'))
  load(file.path(dir_data, 'blankEffortTracks.Rda'))
  load(file.path(dir_data, 'blankSightings.Rda'))
  epNew = ep
  
  # map testing options
  test_code = FALSE
  # blank_map = TRUE
  blank_table = TRUE
  idxNew = integer(0)
  
} else if (data_source == 'gd'){
  googledrive::drive_deauth()
  googledrive::drive_auth()
  # push through authorization approval
  2 # this may need to change??
  
  # turn off test/blank checks
  blank_table = FALSE
  test_code = FALSE
  
  # ------ Identify new das file --------------------------------------------
  
  # open up list of previously checked das files
  # to re-run all, delete dasList_yr.Rda file from your local outputs folder
  if (file.exists(file.path(dir_wd, 'outputs', paste0('dasList_', projID, '.Rda')))){
    load(file.path(dir_wd, 'outputs', paste0('dasList_', projID, '.Rda')))
    dasNames_old = dasList$name
  } else {
    dasNames_old = character()
  }
  
  # look for current list of .das files on Google Drive
  dasList = googledrive::drive_ls(path = dir_gd_raw_das, pattern = 'DAS')
  # sort by day 
  dasList = dasList[order(dasList$name),]
  dasNames_new = dasList$name
  
  # identify which files are new/need to be processed
  idxNew = which(!(dasNames_new %in% dasNames_old))
  cat(' Processing', length(idxNew), 'new das files:\n')
  
  ### FOR TESTING ###
  # test reading in new das
  if (leg == '0'){
    # idxNew = 3
    idxNew = c(1,2)
  }
  ### ### ### ### ###  
  
}

# ------ Download, read and process das file ------------------------------

# if there are new das to process
if (length(idxNew) != 0){
  # loop through all idxNew
  for (i in 1:length(idxNew)){
    # i = 1 # for testing
    d = dasList[idxNew[i],]
    
    dasFile = file.path(dir_gd_dwnl, d$name)
    cat(' ', d$name, '\n')
    
    # download and save locally
    googledrive::drive_download(file = googledrive::as_id(d$id), overwrite = TRUE, 
                                path = dasFile)
    
    # basic data checks
    df_check = swfscDAS::das_check(dasFile, skip = 0, print.cruise.nums = FALSE)
    # read and process
    df_read = swfscDAS::das_read(dasFile, skip = 0)
    df_proc = swfscDAS::das_process(dasFile)
    # update time zone
    # NB! This will be a problem when at Midway
    df_proc$DateTime = lubridate::force_tz(df_proc$DateTime, 'HST')
    # View(df_proc)
    
    # correct cruise number (only need on first few days of Leg 1)
    if (crNum == 2303 && leg == 1){
      df_proc$Cruise = 2303
    }
    
    
    # ------ Parse track data from das ----------------------------------------
    
    # parse on-effort segments as straight lines from Begin/Resume to End 
    source(file.path(dir_wd, 'code', 'functions', 'parseTrack.R'))
    etNew = parseTrack(df_proc)
    
    # save a 'snapshot' of the data for this das file with date it was run
    outName = paste0('newEffortTracks_', legID, '_', d$name, '_ran', 
                     Sys.Date(), '.Rda')
    save(etNew, file = file.path(dir_snaps, outName))
    googledrive::drive_upload(file.path(dir_snaps, outName), path = dir_gd_snaps)
    cat('   saved', outName, '\n')
    
    # combine the old vs dataframe with the new one
    outName = paste0('compiledEffortTracks_', projID, '.Rda')
    if (file.exists(file.path(dir_data, outName))){
      # load old if it exists
      load(file.path(dir_data, outName))
      # combine
      et = rbind(et, etNew)
      et = unique(et)                 # remove duplicates (in case ran already)
      et = et[order(et$DateTime1),]   # sort in case out of order
    } else {
      et = etNew
    }
    
    save(et, file = file.path(dir_data, outName))
    googledrive::drive_put(file.path(dir_data, outName), path = dir_gd_proc)
    outNameCSV = paste0('compiledEffortTracks_', projID, '.csv')
    write.csv(et, file = file.path(dir_data, outNameCSV))
    googledrive::drive_put(file.path(dir_data, outNameCSV), path = dir_gd_proc)
    cat('   saved', outName, 'and as .csv\n')
    
    
    # ------ Create GPX from track data ---------------------------------------
    
    source(file.path(dir_wd, 'code', 'functions', 'trackToGPX.R'))
    
    # by day/das tracks
    outGPX = file.path(dir_gpx, paste0('effortTracks_', legID, '_', d$name, '.gpx'))
    trackToGPX(etNew, outGPX)
    googledrive::drive_put(file.path(outGPX), path = dir_gd_gpx)
    cat('   saved', outGPX, '\n')
    
    # compiled tracks
    outGPX = file.path(dir_gpx, paste0('compiledEffortTracks_', projID, '.gpx'))
    trackToGPX(et, outGPX)
    googledrive::drive_put(file.path(outGPX), path = dir_gd_gpx)
    cat('   saved', outGPX, '\n')
    
    # ------ Parse track data as points ---------------------------------------
    # alternatively, can parse individual lines to get the segments out as points
    
    source(file.path(dir_wd, 'code', 'functions', 'parseTrack_asPoints.R'))
    epNew = parseTrack_asPoints(df_proc)
    
    # save a 'snapshot' of the data for this run
    outName = paste0('newEffortPoints_', legID, '_', d$name, '_ran', 
                     Sys.Date(), '.Rda')
    save(epNew, file = file.path(dir_snaps, outName))
    googledrive::drive_upload(file.path(dir_snaps, outName), path = dir_gd_snaps)
    cat('   saved', outName, '\n')
    
    # combine the old vs dataframe with the new one
    outName = paste0('compiledEffortPoints_', projID, '.Rda')
    if (file.exists(file.path(dir_data, outName))){
      # load old if it exists
      load(file.path(dir_data, outName))
      # combine, remove dupes, sort by date
      ep = rbind(ep, epNew)
      ep = unique(ep)
      ep = ep[order(ep$DateTime),]
    } else {
      ep = epNew
    }
    
    save(ep, file = file.path(dir_data, outName))
    googledrive::drive_put(file.path(dir_data, outName), path = dir_gd_proc)
    outNameCSV = paste0('compiledEffortPoints_', projID, '.csv')
    write.csv(ep, file = file.path(dir_data, outNameCSV))
    googledrive::drive_put(file.path(dir_data, outNameCSV), path = dir_gd_proc)
    cat('   saved', outName, 'and as .csv\n')
    
    # ------ Extract visual sighting data -------------------------------------
    
    # do some stuff here to extract visual sighting data for the day from das
    source(file.path(dir_wd, 'code', 'functions', 'extractVisualSightings.R'))
    vsNew = extractVisualSightings(df_proc)
    
    # confirm all species codes are numeric and delete rows that aren't
    vsNew_clean <- vsNew[!is.na(as.numeric(vsNew$SpCode)), ] 
    vsNew = vsNew_clean
    
    # save a 'snapshot' of the data for this run
    outName = paste0('newSightings_', legId, '_', d$name, '_ran', Sys.Date(), '.Rda')
    save(vsNew, file = file.path(dir_snaps, outName))
    googledrive::drive_upload(file.path(dir_snaps, outName), path = dir_gd_snaps)
    cat('   saved', outName, '\n')
    
    # combine the old vs dataframe with the new one
    outName = paste0('compiledSightings_', projID, '.Rda')
    if (file.exists(file.path(dir_data, outName))){
      # load old if it exists
      load(file.path(dir_data, outName))
      # combine, remove dupes, sort by date
      vs = rbind(vs, vsNew)
      vs = unique(vs)
      vs = vs[order(vs$DateTime),]
    } else { # if no previous sightings file exists
      vs = vsNew
    }
    
    save(vs, file = file.path(dir_data, outName))
    googledrive::drive_put(file.path(dir_data, outName), path = dir_gd_proc)
    outNameCSV = paste0('compiledSightings_', projID, '.csv')
    write.csv(vs, file = file.path(dir_data, outNameCSV))
    googledrive::drive_put(file.path(dir_data, outNameCSV), path = dir_gd_proc)
    cat('   saved', outName, 'and as .csv\n')
    
  } # end loop through all idxNew
  
  
  
  # ------ Extract acoustic detections --------------------------------------
  
  cat(' Skipping acoustic detections...\n')
  # acoustics file will just be a single sql file that is updated/appended to each day
  # it can be large so may be a bit slow to download
  # pamList = googledrive::drive_ls(path = dir_gd_raw_pam, pattern = 'PAM')
  # googledrive::drive_download(file = googledrive::as_id(pamList$id[1]),
  # overwrite = TRUE,
  # path = paste0(dir_wd, 'gd_downloads/', yr, '/', pamList$name[1]))
  
  
  # FUTURE GOALS
  # source(file.path(dir_wd, 'code', 'functions', 'extractAcousticDetections.R')
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
  
  # **Would end loop through multiple vessels here. 
  
  # ------ Make summary table -----------------------------------------------
  cat(' Updating summary table:\n')
  
  # load previously created summary table if it exists
  stName = paste0('summaryTable_', yr, '.Rda')
  if (file.exists(file.path(dir_wd, 'outputs', stName))){
    load(file.path(dir_wd, 'outputs', stName))
  } else {
    st = data.frame()
  }
  
  source(file.path(dir_wd, 'code', 'functions', 'makeSummaryTable.R'))
  lt = makeSummaryTable(st, et, vs, ad, leg, ship, blank_table)
  # break out pieces of returned list
  st = lt$st
  ft = lt$ft
  
  # save st .rda as combined for the whole year (bc loaded on later legs)
  save(st, file = file.path(dir_wd, 'outputs', stName))
  cat('   saved', stName, '\n')
  
  # save ft (formatted flexttable) as image
  outName = paste0('summaryTable.png')
  flextable::save_as_image(ft, path = file.path(dir_wd, 'outputs', outName), 
                           res = 300)
  cat('   saved', outName, '\n')
  outName = paste0('summaryTable_', legID, '_ran', Sys.Date(), '.png')
  flextable::save_as_image(ft, path = file.path(dir_tsnaps, outName), res = 300)
  cat('   saved', outName, '\n')
  
  # ------ Plot map ---------------------------------------------------------
  cat(' Generating latest map:\n')
  
  source(file.path(dir_wd, 'code', 'functions', 'plotMap.R'))
  
  mapOut = plotMap(dir_wd, ep, epNew, vs, leg, ship, test_code)
  base_map = mapOut$base_map
  vsMap = mapOut$vsMap
  
  # ------ Save map figures -------------------------------------------------
  # then save daily update plot as .png and .pdf
  # the latest will be in the 'outputs' folder and a snapshot of each day will
  # saved in the 'map_archive' folder
  height = 5
  width = 10
  res = 400
  
  # save the latest - as .png and .pdf
  outStr = paste0('dailyMap')
  ggsave(filename = file.path(dir_wd, 'outputs', paste0(outStr, '.png')),
         height = height,
         width = width,
         units = 'in', 
         plot = base_map,
         dpi = res,
         bg = 'white',
         device = 'png')
  
  ggsave(filename = file.path(dir_wd, 'outputs', paste0(outStr, '.pdf')),
         height = height,
         width = width,
         plot = base_map,
         dpi = res,
         bg = 'white',
         device = 'pdf')
  cat('   saved', outStr, 'as .png and .pdf\n')
  
  # save a copy of today's run - as .png and .pdf
  outStr = paste0('dailyMap_', legID, '_ran', Sys.Date())
  ggsave(filename = file.path(dir_msnaps, paste0(outStr, '.png')),
         height = height,
         width = width,
         plot = base_map,
         dpi = res,
         bg = 'white',
         device = 'png')
  
  ggsave(filename = file.path(dir_msnaps, paste0(outStr, '.pdf')),
         height = height,
         width = width,
         plot = base_map,
         dpi = res,
         bg = 'white',
         device = 'pdf')
  cat('   saved', outStr, 'as .png and .pdf\n')
  
} # end check for non-empty idxNew

# if all ran ok, save updated dasList so these files won't be run again
save(dasList, file = file.path(dir_wd, 'outputs', paste0('dasList_', projID, '.Rda')))

# ------ Close up log -----------------------------------------------------

cat('...run complete', format(Sys.time(), '%Y-%m-%d %H:%M:%S %Z'), '...\n')
sink()
