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

# dates0 = 'latest' # "all" # 'latest' #"2021-06-05",
# Sys.Date(), # as.character(seq(as.Date("2022-07-30"), as.Date("2022-08-14"), by="days"))

yr = 2023
ship = 'OES' # 'LSK'
leg = '1'
# string for yr_legXX_SHP - used for filename generation
y_l_s = paste0(yr, '_leg', leg, '_', ship)
crNum = 2303
crStr = paste0(ship, crNum)

# dir_gd_raw <- paste0('cruise-maps-live/raw_das_files/', yr)
# specifying path this way searches through all of google drive and is kind of slow
# alternative hard code to url.
if (yr == 2017){
  dir_gd_raw_das <- 'https://drive.google.com/drive/u/0/folders/1x4GzvtLQDGT1nA7nuAPHs5CPXxsX6Umt'
  dir_gd_raw_pam <- 'https://drive.google.com/drive/u/0/folders/1uONES1aEE9SGxAIgI7g1EY-qb1pkwH16'
  dir_gd_processed <- googledrive::as_id('1slkbanFN3Avxxr1hcM99JxKk-TJE1C4k')
  dir_gd_snapshots <- googledrive::as_id('1ABge_3f1491s5odPcHU1p8KIWhG3ymLl')
} else if (yr == 2023){
  dir_gd_raw_das <- 'https://drive.google.com/drive/u/0/folders/1a0GjIQs9RUY-eVoe45K7Q4zcgwHh9J2O'
  dir_gd_raw_pam <- 'https://drive.google.com/drive/u/0/folders/1hevcdNvX_EpdYGXmWHQU5W-a04EL4FVX'
  dir_gd_processed <- googledrive::as_id('1URoovHoWbYxO7-QOsnQ6uE9CUvub2hOo')
  dir_gd_snapshots <- googledrive::as_id('1hl4isf9jn8vwNrXZ-EGwyY0qPjSJqPWd')
  dir_gd_gpx <- googledrive::as_id('1yscmHW2cZ_uP5V79MlpWnP2-1ziLWusp')
}

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

# or specify manually
# dir_wd <- "C:/Users/selene.fregosi/documents/github/cruise-maps-live/"

# as of now, all functions sourced individually, but could source all together
# functionNames <- list.files(pattern = '[.]R$', path = paste0(dir_wd, 'code',
#                                                              functions),
#                             full.names = TRUE);
# invisible(sapply(functionNames, FUN = source))
#


# ------ Set up folder structure ------------------------------------------
# create nested subfolders for this year_leg_ship if needed
# data folder
if (!dir.exists(file.path(dir_wd, 'data', y_l_s))){
  dir.create(file.path(dir_wd, 'data', y_l_s))
}
# downloaded google drive files
if (!dir.exists(file.path(dir_wd, 'data', y_l_s, 'gd_downloads'))){
  dir.create(file.path(dir_wd, 'data', y_l_s, 'gd_downloads'))
}
# data snapshots
if (!dir.exists(file.path(dir_wd, 'data', y_l_s, 'snapshots'))){
  dir.create(file.path(dir_wd, 'data', y_l_s, 'snapshots'))
}
# gpx data
if (!dir.exists(file.path(dir_wd, 'data', y_l_s, 'gpx'))){
  dir.create(file.path(dir_wd, 'data', y_l_s, 'gpx'))
}
# map snapshots
if (!dir.exists(file.path(dir_wd, 'outputs', 'map_archive', y_l_s))){
  dir.create(file.path(dir_wd, 'outputs', 'map_archive', y_l_s))
}
# table snapshots
if (!dir.exists(file.path(dir_wd, 'outputs', 'table_archive', y_l_s))){
  dir.create(file.path(dir_wd, 'outputs', 'table_archive', y_l_s))
}

# ------ Make a log file --------------------------------------------------
# define directory to save log file and create if doesn't exist
logDir = file.path(dir_wd, 'outputs', 'run_logs', y_l_s)
if (!dir.exists(logDir)) {
  dir.create(logDir)}

# start log
logFile = file.path(logDir, paste0('run_', Sys.Date(), '_', locCode, '.log'))
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
  load(file.path(dir_wd, 'data', 'blankEffortPoints.Rda'))
  load(file.path(dir_wd, 'data', 'blankEffortTracks.Rda'))
  load(file.path(dir_wd, 'data', 'blankSightings.Rda'))
  epNew = ep
  
  # map testing options
  test_code = FALSE
  # blank_map = TRUE
  blank_table = TRUE
  idxNew = integer(0)
  
} else if (data_source == 'gd'){
  googledrive_dl <- TRUE
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
  if (file.exists(file.path(dir_wd, 'outputs', paste0('dasList_', yr, '.Rda')))){
    load(file.path(dir_wd, 'outputs', paste0('dasList_', yr, '.Rda')))
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
  if (leg == '00'){
    # idxNew = 3
    idxNew = c(1,2)
  }
  ###################
  
}

# ------ Download, read and process das file ------------------------------

# if there are new das to process
if (length(idxNew) != 0){
  # loop through all idxNew
  for (i in 1:length(idxNew)){
    # i = 1 # for testing
    d = dasList[idxNew[i],]
    
    dasFile = file.path(dir_wd, 'data', y_l_s, 'gd_downloads', d$name)
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
    df_proc$DateTime = lubridate::force_tz(df_proc$DateTime, 'HST')
    # View(df_proc)
    
    # correct cruise number (only need on first few days of Leg 1)
    if (y_l_s == '2023_leg01_OES'){
      df_proc$Cruise = 2303
    }
    
    
    # ------ Parse track data from das ----------------------------------------
    
    # parse on-effort segments as straight lines from Begin/Resume to End 
    source(file.path(dir_wd, 'code', 'functions', 'parseTrack.R'))
    etNew = parseTrack(df_proc)
    
    # save a 'snapshot' of the data for this das file with date it was run
    outName = paste0('newEffortTracks_', y_l_s, '_', d$name, '_', 
                     Sys.Date(), '.Rda')
    save(etNew, file = file.path(dir_wd, 'data', y_l_s, 'snapshots', outName))
    googledrive::drive_upload(file.path(dir_wd, 'data', y_l_s, 'snapshots', outName), 
                              path = dir_gd_snapshots)
    cat('   saved', outName, '\n')
    
    # combine the old vs dataframe with the new one
    outName = paste0('compiledEffortTracks_', y_l_s, '.Rda')
    if (file.exists(file.path(dir_wd, 'data', y_l_s, outName))){
      # load old if it exists
      load(file.path(dir_wd, 'data', y_l_s, outName))
      # combine
      et = rbind(et, etNew)
      et = unique(et)                 # remove duplicates (in case ran already)
      et = et[order(et$DateTime1),]   # sort in case out of order
    } else {
      et = etNew
    }
    
    save(et, file = file.path(dir_wd, 'data', y_l_s, outName))
    googledrive::drive_put(file.path(dir_wd, 'data', y_l_s, outName), 
                           path = dir_gd_processed)
    outNameCSV = paste0('compiledEffortTracks_', y_l_s, '.csv')
    write.csv(et, file = file.path(dir_wd, 'data', y_l_s, outNameCSV))
    googledrive::drive_put(file.path(dir_wd, 'data', y_l_s, outNameCSV), 
                           path = dir_gd_processed)
    cat('   saved', outName, 'and as .csv\n')
    
    
    # ------ Create GPX from track data ---------------------------------------
    
    source(file.path(dir_wd, 'code', 'functions', 'trackToGPX.R'))
    
    # by day/das tracks
    outGPX = file.path(dir_wd, 'data', y_l_s, 'gpx', 
                       paste0('newEffortTracks_', y_l_s, '_', d$name, '_', 
                              Sys.Date(), '.gpx'))
    trackToGPX(etNew, outGPX)
    googledrive::drive_put(file.path(outGPX), path = dir_gd_gpx)
    cat('   saved', outGPX, '\n')
    
    # compiled tracks
    outGPX = file.path(dir_wd, 'data', y_l_s, 'gpx', 
                       paste0('compiledEffortTracks_', y_l_s, '.gpx'))
    trackToGPX(et, outGPX)
    googledrive::drive_put(file.path(outGPX), path = dir_gd_gpx)
    cat('   saved', outGPX, '\n')
    
    # ------ Parse track data as points ---------------------------------------
    # alternatively, can parse individual lines to get the segments out as points
    
    source(file.path(dir_wd, 'code', 'functions', 'parseTrack_asPoints.R'))
    epNew = parseTrack_asPoints(df_proc)
    
    # save a 'snapshot' of the data for this run
    outName = paste0('newEffortPoints_', y_l_s, '_', d$name, '_', 
                     Sys.Date(), '.Rda')
    save(epNew, file = file.path(dir_wd, 'data', y_l_s, 'snapshots', outName))
    googledrive::drive_upload(file.path(dir_wd, 'data', y_l_s, 'snapshots', outName), 
                              path = dir_gd_snapshots)
    cat('   saved', outName, '\n')
    
    # combine the old vs dataframe with the new one
    outName = paste0('compiledEffortPoints_', y_l_s, '.Rda')
    if (file.exists(file.path(dir_wd, 'data', y_l_s, outName))){
      # load old if it exists
      load(file.path(dir_wd, 'data', y_l_s, outName))
      # combine, remove dupes, sort by date
      ep = rbind(ep, epNew)
      ep = unique(ep)
      ep = ep[order(ep$DateTime),]
    } else {
      ep = epNew
    }
    
    save(ep, file = file.path(dir_wd, 'data', y_l_s, outName))
    googledrive::drive_put(file.path(dir_wd, 'data', y_l_s, outName), 
                           path = dir_gd_processed)
    outNameCSV = paste0('compiledEffortPoints_', y_l_s, '.csv')
    write.csv(ep, file = file.path(dir_wd, 'data', y_l_s, outNameCSV))
    googledrive::drive_put(file.path(dir_wd, 'data', y_l_s, outNameCSV), 
                           path = dir_gd_processed)
    cat('   saved', outName, 'and as .csv\n')
    
    # ------ Extract visual sighting data -------------------------------------
    
    # do some stuff here to extract visual sighting data for the day from das
    source(file.path(dir_wd, 'code', 'functions', 'extractVisualSightings.R'))
    vsNew = extractVisualSightings(df_proc)
    
    # confirm all species codes are numeric and delete rows that aren't
    vsNew_clean <- vsNew[!is.na(as.numeric(vsNew$SpCode)), ] 
    vsNew = vsNew_clean
    
    # save a 'snapshot' of the data for this run
    outName = paste0('newSightings_', y_l_s, '_', d$name, '_', Sys.Date(), '.Rda')
    save(vsNew, file = file.path(dir_wd, 'data', y_l_s, 'snapshots', outName))
    googledrive::drive_upload(file.path(dir_wd, 'data', y_l_s, 'snapshots', outName), 
                              path = dir_gd_snapshots)
    cat('   saved', outName, '\n')
    
    # combine the old vs dataframe with the new one
    outName = paste0('compiledSightings_', y_l_s, '.Rda')
    if (file.exists(file.path(dir_wd, 'data', y_l_s, outName))){
      # load old if it exists
      load(file.path(dir_wd, 'data', y_l_s, outName))
      # combine, remove dupes, sort by date
      vs = rbind(vs, vsNew)
      vs = unique(vs)
      vs = vs[order(vs$DateTime),]
    } else { # if no previous sightings file exists
      vs = vsNew
    }
    
    save(vs, file = file.path(dir_wd, 'data', y_l_s, outName))
    googledrive::drive_put(file.path(dir_wd, 'data', y_l_s, outName), 
                           path = dir_gd_processed)
    outNameCSV = paste0('compiledSightings_', y_l_s, '.csv')
    write.csv(vs, file = file.path(dir_wd, 'data', y_l_s, outNameCSV))
    googledrive::drive_put(file.path(dir_wd, 'data', y_l_s, outNameCSV), 
                           path = dir_gd_processed)
    cat('   saved', outName, 'and as .csv\n')
    
  } # end loop through all idxNew for download and processing of DAS
  
  
  
  # ------ Extract acoustic detections --------------------------------------
  
  cat(' Skipping acoustic detections...\n')
  # acoustics file is single sql file that is updated/appended each day
  # file is large so slow to download
  
  # assemble search string (may change later to ship name being based on cruise num)
  # or may define this at top?
  if (ship == 'OES'){
    shipName = 'Sette'
  } else if (ship == 'LSK'){ # maybe will be changed to 'RL'
    shipName = 'Lasker'
  }
  pat = paste0(shipName, 'Leg', leg)
  
  # read in the file for this ship and leg - pamList should be length 1
  pamList = googledrive::drive_ls(path = dir_gd_raw_pam, pattern = pat)
  if (nrow(pamList) == 1){
    pamFile = file.path(dir_wd, 'data', crStr, 'gd_downloads', pamList$name[1])
    googledrive::drive_download(file = googledrive::as_id(pamList$id[1]),
                                overwrite = TRUE, path = pamFile)
  } else {stop('Should only be 1 PAM file!! Resolve on Google Drive and try again.')}
  
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
  outName = paste0('summaryTable_', y_l_s, '.png')
  flextable::save_as_image(ft, path = file.path(dir_wd, 'outputs', outName), 
                           res = 300)
  cat('   saved', outName, '\n')
  outName = paste0('summaryTable_', y_l_s, '_', Sys.Date(), '.png')
  flextable::save_as_image(ft, path = file.path(dir_wd, 'outputs', 'table_archive',
                                                y_l_s, outName), res = 300)
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
  outStr = paste0('dailyMap_', y_l_s)
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
  outStr = paste0('dailyMap_', y_l_s, '_', Sys.Date())
  ggsave(filename = file.path(dir_wd, 'outputs', 'map_archive', y_l_s, 
                              paste0(outStr, '.png')),
         height = height,
         width = width,
         plot = base_map,
         dpi = res,
         bg = 'white',
         device = 'png')
  
  ggsave(filename = file.path(dir_wd, 'outputs', 'map_archive', y_l_s, 
                              paste0(outStr, '.pdf')),
         height = height,
         width = width,
         plot = base_map,
         dpi = res,
         bg = 'white',
         device = 'pdf')
  cat('   saved', outStr, 'as .png and .pdf\n')
  
} # end check for non-empty idxNew

# if all ran ok, save updated dasList so these files won't be run again
save(dasList, file = file.path(dir_wd, 'outputs', paste0('dasList_', yr, '.Rda')))
# ------ Close up log -----------------------------------------------------

cat('...run complete', format(Sys.time(), '%Y-%m-%d %H:%M:%S %Z'), '...\n')
sink()
