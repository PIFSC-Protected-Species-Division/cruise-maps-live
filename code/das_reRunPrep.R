#' ---------------------------
#' title: Prep compiled data to re-run a particular DAS file
#' authors: Selene Fregosi
#' purpose: 'roll-back' compiled data outputs and dasList of previously 
#' processed DAS files to force a re-run on a DAS file that has been updated 
#' or corrected by a cruise leader 
#' 
#' **TO BE USED MANUALLY BY CODE DEVELOPERS**
#' ---------------------------


# ------ File to be re-run ------------------------------------------------
# projID = 'OES2303'
projID = 'LSK2401'

# dasList filename to be modified
dasListFile = paste0('~/GitHub/cruise-maps-live/outputs/dasList_', projID, '.Rda')
# das file to be reprocessed
dasFile = 'DASALL.B02'
# modDateStr = '2023-08-12'

# compiled file names
epFile = file.path('~/GitHub/cruise-maps-live/data', projID, 
                   paste0('compiledEffortPoints_', projID, '.Rda'))
etFile = file.path('~/GitHub/cruise-maps-live/data', projID, 
                   paste0('compiledEffortTracks_', projID, '.Rda'))
vsFile = file.path('~/GitHub/cruise-maps-live/data', projID, 
                   paste0('compiledSightings_', projID, '.Rda'))
# adFile = '~/GitHub/cruise-maps-live/data/OES2303/compiledDetections_OES2303.Rda'

# ------ Remove from dasList ----------------------------------------------

# load existing dasList - change this filename as needed
load(dasListFile) 
# view the list of DAS files that have been processed
# View(dasList)
# find the index of the one to rerun and remove it
dasFileIdx = which(dasList$name == dasFile)
# if it isn't empty, remove that idx and save
if (length(dasFileIdx) != 0){
  dasList = dasList[-which(dasList$name == dasFile),]
}
# now remove the dateStr col
# save this new dasList - change filename as needed
save(dasList, file = dasListFile)


# ------ Remove entries from compiled data.frames -------------------------

# --------- Effort as points ----------------------------------------------
load(epFile)
# edit out the bad row
# ep$dateStr = format(lubridate::date(ep$DateTime), '%Y-%m-%d')
fileIdx = which(ep$file_das == dasFile)
if (length(fileIdx) != 0){
  ep = ep[-fileIdx,]
}

# remove temporary dateStr col
# ep = ep[,-which(names(ep) %in% 'dateStr')]

# save corrected file
save(ep, file = epFile)


# --------- Effort as tracks ----------------------------------------------
load(etFile)
# edit out the bad row
# et$dateStr = format(lubridate::date(et$DateTime1), '%Y-%m-%d')
fileIdx = which(et$file_das == dasFile)
if (length(fileIdx) != 0){
  et = et[-fileIdx,]
}
# save corrected file
save(et, file = etFile)


# --------- Visual sightings ----------------------------------------------
load(vsFile)
# edit out the bad row
# vs$dateStr = format(lubridate::date(vs$DateTime), '%Y-%m-%d')
fileIdx = which(vs$file_das == dasFile)
if (length(fileIdx) != 0){
  vs = vs[-fileIdx,]
}
# save corrected file
save(vs, file = vsFile)


# ------ Now go re-run the whole run.R script! ----------------------------


# now go re-run whole run.R script 
