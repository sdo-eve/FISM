from config import SUCCESS
from util import ensurePath, appendSlash
from URLFetcher import URLFetcher
from config_lisird import LISIRD_DATA_ROOT, SORCE_XPS5_SOURCE, LISIRD_SORCE_XPS5_DIR
import os
from os import path
import zipfile
import sys
import shutil
import glob
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
class sorceXPS5DataFetcher:

  # From the configuration
  _localRoot = None
  _source = SORCE_XPS5_SOURCE
  _dest = LISIRD_SORCE_XPS5_DIR
  
  _startYear = 2003
  _endYear = 2020  #SORCE ended in 2020
  _thisYear = None     # current year, tbd 
  
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def __init__(self):
      from util import getNowYear, appendSlash

      self._localRoot   = appendSlash(LISIRD_DATA_ROOT)
      self._sorce       = appendSlash(SORCE_XPS5_SOURCE)
      self._dest        = appendSlash(LISIRD_SORCE_XPS5_DIR)
      self._thisYear    = getNowYear()
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------  
  def genSourceURLs(self, year):  
      #for 5 minute data
      import Date
        
      urls = []
      print "Fetching for year " + year

      url = self._source + year + ".ncdf.zip"
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

      years = range(self._startYear, self._endYear + 1) # self._thisYear + 1)
      print "Fetching files for years: " + str(years)

      allFetchesSuccessful = True
      for iyear in years:
          print "-----"
          year = str(iyear)
          sourceURLs = self.genSourceURLs(year) 
          for url in sourceURLs:
              fileName = self.getFileNameFromURL(url)
              destination = self.getFileDest(year, fileName)
              #check if file exists
              if glob.glob(os.environ["fism_data"] + '/lasp/sorce/sorce_xps/full/*[' + str(iyear) + ']*.*'):
                #if it is the current year then update 
                #if iyear == self._thisYear:
                    ensurePath(getDir(destination), previewOnly)
                    print 'Writing: ' + destination  
                    if not previewOnly:
                        if readHTTP(url, destination) != SUCCESS: 
                            print "Failed to retrieve URL: " + url  
                            allFetchesSuccesful = False              
                    #unzip the file
                    zip_ref = zipfile.ZipFile(destination, 'r')
                    zip_ref.extractall(LISIRD_DATA_ROOT + '/lasp/sorce/sorce_xps/full')
                    zip_ref.close()
                    #remove zip file
                    os.remove(destination)
                    #unzfile = os.listdir(self._localRoot + 'lasp/sorce/sorce_xps/full/data/merged')
                    #old = os.environ["fism_data"] + "/lasp/sorce/sorce_xps/full/data/merged/" + unzfile[0]
                    #new = os.environ["fism_data"] + "/lasp/sorce/sorce_xps/full/" + unzfile[0]
                    #move file to correct location 
                    #os.rename(old, new)
                    #remove extra files from zip file 
                    #shutil.rmtree(os.environ["fism_data"] + "/lasp/sorce/sorce_xps/full/data/")
                #dont update if not current year
                #else:
                #    print 'File already exists, moving to next'
              else:
                ensurePath(getDir(destination), previewOnly)
                print 'Writing: ' + destination  
                if not previewOnly:
                    if readHTTP(url, destination) != SUCCESS: 
                        print "Failed to retrieve URL: " + url  
                        allFetchesSuccesful = False              
                #unzip the file
                zip_ref = zipfile.ZipFile(destination, 'r')
                zip_ref.extractall(os.environ["fism_data"] + '/lasp/sorce/sorce_xps/full')
                zip_ref.close()
                #remove zip file
                os.remove(destination)
                #unzfile = os.listdir(self._localRoot + 'lasp/sorce/sorce_xps/full/data/merged')
                #old = os.environ["fism_data"] + "/lasp/sorce/sorce_xps/full/data/merged/" + unzfile[0]
                #new = os.environ["fism_data"] + "/lasp/sorce/sorce_xps/full/" + unzfile[0]
                #move file to correct location 
                #os.rename(old, new)
                #remove extra files from zip file 
                #shutil.rmtree(os.environ["fism_data"] + "/lasp/sorce/sorce_xps/full/data/")
      return SUCCESS
      

# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------
if __name__ == '__main__':
    from config import SUCCESS, FAILURE
    previewOnly = False
    print "================================= SOLSTICE files ====="

    previewOnly = False
    x = sorceXPS5DataFetcher()   
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching SORCE SOLSTICE files.  Aborting."
        sys.exit(1)
        
    

