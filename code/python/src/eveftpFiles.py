'''
Created on Nov 14, 2011

@author: wilson
'''
from config import SUCCESS
from util import ensurePath, appendSlash
from URLFetcher import URLFetcher
from config_lisird import LISIRD_DATA_ROOT, EVE_SOURCE, LISIRD_EVE_DIR
from config_lisird import EVE_FILE_LIST

import sys

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
class eveftpFiles:

  # From the configuration
  _localRoot = None
  _source = None
  _dest = None
  _fileList = None
  
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def __init__(self):

      self._localRoot = appendSlash(LISIRD_DATA_ROOT)
      self._source    = appendSlash(EVE_SOURCE)
      self._dest      = appendSlash(LISIRD_EVE_DIR)
      self._fileList = EVE_FILE_LIST
      

  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def getSource(self, dataset):
      return self._source + dataset
  
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def getDest(self, destEnd):
      return self._dest + destEnd
  
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def get(self, previewOnly):  
      for dataset, dest in self._fileList:
          x = URLFetcher()
          source = self.getSource(dataset)
          x.setSource(source)         
          x.setDest(self.getDest(dest))
          if x.get(previewOnly) != SUCCESS:
              print "Problem encountered in fetching " + source + ".  Aborting."
              sys.exit(1)               
      return SUCCESS
  
# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------
if __name__ == '__main__':
    
    previewOnly = False
    print "================================= EVE files ====="

    x = eveftpFiles()   
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in fetching EVE files.  Aborting."
        sys.exit(1)
        
    

