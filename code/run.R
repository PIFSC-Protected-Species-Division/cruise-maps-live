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
leg = '2'

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
  load(file.path(dir_wd, 'data', 'blank', 'blankEffortPoints.Rda'))
  load(file.path(dir_wd, 'data', 'blank', 'blankEffortTracks.Rda'))
  load(file.path(dir_wd, 'data', 'blank', 'blankSightings.Rda'))
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
  if (file.exists(file.path(dir_wd, 'outputs', 
                            paste0('dasList_', projID, '.Rda')))){
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
    idxNew = 6
    # idxNew = c(1,2)
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
    
    # add on some ship info
    etNew$shipCode = shipCode
    etNew$shipName = shipName
    etNew$projID = projID
    etNew$leg = leg
    
    # save a 'snapshot' of the data for this das file with date it was run
    outName = paste0('newEffortTracks_', legID, '_', d$name, '_ran', 
                     Sys.Date(), '.Rda')
    save(etNew, file = file.path(dir_snaps, outName))
    googledrive::drive_put(file.path(dir_snaps, outName), path = dir_gd_snaps)
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
    outGPX = file.path(dir_gpx, paste0('effortTracks_', legID, '_', d$name, 
                                       '.gpx'))
    trackToGPX(etNew, outGPX)
    googledrive::drive_put(file.path(outGPX), path = dir_gd_gpx)
    cat('   saved', basename(outGPX), '\n')
    
    # compiled tracks
    outGPX = file.path(dir_gpx, paste0('compiledEffortTracks_', projID, '.gpx'))
    trackToGPX(et, outGPX)
    googledrive::drive_put(file.path(outGPX), path = dir_gd_gpx)
    cat('   saved', basename(outGPX), '\n')
    
    # ------ Parse track data as points ---------------------------------------
    # alternatively, can parse individual lines to get the segments out as points
    
    source(file.path(dir_wd, 'code', 'functions', 'parseTrack_asPoints.R'))
    epNew = parseTrack_asPoints(df_proc)
    
    # add on some ship info
    epNew$shipCode = shipCode
    epNew$shipName = shipName
    epNew$projID = projID
    epNew$leg = leg
    
    # save a 'snapshot' of the data for this run
    outName = paste0('newEffortPoints_', legID, '_', d$name, '_ran', 
                     Sys.Date(), '.Rda')
    save(epNew, file = file.path(dir_snaps, outName))
    googledrive::drive_put(file.path(dir_snaps, outName), path = dir_gd_snaps)
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
    
    if (nrow(vsNew) > 0){
      # add on some ship info
      vsNew$shipCode = shipCode
      vsNew$shipName = shipName
      vsNew$projID = projID
      vsNew$leg = leg
    }
    
    # confirm all species codes are numeric and delete rows that aren't
    vsNew_clean <- vsNew[!is.na(as.numeric(vsNew$SpCode)), ] 
    vsNew = vsNew_clean
    
    # save a 'snapshot' of the data for this run
    outName = paste0('newSightings_', legID, '_', d$name, '_ran', Sys.Date(), 
                     '.Rda')
    save(vsNew, file = file.path(dir_snaps, outName))
    googledrive::drive_put(file.path(dir_snaps, outName), path = dir_gd_snaps)
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
    
  } # end loop through all idxNew for download and processing of DAS
  
  
  
  # ------ Extract acoustic detections --------------------------------------
  # acoustics file is single sql file that is updated/appended each day
  # file is large so slow to download
  
  # assemble search pattern
  pat = paste0(shipName, 'Leg', leg)
  
  # read in the file for this ship and leg - pamList should be length 1
  pamList = googledrive::drive_ls(path = dir_gd_raw_pam, pattern = pat)
  if (nrow(pamList) == 0){
    cat('No PAM file!! Skipping any new acoustic detections.')
    # stop('Should only be 1 PAM file!! Resolve on Google Drive and try again.')
    
  } else if (nrow(pamList) > 1 && nrow(pamList) != 1){
    cat('Should only be 1 PAM file!! Stopping process. Resolve and try again.')
    stop('Should only be 1 PAM file!! Resolve on Google Drive and try again.')
    
  } else if (nrow(pamList) == 1){
    
    pamFile = file.path(dir_gd_dwnl, pamList$name[1])
    googledrive::drive_download(file = googledrive::as_id(pamList$id[1]),
                                overwrite = TRUE, path = pamFile)
    
    # 'new' acoustic data will be for an entire leg (not per day) and loaded old 
    # ad file will contain all detections from previous legs
    # will still save a 'snapshot' of each day (but it will be cumulative)
    
    # process new file
    source(file.path(dir_wd, 'code', 'functions', 'extractAcousticDetections.R'))
    adNew = extractAcousticDetections(pamFile)
    
    if (nrow(adNew) > 0){
      # add on some ship info
      adNew$shipCode = shipCode
      adNew$shipName = shipName
      adNew$projID = projID
      adNew$leg = leg
    }
    
    # save a 'snapshot' of the data for this run
    outName = paste0('acousticDetections_', legID, '_ran', Sys.Date(), '.Rda')
    save(adNew, file = file.path(dir_snaps, outName))
    googledrive::drive_put(file.path(dir_snaps, outName), path = dir_gd_snaps)
    cat('   saved', outName, '\n')
  }
  
  # combine the old vs dataframe with the new one
  outName = paste0('compiledDetections_', projID, '.Rda')
  if (file.exists(file.path(dir_data, outName))){
    # load old if it exists
    load(file.path(dir_data, outName))
    # combine, if new data loaded
    if (exists('adNew')){ad = rbind(ad, adNew)}
    # remove dupes, sort by date
    ad = unique(ad)
    ad = ad[order(ad$UTC),]
  } else if (exists('adNew')){ # if no previous sightings file exists, but new does
    ad = adNew
  }
  
  # save the primary compiled version
  save(ad, file = file.path(dir_data, outName))
  googledrive::drive_put(file.path(dir_data, outName), path = dir_gd_proc)
  outNameCSV = paste0('compiledDetections_', projID, '.csv')
  write.csv(vs, file = file.path(dir_data, outNameCSV))
  googledrive::drive_put(file.path(dir_data, outNameCSV), path = dir_gd_proc)
  cat('   saved', outName, 'and as .csv\n')
  
  # **Would end loop through multiple vessels here. 
  
  
  # ------ Make summary table -----------------------------------------------
  cat(' Updating summary table:\n')
  
  # load previously created summary table if it exists
  stName = paste0('summaryTable.Rda')
  if (file.exists(file.path(dir_wd, 'outputs', stName))){
    load(file.path(dir_wd, 'outputs', stName))
  } else {
    st = data.frame()
  }
  
  source(file.path(dir_wd, 'code', 'functions', 'makeSummaryTable.R'))
  lt = makeSummaryTable(st, et, vs, ad, shipCode, leg, blank_table)
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
  
  # ------ Plot visual sightings map --------------------------------------
  cat(' Generating latest map of visual sightings:\n')
  
  source(file.path(dir_wd, 'code', 'functions', 'plotMap.R'))
  
  mapOutV = plotMap(dir_wd, ep, epNew, vs, shipCode, leg, test_code)
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
  cat('   saved', outStr, 'as .png and .pdf\n')
  
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
  cat('   saved', outStr, 'as .png and .pdf\n')
  
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
  cat('   saved', outName, 'and as .csv\n')
  cat('   saved', outStr, 'as .png and .pdf\n')
  
  # ------ Plot acoustic detections map -----------------------------------
  cat(' Generating latest map of acoustic detections:\n')
  
  # add correctly formated SpCode col
  ad$SpCode = as.integer(ad$sp_map)
  
  mapOutA = plotMap(dir_wd, ep, epNew, ad, shipCode, leg, test_code)
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
  cat('   saved', outStr, 'as .png and .pdf\n')
  
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
  cat('   saved', outStr, 'as .png and .pdf\n')
  
  
  # ------ Save dasList and close log  ------------------------------------
  
} # end check for non-empty idxNew

# if all ran ok, save updated dasList so these files won't be run again
save(dasList, file = file.path(dir_wd, 'outputs', 
                               paste0('dasList_', projID, '.Rda')))

cat('...run complete', format(Sys.time(), '%Y-%m-%d %H:%M:%S %Z'), '...\n')
sink()
