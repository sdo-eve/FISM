'''
Created on Nov 17, 2011

@author: wilson
'''

# Fetches Bremen mg ii composite.  Stores file with a date stamp in the file name.
# Also sets 'latest' to point to the newly fetched file.
# ------------------------------------------
from config_lisird import LISIRD_DATA_ROOT, BREMEN_COMPOSITE_MG_II_SOURCE, LISIRD_BREMEN_COMPOSITE_MG_II, LISIRD_BREMEN_LATEST
from util import getNowyyyyMMdd, symlink_force
from sys import exit
from os import symlink, path
import os

class bremen_composite_mg_iiDataFetcher:
    
  _localRoot = None
  _source = BREMEN_COMPOSITE_MG_II_SOURCE
  _dest = LISIRD_BREMEN_COMPOSITE_MG_II
  _latest_dest = LISIRD_BREMEN_LATEST

  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def __init__(self):
      from util import getNowYear, appendSlash

      # Set up path pieces properly
      self._localRoot = appendSlash(LISIRD_DATA_ROOT)
      self._thisYear = getNowYear()

  # -----------------------------------------------------------------------------
  # bremen_composite_mg_ii.yyyyMMdd.dat
  # -----------------------------------------------------------------------------
  def getFileDest(self):
      return self._localRoot + self._dest + getNowyyyyMMdd() + ".dat"
  
  # -----------------------------------------------------------------------------
  # bremen_composite_mg_ii.yyyyMMdd.dat
  # -----------------------------------------------------------------------------
  def getLatestPath(self):
      return self._localRoot + self._latest_dest 
  
  # -----------------------------------------------------------------------------
  # Fetchs data and places in destination
  # -----------------------------------------------------------------------------
  def get(self, previewOnly):  
      from util import readHTTP, ensurePath, getDir
      from config import SUCCESS, FAILURE
      
      print "-----"      
      destination = self.getFileDest()
      print "lisird dest: " + destination
      ensurePath(getDir(destination), previewOnly) 
      entries = os.listdir(self._localRoot + 'bremen')
      #check if a previous file exists already
      print '----'
      for dile in entries:
        print dile
            
      print '----'
      #if it does delete it 
      if(len(entries) > 0):
        oldfile = self._localRoot + '/bremen/' + entries[0]
        print oldfile
        exists = path.isfile(oldfile)
        print exists
        if exists: #extra confirmation file exists
          print 'Deleting ' + oldfile
          os.remove(oldfile)
        else:
          print 'no file to delete'
      print 'Writing: ' + destination 
      #print "symlinking " + destination + " " + self.getLatestPath()
      if not previewOnly:
          if readHTTP(self._source, destination) != SUCCESS: 
              print "Failed to retrieve URL: " + self._source
              return FAILURE
          else:
              # make 'latest' point to this most recently retrieved file
              #symlink_force(destination, self.getLatestPath())  
              #list files in directory
              return SUCCESS 
              
      
              
# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------
if __name__ == '__main__':
    from config import SUCCESS, FAILURE
        
    previewOnly = False
    x = bremen_composite_mg_iiDataFetcher()
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in reading Bremen composite mg ii.  Aborting."
        exit(1)
