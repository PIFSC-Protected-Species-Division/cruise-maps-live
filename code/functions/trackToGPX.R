trackToGPX = function(dir_wd, et, etNew, outGPX){
  
  #' plotMap
  #' 
  #' description:
  #' 
  #' author: Selene Fregosi selene.fregosi [at] noaa.gov
  #' date: 27 July 2023
  #'
  #' @param dir_wd character string to the cruise-maps-live working directory
  #' @param et data.frame of effort as tracks, cumulative over a HICEAS leg
  #' @param etNew data.frame of effort as tracks, just new additions
  #' @param outGPX fullpath filename to save
  #' example: outGPX = paste0('newEffortTracks_', y_l_s, '_', d$name, '_', Sys.Date(), '.gpx')
  #' 
  #' @return outGPX output file name? data?  
  #' @export
  #' @examples
  #'  plotMap(dir, leg, ship, test_code=TRUE)
  #'
  #'
  #'
  #'
  #'
  
  # Get etNew into a simplified longform format
  # clean up etNew to the essential cols
  etNewTrim = subset(etNew, select = c(Cruise, segnum, lat1, lon1, DateTime1, 
                                       lat2, lon2, DateTime2, EffType, avgBft))
  # add a 'date' only column
  etNewTrim$date = date(etNew$DateTime1)
  
  # reshape to long format with 'status' tag for start or end of each segment
  etNewLong = reshape(etNewTrim, direction = 'long',
                      idvar = 'segnum',
                      ids = etNewTrim$segnum,
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
  etNewLong = etNewLong[order(etNewLong$segnum),c(1, 5, 2:3, 6, 9, 7:8, 4)]
  
  # get info about segments for populating the GPX
  segList = unique(etNewTrim$segnum)
  # numSegs = length(unique(etNewTrim$segnum))
  
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
                              'minlat="', format(min(etNewLong$lat), nsmall = 6), '" ', 
                              'minlon="', format(min(etNewLong$lon), nsmall = 6), '" ',
                              'maxlat="', format(max(etNewLong$lat), nsmall = 6), '" ',
                              'maxlon="',  format(max(etNewLong$lon), nsmall = 6), '"',
                              '/></metadata>')
  
  
  
  # start assembling the file contents, in 'o'
  o = c(gpxHeader_xmlVer, 
        gpxHeader_gpxVer, 
        gpxHeader_metadata
        )
  
  # set up the day (track)
  o = c(o, '<trk>', 
        paste0('  <name>', 
               etNewLong$Cruise[1], '_', etNewLong$date[1],
               '</name>'),
        paste0('  <desc>Vessel tracks for Cruise ',
               etNewLong$Cruise[1], ', ', etNewLong$date[1], ', ',
               length(segList), ' total segments',
               '</desc>')
  )
  
  # loop through each segment and write that line as a track segment
  
  for (i in 1:length(segList)){
    segNum = segList[i]
    o = c(o, '  <trkseg>')
    for (j in 1:2){
      o = c(o, 
            paste0('    <trkpt lat="', etNewLong$lat[which(etNewLong$segnum == segNum)[j]], 
                   '" lon="', etNewLong$lon[which(etNewLong$segnum == segNum)[j]],'">'), 
            paste0('      <time>', paste0(gsub(' ', 'T', as.character(
              etNewLong$DateTime[which(etNewLong$segnum == segNum)[j]])), 'Z'),
              '</time>'), 
            '    </trkpt>')
    }
    o = c(o,
          # try some extra info about the segment
          # paste0('<date>', 
          #        etNewLong$date[which(etNewLong$segnum == segNum)[1]], 
          #        '</date>'),
          # paste0('<segnum>', 
          #        etNewLong$segnum[which(etNewLong$segnum == segNum)[1]], 
          #        '</segnum>'),
          '  </trkseg>'
    )
  }
  
  # wrap up this day (track) and the file 
  o = c(o, '</trk>', '</gpx>')
  
  # open the file
  fileConn = file(outGPX)
  writeLines(o, fileConn)
  close(fileConn)
  
  
  # 
  # 
  # %% loop and write
  # % loop through each row of this table and write the data in the correct
  # % format
  # 
  # % each data point is a <wpt> in the gpx, with various extensions that have
  # % the date/time info
  # % ***does the indents matter??
  # 
  # for f = 1:height(t)
  #     fprintf(fid, '<wpt lat="%.15f" lon="%.15f">\n' , t.Lat(f), t.Lon(f));
  #         fprintf(fid, '<fix>%i</fix>\n', t.Fix(f));
  #         % these may be "bonus" info...may not need all of it?
  #         fprintf(fid, '<extensions>\n');
  #             fprintf(fid, '<ogr:UnitName>%s</ogr:UnitName>\n', t.UnitName{f});
  #             fprintf(fid, '<ogr:ReportTimeUTC>%s</ogr:ReportTimeUTC>\n', t.ReportTimeUTC{f});
  #             fprintf(fid, '<ogr:Lat>%.15f</ogr:Lat>\n', t.Lat(f));
  #             fprintf(fid, '<ogr:Lon>%.15f</ogr:Lon>\n', t.Lon(f));
  #             fprintf(fid, '<ogr:NumberOfSatellites>%i</ogr:NumberOfSatellites>\n', t.NumberOfSatellites(f));
  #             fprintf(fid, '<ogr:Altitude>%s</ogr:Altitude>\n', t.Altitude{f});
  #             fprintf(fid, '<ogr:Speed>%s</ogr:Speed>\n', t.Speed{f});
  #             fprintf(fid, '<ogr:Course>%s</ogr:Course>\n', t.Course{f});
  #             fprintf(fid, '<ogr:VerticalVelocity>%s</ogr:VerticalVelocity>\n', t.VerticalVelocity{f});
  #             fprintf(fid, '<ogr:HorizDilutionofPrecision>%.2f</ogr:HorizDilutionofPrecision>\n', t.HorizDilutionofPrecision(f));
  #             fprintf(fid, '<ogr:VertDilutionOfPrecision>%.2f</ogr:VertDilutionOfPrecision>\n', t.VertDilutionOfPrecision(f));
  #             fprintf(fid, '<ogr:Format>%s</ogr:Format>\n', t.Format{f});
  #             fprintf(fid, '<ogr:Motion>%i</ogr:Motion>\n', t.Motion(f));
  #             fprintf(fid, '<ogr:Version>%s</ogr:Version>\n', t.Version{f});
  #         fprintf(fid, '</extensions>\n');
  #     fprintf(fid, '</wpt>\n');   
  # end
  # 
  # fprintf(fid, '</gpx>\n');
  # 
  # % close the file
  # fclose(fid); % this "saves" it
  
  return()
}
