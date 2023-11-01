extractAcousticDetections <- function(pamFile){
  
  #' pull acoustic detections from Pamguard sql
  #'
  #' @description Read in PAM sql database and extract the acoustic detections.
  #' Species IDs are simplified using a decision tree that steps through several
  #' choices based on visual vs acoustic IDs and what ID type. The detections 
  #' are then cleaned up in a data.frame output to be used in the summary table
  #' and map. 
  #' 
  #' author: Selene Fregosi selene.fregosi [at] noaa.gov
  #' date: 01 August 2023
  #' 
  #' @param pamFile full file path to downloaded Pamguard sql file
  #' @return ad data.frame of acoustic detections with cols...
  #'
  #' @examples
  #' 
  #' ######################################################################
  
  # check that is sqlite file
  isSqlite = grepl("\\.sqlite3$", pamFile)
  if (!isSqlite){
    stop('Not an SQLite file, check Google Drive!')
  }
  
  bwList = c(49, 51, 57, 59, 61, 63, 65)
  unidDolpList = c(77, 177, 277, 377)
  
  # open database and list all tables
  db = DBI::dbConnect(RSQLite::SQLite(), pamFile)
  # tblList = dbListTables(db)
  
  # set up combined detection table
  colNames = c('ac_id', 'UTC', 'vis_id', 'lat', 'lon', 'class1', 'cl1_sp1', 
               'class2', 'cl2_sp1', 'sp_map')
  
  dtCmb = setNames(data.frame(matrix(ncol = length(colNames), nrow = 0)), colNames)
  
  # loop through the three 'Detection' tables and combine
  for (d in 1:3){
    # read in table
    dt = DBI::dbReadTable(db, paste0('Detection', d))
    
    # if not empty, process
    if (nrow(dt) != 0){
      
      # pull just cols needed - not necessary step but easier to view
      dtTmp = data.frame(dt$ac_id, dt$UTC, dt$vis_id, dt$date_time_start, 
                         dt$date_time_end, dt$latlong_LAT, dt$latlong_LON,
                         dt$class1, dt$species1_class1, dt$class2, 
                         dt$species1_class2, dt$Comment)
      colnames(dtTmp) = c('ac_id', 'UTC', 'vis_id', 'date_time_start', 
                          'date_time_end', 'Lat', 'Lon', 'class1', 'cl1_sp1', 
                          'class2', 'cl2_sp1', 'comment')
      # clean up extra spaces out of some cols
      dtTmp$class1 = stringr::str_trim(dtTmp$class1)
      dtTmp$cl1_sp1 = stringr::str_trim(dtTmp$cl1_sp1)
      dtTmp$class2 = stringr::str_trim(dtTmp$class2)
      dtTmp$cl2_sp1 = stringr::str_trim(dtTmp$cl2_sp1)
      
      # add column for sp for mapping
      dtTmp$sp_map = NA
      # work through decision tree to come up with 'final' species code for map
      for (s in 1:nrow(dtTmp)){
        spTmp = NA
        
        # SELECT ACOUSTIC VS VISUAL ID 
        # if there is a visual ID...
        if (dtTmp$vis_id[s] != '999'){
          # pull out visual and acoustic IDs
          idOpts = c(dtTmp$class1[s], dtTmp$class2[s])
          spOpts = c(dtTmp$cl1_sp1[s], dtTmp$cl2_sp1[s])
          
          # if no Acoustic ID, use visual
          if (!('AT' %in% idOpts)){
            spTmp = spOpts[which(idOpts == 'V')]
          }
          
          # if there IS an acoustic ID
          if ('AT' %in% idOpts){
            # and its a beaked whale use acoustic ID
            if (spOpts[which(idOpts == 'AT')] %in% bwList){
              spTmp = spOpts[which(idOpts == 'AT')]
              # if not a beaked whale species, use visual ID
            } else {spTmp = spOpts[which(idOpts == 'V')]}
          }
        }
        
        # if no visual ID... use acoustic ID but simplify to allowable (JLKM) 
        if (dtTmp$vis_id[s] == '999' && dtTmp$class1[s] == 'AT'){ 
          
          # if acoustic ID is a beaked whale species, use acoustic ID as is
          if (dtTmp$cl1_sp1[s] %in% bwList){
            spTmp = dtTmp$cl1_sp1[s]
            
            # if acoustic ID is sperm whale, use acoustic ID as is
          } else if (dtTmp$cl1_sp1[s] == '46'){
            spTmp = dtTmp$cl1_sp1[s]
            
            # if acoustic ID is unid dolphin, use acoustic ID as is
            # (alternatively could collapse these all to 77)
          } else if (dtTmp$cl1_sp1[s] %in% unidDolpList){
            spTmp = dtTmp$cl1_sp1[s]
            
            # anything else (e.g., pilot whales, fkw, etc) call unid dolphin
          } else {
            spTmp = '77'
          }
        }
        
        # Check for BWC noted in comments
        if (grepl("BWC", dtTmp$comment[s])){
          spTmp = '949'
        }
        
        # occasionally get warning bc there are two visual ids. Just take first. 
        # tryCatch({dtTmp$sp_map[s] = spTmp}, warning = function(w) print(s))
        dtTmp$sp_map[s] = spTmp
      } # loop through all detection rows
      
      dtCmb = rbind(dtCmb, dtTmp)
    } # empty dt check
    
  } # loop through 3 detection tables
  
  DBI::dbDisconnect(db)
  
  # clean up output ad data.frame
  # sort by time
  ad = dtCmb[order(dtCmb$UTC),]
  # times are just character - convert to DateTimes and set time zone to UTC
  ad$UTC = as.POSIXct(ad$UTC, tz = 'UTC')
  ad$date_time_start = as.POSIXct(ad$date_time_start, tz = 'UTC')
  ad$date_time_end = as.POSIXct(ad$date_time_end, tz = 'UTC')
  
  return(ad)
  
}
