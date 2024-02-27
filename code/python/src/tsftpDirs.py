'''
Created on Nov 14, 2011

@author: wilson
'''
from ftpUtil import ftpUtil
from config import SUCCESS
from util import appendSlash, getNowYear
from config_lisird import LISIRD_DATA_ROOT, TIMED_SEE_SOURCE, LISIRD_TIMED_SEE
from config_lisird import SEE_LEVEL2A_EGS, SEE_LEVEL2A_XPS

class tsftpDirs:
    _see_level3_merged_latest = "latest_see_L3_merged.ncdf"
    _see_level3_dated_prefex = "see__L3_merged_"
     
    # From the configuration
    _localRoot = None
    _source = None
    _dest = None
    _level2a_egs = None
    _level2a_xps = None

    # -----------------------------------------------------------------------------
    # -----------------------------------------------------------------------------
    def __init__(self):
      
        self._localRoot = appendSlash(LISIRD_DATA_ROOT)
        self._source = appendSlash(TIMED_SEE_SOURCE)
        self._dest = appendSlash(LISIRD_TIMED_SEE)      
        self._level2a_egs = SEE_LEVEL2A_EGS
        self._level2a_xps = SEE_LEVEL2A_XPS
          
    # -----------------------------------------------------------------------------
    # -----------------------------------------------------------------------------
    def fetch(self, dataset, onlyNewFiles, previewOnly):
        startYear = int(dataset[2])
        currentYear = getNowYear()
        for year in range(startYear, currentYear + 1):  # +1 because range is not inclusive
            # create the mapping based on the configuration
            remotePath = self._source + dataset[0] + "/" + str(year)
            localPath = self._localRoot + self._dest + dataset[1] + "/" + str(year) + "/"
            x = ftpUtil()
            x.ftpTimedFetch(remotePath, localPath, onlyNewFiles, previewOnly)
        return SUCCESS


# -----------------------------------------------------------------------------
# main
# -----------------------------------------------------------------------------
if __name__ == '__main__':
#    from util import destPath
    
    previewOnly = False
    print "================================= SEE datasets ====="

    # Fetch all descendents
    onlyNewFiles = True  # set this to false to overwrite all files locally
    x = tsftpDirs()      
            
    print "================================= TIMED SEE level2a egs ====="
    if x.fetch(x._level2a_egs, onlyNewFiles, previewOnly) != SUCCESS:
        print "Problem encountered in fetching timed see level2a egs data.  Aborting."
        exit(1)
    
    print "================================= TIMED SEE level2a xps ====="
    if x.fetch(x._level2a_xps, onlyNewFiles, previewOnly) != SUCCESS:
        print "Problem encountered in fetching timed see level2a xps data.  Aborting."
        exit(1)

