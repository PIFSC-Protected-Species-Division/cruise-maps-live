trackToGPX = function(et, outGPX){
  
  #' plotMap
  #' 
  #' description:
  #' 
  #' author: Selene Fregosi selene.fregosi [at] noaa.gov
  #' date: 27 July 2023
  #'
  #' @param et data.frame of effort as tracks, can be 'et' cumlative over a HICEAS
  #' leg or 'et' for just a single DAS
  #' @param outGPX fullpath filename to save
  #' example: outGPX = paste0('newEffortTracks_', y_l_s, '_', d$name, '_', Sys.Date(), '.gpx')
  #' 
  #' @return none, will write a file
  #' @export
  #' @examples
  #'  
  #'
  #'
  #'
  #'
  #'
  
  # Get et into a simplified longform format
  # clean up et to the essential cols
  etTrim = subset(et, select = c(Cruise, segnum, lat1, lon1, DateTime1, 
                                 lat2, lon2, DateTime2))
  
  # add a 'date' only column
  etTrim$date = date(et$DateTime1)
  # create a unique ID based on date and segnum
  etTrim$uid = paste0(etTrim$date, '_', etTrim$segnum)
  
  # reshape to long format with 'status' tag for start or end of each segment
  etLong = reshape(etTrim, direction = 'long',
                   idvar = 'uid',
                   ids = etTrim$uid,
                   varying = list(lat = c('lat1', 'lat2'),
                                  lon = c('lon1', 'lon2'),
                                  dt = c('DateTime1', 'DateTime2')),
                   # 'lon', 'DateTime') #,
                   # 'lat2', 'lon2', 'DateTime2')#,
                   v.names = c('lat', 'lon', 'DateTime'),
                   timevar = 'status',
                   times = c('start', 'end')
  )
  
  # reorder by segnum, and rearrange columns
  etLong = etLong[order(etLong$date, etLong$segnum), c(1, 4, 3, 2, 5:8)]
  
  # get info about segments for populating the GPX
  uidList = unique(etLong$uid)
  dateList = unique(etLong$date)
  
  # set up the GPX file header info
  # this is copied from a gpx file made using an online converter
  gpxHeader_xmlVer = '<?xml version="1.0" encoding="utf-8" standalone="yes"?>';
  # The websites and such might not be necessary...
  gpxHeader_gpxVer = paste('<gpx version="1.1" creator="R trackToGPX.R"', 
                           'xmlns="http://www.topografix.com/GPX/1/1"',
                           'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"',
                           'xsi:schemaLocation="http://www.topografix.com/GPX/1/1',
                           'http://www.topografix.com/GPX/1/1/gpx.xsd">')
  # metadata - other things could be added here.  
  gpxHeader_metadata = paste0('<metadata><bounds ', 
                              'minlat="', format(min(etLong$lat), nsmall = 6), '" ', 
                              'minlon="', format(min(etLong$lon), nsmall = 6), '" ',
                              'maxlat="', format(max(etLong$lat), nsmall = 6), '" ',
                              'maxlon="', format(max(etLong$lon), nsmall = 6), '"',
                              '/></metadata>')
  
  
  
  # start assembling the file contents, in 'o'
  o = c(gpxHeader_xmlVer, 
        gpxHeader_gpxVer, 
        gpxHeader_metadata
  )
  
  # loop through multiple days if it is the compiled data
  # set up the day (track)
  for (d in 1:length(dateList)){
    dt = as.character(dateList[d])
    dtIdx = which(etLong$date == dt)
    # how many segments for this day?
    segList = unique(etLong$segnum[dtIdx])
    
    # add to our output string
    o = c(o, '<trk>', 
          paste0('  <name>', 
                 etLong$Cruise[1], '_', dt,
                 '</name>'),
          paste0('  <desc>Vessel tracks for Cruise ',
                 etLong$Cruise[1], ', ', dt, ', ',
                 length(segList), ' total segments',
                 '</desc>')
    )
    
    # loop through each segment and write that line as a track segment
    for (i in 1:length(segList)){
      segNum = segList[i]
      o = c(o, '  <trkseg>')
      segIdx = which(etLong$segnum[dtIdx] == segNum)
      for (j in 1:2){
        o = c(o, 
              paste0('    <trkpt lat="', etLong$lat[dtIdx][segIdx][j], 
                     '" lon="', etLong$lon[dtIdx][segIdx][j],'">'), 
              paste0('      <time>', paste0(gsub(' ', 'T', as.character(
                etLong$DateTime[dtIdx][segIdx][j])), 'Z'),
                '</time>'), 
              '    </trkpt>')
      }
      o = c(o,
            # try some extra info about the segment
            # paste0('<date>', 
            #        etLong$date[which(etLong$segnum == segNum)[1]], 
            #        '</date>'),
            # paste0('<segnum>', 
            #        etLong$segnum[which(etLong$segnum == segNum)[1]], 
            #        '</segnum>'),
            '  </trkseg>'
      )
    }
    
    # wrap up this day (track) 
    o = c(o, '</trk>')
  }
  # wrap up the file 
  o = c(o, '</gpx>')
  
  # open the file, write it, and close it
  fileConn = file(outGPX)
  writeLines(o, fileConn)
  close(fileConn)
  
}
