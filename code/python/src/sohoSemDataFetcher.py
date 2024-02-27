from config import SUCCESS
from util import ensurePath, appendSlash
from URLFetcher import URLFetcher
from config_lisird import LISIRD_DATA_ROOT, SEM_SOURCE, LISIRD_SEM
from os import path

import sys

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
class sohoSemDataFetcher:

  # From the configuration
  _localRoot = None
  _source = SEM_SOURCE
  _dest = LISIRD_SEM
  
  _startYear = 1996
  _thisYear = None     # current year, tbd 
  
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def __init__(self):
      from util import getNowYear, appendSlash

      self._localRoot   = appendSlash(LISIRD_DATA_ROOT)
      self._sorce       = appendSlash(SEM_SOURCE)
      self._dest        = appendSlash(LISIRD_SEM)
      self._thisYear    = getNowYear()
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------  
  def genSourceURLs(self, year):  
      #for solstice data
      import Date
        
      urls = []
      print "Fetching for year " + year
      yrstr = str(year)
      yrport = yrstr[2:4]
      url = self._source + yrport + "_v3.day.txt"
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

      years = range(self._startYear, self._thisYear + 1)
      print "Fetching files for years: " + str(years)

      allFetchesSuccessful = True
      for iyear in years:
          print "-----"
          year = str(iyear)
          sourceURLs = self.genSourceURLs(year) 
          for url in sourceURLs:
              if iyear == self._thisYear:
                fileName = self.getFileNameFromURL(url)
                destination = self.getFileDest(year, fileName)
                ensurePath(getDir(destination), previewOnly)
                print 'Writing: ' + destination  
                if not previewOnly:
                    if readHTTP(url, destination) != SUCCESS: 
                        print "Failed to retrieve URL: " + url  
                        allFetchesSuccesful = False          
              else:
                fileName = self.getFileNameFromURL(url)
                destination = self.getFileDest(year, fileName)
                print destination
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
    print "================================= SOHO SEM files ====="

    previewOnly = False
    x = sorceSolsticeDataFetcher()   
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching SOHO SEM files.  Aborting."
        sys.exit(1)
        
    

