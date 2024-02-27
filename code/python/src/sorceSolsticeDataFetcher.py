
from config import SUCCESS
from util import ensurePath, appendSlash
from URLFetcher import URLFetcher
from config_lisird import LISIRD_DATA_ROOT, SORCE_SOLSTICE_DAILY_SOURCE, LISIRD_SORCE_SOLSTICE_DIR
from os import path

import sys

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
class sorceSolsticeDataFetcher:

  # From the configuration
  _localRoot = None
  _source = SORCE_SOLSTICE_DAILY_SOURCE
  _dest = LISIRD_SORCE_SOLSTICE_DIR
  
  _startYear = 2003
  _endYear  = 2020     # SORCE mission ended in 2020
  _thisYear = None     # current year, tbd 
  
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def __init__(self):
      from util import getNowYear, appendSlash

      self._localRoot   = appendSlash(LISIRD_DATA_ROOT)
      self._sorce       = appendSlash(SORCE_SOLSTICE_DAILY_SOURCE)
      self._dest        = appendSlash(LISIRD_SORCE_SOLSTICE_DIR)
      self._thisYear    = getNowYear()
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------  
  def genSourceURLs(self, year):  
      #for solstice data
      import Date
        
      urls = []
      print "Fetching for year " + year

      url = self._source + year + ".nc"
      urls.append(url)

      return urls
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def getSource(self, dataset):
      return self._source + dataset

  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def getFileDest(self, year, fileName):
      return self._localRoot + self._dest + fileName
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def getFileNameFromURL(self, url):
      import urlparse
      
      path = urlparse.urlsplit(url)[2]
      fileName = path[path.rfind("/") + 1:]
      return fileName
  
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def get(self, previewOnly): 
      from util import readHTTP, ensurePath, getDir
      from config import SUCCESS, FAILURE

      years = range(self._startYear, self._endYear + 1) #self._thisYear + 1)
      print "Fetching files for years: " + str(years)

      allFetchesSuccessful = True
      for iyear in years:
          print "-----"
          year = str(iyear)
          sourceURLs = self.genSourceURLs(year) 
          for url in sourceURLs:
              fileName = self.getFileNameFromURL(url)
              destination = self.getFileDest(year, fileName)
              exists = path.isfile(destination)
              if exists:
                print destination + ' already exists, checking next'
              else:
                ensurePath(getDir(destination), previewOnly)
                print 'Writing: ' + destination  
                if not previewOnly:
                  if readHTTP(url, destination) != SUCCESS: 
                      print "Failed to retrieve URL: " + url  
                      allFetchesSuccesful = False              
      
      return SUCCESS
      

# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------
if __name__ == '__main__':
    from config import SUCCESS, FAILURE
    previewOnly = False
    print "================================= SOLSTICE files ====="

    previewOnly = False
    x = sorceSolsticeDataFetcher()   
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching SORCE SOLSTICE files.  Aborting."
        sys.exit(1)
        
    

