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

# dasList filename to be modified
dasListFile = '~/GitHub/cruise-maps-live/outputs/dasList_OES2303.Rda'
# das file to be reprocessed
dasFile = 'DASALL.812'
modDateStr = '2023-08-12'

# compiled file names
epFile = '~/GitHub/cruise-maps-live/data/OES2303/compiledEffortPoints_OES2303.Rda'
etFile = '~/GitHub/cruise-maps-live/data/OES2303/compiledEffortTracks_OES2303.Rda'
vsFile = '~/GitHub/cruise-maps-live/data/OES2303/compiledSightings_OES2303.Rda'

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
# save this new dasList - change filename as needed
save(dasList, file = dasListFile)


# ------ Remove entries from compiled data.frames -------------------------

# --------- Effort as points ----------------------------------------------
load(epFile)
# edit out the bad row
ep$dateStr = format(lubridate::date(ep$DateTime), '%Y-%m-%d')
dateIdx = which(ep$dateStr == modDateStr)
if (length(dateIdx) != 0){
  ep = ep[-dateIdx,]
}
# save corrected file
save(ep, file = epFile)


# --------- Effort as tracks ----------------------------------------------
load(etFile)
# edit out the bad row
et$dateStr = format(lubridate::date(et$DateTime1), '%Y-%m-%d')
dateIdx = which(et$dateStr == modDateStr)
if (length(dateIdx) != 0){
  et = et[-dateIdx,]
}
# save corrected file
save(et, file = etFile)


# --------- Visual sightings ----------------------------------------------
load(vsFile)
# edit out the bad row
vs$dateStr = format(lubridate::date(vs$DateTime), '%Y-%m-%d')
dateIdx = which(vs$dateStr == modDateStr)
if (length(dateIdx) != 0){
  vs = vs[-dateIdx,]
}
# save corrected file
save(vs, file = vsFile)


# ------ Now go re-run the whole run.R script! ----------------------------


# now re-run whole script 