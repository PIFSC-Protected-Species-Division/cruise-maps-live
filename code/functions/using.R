using <- function(...){
  
  #' using
  #' 
  #' description: function to search/install/load needed packages
  #' 
  #' author: Janelle Badger janelle.badger [at] noaa.gov
  #' date: 30 June 2023
  #'
  #' @param #none
  #' @return #none
  #'
  #' @examples 
  #' using('raster')
  #' 
  #' ######################################################################
  
  libs<-unlist(list(...))
  req<-unlist(lapply(libs,require,character.only=TRUE))
  need<-libs[req==FALSE]
  n<-length(need)
  if(n>0){
    libsmsg<-if(n>2) paste(paste(need[1:(n-1)],collapse=", "),",",sep="") else need[1]
    print(libsmsg)
    if(n>1){
      libsmsg<-paste(libsmsg," and ", need[n],sep="")
    }
    libsmsg<-paste("The following packages could not be found: ",libsmsg,"\n\r\n\rInstall missing packages?",collapse="")
    if(winDialog(type = c("yesno"), libsmsg)=="YES"){       
      install.packages(need)
      lapply(need,require,character.only=TRUE)
    }
  }
}
  
