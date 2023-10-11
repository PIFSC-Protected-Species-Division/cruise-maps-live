#' ---------------------------
#' title: Daily Survey Effort and Sightings Map
#' authors: Selene Fregosi, Janelle Badger, Yvonne Barkley, Kym Yano
#' inspired by: Emily Markowitz et al at NWFSC
#' purpose: pull in raw survey data, parse out relevant bits, and create a 
#' map with the most recent survey effort and sightings
#' ---------------------------

# --- USER SPECIFIED INPUTS -----------------------------------------------
# these inputs will change/need updating within a SURVEY (e.g., within HICEAS)

# data_source = 'gd' # google drive
# data_source = 'blank' # for making blank table and map. Set leg to 0
data_source = 'test' # work with test data set.

# yr = 2023
crNum = c(2303, 2401) #2303
# ship = 'OES' # 'LSK'
leg = c('3', '1')

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

# --- Libraries -----------------------------------------------------------

# most functions are called with :: so don't have to load all libraries, but do 
# have to load a few for using %>% pipeline
library(raster)
library(tidyverse)


# --- Make a log file -----------------------------------------------------
# define directory to save log file and create if doesn't exist
# now with two boats, putting all logs in a single folder
subStr = paste0(crNum, 'leg', leg)
dir_log = file.path(dir_wd, 'outputs', 'run_logs', 'twoBoats')
if (!dir.exists(dir_log)){
  dir.create(dir_log)}

# start log
logFile = file.path(dir_log, paste0('run_', Sys.Date(), '_', locCode, '.log'))
sink(logFile, append = TRUE)

# first entries
cat('\n... run started', format(Sys.time(), '%Y-%m-%d %H:%M:%S %Z'), '...\n')
cat(' dir_wd =', dir_wd, '\n')


# --- Loop through each cruise/vessel -------------------------------------
# loop through each cruise to download/process data streams
cat('Processing data for', length(crNum), 'vessel(s).\n')

if (length(crNum) > 1){
  multiVessel = TRUE
  
  # set up empty epL, epNewL, etL, etNewL, adL, and vsL outputs for combining vessels
  etL = list()
  etNewL = list()
  epL = list()
  epNewL = list()
  adL = list()
  vsL = list()
  
}

for (cr in 1:length(crNum)){
  # crNumTmp = crNum[cr]
  cat(' -- Cruise number', crNum[cr], '--\n')
  
  
  # ------ MORE USER SPECIFIED INPUTS ---------------------------------------
  # these inputs will only need to be set at the START of a SURVEY or when 
  # code is set up to run on new person's machine
  
  # specify ship info and google drive paths for each cruise num/ship
  if (crNum[cr] == 2303){
    shipCode = 'OES'
    shipName = 'Sette'
    projID = 'OES2303'
    
    if (data_source == 'gd'){
      dir_gd_raw_das <- googledrive::as_id('1a0GjIQs9RUY-eVoe45K7Q4zcgwHh9J2O')
      dir_gd_proc <- googledrive::as_id('1URoovHoWbYxO7-QOsnQ6uE9CUvub2hOo')
      dir_gd_snaps <- googledrive::as_id('1hl4isf9jn8vwNrXZ-EGwyY0qPjSJqPWd')
      dir_gd_gpx <- googledrive::as_id('1yscmHW2cZ_uP5V79MlpWnP2-1ziLWusp')
    } else if (data_source == 'test'){
      dir_gd_raw_das <- googledrive::as_id('1ivy3JzfYV7B5tQaGllhomqcyZh0c18U4')
      dir_gd_proc <- googledrive::as_id('12P03T2frWuCBsDZcN2ZSYzAr9lxRZ0Iq')
      dir_gd_snaps <- googledrive::as_id('1ubIn5fO3xH5hfwk256fDbh0dQ0n8FmVz')
      dir_gd_gpx <- googledrive::as_id('1vU_LsU5zSOdgDA8hh2aVWYBIUO12rdSa')
    }
  } else if (crNum[cr] == 2401){
    shipCode = 'LSK'
    shipName = 'Lasker'
    projID = 'LSK2401'
    
    if (data_source == 'gd'){
      dir_gd_raw_das <- googledrive::as_id('1D6vZ9S_tmu_Wn4_NhSBD-y4KxEjCJCYN')
      dir_gd_proc <- googledrive::as_id('13r2m9vGpf9CqDeCEvA2WHnxi1vvoLd89')
      dir_gd_snaps <- googledrive::as_id('1NtgC_A42XjzNXKNnQGZqwa-7x5P6E6Ca')
      dir_gd_gpx <- googledrive::as_id('1hGLdiVwGjAVw34rScjLPyLxwvj8uKftP')
    } else if (data_source == 'test'){
      dir_gd_raw_das <- googledrive::as_id('1AHhZ8vi0p5z3v-u1PBchJII7muB8jlUJ')
      dir_gd_proc <- googledrive::as_id('1w3rD9v3fRdm79rnPYVitHmqoD8gHxZW1')
      dir_gd_snaps <- googledrive::as_id('1jeqYIqjWkcD6W9vWvZdbQIiIWnslMsyY')
      dir_gd_gpx <- googledrive::as_id('1WsmVdMMGFkKv-pfumFGRldSk5-xulNrQ')
    }
  }
  
  # all pam data is in a single folder
  dir_gd_raw_pam <- googledrive::as_id('1hevcdNvX_EpdYGXmWHQU5W-a04EL4FVX')
  # and set 'outer' folder paths for data for two vessels
  dir_gd_gpx_up = googledrive::as_id('1O8H8zII_q-4cuGsvi61ETVUojUOxwmN3')
  
  # manually set the 'combined' projID
  if (multiVessel == TRUE){
    projIDC = 'OES2303_LSK2401'
  }
  
  # build string with leg num used throughout for filename generation
  legID = paste0(projID, '_leg', leg[cr])
  
  # if test data, modify projID and legID
  if (data_source == 'test'){
    legID = paste0(projID, '_leg', leg[cr], '_test')
    projID = paste0(projID, '_test')
  }
  
  
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
  
  # ------ Prep data source -------------------------------------------------
  
  # if creating blank map, load blank data.frames
  if (data_source == 'blank'){
    # to make blank table and map - these were made by hand
    load(file.path(dir_wd, 'data', 'blank', 'blankEffortPoints.Rda'))
    load(file.path(dir_wd, 'data', 'blank', 'blankEffortTracks.Rda'))
    load(file.path(dir_wd, 'data', 'blank', 'blankSightings.Rda'))
    load(file.path(dir_wd, 'data', 'blank', 'blankDetections.Rda'))
    epNew = ep
    idxNew = integer(0) # no new files to download/process
    
    # if testing, load test data.frames
  } else if (data_source == 'testPlots'){
    load(file.path(dir_wd, 'data', 'OES2303', 'compiledEffortPoints_OES2303.Rda'))
    load(file.path(dir_wd, 'data', 'OES2303', 'snapshots', 
                   'newEffortPoints_OES2303_leg2_DASALL.812_ran2023-08-15.Rda'))
    load(file.path(dir_wd, 'data', 'OES2303', 'compiledEffortTracks_OES2303.Rda'))
    load(file.path(dir_wd, 'data', 'OES2303', 'compiledSightings_OES2303.Rda'))
    load(file.path(dir_wd, 'data', 'OES2303', 'compiledDetections_OES2303.Rda'))
    idxNew = integer(0) # no new files to download/process
    
    
  } else if (data_source == 'gd'){
    # --------- Sign in to google drive -------------------------------------
    # if actually running, log in to Google Drive and download new files
    googledrive::drive_deauth()
    googledrive::drive_auth()
    # push through authorization approval
    2 # this may need to change??
    
    # ------------ Check for/id new das files -------------------------------
    
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
    dasList_gd = googledrive::drive_ls(path = dir_gd_raw_das, pattern = 'DASALL')
    # sort by day 
    dasList_gd = dasList_gd[order(dasList_gd$name),]
    dasNames_gd = dasList_gd$name
    
    # identify which files are new/need to be processed
    idxNew = which(!(dasNames_gd %in% dasNames_old))
    
    ### FOR TESTING ###
    # test reading in new das
    if (leg[cr] == '0'){
      # idxNew = 16
      idxNew = c(15, 16)
    }
    ### ### ### ### ###  
    
    if (length(idxNew) > 0){
      newDas = TRUE
    } else {
      newDas = FALSE
    }
    
    # ------------ Check for/download new acoustics file --------------------
    # acoustics file is single sql file that is updated/appended each day
    # file is large so slow to download
    
    # assemble search pattern
    pat = paste0(shipName, 'Leg', leg[cr])
    
    # read in the file for this ship and leg - pamList should be length 1
    pamList = googledrive::drive_ls(path = dir_gd_raw_pam, pattern = pat)
    if (nrow(pamList) == 0){
      cat('No PAM file present!! Skipping any acoustic processing/plotting...\n')
      newPam = FALSE
      # stop('Should only be 1 PAM file!! Resolve on Google Drive and try again.')
      
    } else if (nrow(pamList) > 1 && nrow(pamList) != 1){
      cat('Should only be 1 PAM file!! Stopping process. Resolve and try again.')
      newPam = FALSE
      stop('Should only be 1 PAM file!! Resolve on Google Drive and try again.')
      
    } else if (nrow(pamList) == 1){
      pamFile = file.path(dir_gd_dwnl, pamList$name[1])
      
      # check modified datetime vs last download datetime
      lastTime = file.info(pamFile)$mtime
      modTime = pamList$drive_resource[[1]]$modifiedTime
      
      # only download if it is newly updated
      if (is.na(lastTime) || (lastTime <= modTime)){
        googledrive::drive_download(file = googledrive::as_id(pamList$id[1]),
                                    overwrite = TRUE, path = pamFile)
        newPam = TRUE
      } else {
        newPam = FALSE
      }
    }
  } # end data source check
  
  # ------ Process everything! ----------------------------------------------
  # if there are new das OR acoustics to process/not test or blank run
  if (newDas == TRUE || newPam == TRUE){
    
    # --------- Download, read, process new das files -----------------------
    if (newDas == TRUE){
      cat(' Processing', length(idxNew), 'new das files:\n')
      # loop through all idxNew
      for (i in 1:length(idxNew)){
        # i = 1 # for testing
        d = dasList[idxNew[i],]
        
        dasFile = file.path(dir_gd_dwnl, d$name)
        cat(' ', d$name, '\n')
        
        # download and save locally
        googledrive::drive_download(file = googledrive::as_id(d$id), 
                                    overwrite = TRUE, path = dasFile)
        
        # basic data checks
        df_check = swfscDAS::das_check(dasFile, skip = 0, print.cruise.nums = FALSE)
        # read and process
        df_read = swfscDAS::das_read(dasFile, skip = 0)
        df_proc = swfscDAS::das_process(dasFile)
        
        # update time zone
        source(file.path(dir_wd, 'code', 'functions', 'assignTimeZone.R'))
        df_proc = assignTimeZone(df_proc, shipCode, file.path(dir_wd, 'inputs', 
                                                              'TimeZones.csv'))
        # If looking at compiled data.frames (tracks, points, etc) all timezones 
        # will be just a single one (HST), but they will have been adjusted for SST
        # View(df_proc)
        
        # correct cruise number (only need on first few days of Leg 1)
        if (crNum[cr] == 2303 && leg[cr] == 1){
          df_proc$Cruise = 2303
        }
        
        # save copy of df_proc
        outName = paste0('processedDAS_', legID, '_', d$name, '_ran', 
                         Sys.Date(), '.Rda')
        save(df_proc, file = file.path(dir_snaps, outName))
        
        
        # ------------ Extract track data from das --------------------------
        
        # parse on-effort segments as straight lines from Begin/Resume to End 
        source(file.path(dir_wd, 'code', 'functions', 'extractTrack.R'))
        etNew = extractTrack(df_proc)
        
        # add on some ship info
        etNew$shipCode = shipCode
        etNew$shipName = shipName
        etNew$projID = projID
        etNew$leg = leg[cr]
        
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
        
        if (multiVessel == TRUE){
          # add newly processed data to the combined/multivessel lists
          # just new tracks
          etNewL[[projID]] = etNew
          # compiled for this cruise number
          etL[[projID]] = et
        }
        
        # ------------ Create GPX from track data ---------------------------
        
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
        
        # ------------ Extract track data as points -------------------------
        # alternatively, can parse individual lines to get the segments out as points
        
        source(file.path(dir_wd, 'code', 'functions', 'extractTrack_asPoints.R'))
        epNew = extractTrack_asPoints(df_proc)
        
        # add on some ship info
        epNew$shipCode = shipCode
        epNew$shipName = shipName
        epNew$projID = projID
        epNew$leg = leg[cr]
        
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
        
        if (multiVessel == TRUE){
          # add newly processed data to the combined/multivessel lists
          # just new points
          epNewL[[projID]] = epNew
          # compiled for this cruise number
          epL[[projID]] = ep
        }
        
        # ------------ Extract visual sighting data -------------------------
        
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
        
        if (multiVessel == TRUE){
          # add newly processed data to the combined/multivessel lists
          vsL[[projID]] = vs
        }
        
      } # end loop through all idxNew for download and processing of DAS
      # turn on plotting bc we have new data (either visual, acoustic, or both)
      genPlots = TRUE
    } else {
      cat(' No new das files to process. Proceeding to acoustics...\n')
    }# end idx == 0 catch
    
    # --------- Extract acoustic detections ---------------------------------
    if (newPam == TRUE){
      cat(' Processing updated acoustic database.\n')
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
        
        # save a 'snapshot' of the data for this run
        outName = paste0('acousticDetections_', legID, '_ran', Sys.Date(), '.Rda')
        save(adNew, file = file.path(dir_snaps, outName))
        googledrive::drive_put(file.path(dir_snaps, outName), path = dir_gd_snaps)
        cat('   saved', outName, '\n')
      }
      
      # combine the old ad dataframe with the new one
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
      
      if (multiVessel == TRUE){
        # add newly processed data to the combined/multivessel lists
        adL[[projID]] = ad
      }
      
    } else {
      cat(' No new acoustic file to process.\n')
    }# end newPam catch
    
    # turn on plotting bc we have new data (either visual, acoustic, or both)
    genPlots = TRUE
  } else {
    genPlots = FALSE
    cat(' No new das or acoustic files to process. Exiting.\n')
  }
  
} # end loop through multiple boats 


# --- Combine vessels for plotting ----------------------------------------

if (multiVessel == TRUE){
  # combined lists generated within the loop need to be 'collapsed' into dfs 
  epNewC = dplyr::bind_rows(epNewL, .id = 'projID')
  epC = dplyr::bind_rows(epL, .id = 'projID')
  etC = dplyr::bind_rows(etL, .id = 'projID')
  vsC = dplyr::bind_rows(vsL, .id = 'projID')
  adC = dplyr::bind_rows(adL, .id = 'projID')
  
  # ### NEEDS UPDATING/DECISIONS ##############
  # will need to have some checks for if one vessel does have new data and other doesnt?
  # do we want to save the combined .rda as well?
  # if so, just save in file.path(dir_wd, 'data', paste0('compiledEffortTracks_', projIDC, '_combined.rda')) ????
  
  # ------ Create GPX from combined track data ----------------------------
  
  source(file.path(dir_wd, 'code', 'functions', 'trackToGPX.R'))
  
  # two-vessel combined compiled tracks
  outGPX = file.path(dir_wd, 'data', paste0('compiledEffortTracks_', projIDC, 
                                            '_combined.gpx'))
  trackToGPX(etC, outGPX)
  googledrive::drive_put(file.path(outGPX), path = dir_gd_gpx_up)
  cat('   saved', basename(outGPX), '\n')
  
} else{
  multiVessel = FALSE
  # just rename things with C so same function calls can be used below
  epNewC = epNew
  epC = ep
  etC = et
  vsC = vs
  adC = ad
}# multiple crNum steps

# ------ Plot everything! -------------------------------------------------
if (genPlots == TRUE){
  
  # --------- Make summary table ------------------------------------------
  # check for acoustics - they might not be updated daily
  if (!exists('ad')){ad = NULL}
  
  #source and create table
  source(file.path(dir_wd, 'code', 'functions', 'makeSummaryTable.R'))
  if (exists('etC') && exists('vsC') && exists('adC')){ #all vars present
    
    cat(' Updating summary table:\n')
    # load previously created summary table if it exists
    stName = paste0('summaryTable.Rda')
    if (data_source == 'gd' & file.exists(file.path(dir_wd, 'outputs', stName))){
      load(file.path(dir_wd, 'outputs', stName))
    } else {
      st = data.frame()
    }
    
    lt = makeSummaryTable(st, etC, vsC, adC, shipCode, leg)
    
    # break out pieces of returned list
    st = lt$st
    ft = lt$ft
    
    # save st .rda as combined for the whole year (bc loaded on later legs)
    if (data_source == 'gd'){ # only save if actual run, not test or blank
      save(st, file = file.path(dir_wd, 'outputs', stName))
      cat('   saved', stName, '\n')
      
      # save ft (formatted flexttable) as image
      outName = paste0('summaryTable.png')
      flextable::save_as_image(ft, path = file.path(dir_wd, 'outputs', outName), 
                               res = 180)
      cat('   saved', outName, '\n')
      # #####THIS NEEDS UPDATING - SAVE PATH #####
      # outName = paste0('summaryTable_', legID, '_ran', Sys.Date(), '.png')
      # flextable::save_as_image(ft, path = file.path(dir_tsnaps, outName), res = 180)
      # cat('   saved', outName, '\n')
      
    }
  } else {
    cat('   Missing some variable, skipping summary table...\n')
  }
  
  # --------- Plot visual sightings map -----------------------------------
  if (newDas == TRUE){
    cat(' Generating latest map of visual sightings:\n')
    
    source(file.path(dir_wd, 'code', 'functions', 'plotMap.R'))
    
    mapOutV = plotMap(dir_wd, epC, epNewC, vsC, shipCode, dataType = 'visual')
    base_map_V = mapOutV$base_map
    vsMap = mapOutV$ceMap
    numCols = mapOutV$numCols
    
    # ------------ Set plot save sizes ------------------------------------
    
    height = 5
    # printed width needs to vary by number of legend items
    if (numCols == 1){width = 9.35
    } else if (numCols == 2){width = 11
    } else if (numCols == 3){width = 12.65}
    # resolution
    res = 200
    
    # ------------ Save visuals map figures -------------------------------
    
    # save the latest - as .png and .pdf
    if (data_source == 'gd'){ # only save if actual run, not test or blank
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
      
      # save a large copy for CLs as PDF
      outStr = paste0('dailyMap_visuals_CL')
      ggsave(filename = file.path(dir_wd, 'outputs', paste0(outStr, '.pdf')),
             height = 10,
             width = 20,
             plot = base_map_V,
             # dpi = 1200,
             bg = 'white',
             device = 'pdf')
      # googledrive::drive_put(file.path(dir_wd, 'outputs', paste0(outStr, '.pdf')),
      #                        path = dir_gd_proc)
      googledrive::drive_put(file.path(dir_wd, 'outputs', paste0(outStr, '.pdf')),
                             path = dir_gd_gpx_up)
      cat('   saved', outName, 'and as .csv\n')
      cat('   saved', outStr, 'as .png and .pdf\n')
      
    }
    
    # save a copy of today's run - as .png and .pdf
    # ### NEEDS UPDATING - SAVE PATH #####################################
    # outStr = paste0('dailyMap_visuals_', legID, '_ran', Sys.Date())
    # ggsave(filename = file.path(dir_msnaps, paste0(outStr, '.png')),
    #        height = height,
    #        width = width,
    #        plot = base_map_V,
    #        dpi = res,
    #        bg = 'white',
    #        device = 'png')
    # 
    # ggsave(filename = file.path(dir_msnaps, paste0(outStr, '.pdf')),
    #        height = height,
    #        width = width,
    #        plot = base_map_V,
    #        dpi = res,
    #        bg = 'white',
    #        device = 'pdf')
    cat('   saved', outStr, 'as .png and .pdf\n')
  } else {
    cat(' No new das files, skipping visual sightings map...\n')
  }
  
  # --------- Plot acoustic detections map --------------------------------
  if (newPam == TRUE){
    cat(' Generating latest map of acoustic detections:\n')
    
    # add correctly formated SpCode col
    ad$SpCode = as.integer(ad$sp_map)
    
    mapOutA = plotMap(dir_wd, epC, epNewC, adC, shipCode, dataType = 'acoustic')
    base_map_A = mapOutA$base_map
    adMap = mapOutA$ceMap
    numCols = mapOutA$numCols
    
    # ------------ Set plot save sizes ------------------------------------
    height = 5
    # printed width needs to vary by number of legend items
    if (numCols == 1){width = 9.35
    } else if (numCols == 2){width = 11
    } else if (numCols == 3){width = 12.65}
    # resolution
    res = 200
    
    # ------------ Save acoustics map figures -----------------------------
    # save the latest - as .png and .pdf
    if (data_source == 'gd'){ # only save if actual run, not test or blank
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
    }
    
    # save a copy of today's run - as .png and .pdf
    # ### NEEDS UPDATING - SAVE PATH #####################################
    # outStr = paste0('dailyMap_acoustics_', legID, '_ran', Sys.Date())
    # ggsave(filename = file.path(dir_msnaps, paste0(outStr, '.png')),
    #        height = height,
    #        width = width,
    #        plot = base_map_A,
    #        dpi = res,
    #        bg = 'white',
    #        device = 'png')
    # 
    # ggsave(filename = file.path(dir_msnaps, paste0(outStr, '.pdf')),
    #        height = height,
    #        width = width,
    #        plot = base_map_A,
    #        dpi = res,
    #        bg = 'white',
    #        device = 'pdf')
    cat('   saved', outStr, 'as .png and .pdf\n')
  } else {
    cat(' No new acoustic file, skipping acoustic detections map...\n')
  }
} # end genPlots TF trigger

# ------ Save dasList and close log  --------------------------------------

# if all ran ok, save updated dasList so these files won't be run again
# ### NEEDS UPDATING - DEAL WITH TWO DASLISTS ##############################
# if (data_source == 'gd'){ # only save if actual run, not test or blank
#   save(dasList, file = file.path(dir_wd, 'outputs', 
#                                  paste0('dasList_', projID, '.Rda')))
# }

cat('...run complete', format(Sys.time(), '%Y-%m-%d %H:%M:%S %Z'), '...\n')
sink()
