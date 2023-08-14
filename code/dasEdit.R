#' ---------------------------
#' title: Manually edit DAS errors
#' authors: Selene Fregosi
#' purpose: modify existing processed DAS files that may contain small errors 
#' that are affecting plotting and summary tables
#' 
#' **TO BE USED MANUALLY BY CODE DEVELOPERS**
#' ---------------------------

# ------ USER INPUTS/SETUP STUFF ------------------------------------------

crNum = 2303
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
dir_gd_raw_pam <- googledrive::as_id('1hevcdNvX_EpdYGXmWHQU5W-a04EL4FVX')

# set working directory
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

# Define local output paths
dir_data = file.path(dir_wd, 'data', projID)                      # outer 'data' folder
dir_gd_dwnl = file.path(dir_wd, 'data', projID, 'gd_downloads')   # gd downloads
dir_snaps = file.path(dir_wd, 'data', projID, 'snapshots')        # data snapshots
dir_gpx = file.path(dir_wd, 'data', projID, 'gpx')                # gpx files
dir_tsnaps = file.path(dir_wd, 'outputs', 'table_archive', legID) # table snapshots - saved by leg
dir_msnaps = file.path(dir_wd, 'outputs', 'map_archive', legID)   # map snapshots - saved by leg

# sign in to google drive
googledrive::drive_deauth()
googledrive::drive_auth()
# push through authorization approval
2 # this may need to change??

library(raster)
library(tidyverse)


# ------ MAKE MANUAL CHANGES ----------------------------------------------

# Below are some suggested code for types of edits we may need to make

# ###### Changes to DAS directly ######

# first manually make a copy of the original with '_original' appended to the name
# then manually remove or modify the bad line in a text editor

# then, re specify the file and reprocess (DO NOT RE-DOWNLOAD)
dasName = 'DASALL.813'
dasFile = paste0('~/github/cruise-maps-live/data/OES2303/gd_downloads/', dasName)
editedDay = 13
editedDayStr = as.character(editedDay)

df_check = swfscDAS::das_check(dasFile, skip = 0, print.cruise.nums = FALSE)
df_read = swfscDAS::das_read(dasFile, skip = 0)
df_proc = swfscDAS::das_process(dasFile)
# update time zone
# update time zone
source(file.path(dir_wd, 'code', 'functions', 'assignTimeZone.R'))
df_proc = assignTimeZone(df_proc, shipCode, file.path(dir_wd, 'inputs', 
                                                      'TimeZones.csv'))
# View(df_proc)

# save copy of new df_proc
outName = paste0('processedDAS_', legID, '_', dasName, '_ran', 
                 Sys.Date(), '.Rda')
save(df_proc, file = file.path(dir_snaps, outName))


# ###### Changes to ep dataframe ######

# # first tackle epNew
# # load the file of interest
# load("~/GitHub/cruise-maps-live/data/OES2303/snapshots/newEffortPoints_OES2303_leg2_DASALL.805_ran2023-08-06.Rda")
# # create a backup variable
# epNewOrig = epNew
# # save a backup '_original'
# save(epNew, file = "~/GitHub/cruise-maps-live/data/OES2303/snapshots/newEffortPoints_OES2303_leg2_DASALL.805_ran2023-08-06_original.Rda")
# 
# # edit out the bad row
# epNew = epNew[-which(epNew$line_num == 297 & epNew$leg == 2 & 
#                        format(epNew$DateTime, format = "%d") == '05'),]
# 
# # save corrected file
# save(epNew, file = "~/GitHub/cruise-maps-live/data/OES2303/snapshots/newEffortPoints_OES2303_leg2_DASALL.805_ran2023-08-06.Rda")
# 
# # then tackle ep
# load("~/GitHub/cruise-maps-live/data/OES2303/compiledEffortPoints_OES2303.Rda")
# # create a backup variable
# epOrig = ep
# # edit out the bad row
# ep = ep[-which(ep$line_num == 297 & ep$leg == 2 & 
#                        format(ep$DateTime, format = "%d") == '05'),]
# # save corrected file
# save(ep, file = "~/GitHub/cruise-maps-live/data/OES2303/compiledEffortPoints_OES2303.Rda")


# ------ RE-RUN WHAT NEEDS TO BE RE-RUN -----------------------------------

# load any data.frames that don't need to be re-run
# visual sightings
load("~/GitHub/cruise-maps-live/data/OES2303/compiledSightings_OES2303.Rda")
# acoustic detections
load("~/GitHub/cruise-maps-live/data/OES2303/compiledDetections_OES2303.Rda")

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
outName = paste0('newEffortTracks_', legID, '_', dasName, '_ran', 
                 Sys.Date(), '.Rda')
save(etNew, file = file.path(dir_snaps, outName))
googledrive::drive_put(file.path(dir_snaps, outName), path = dir_gd_snaps)

# load the old compiled data.frame
outName = paste0('compiledEffortTracks_', projID, '.Rda')
load(file.path(dir_data, outName))
# clear the edited day and add on etNew
et = et[-which(et$day == editedDay),]
et = rbind(et, etNew)
et = unique(et)                 # remove duplicates (in case ran already)
et = et[order(et$DateTime1),]   # sort in case out of order

save(et, file = file.path(dir_data, outName))
googledrive::drive_put(file.path(dir_data, outName), path = dir_gd_proc)
outNameCSV = paste0('compiledEffortTracks_', projID, '.csv')
write.csv(et, file = file.path(dir_data, outNameCSV))
googledrive::drive_put(file.path(dir_data, outNameCSV), path = dir_gd_proc)

# ------ Create GPX from track data ---------------------------------------
source(file.path(dir_wd, 'code', 'functions', 'trackToGPX.R'))
# by day/das tracks
outGPX = file.path(dir_gpx, paste0('effortTracks_', legID, '_', dasName, 
                                   '.gpx'))
trackToGPX(etNew, outGPX)
googledrive::drive_put(file.path(outGPX), path = dir_gd_gpx)
# compiled tracks
outGPX = file.path(dir_gpx, paste0('compiledEffortTracks_', projID, '.gpx'))
trackToGPX(et, outGPX)
googledrive::drive_put(file.path(outGPX), path = dir_gd_gpx)

# ------ Parse track data as points ---------------------------------------
source(file.path(dir_wd, 'code', 'functions', 'parseTrack_asPoints.R'))
epNew = parseTrack_asPoints(df_proc)

# add on some ship info
epNew$shipCode = shipCode
epNew$shipName = shipName
epNew$projID = projID
epNew$leg = leg

# save a 'snapshot' of the data for this run
outName = paste0('newEffortPoints_', legID, '_', dasName, '_ran', 
                 Sys.Date(), '.Rda')
save(epNew, file = file.path(dir_snaps, outName))
googledrive::drive_put(file.path(dir_snaps, outName), path = dir_gd_snaps)

# load the old compiled data.frame
outName = paste0('compiledEffortPoints_', projID, '.Rda')
load(file.path(dir_data, outName))
# clear the edited day and add on etNew
ep = ep[-which(format(ep$DateTime, format = '%d') == editedDayStr),]
ep = rbind(ep, epNew)
ep = unique(ep)
ep = ep[order(ep$DateTime),]

save(ep, file = file.path(dir_data, outName))
googledrive::drive_put(file.path(dir_data, outName), path = dir_gd_proc)
outNameCSV = paste0('compiledEffortPoints_', projID, '.csv')
write.csv(ep, file = file.path(dir_data, outNameCSV))
googledrive::drive_put(file.path(dir_data, outNameCSV), path = dir_gd_proc)



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
outName = paste0('newSightings_', legID, '_', dasName, '_ran', Sys.Date(), 
                 '.Rda')
save(vsNew, file = file.path(dir_snaps, outName))
googledrive::drive_put(file.path(dir_snaps, outName), path = dir_gd_snaps)
cat('   saved', outName, '\n')

# combine the old vs dataframe with the new one
outName = paste0('compiledSightings_', projID, '.Rda')
# load old if it exists
load(file.path(dir_data, outName))
# clear the edited day and add on etNew
vs = vs[-which(format(vs$DateTime, format = '%d') == editedDayStr),]
vs = rbind(vs, vsNew)
vs = unique(vs)
vs = vs[order(vs$DateTime),]


save(vs, file = file.path(dir_data, outName))
googledrive::drive_put(file.path(dir_data, outName), path = dir_gd_proc)
outNameCSV = paste0('compiledSightings_', projID, '.csv')
write.csv(vs, file = file.path(dir_data, outNameCSV))
googledrive::drive_put(file.path(dir_data, outNameCSV), path = dir_gd_proc)
cat('   saved', outName, 'and as .csv\n')

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

