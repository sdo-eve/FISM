'''
Created on Nov 17, 2011
Fetches NOAA Events records

@author: wilson
'''
from config_lisird import LISIRD_DATA_ROOT, NER_SOURCE, LISIRD_NER, NER_2019_SOURCE
from sys import exit
from os import path

class nerDataFetcher:
    
  _localRoot = None
  _source = NER_SOURCE
  _source2 = NER_2019_SOURCE
  _dest = LISIRD_NER

  _startYear = 1996
  _thisYear = None     # current year, tbd 

  _nerTrailingTarString = "_events.tar.gz"

  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def __init__(self):
      from util import getNowYear, appendSlash

      # Set up path pieces properly
      self._localRoot = appendSlash(LISIRD_DATA_ROOT)
      self._source    = appendSlash(NER_SOURCE)
      self._source2	  = appendSlash(NER_2019_SOURCE)
      self._dest      = appendSlash(LISIRD_NER)
      self._thisYear = getNowYear()
      
  # -----------------------------------------------------------------------------
  # Generates URL for fetching data
  # Handles change in swpc data directory structure: current year is different than prior years.
  # From http://www.swpc.noaa.gov/ftpdir/warehouse/README:
  # "The products and displays are organized in yearly sub-directories. In the
  # current year's directory, new products are added daily. For previous years,
  # the product and plot subdirectories are compressed and zipped for download."
  # -----------------------------------------------------------------------------
  def genSourceURLs(self, year):  
      import Date
       
      urls = []
      print "Fetching for year " + year
#      baseUrl = "http://www.swpc.noaa.gov/ftpdir/warehouse/" + year + "/" + year
      baseUrl = self._source + year + "/" + year
#      print "baseURL: " + baseUrl
      if (int(year) < self._thisYear):
          #For when 2019 is no longer the current year, special because of january
          #if (int(year) == 2019):
          #  baseUrl = self.source2 
          # For years prior to current year, the daily reports are provided in a tar file
          url = baseUrl + self._nerTrailingTarString
          urls.append(url)
          

      else:   # handle current year
          # 
          # For current year the daily reports are in a dir called <currentYear>/<currentYear>_events.
          # does not have 1/1/2019-1/25/2019
          # (And there is no tar.gz file.)
          # So get all days of year up until now
          today = Date.Date()
#          print "Today is " + str(today)
          #if the current year is 2019 for special january
          #if (self._thisYear >= 2019):
          #  baseUrl = self._source2
          # Most recent complete version seems to be three days behind today.
          mostRecentFinalVersion = today - 3
          mostRecentFinalVersionTT = mostRecentFinalVersion.ToTimeTuple()
#          print "Most recent final version is " + str(mostRecentFinalVersionTT)
          
          # Cycle through every day 
          # Fetch X days worth of daily files, where X is today's day of year.
          # But, shift the days fetched by data lag time.
          # This is appropriate because the swpc web site places the last three days of the prior
          # year in the current year (the appropriateness of which is debatable).
          # (And, yes, those three files are repeated in the their own year dir too.)
          # (Who designed this scheme????)
          dayCnt = today.GetYearDay()
#          print "today's day of year is " + str(dayCnt)
          print "Fetching daily files for " + str(dayCnt) + " days"
          for day in range(dayCnt):
              # Simpler to go backwards.  
              date = mostRecentFinalVersion - day
              dateTT = date.ToTimeTuple()
              # if we're straying back past the current year then stop because
              # we'll have already retrieve the tar file
              year = dateTT[0]
              if year < self._thisYear:
                break
              y = str(dateTT[0]).rjust(2, '0')
              m = str(dateTT[1]).rjust(2, '0')
              d = str(dateTT[2]).rjust(2, '0')
              ymdStr = y + m + d    
              # Daily files are named yyyy_events/yyyymmddevents.txt
              url = baseUrl + "_events/" + ymdStr + "events.txt"
              #if (self._thisYear == 2019):
              #  url = baseUrl + ymdStr + "events.txt" 
              
              urls.append(url)
#              print url
      return urls

  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def getTarDest(self, year):
      return self._localRoot + self._dest + year + "_events.tar.gz"
  
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def getFileDest(self, year, fileName):
      return self._localRoot + self._dest + year + "_events/" + fileName
  
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def getFileNameFromURL(self, url):
      import urlparse
      
      path = urlparse.urlsplit(url)[2]
      fileName = path[path.rfind("/") + 1:]
      return fileName
  
  # -----------------------------------------------------------------------------
  # Fetchs data and places in destination
  # -----------------------------------------------------------------------------
  def get(self, previewOnly):  
      from util import readHTTP, unTar, deleteTar, ensurePath, getDir
      from config import SUCCESS, FAILURE
      
      years = range(self._startYear, self._thisYear + 1)   # range is not inclusive of end point
      print "Fetching files for years: " + str(years)
       
      allFetchesSuccesful = True 
      for iyear in years:
          print "-----"
          year = str(iyear)
          sourceURLs = self.genSourceURLs(year)
          
          for url in sourceURLs:              
#            print 'Fetching: ' + url   
            if  url.endswith(".tar.gz"):             # it's a tar file  
                destination = self.getTarDest(year)
                exists = path.isdir(destination[:-7]) #check if file already exists
                #print exists
                if exists:
                    print  destination[:-7] + ' already exists, checking next'
                else:
                    ensurePath(getDir(destination), previewOnly)
                    print 'Writing: ' + destination  
                    if not previewOnly:
                            if readHTTP(url, destination) == SUCCESS: 
                                unTar(destination)
                                deleteTar(destination)
                            else:
                                print "Failed to retrieve URL: " + url  
                                allFetchesSuccesful = False
                
            elif url.endswith(".txt"):               # it's a .txt file   
                fileName = self.getFileNameFromURL(url)
                destination = self.getFileDest(year, fileName) 
                exists = path.isfile(destination) #check if the file already exists
                #print exists
                if exists:
                    print destination + ' already exists, checking next'    
                else:
                    ensurePath(getDir(destination), previewOnly)
                    print 'Writing: ' + destination  
                    if not previewOnly:
                        if readHTTP(url, destination) != SUCCESS: 
                            print "Failed to retrieve URL: " + url  
                            allFetchesSuccesful = False                    
            else:                                 # it's an abomination!
                print "ERROR, unrecognized file type " + url          
                allFetchesSuccesful = False
                                
      if allFetchesSuccesful:
          return SUCCESS
      else:
          return FAILURE        

# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------
if __name__ == '__main__':
    from config import SUCCESS, FAILURE
        
    previewOnly = False
    x = nerDataFetcher()
    if x.get(previewOnly) != SUCCESS:
        # for now, not calling missing 2014_events.tar an error.  1/20/15
        # print "Problem encountered in reading NOAA event reports.  Aborting."
        print "Problem encountered in reading NOAA event reports."
        # exit(1)
