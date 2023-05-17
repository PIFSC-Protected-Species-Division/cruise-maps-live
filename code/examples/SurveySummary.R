#**********************************************************************************************
#	Programmer: Amanda Bradford
#	Project Name: Effort and sighting summaries from DAS data
#	Date: 1 August 2021
#	Comments: This program refines output from the package 'swfscDAS' to get effort and sighting
# summaries in a more streamlined form, primarily for the purpose of mapping. The code can be
# easily modified to further refine or reformat the summaries. While multiple surveys can be
# combined in a DAS file, I'd recommend doing summaries by survey for now because 'swfscDAS' 
# can get tripped up on DAS file errors and inconsistencies that can be hard to troubleshoot.
#**********************************************************************************************

#Call necessary libraries
library(dplyr)
library(stringr)
library(swfscDAS)

#Specify the survey, making sure the DAS file has the same name
survey <- '2020WHICEAS'

#Check, read, and process the DAS file in swfscDAS
y <- paste(survey, ".das", sep = "")
head(readLines(y))
y.check <- das_check(y, skip = 0, print.cruise.nums = TRUE)
y.read <- das_read(y, skip = 0)
y.proc <- das_process(y) #comment out this line for 2010TRANSIT and use the following code instead

#The following addresses a DAS oddity in 2010TRANSIT (second leg conducted in UTC), comment out after use
#library(lubridate)
#Keep <- y.read$DateTime[1:3481]
#Plus10 <- as.POSIXct(format(y.read$DateTime[3482:4470], tz="Pacific/Guam", usetz=TRUE), tz="Pacific/Guam")
#Plus10 <- force_tz(Plus10, "UTC") #need to force reformatted times to be in UTC timezone because swfscDAS doesn't
#assign timezones, so local date and times, while correct, are assigned UTC by default and you can't combine multiple
#time zones in a column - the rest of the times default to the time zone of the first element, so all the work
#reformatting for Leg 2 would be undone unless the corrected local times were forced to be UTC
#Plus11 <- as.POSIXct(format(y.read$DateTime[4471:4758], tz="Pacific/Pohnpei", usetz=TRUE), tz="Pacific/Pohnpei")
#Plus11 <- force_tz(Plus11, "UTC")
#Plus12 <- as.POSIXct(format(y.read$DateTime[4759:6216], tz="Pacific/Wake", usetz=TRUE), tz="Pacific/Wake")
#Plus12 <- force_tz(Plus12, "UTC")
#Minus11 <- as.POSIXct(format(y.read$DateTime[6217:6516], tz="Pacific/Midway", usetz=TRUE), tz="Pacific/Midway")
#Minus11 <- force_tz(Minus11, "UTC")
#Minus10 <- as.POSIXct(format(y.read$DateTime[6517:7820], tz="Pacific/Honolulu", usetz=TRUE), tz="Pacific/Honolulu")
#Minus10 <- force_tz(Minus10, "UTC")
#NewDateTime <- c(Keep, Plus10, Plus11, Plus12, Minus11, Minus10)
#y.read$DateTime <- NewDateTime
#y.proc <- das_process(y.read) #can also process files from the read file, necessary in this case

#Get summary of effort segments using "section" method, where each segment is a full continuous 
#effort section (i.e., it runs from an R event to an E event) and trim unwanted columns
y.eff <- das_effort(y.proc, method = "section", dist.method = "greatcircle", num.cores = 1)
y.eff.seg <- y.eff$segdata
y.eff.seg.sub <- subset(y.eff.seg, select = c(Cruise, segnum, stlin:mtime, Mode, EffType, avgSpdKt, avgBft))
write.csv(y.eff.seg.sub, file = paste (survey, "_EffSegs.csv", sep = ""), row.names = FALSE)

#Using the above as a point of reference, now refine and reformat processed data into point data by effort 
#segment, so that points can be made into a line for mapping
y.proc.sub <- subset(y.proc, select = c(line_num, Cruise, Event, DateTime, Lat, Lon, Mode, OnEffort, EffortDot, 
                                        EffType, SpdKt, Bft))
for(i in 1:length(y.proc.sub$line_num)) { #technically on-effort when E entered, consistent with segmenting
  if (y.proc.sub$Event[i]=="E")
  {y.proc.sub$OnEffort[i] <- TRUE}
}

y.proc.sub$LineID <- 0
linecounter <- 1
for(i in 1:length(y.proc.sub$line_num)) { #add segment numbers for continuous effort segments
  if (y.proc.sub$OnEffort[i]=="TRUE" & y.proc.sub$Event[i]=="R")
  {y.proc.sub$LineID[i] <- linecounter}
  else if (y.proc.sub$OnEffort[i]=="TRUE" & y.proc.sub$Event[i]!="E")
  {y.proc.sub$LineID[i] <- linecounter}
  else if (y.proc.sub$OnEffort[i]=="TRUE" & y.proc.sub$Event[i]=="E") {
    y.proc.sub$LineID[i] <- linecounter
    linecounter <- linecounter + 1
  }
}
y.proc.sub.lines <- subset(y.proc.sub, LineID > 0) #remove off-effort lines
y.proc.sub.lines <- subset(y.proc.sub.lines, Event != "B") #remove Begin effort lines, as not needed
y.proc.sub.lines <- subset(y.proc.sub.lines, Event != "C") #remove Comment lines to remove NA lat/lon values
write.csv(y.proc.sub.lines, file = paste (survey, "_EffLines.csv", sep = ""), row.names = FALSE)

#Finally, get list of sightings by species (i.e., mixed species sightings have a line per species ) with 
#lat/lon and relevant info
y.sight <- das_sight(y.proc, return.format = "default")
y.sight.S <- subset(y.sight, Event=="S") #remove resight or subgroup info
y.sight.S <- subset(y.sight.S, SpCode != "AT" & SpCode != "CU" & SpCode != "CU" & SpCode != "MA" & SpCode != "PU" 
                    & SpCode != "UA" & SpCode != "UO" & SpCode != "ZC" & SpCode != "MS") #remove non-cetacean sightings
y.sight.S.sub <- subset(y.sight.S, select = c(line_num, Cruise, DateTime, SightNo, Lat, Lon, OnEffort, EffortDot,
                                              EffType, SpdKt, Bft, nSp, Mixed, SpCode, SpCodeProb, GsSchoolBest,
                                              GsSpBest, PerpDistKm))
#The following addresses a das file issue in 2005PICEAS, comment out after use
#y.sight.S.sub$Cruise <- 1629 
write.csv(y.sight.S.sub, file = paste (survey, "_Sights.csv", sep = ""), row.names = FALSE)
