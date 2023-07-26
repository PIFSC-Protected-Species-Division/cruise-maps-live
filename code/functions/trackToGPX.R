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

# ORIGINAL MATLAB CODE
# %% create gpx output file
# fid = fopen([path_in fileName(1:end-4) '.gpx'], 'w');
# % this will overwrite any previous file with this name
# 
# %% write header info
# % copied from gpx file made using online coverter
# 
# gpxHeader_xmlVer = '<?xml version="1.0"?>';
# fprintf(fid, '%s\n', gpxHeader_xmlVer);
# 
# % I might not need all of this - e.g., the web site...but just copied here
# gpxHeader_gpxVer = ['<gpx version="1.1" ' ...
#     'creator="GDAL 2.2.2" ' ... 
#     'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' ...
#     'xmlns:ogr="http://osgeo.org/gdal" ' ...
#     'xmlns="http://www.topografix.com/GPX/1/1" ' ...
#     'xsi:schemaLocation="http://www.topografix.com/GPX/1/1 ' ...
#     'http://www.topografix.com/GPX/1/1/gpx.xsd">'];  
# fprintf(fid, '%s\n', gpxHeader_gpxVer);
# 
# % metadata - other things could be added here.  
# fprintf(fid, ['<metadata><bounds minlat="%.15f" minlon="%.15f" ' ...
#     'maxlat="%.15f" maxlon="%.15f"/></metadata>\n'], min(t.Lat), min(t.Lon), max(t.Lat), max(t.Lon));
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
    