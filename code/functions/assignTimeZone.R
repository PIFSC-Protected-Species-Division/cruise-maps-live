assignTimeZone = function(df_proc, shipCode, tzKeyFile){
  
  #' assignTimeZone
  #' 
  #' @description Update the timezone from a processed das file (processed with
  #' sfwscDAS::das_process). DAS files are recorded in local time, but when read
  #' into R they are defined as UTC. For consistency across data streams we want
  #' to have the correct time zone. 
  #' 
  #' author: Selene Fregosi selene.fregosi [at] noaa.gov
  #' date: 14 August 2023
  #'
  #' @param df_proc processed das file (with swfscDAS::das_process)
  #' @param shipCode three letter code for ship name (OES or LSK)
  #' @param tzKeyFile full path file name to the manually created csv that has 
  #' a record of which days the ship is in which time zone (either HST or SST)
  #' 
  #' @return df_proc but with the correct time zone
  #'
  #' @examples
  #' df_prof = assignTimeZone(df_proc, file.path(dir_wd, 'inputs', "TimeZones.csv"))
  #' 
  #' ######################################################################
  
  # read in the key and convert to 'dates'
  tzKey = read.csv(tzKeyFile)
  # looking for two possible formats, that might need to be expanded later
  tzKey$StartDate = as.Date(tzKey$StartDate, 
                            if (grepl('^\\d+/\\d+/\\d+$', tzKey$StartDate[1])) 
                              '%m/%d/%Y' else '%Y-%m-%d')
  tzKey$EndDate = as.Date(tzKey$EndDate, 
                          if (grepl('^\\d+/\\d+/\\d+$', tzKey$EndDate[1])) 
                            '%m/%d/%Y' else '%Y-%m-%d')
  
  # pull just the date for the first entry in this DAS file
  dateCheck = lubridate::date(df_proc$DateTime[1])
  
  # narrow down the key to only this ship
  tzKeyS = tzKey[which(tzKey$Ship == shipCode),]
  # find the correct entry
  tzStr = tzKeyS$TimeZone[which(dateCheck >= tzKeyS$StartDate & 
                                  dateCheck <= tzKeyS$EndDate)]
  # update df_proc
  df_proc$DateTime = lubridate::force_tz(df_proc$DateTime, tzStr)
  
  return(df_proc)
  
  }