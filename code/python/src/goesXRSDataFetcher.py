from config import SUCCESS, FAILURE
from config_lisird import LISIRD_DATA_ROOT, GOES_XRS_SOURCE, LISIRD_GOES_XRS
from util import ensurePath, getNowYear, appendSlash
import subprocess
import os
from os import path
import sys
from shutil import copy
# -----------------------------------------------------------------------------
# This dataset must be retrieved from carina via scp, which requires a 
# login and authentication.  Thus a login name is required on instantiation.  
# Then, each call to the server will require authentication unless ssh 
# keys are in place.
# -----------------------------------------------------------------------------
class goesXRSDataFetcher(): # object):

  # Values from config file
  _localRoot = None
  _source = GOES_XRS_SOURCE  # expects a directory
  _dest = LISIRD_GOES_XRS      # expects a directory

  #_userName = None   # Must be provided on init
  _remoteFileNameRoot = "goes_1mdata_widx_"
  _remoteFileNameTrailing = ".sav"

  _startYear = 1981 
  _thisYear = None
  # Due to /public/lisird disk space problem, for now, since we already have the prior year's files, 
  # just get this one year.
  # (copyToFismDir.py also updated to only copy one file)
  #  _startYear = 2012 
  
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def __init__(self ): #username):

      # Set up path pieces properly
      self._localRoot = appendSlash(LISIRD_DATA_ROOT)
      self._source    = appendSlash(GOES_XRS_SOURCE)
      self._dest      = appendSlash(LISIRD_GOES_XRS)
      self._thisYear  = getNowYear()
      #self._userName  = username

  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def xrsFileName(self, year):
      return self._remoteFileNameRoot + year + self._remoteFileNameTrailing
      
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def scpSourcePart(self, year): 
      # e.g., "scp lisird@carina:/titus/timed/analysis/goes/goes_1mdata_widx_" + year + ".sav"
      return "scp " + self._userName + "@" + self._source + self.xrsFileName(year)

  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def getDest(self, year):
#      return self._localRoot + self._dest + self.xrsFileName(year)
      return self._localRoot + self._dest

  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def getSource(self):
      return self._source()
      
  # -----------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  def get(self, previewOnly):  
      if previewOnly:
          print "PREVIEW ONLY"
      
      # Phil:
      # Fetch most recent, currently /titus/timed/analysis/goes/goes_1mdata_widx_2009.sav
      # Assume previous files already present??? 
      
      years = range(self._startYear, getNowYear() + 1)   # range is not inclusive of end point
      print "Fetching files for years: " + str(years)
       
      for iyear in years:
          year = str(iyear)
      
          #scpSourcePart = self.scpSourcePart(year)
          destination = self.getDest(year)
          exists = path.isfile(destination + self.xrsFileName(year))
          if iyear == self._thisYear:
            ensurePath(destination, previewOnly)
            #command = scpSourcePart + " " + destination
            #print command
            if not previewOnly:
                copy((self._source + self.xrsFileName(year)), destination)
                #try:
                #    returnCode = subprocess.call([command],shell=True)
                #    if returnCode > 0:
                #        print >>sys.stderr, "ERROR: scp command failed, got status ", returnCode
                 #       return FAILURE
                 #   if returnCode < 0:
                #        print >>sys.stderr, "ERROR: scp command failed, terminated by signal ", -returnCode
                #        return FAILURE             
                #except OSError, e:
                #    print >>sys.stderr, "Execution failed.", e  
                #print "Problem encountered"   
          else: 
            if exists:
                    print destination + self.xrsFileName(year) + ' already exists, checking next'
            else:
                ensurePath(destination, previewOnly)
                #command = scpSourcePart + " " + destination
                #print command
                if not previewOnly:
                    copy((self._source + self.xrsFileName(year)), destination)
                    #try:
                    #    returnCode = subprocess.call([command],shell=True)
                    #    if returnCode > 0:
                    #        print >>sys.stderr, "ERROR: scp command failed, got status ", returnCode
                    #        return FAILURE
                    #    if returnCode < 0:
                    #        print >>sys.stderr, "ERROR: scp command failed, terminated by signal ", -returnCode
                    #        return FAILURE             
                    #except OSError, e:
                    #    print >>sys.stderr, "Execution failed.", e    
      return SUCCESS    
          
          
# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------
if __name__ == '__main__':
       
    previewOnly = False
    from config_lisird import LOGIN_NAME
    x = goesXRSDataFetcher()#LOGIN_NAME)
    if x.get(previewOnly) != SUCCESS:
        print "Problem encountered in reading GOES XRS data.  Aborting."
        sys.exit(1)
          
          
          
          