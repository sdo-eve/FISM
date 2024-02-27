'''
Created on Nov 14, 2011

@author: wilson
'''
import os

from config import SUCCESS, FAILURE
from config_lisird import LISIRD_DATA_ROOT
from util import ensurePath, readHTTP, appendSlash

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
class URLFetcher(object):
  _localRoot = None
  # ??? do subclass override these or make a new instance?
  # Does it matter?
#  _source = None
#  _dest = None
       
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def __init__(self):
      self._localRoot = appendSlash(LISIRD_DATA_ROOT)

  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def getDest(self):
      return self._localRoot + self._dest
  
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def getSource(self):
      return self._source
  
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def setSource(self, source):
      self._source = source
  
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def setDest(self, dest):
      self._dest = dest
  
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def get(self, previewOnly):
      dest = self.getDest()
      destDir = dest[:dest.rindex("/")]
      ensurePath(destDir, previewOnly)
      if self.fetch(previewOnly) == SUCCESS:
          return SUCCESS
      else:
          return FAILURE


  # -----------------------------------------------------------------------------
  # Fetchs  data and places in destination
  # -----------------------------------------------------------------------------
  def fetch(self, previewOnly):  
      if previewOnly:
          print "    PREVIEW ONLY"
      print 'Fetch via: ' + self.getSource()
      print 'Writing to: ' + self.getDest()
      if previewOnly:
          return SUCCESS
      readHTTP(self.getSource(), self.getDest())
      return SUCCESS